addpath('Utilities');
addpath 'D:\bbarnett\Documents\ecobrain\spm12';
addpath 'D:\bbarnett\Documents\ecobrain\fmri\fmri_analysis\'


subjs = {'S01'
        'S02'
        'S03'
        'S04'
        'S05'
        %'S06'
        %'S07'
        'S08'
        'S09'
        'S10'
        'S11'
        %'S12'
        'S13'
        'S14'
        'S15'
        'S16'
        'S17'
        %'S18'
        'S19'
        %'S20'
        'S21'
        'S22'
        'S23'
        'S24'
        'S25'
        'S26'
        'S27'
        %'S28'
        'S29'
        'S30'
        'S31'
        'S32'
        'S35'
        'S36'
        'S37'};
 



tic
%% within decoding
cfg = [];
cfg = [];
cfg.nFold=5;
cfg.gamma =0.2;
cfg.sl_radius = 4;
cfg.mask = 'stat_mask.nii'; % GM + has signal in each sub
cfg.data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
cfg.output_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\';
cfg.decoding_type = 'within';

%animate
cfg.fname = 'animate.nii';
cfg.classIdx = {'1','2'}; %1 and 2 is animate, 3 and 4 is inanimate

for subj = 1:length(subjs)
    
    subject = subjs{subj};
    disp(subject)
    
    [hdr,acc] = within_decode(cfg,subject);
    output_path = fullfile(cfg.output_dir,subject,cfg.decoding_type);
    
    if ~isfolder(output_path)
        mkdir(output_path)
    end
    
    output_file = fullfile(output_path,cfg.fname);
    write_nii(hdr,acc,output_file)
    within_anim_acc{subj} = acc;
end

%inanimate
cfg.fname = 'inanimate.nii';
cfg.classIdx = {'3','4'}; %1 and 2 is animate, 3 and 4 is inanimate

for subj = 1:length(subjs)
    
    subject = subjs{subj};
    disp(subject)
    
    [hdr,acc] = within_decode(cfg,subject);
    output_path = fullfile(cfg.output_dir,subject,cfg.decoding_type);
    
    if ~isfolder(output_path)
        mkdir(output_path)
    end
    
    output_file = fullfile(output_path,cfg.fname);
    write_nii(hdr,acc,output_file)
    within_inanim_acc{subj} = acc;
end
toc
%% cross-decoding