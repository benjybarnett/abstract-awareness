subj_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results';

accAI_paths = {};
accIA_paths = {};
for subj = 1:length(subjs)
    
    subject = subjs{subj};
    
    accAI_path = fullfile(subj_dir,subject,'cross',['train_animate','.nii']);
    accAI_paths{subj} = accAI_path;
    accIA_path = fullfile(subj_dir,subject,'cross',['train_inanimate','.nii']);
    accIA_paths{subj} = accIA_path;
end
    
%take average of AI map and IA map for each subject
for map = 1:length(accAI_paths)
    subject = subjs{map};
    output_file = fullfile(subj_dir,subject,'cross',['average','.nii']);
    spm_imcalc({char(accAI_paths{map}),char(accIA_paths{map})}, output_file,'(i1+i2)/2')
    
end

%make4D files of all AI maps, IA maps, and average maps
AI_files = {};
IA_files = {};
avg_files = {};
for subj = 1:length(subjs)
    
    subject = subjs{subj};
    
    accAI_path = fullfile(subj_dir,subject,'cross',['train_animate','.nii']);
    AI_files{subj} = accAI_path;
    accIA_path = fullfile(subj_dir,subject,'cross',['train_inanimate','.nii']);
    IA_files{subj} = accIA_path;
    avg_path = fullfile(subj_dir,subject,'cross',['average','.nii']);
    avg_files{subj} = avg_path;
    
end
AI_4D = spm_file_merge(AI_files,'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\group\cross\accuracyAI.nii');
IA_4D = spm_file_merge(IA_files,'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\group\cross\accuracyIA.nii');
avg_4D = spm_file_merge(AI_files,'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\group\cross\accuracy.nii');


