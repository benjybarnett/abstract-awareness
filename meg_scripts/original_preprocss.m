clear;
addpath /Users/bbarnett/Documents/ecobrain/fieldtrip-master/

ft_defaults

meg_path = 'B:\Data';

%%subjects
subjects = ...
                    {   
                        'sub02'
                        
                        
                        
                        
                        
                    };
                           



subjects_with_errors = [];

for subj_idx =1:length(subjects)

    disp(strcat('**********Working on subject ', subjects{subj_idx},'***************'))
    
    subject = subjects{subj_idx};
    
    
    filenames = {...
        
        strcat('PROJ0076_SUBJ00',subject(4:5),'_SER001_FILESNO001.fif')
        %strcat('PROJ0076_SUBJ00',subject(4:5),'_SER001_FILESNO002.fif')
        %strcat('PROJ0076_SUBJ00',subject(4:5),'_SER002_FILESNO001.fif')
        %strcat('PROJ0076_SUBJ00',subject(4:5),'_SER003_FILESNO001.fif')
        %strcat('PROJ0076_SUBJ00',subject(4:5),'_SER004_FILESNO001.fif')
        %strcat('PROJ0076_SUBJ00',subject(4:5),'_SER005_FILESNO001.fif')
            };
     
    
    
    n_filenames = length(filenames);  
    output_path = fullfile(meg_path, subject);

    events = [6 7 9]; %squares, diamonds, catch

    %%read in data
    
    split_files = {}; %blank cell array to hold the various data files of each subject to concatenate
    split_file_idx = 1;
    for filename_index = 1:n_filenames
        
        

        filename = filenames{filename_index};
        full_path = fullfile(meg_path, subject, filename);
        
        if isfile(full_path) == 0
            %checks to see if file exists, if not we skip to next file.
            %necessary as different num files per subject
            continue
        end
        
        
        % define trials
        cfg = [];
        cfg.dataset = full_path;
        cfg.trialdef.prestim = 0.175; % seconds  adjusted with 25 ms 
        cfg.trialdef.poststim = 0.625; % seconds
        cfg.trialdef.eventvalue = events;
        cfg.trialfun = 'ft_trialfun_general';
        %edited the source code of this function so that it removes events
        %with length of one sample from the cfg.trl field. Can't copy it
        %and use it outside of source code since throws weird error?
        
        cfg.trialdef.eventtype = 'STI101';
        cfg = ft_definetrial(cfg);

        % preprocess

        cfg.demean = 'yes';
        cfg.baselinewindow = [-0.175 0.025];
        cfg.lpfilter = 'no';
        cfg.hpfilter = 'no';
        cfg.dftfilter = 'yes';
        
        
        if strcmp(subject, 'sub06') 
            %missing EOG data for sub06 so we only include MEG channels
            cfg.channel = 'MEG';
        end

        split_files{split_file_idx} = ft_preprocessing(cfg); %preprocess
        split_file_idx = split_file_idx + 1 ;
        
    end

    %{
    
    % concat split files
    disp('hi')
    cfg = [];
    cfg.keepsampleinfo='no'; %%SHOULD I USE THIS?
    concat_data = ft_appenddata(cfg, split_files{:});
    disp('done');
    
   
    

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

    int_correct = zeros(trial_info_length,1);

    %change strings for correct variable into integer
    %for concatenation ease later
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
    
    
    
    %remove trials from .data file if they do not exist in the meg data
    %this occurred when the meg data files were split across trials, this means
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
            
    
    concat_data.trialinfo = [concat_data.trialinfo trial_info]; %add excel data to MEG data in .trialinfo
    
    
    %%%%%%%CHECK%%%%%%%%%%%%
    %check all trials from meg data match .data file
    %add subj ID to list if there is a mismatch
    
    for trial = 1:length(concat_data.trialinfo)
        if  (concat_data.trialinfo(trial) == 6 && trial_info(trial,1) == 1) || ...
                (concat_data.trialinfo(trial) == 7 && trial_info(trial,1) == 2) || ...
                    (concat_data.trialinfo(trial) == 9 && trial_info(trial,1) == 3)
              continue
            
        else
            subjects_with_errors = [subjects_with_errors subject];
            break
        end
    end
    %}
    %%%%%%%%%%%%%%%%%%%%%end check%%%%%%%%%%%55
    
    %%----------Finished reading in data from accompanying excel .data file--------%%
    %}
    %save(strcat(subject,'\',subject),'concat_data','-v7.3')
    concat_data = split_files{1};
    save('sub02_625_default','concat_data','-v7.3')

    
end %finish loop over subjects



