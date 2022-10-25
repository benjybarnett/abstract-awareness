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
 
     
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    %load original data and artefact rejected data
    
    %original data
    orig_data = load(fullfile(meg_path,subject,[subject,'.mat']));
    orig_data = orig_data.data;
    orig_samples = orig_data.sampleinfo;
    
    %rejected GRAD trials
    rej_grad = load(fullfile(meg_path,subject,[subject,'_cfgart_grad.mat']));
    rej_grad = rej_grad.cfgart_grad;
    grad_samples = rej_grad.artfctdef.grad.artifact;
    
    %rejected MAG trials
    rej_mag = load(fullfile(meg_path,subject,[subject,'_cfgart_mag.mat']));
    rej_mag = rej_mag.cfgart_mag;
    mag_samples = rej_mag.artfctdef.mag.artifact;

    
    %rejected EOG trials
    try
        rej_eog = load(fullfile(meg_path,subject,[subject,'_cfgart_eog.mat']));
        rej_eog = rej_eog.cfgart_eog;
        eog_samples = rej_eog.artfctdef.blinks.artifact;
    catch
        disp('No EOG artefact data')
        eog_samples =[];
    end
    
    %loop through rejected trial samples
    rejected_trials = [];
    samples = {grad_samples,mag_samples,eog_samples};
    for smp_idx = 1:length(samples)
        sample_type = samples(smp_idx);
        sample_type = sample_type{1} ;
        
        for trl_idx = 1:size(sample_type,1)
            
            
            sample = sample_type(trl_idx,:);

            sample1 = sample(1);
            sample2 = sample(2);

            [begin_pos,~] = find(orig_samples == sample1); %find which trial rejected sample begins
            [end_pos,~] = find(orig_samples == sample2); %find which trial rejected sample ends
            rej_trials = begin_pos:1:end_pos; %get all intermediate trials between beginning and end sample
            rejected_trials = [rejected_trials rej_trials];
            
        end
        
    end
    
    subjects_rejected_trials{2,subj} = unique(sort(rejected_trials));
    subjects_rejected_trials{1,subj} = subject;
    
    %check against clean data files
    clean_data = load(fullfile(clean_path,subject,[subject,'_clean.mat']));
    clean_data = clean_data.data;
    
    num_clean_trials = size(clean_data.sampleinfo,1);
    is_correct = num_clean_trials == (size(orig_samples,1)-size(subjects_rejected_trials{2,subj},2));
    disp(is_correct);
    
end


