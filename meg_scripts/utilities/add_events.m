function  [concat_data, subj_error] = add_events(concat_data, meg_path,subject)

    %%%function reads in the events from external .data files and appends
    %%%them to the data.trialinfo field. 
    %%%RETURNS: 
    %%% concat_data : (data structure) data structure with added .trialinfo field
    %%% subj_error : (boolean) whether there is an error in the matching of external data to event data in meg file
    
    subj_error=false;
    
    %%--------------Read in data from accompanying excel .data file-----------------%%
    info_path = fullfile(meg_path, subject,'*.data');
    info_file_ = dir(info_path);
    info_file = fullfile(meg_path, subject,info_file_.name);
    trial_info = readcell(info_file,'FileType','text','NumHeaderLines',1);

    %create table with  info of interest
    %stim, contrast, correct,RT,PAS,response
    trial_info = trial_info(:,[5,7,9,10,11,14]);

    trial_info_size = size(trial_info);
    trial_info_length = trial_info_size(1);

    %change strings for correct variable into integer
    %for concatenation ease later %%%%%%%%%%%
    int_correct = zeros(trial_info_length,1);
    for i = 1:trial_info_length
        correct = trial_info(i,3);
        correct = correct{1,1};
        if strcmp(correct,'true')
            int_correct(i) = 1;
        elseif strcmp(correct,'false')
            int_correct(i) = 0;
        elseif strcmp(correct,'catch_trial')
            int_correct(i) = 2;
        elseif strcmp(correct,'too_slow')
            int_correct(i) = 3;
        end
    end
    trial_info(:,3) = num2cell(int_correct); %add the new column denoting trials correct, replacing the col with strings
    trial_info = cell2mat(trial_info); %creates a matrix of the data from the .data file
    %%%%%conversion of strings to integers complete%%%%%%


    %remove trials from .data file if they do not exist in the meg data
    %this occurrs when the meg data files are split across trials, this means
    %this trial's data cannot be recovered
    remove = false;
    for trial = 1:length(concat_data.trialinfo)
        if  (concat_data.trialinfo(trial) == 6 && trial_info(trial,1) == 1) || ...
                (concat_data.trialinfo(trial) == 7 && trial_info(trial,1) == 2) || ...
                    (concat_data.trialinfo(trial) == 9 && trial_info(trial,1) == 3)
              continue
        else
            idx_to_remove = trial;
            remove = true;
            break
        end
    end

    if remove == true
        trial_info(idx_to_remove,:) = []; %remove trials from .data files that arent in meg data
    end
    

    disp(size(concat_data.trialinfo))
    disp(size(trial_info))
    concat_data.trialinfo = [concat_data.trialinfo trial_info]; %add excel data to MEG data in .trialinfo


    %%%%%%%CHECK%%%%%%%%%%%%
    %check all trials from meg data match .data file
    %return subject error = True if the is a mismatch
    for trial = 1:length(concat_data.trialinfo)
        if  (concat_data.trialinfo(trial) == 6 && trial_info(trial,1) == 1) || ...
                (concat_data.trialinfo(trial) == 7 && trial_info(trial,1) == 2) || ...
                    (concat_data.trialinfo(trial) == 9 && trial_info(trial,1) == 3)
              continue
        else
            subj_error = true;
            break
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%end check%%%%%%%%%%%55

    
    %%----------Finished reading in data from accompanying excel .data file--------%%
end 