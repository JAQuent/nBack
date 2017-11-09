function [trialList, levels, blocks] = nBackCreateTrialList_v1_2(lowestLevel, highestLevel,trialsPerBlock ,targetsPerBlock, numOfBlocks)
%Creates stimuli list for n-back task.
% Version 1.2
    trialList = [];
    levels    = [];
    blocks    = [];
    for n = lowestLevel:highestLevel
        disp(horzcat('Creating trial list for level n = ', num2str(n)))
        %  First try of creating trial list with targetsPerBlock
        for block      = 1:numOfBlocks
            targetCount    = 0; % Variable counting the n-back targets in a block
            levelsBlock    = zeros(1, trialsPerBlock(n)) + n; % Indicating the level of every trial
            blocksBlock    = zeros(1, trialsPerBlock(n)) + block; % Indicating the block of every trial
            trialListBlock(1, 1:trialsPerBlock(n)) = randi(10,1, trialsPerBlock(n)); % Indicating stimulus number
            trialListBlock(2, 1:trialsPerBlock(n)) = zeros(1, trialsPerBlock(n)); % Indicating target status

            % Counting the number of targetsPerBlock in trialListBlock
            for position = 1:length(trialListBlock)
                if position > n
                    if trialListBlock(1, position) == trialListBlock(1, position - n)
                        targetCount = targetCount + 1;
                        trialListBlock(2, position) = 1;
                    end
                end
            end
            moreThanThree = 0;
            for i = 1:length(trialListBlock) - 4 % Checking whether a stimulus more than three times
                if trialListBlock(1, i + 1) ==  trialListBlock(1, i + 2) &&  trialListBlock(1, i + 3) == trialListBlock(1, i + 1) &&  trialListBlock(1, i + 1) == trialListBlock(1, i + 4)
                    moreThanThree = 1;
                end
            end
            % Checking whether the number of targets in trialListBlock is
            % equal to targetsPerBlock
            if targetCount ~= targetsPerBlock || moreThanThree == 1% Not equal so do it again
                
                while targetCount ~= targetsPerBlock || moreThanThree == 1
                    targetCount    = 0;
                    moreThanThree  = 0;
                    trialListBlock(1, 1:trialsPerBlock(n)) = randi(10,1, trialsPerBlock(n));
                    trialListBlock(2, 1:trialsPerBlock(n)) = zeros(1, trialsPerBlock(n));
                    for position = 1:length(trialListBlock)
                        if position > n
                            if trialListBlock(1, position) == trialListBlock(1, position - n)
                                targetCount = targetCount + 1;
                                trialListBlock(2, position) = 1;
                            end
                        end
                    end
                    for i = 1:length(trialListBlock) - 4 % Checking whether a stimulus is repeated more than three times
                        if trialListBlock(1, i + 1) ==  trialListBlock(1, i + 2) &&  trialListBlock(1, i + 3) == trialListBlock(1, i + 1) &&  trialListBlock(1, i + 1) == trialListBlock(1, i + 4)
                            moreThanThree = 1;
                        end
                    end
                end
            end
                levels    = [levels levelsBlock];
                blocks    = [blocks blocksBlock];
                trialList = [trialList trialListBlock];
        end
    end
end

