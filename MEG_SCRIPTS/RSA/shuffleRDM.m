function [shuffledRDM, shuffledGradedRDM] = shuffleRDM(RDM_flat,idxs)
    %shuffles and blurs RDM to alter model while maintaining frequency
    
    %first shuffle RDM
    mRDM_shuff = RDM_flat(randperm(length(RDM_flat)));
    shuffledRDM = mRDM_shuff;
    fullRDM = ones(8,8);
    fullRDM(idxs) = mRDM_shuff; %put shuffled RDM back in 8x8 RDM to make blurring easier
    %blur 
    if rand < 0.5 % on 50% trials we run blurring from the other end of the RDM, so that over the course of N permutations we have balanced whether the first cells or the last cells get priority in blending
        for i = 1:size(fullRDM,1)
            for j = 1:size(fullRDM,2)
                if fullRDM(i,j) == 0
                    %N/E/S/W neighbours get high blending
                    %Four Diagonals get low blending
                    if i < size(fullRDM,1) && fullRDM(i+1,j) ~= 0
                            fullRDM(i+1,j) = 0.25; %S
                      
                    end
                    if j < size(fullRDM,1) && fullRDM(i,j+1)~= 0
                        fullRDM(i,j+1) = 0.25; %E
                    end
                    if i > 1 && fullRDM(i-1,j)~= 0
                        fullRDM(i-1,j) = 0.25; %N
                        
                    end
                    if j > 1 && fullRDM(i,j-1)~= 0
                        fullRDM(i,j-1) = 0.25;%W
                    end
                    if i>1 && j>1  && fullRDM(i-1,j-1)~= 0
                        fullRDM(i-1,j-1) = 0.5; %NW
                    end
                    if i < size(fullRDM,1) && j < size(fullRDM,2)  && fullRDM(i+1,j+1)~= 0
                        fullRDM(i+1,j+1) = 0.5; %SE
                    end
                    if i < size(fullRDM,1) && j > 1  && fullRDM(i+1,j-1)~= 0
                        fullRDM(i+1,j-1) = 0.5; %SW
                    end
                    if i>1 && j < size(fullRDM,2)  && fullRDM(i-1,j+1)~= 0
                        fullRDM(i-1,j+1) = 0.5; %NE
                    end
                end
    
    
            end
        end
    else
        for i = size(fullRDM,1):-1:1
            for j = size(fullRDM,2):-1:1
                if fullRDM(i,j) == 0
                    %N/E/S/W neighbours get high blending
                    %Four Diagonals get low blending
                    if i < size(fullRDM,1) && fullRDM(i+1,j) ~= 0
                            fullRDM(i+1,j) = 0.25; %S
                      
                    end
                    if j < size(fullRDM,1) && fullRDM(i,j+1)~= 0
                        fullRDM(i,j+1) = 0.25; %E
                    end
                    if i > 1 && fullRDM(i-1,j)~= 0
                        fullRDM(i-1,j) = 0.25; %N
                        
                    end
                    if j > 1 && fullRDM(i,j-1)~= 0
                        fullRDM(i,j-1) = 0.25;%W
                    end
                    if i>1 && j>1  && fullRDM(i-1,j-1)~= 0
                        fullRDM(i-1,j-1) = 0.5; %NW
                    end
                    if i < size(fullRDM,1) && j < size(fullRDM,2)  && fullRDM(i+1,j+1)~= 0
                        fullRDM(i+1,j+1) = 0.5; %SE
                    end
                    if i < size(fullRDM,1) && j > 1  && fullRDM(i+1,j-1)~= 0
                        fullRDM(i+1,j-1) = 0.5; %SW
                    end
                    if i>1 && j < size(fullRDM,2)  && fullRDM(i-1,j+1)~= 0
                        fullRDM(i-1,j+1) = 0.5; %NE
                    end
                end
    
    
            end
        end
    end
    shuffledGradedRDM = fullRDM(idxs); %vectorise lower triangle without diagonal

    
end