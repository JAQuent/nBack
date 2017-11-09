% % % % % % % % % % % % % % % % % % % % % % % % % 
% n-back task after Jaeggi et al. 2010
% Author: Alexander Quent (alexander.quent@rub.de)
% Version: 1.7 23 Feburary 2017
% % % % % % % % % % % % % % % % % % % % % % % % % 

try
    % Preliminary stuff
    % Clear Matlab/Octave window:
    clc;
    
    % Reseed randomization
    rand('state', sum(100*clock));
    
    % check for Opengl compatibility, abort otherwise:
    AssertOpenGL;
    
    % General information about subject and session
    subNo = input('Subject number: ');
    date  = str2num(datestr(now,'yyyymmdd'));
    time  = str2num(datestr(now,'HHMMSS'));
    
    % Get information about the screen and set general things
    Screen('Preference', 'SuppressAllWarnings',0);
    Screen('Preference', 'SkipSyncTests', 0);
    screens       = Screen('Screens');
    if length(screens) > 1
        error('Multi display mode not supported.');
    end
    rect          = Screen('Rect',0);
    screenRatio   = rect(3)/rect(4);
    pixelSizes    = Screen('PixelSizes', 0);
    startPosition = round([rect(3)/2, rect(4)/2]);
    HideCursor;
    
    % Experimental variables
    % Number of trials etc.
    lowestLevel         = 1; % n
    highestLevel        = 4;
    numOfBlocks         = 3;
    targetsPerBlock     = 6;
    nonTargetsPerBlock  = 14; % + n
    trialsPerBlock      = []; % Number of trials for a block per level
    nTrial              = []; % Total number of trials per level
    for n = lowestLevel:highestLevel
        trialsPerBlock(n) = nonTargetsPerBlock + targetsPerBlock + n;
        nTrial(n)         = trialsPerBlock(n)*numOfBlocks;
    end
    totalNTrial        = sum(nTrial);
    
    % Output files
    datafilename = strcat('results/nBack_',num2str(subNo),'.dat'); % name of data file to write to
    mSave        = strcat('results/nBack_',num2str(subNo),'.mat'); % name of another data file to write to (in .mat format)
    mSaveALL     = strcat('results/nBack_',num2str(subNo),'_all.mat'); % name of another data file to write to (in .mat format)
    xSave        = strcat('results/nBack_',num2str(subNo),'.xls'); % name of another data file to write to (in .xls format)
    % Checks for existing result file to prevent accidentally overwriting
    % files from a previous subject/session (except for subject numbers > 99):
    if subNo<99 && fopen(datafilename, 'rt')~=-1
        fclose('all');
        error('Result data file already exists! Choose a different subject number.');
    else
        datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing
    end
    
    % Temporal variables
    ISI                 = 2.5;
    stimDuration        = 0.5;
    
    % Experimental data
    RT                  = zeros(1, totalNTrial)-99;
    response            = zeros(1, totalNTrial)+99;
    correctness         = zeros(1, totalNTrial)+99; % Hit = 1, False alarm =  2, Miss =  3,  Correct rejection = 4
    results             = cell(totalNTrial, 14); % SubNo, date, time, trial, stim, level, block, rightAnswer, response, correctness, RT, StimulusOnsetTime1, StimulusEndTime1, trial length
    
    % Colors
    bgColor             = [255 255 255];
    
    % Creating screen etc.
    try
        [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
    catch
        try
            [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
        catch
            try
                [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
            catch
                try
                    [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
                catch
                    [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
                end
            end
        end
    end
    center              = round([rect(3) rect(4)]/2);
    
    % Keys and responses
    KbName('UnifyKeyNames');
    space               = KbName('space');
    right_control       = KbName('RightControl');
    numberKeys          = [KbName('1!') KbName('2@') KbName('3#') KbName('4$') KbName('5%') KbName('6^')];
    
    % Loading stimuli and making texture
    [trialList, levels, blocks] = nBackCreateTrialList(lowestLevel, highestLevel,trialsPerBlock ,targetsPerBlock, numOfBlocks);
    images              = {};
    stimuli             = {};
    for i = 1:10
        images{i}  = imread(strcat('stimuli/stim_',num2str(i),'.jpeg'));
        stimuli{i} = Screen('MakeTexture', myScreen, images{i});
    end
    
    % Message for introdution
    lineLength   = 70; % Sets the maximal length of each line (in characters) to ensure a block text. 
    messageIntro = WrapString('N-Back Aufgabe \n\n In dieser Aufgabe werden Ihnen geometrische Figuren präsentiert. Ihre Aufgabe ist es zu entscheiden, ob eine bestimmte Figur (Zielreiz) bereits an einem vorherigen Durchgang, dem Durchgang « n », präsentiert wurde. Die Aufgabe startet einfach und endet schwierig. Zuerst sollen Sie angeben, ob der Zielreiz 1 Durchgang  (n = 1) vorher bereits präsentiert wurde. Die Anzahl der vorherigen Durchgänge steigt mit jedem Abschnitt des Experiments (Block) an, sodass Sie zum Ende hin angeben müssen, ob Sie den Zielreiz vor 4 Durchgängen (n = 4) gesehen haben.\n\n Sobald Sie glauben, dass ein Stimulus n Durchgänge zuvor präsentiert wurde, drücken Sie bitte die rechte Steuerungstaste (Strg rechts). Die Stimuli selbst werden nur kurz eingeblendet, Sie haben aber solange Zeit zu antworten, bis der nächste Stimulus eingeblendet wird. Ansonsten müssen Sie keine Taste drücken und können einfach warten bis der nächste Stimulus angezeigt wird. Die einzelnen Bedingungen werden Ihnen vor jedem Block noch einmal genauer erklärt. \n Bitte drücken Sie die Leertaste, um zur nächsten Seite zu gelangen.',lineLength);
    
    % Experimental loop
    for trial = 1:length(trialList)
        % Block and n-back information
        if trial == 1 % Shows introduction
            DrawFormattedText(myScreen, messageIntro, 'center', 'center');
            Screen('Flip', myScreen);
            [responseTime, keyCode] = KbWait;
            while keyCode(space) == 0
                [responseTime, keyCode] = KbWait;
            end
        end
        if trial == 1 || levels(trial) ~= levels(trial-1) || blocks(trial) ~= blocks(trial-1)
           if levels(trial) == 1 && blocks(trial) == 1
               % Instruction for block
               % Example array: 1 8 9 9 10 3
               % Correct answer = 4 (button press)
               exampleArray_img  = imread(strcat('stimuli/example_',num2str(levels(trial)),'.jpeg'));
               exampleArray_size = size(exampleArray_img);
               exampleArray_tex  = Screen('MakeTexture', myScreen, exampleArray_img);
               introResponse   = 4;
               messageBlockInfo         =  WrapString(horzcat( num2str(blocks(trial)),'. Block, ', 'N = ', num2str(levels(trial)),'.\n In dieser Bedingung müssen Sie die rechte Steuerungstaste drücken, wenn ', num2str(levels(trial)),' Durchgang zuvor der gleiche Stimlus präsentiert wurde. Unter diesem Text sehen Sie eine Beispielreihe von Stimuli, wie Sie auch im Experiment einzeln präsentiert werden könnten. Geben Sie mit der Hilfe der Zahlen oben auf der Tastatur an, an welcher Stelle Sie im Experiment die rechte Steuerungstaste drücken müssten. '),lineLength);
               DrawFormattedText(myScreen, messageBlockInfo, 'center', 'center');
               Screen('DrawTexture', myScreen, exampleArray_tex, [] , round([center(1) - exampleArray_size(2)/2 rect(4)*0.8 - exampleArray_size(1)/2 center(1) + exampleArray_size(2)/2 rect(4)*0.8 + exampleArray_size(1)/2]));
                
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(numberKeys(introResponse)) == 0
                    [~, keyCode] = KbWait;
               end
               
               % Start block
               DrawFormattedText(myScreen, horzcat('Um ', num2str(blocks(trial)),'. Block zu starten, bitte Leertaste drücken!'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(space) == 0
                    [~, keyCode] = KbWait;
               end
           elseif levels(trial) == 2 && blocks(trial) == 1
               % Instruction for block
               % Example array: 4 8 9 7 4 7
               % Correct answer = 6 (button press)
               exampleArray_img  = imread(strcat('stimuli/example_',num2str(levels(trial)),'.jpeg'));
               exampleArray_size = size(exampleArray_img);
               exampleArray_tex  = Screen('MakeTexture', myScreen, exampleArray_img);
               introResponse     = 6;
               messageBlockInfo  =  WrapString(horzcat( num2str(blocks(trial)),'. Block, ', 'N = ', num2str(levels(trial)),'.\n In dieser Bedingung müssen Sie die rechte Steuerungstaste drücken, wenn ', num2str(levels(trial)),' Durchgänge zuvor der gleiche Stimlus präsentiert wurde. Unter diesem Text sehen Sie eine Beispielreihe von Stimuli, wie Sie auch im Experiment einzeln präsentiert werden könnten. Geben Sie mit der Hilfe der Zahlen oben auf der Tastatur an, an welcher Stelle Sie im Experiment die rechte Steuerungstaste drücken müssten. '),lineLength);
               DrawFormattedText(myScreen, messageBlockInfo, 'center', 'center');
               Screen('DrawTexture', myScreen, exampleArray_tex, [] , round([center(1) - exampleArray_size(2)/2 rect(4)*0.8 - exampleArray_size(1)/2 center(1) + exampleArray_size(2)/2 rect(4)*0.8 + exampleArray_size(1)/2]));
                
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(numberKeys(introResponse)) == 0
                    [~, keyCode] = KbWait;
               end
               
               % Start block
               DrawFormattedText(myScreen, horzcat('Um ', num2str(blocks(trial)),'. Block zu starten, bitte Leertaste drücken!'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(space) == 0
                    [~, keyCode] = KbWait;
               end
           elseif levels(trial) == 3 && blocks(trial) == 1
               % Instruction for block
               % Example array: 8 6 1 8 7 2
               % Correct answer = 4 (button press)
               exampleArray_img  = imread(strcat('stimuli/example_',num2str(levels(trial)),'.jpeg'));
               exampleArray_size = size(exampleArray_img);
               exampleArray_tex  = Screen('MakeTexture', myScreen, exampleArray_img);
               introResponse     = 4;
               messageBlockInfo  =  WrapString(horzcat( num2str(blocks(trial)),'. Block, ', 'N = ', num2str(levels(trial)),'.\n In dieser Bedingung müssen Sie die rechte Steuerungstaste drücken, wenn ', num2str(levels(trial)),' Durchgänge zuvor der gleiche Stimlus präsentiert wurde. Unter diesem Text sehen Sie eine Beispielreihe von Stimuli, wie Sie auch im Experiment einzeln präsentiert werden könnten. Geben Sie mit der Hilfe der Zahlen oben auf der Tastatur an, an welcher Stelle Sie im Experiment die rechte Steuerungstaste drücken müssten. '),lineLength);
               DrawFormattedText(myScreen, messageBlockInfo, 'center', 'center');
               Screen('DrawTexture', myScreen, exampleArray_tex, [] , round([center(1) - exampleArray_size(2)/2 rect(4)*0.8 - exampleArray_size(1)/2 center(1) + exampleArray_size(2)/2 rect(4)*0.8 + exampleArray_size(1)/2]));
                
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(numberKeys(introResponse)) == 0
                    [~, keyCode] = KbWait;
               end
               
               % Start block
               DrawFormattedText(myScreen, horzcat('Um ', num2str(blocks(trial)),'. Block zu starten, bitte Leertaste drücken!'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [responseTime, keyCode] = KbWait;
               while keyCode(space) == 0
                    [responseTime, keyCode] = KbWait;
               end
           elseif levels(trial) == 4 && blocks(trial) == 1
               % Instruction for block
               % Example array: 10 9 8 8 10 6
               % Correct answer = 5 (button press)
               exampleArray_img  = imread(strcat('stimuli/example_',num2str(levels(trial)),'.jpeg'));
               exampleArray_size = size(exampleArray_img);
               exampleArray_tex  = Screen('MakeTexture', myScreen, exampleArray_img);
               introResponse     = 5;
               messageBlockInfo  =  WrapString(horzcat( num2str(blocks(trial)),'. Block, ', 'N = ', num2str(levels(trial)),'.\n In dieser Bedingung müssen Sie die rechte Steuerungstaste drücken, wenn ', num2str(levels(trial)),' Durchgänge zuvor der gleiche Stimlus präsentiert wurde. Unter diesem Text sehen Sie eine Beispielreihe von Stimuli, wie Sie auch im Experiment einzeln präsentiert werden könnten. Geben Sie mit der Hilfe der Zahlen oben auf der Tastatur an, an welcher Stelle Sie im Experiment die rechte Steuerungstaste drücken müssten. '),lineLength);
               DrawFormattedText(myScreen, messageBlockInfo, 'center', 'center');
               Screen('DrawTexture', myScreen, exampleArray_tex, [] , round([center(1) - exampleArray_size(2)/2 rect(4)*0.8 - exampleArray_size(1)/2 center(1) + exampleArray_size(2)/2 rect(4)*0.8 + exampleArray_size(1)/2]));
                
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(numberKeys(introResponse)) == 0
                    [~, keyCode] = KbWait;
               end
               
               % Start block
               DrawFormattedText(myScreen, horzcat('Um ', num2str(blocks(trial)),'. Block zu starten, bitte Leertaste drücken!'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(space) == 0
                    [~, keyCode] = KbWait;
               end
           else 
               % Start block
               DrawFormattedText(myScreen, horzcat('Um ', num2str(blocks(trial)),'. Block zu starten, bitte Leertaste drücken!'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(space) == 0
                    [~, keyCode] = KbWait;
               end
           end
        end
        startOfTrial = GetSecs;
        
        % Stimulus presentation
        Screen('DrawTexture', myScreen, stimuli{trialList(1,trial)});
        [VBLTimestamp StimulusOnsetTime1] = Screen('Flip', myScreen);
        % Response recording
        [keyIsDown, responseTime1, keyCode] = KbCheck; % saves whether a key has been pressed, seconds and the key which has been pressed.
        while keyCode(right_control) == 0 
            [keyIsDown, responseTime1, keyCode] = KbCheck;
            if responseTime1 - StimulusOnsetTime1 >= stimDuration
                [VBLTimestamp StimulusEndTime1]  = Screen('Flip', myScreen);
                if responseTime1 - StimulusOnsetTime1 >= stimDuration + ISI
                    break
                end
            end
        end
        
        if responseTime1 - StimulusOnsetTime1 < stimDuration
            WaitSecs(stimDuration - (responseTime1 - StimulusOnsetTime1));
            [VBLTimestamp StimulusEndTime1]  = Screen('Flip', myScreen); 
        end

        % Checking correctness
        if keyCode(right_control) == 1
            RT(trial) = (responseTime1 - StimulusOnsetTime1)*1000; % Converts to milliseconds
            response(trial) = 1;
            if trialList(2, trial) == 1
                correctness(trial) = 1; % Hit
            else
                correctness(trial) = 2; % False Alarm
            end
        else
            response(trial) = 0;
            if trialList(2, trial) == 1
                correctness(trial) = 3; % Miss
            else
                correctness(trial) = 4; % Correct rejection
            end
        end
        t2 = GetSecs;
        % Presenting blank screen for remaining time
        if t2 - StimulusEndTime1 < ISI
            WaitSecs(ISI - (t2 - StimulusEndTime1));
        end
        
        % SubNo, date, time, trial, stim, level, block, rightAnswer,
        % response, correctness, RT, StimulusOnsetTime1, StimulusEndTime1,
        % trial length
        endOfTrial = GetSecs;
        fprintf(datafilepointer,'%i %i %i %i %i %i %i %i %i %i %f %f %f %f\n', ...
            subNo, ...
            date, ...
            time, ...
            trial, ...
            trialList(1,trial), ...
            levels(trial), ...
            blocks(trial), ...
            trialList(2, trial), ...
            response(trial),...
            correctness(trial),...
            RT(trial),...
            (StimulusOnsetTime1-startOfTrial)*1000,... % Calculating stimulus onset time
            (StimulusEndTime1-startOfTrial)*1000,...
            (endOfTrial-startOfTrial)*1000);   
        
        results{trial, 1}  = subNo;
        results{trial, 2}  = date;
        results{trial, 3}  = time;
        results{trial, 4}  = trial;
        results{trial, 5}  = trialList(1,trial);
        results{trial, 6}  = levels(trial);
        results{trial, 7}  = blocks(trial);
        results{trial, 8}  = trialList(2, trial);
        results{trial, 9}  = response(trial);
        results{trial, 10} = correctness(trial);
        results{trial, 11} = RT(trial);
        results{trial, 12} = (StimulusOnsetTime1-startOfTrial)*1000;
        results{trial, 13} = (StimulusEndTime1-startOfTrial)*1000;
        results{trial, 14} = (endOfTrial-startOfTrial)*1000;
    end
    save(mSave, 'results');
    save(mSaveALL);
    xlswrite(xSave, results);  
    Screen('CloseAll')
    fclose('all')
catch
    rethrow(lasterror)
    Screen('CloseAll')
    save(mSave, 'results');
    save(mSaveALL);
    xlswrite(xSave, results);
    fclose('all')
end
% Changes:
% 4. Mapping der response keys?
% Response time?