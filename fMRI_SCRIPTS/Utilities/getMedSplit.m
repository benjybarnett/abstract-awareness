function [med] = getMedSplit(subject, data_dir)
%function to determine median rating in order to perform a median split
%where every rating below the median is a low visibility rating, and
%evrything equal to or above the median is high visibility ratings

%INPUT: (string) subject number
%OUTPUT: (double) median rating value


SPM = load(strcat(data_dir,subject,'\SPM.mat'));
SPM=SPM.SPM;

%read in only conscious trials
trials = {};
for trl = 1:length(SPM.xX.name)
    if contains(SPM.xX.name(trl),' conscious')
        trials = [trials SPM.xX.name(trl)];
    end
end


all_ratings = [];

    for trial = 1:length(trials) %loop through trials to add up different visibility ratings

        trl = reverse(char(trials(trial)));
        if trl(7) == '1'
            all_ratings = [all_ratings 1];
        elseif trl(7) =='2'
            all_ratings = [all_ratings 2];
        elseif trl(7) == '3'
            all_ratings = [all_ratings 3];
        elseif trl(7) == '4'
            all_ratings = [all_ratings 4];
        else 
            disp(trl(7));
        end
    end

    med = median(all_ratings); %get median for split
  

end


