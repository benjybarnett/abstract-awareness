addpath /bbarnett/Documents/ecobrain/scripts/utilities/
addpath /bbarnett/Documents/ecobrain/scripts/Decoding/
addpath /bbarnett/Documents/ecobrain/scripts/Decoding/plotting/
addpath /bbarnett/Documents/ecobrain/scripts/Decoding/stats/

addpath('/bbarnett/Documents/ecobrain/MVPA-Light\startup')
addpath /bbarnett/Documents/ecobrain/fieldtrip-master-MVPA/
startup_MVPA_Light
ft_defaults
meg_path = 'B:\benjy_backup\data\';
subjects_path = 'C:\Users\bbarnett\Documents\ecobrain\';
clean_path = 'D:\bbarnett\Documents\ecobrain\data\';


%%subjects
subjects = ...
{    
    'sub02'
    'sub03'
    'sub04'
    'sub05'
    'sub06'
    'sub07'
    'sub08'
    'sub09'
    'sub10'
    'sub11'
    'sub12'
    %'sub13'
    'sub15'
    'sub16'
    'sub17'
    'sub18'
    'sub19'
    'sub20'
         };

rejected_trials = [];    
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    %load original data and artefact rejected data
    
    %original data
    orig_data = load(fullfile(meg_path,subject,[subject,'.mat']));
    orig_data = orig_data.data;
    orig_samples = orig_data.sampleinfo;
    
    %clean data files
    clean_data = load(fullfile(clean_path,subject,[subject,'_clean.mat']));
    clean_data = clean_data.data;
    
    %loop through rejected trial samples
    accepted_trials = [];

    for trl_idx = 1:size(clean_data.sampleinfo,1)


        sample = clean_data.sampleinfo(trl_idx,:);

        sample1 = sample(1);
        

        [begin_pos,~] = find(orig_samples == sample1); %find which trial accepted sample begins
        acc_trials = begin_pos; 
        accepted_trials = [accepted_trials acc_trials];

    end

    subjects_accepted_trials{2,subj} = unique(sort(accepted_trials));
    subjects_accepted_trials{1,subj} = subject;
    
    
    num_clean_trials = size(clean_data.sampleinfo,1);
    is_correct = (num_clean_trials == size(subjects_accepted_trials{2,subj},2)); %check if numbers match
    disp(is_correct);
    
    rejected_trials = [rejected_trials (size(orig_samples,1) - num_clean_trials)];
    disp(rejected_trials)
end

save('accepted_trials.mat','subjects_accepted_trials');


