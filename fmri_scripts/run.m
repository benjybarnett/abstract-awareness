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
    
end
toc

%% cross-decoding

%train on animate, test on inanimate
cfg = [];
cfg.fname = 'train_animate.nii';
cfg.trainClass = {'1','2'}; %1 and 2 is animate, 3 and 4 is inanimate
cfg.testClass = {'3','4'}; 

cfg.nFold=5;
cfg.gamma =0.2;
cfg.sl_radius = 4;
cfg.mask = 'stat_mask.nii'; % GM + has signal in each sub
cfg.data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
cfg.output_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\';
cfg.decoding_type = 'cross';

for subj = 1:length(subjs)
    
    subject = subjs{subj};
    disp(subject)
    
    [hdr, acc] = cross_decode(cfg,subject);
    output_path = fullfile(cfg.output_dir,subject,cfg.decoding_type);
     
    if ~isfolder(output_path)
        mkdir(output_path)
    end
    
    output_file = fullfile(output_path,cfg.fname);
    write_nii(hdr,acc,output_file)
    
end

%train on inanimate; test on animate
cfg.fname = 'train_inanimate.nii';
cfg.trainClass = {'3','4'}; %1 and 2 is animate, 3 and 4 is inanimate
cfg.testClass = {'1','2'}; 

for subj = 1:length(subjs)
    
    subject = subjs{subj};
    disp(subject)
    
    [hdr, acc] = cross_decode(cfg,subject);
    output_path = fullfile(cfg.output_dir,subject,cfg.decoding_type);
     
    if ~isfolder(output_path)
        mkdir(output_path)
    end
    
    output_file = fullfile(output_path,cfg.fname);
    write_nii(hdr,acc,output_file)
    
end

%% create mean accuracy maps
all_subjs=zeros(length(subjs),99,117,95);
for subj = 1:length(subjs)
    disp(subj)
    subject = subjs{subj};
    
    [hdr,acc] = read_nii(fullfile(cfg.output_dir,subject,cfg.decoding_type,cfg.fname));
    all_subjs(subj,:,:,:) = acc;
end
mean_acc = squeeze(mean(all_subjs));

output_path = fullfile(cfg.output_dir,'group',cfg.decoding_type);
output_file = fullfile(output_path,cfg.fname);
if ~isfolder(output_path)
        mkdir(output_path)
end
write_nii(hdr,mean_acc,output_file);

%% run permutation testing for cross condition decoding
cfg = [];
cfg.subjects = subjs;
cfg.nPerm = 25;
cfg.nFold=5;
cfg.gamma =0.2;
cfg.sl_radius = 4;
cfg.mask = 'stat_mask.nii'; % GM + has signal in each sub
cfg.data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
cfg.output_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\';
cfg.decoding_type = 'cross';
cfg.nBtrsp = 10000;

[~,~,accIA_btstrp,accAI_btstrp] =CrossDecodingSearchlightPermutationBOB(cfg);

%% run permutation testing for within condition decoding
cfg = [];
cfg.subjects = subjs;
cfg.nPerm = 25;
cfg.nFold=5;
cfg.gamma =0.2;
cfg.sl_radius = 4;
cfg.mask = 'stat_mask.nii'; % GM + has signal in each sub
cfg.data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
cfg.output_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\';
cfg.decoding_type = 'within';
cfg.nBtrsp = 10000;

WithinDecodingSearchlightPermutationBOB(cfg);

%% run permutation testing for paired test cross vs within
cfg = [];
cfg.subjects = subjs;
cfg.nPerm = 25;
cfg.nFold=5;
cfg.gamma =0.2;
cfg.sl_radius = 4;
cfg.mask = 'stat_mask.nii'; % GM + has signal in each sub
cfg.data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
cfg.output_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\';
cfg.empirical_map = 'animate';
cfg.order = 1; %change this with cfg.empirical_map
cfg.nBtrsp = 10000;

paired_test_bootstrap(cfg);

%% multiple comparisons correction
cfg =[];
cfg.root = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\';
cfg.decoding_type = 'paired';
cfg.empirical_map = 'animate_diff.nii';
cfg.pvals_map = 'Paired.nii';
cfg.mask = 'stat_mask.nii';
cfg.qval = 0.01;
[sig_vals,vals] = MCCmask(cfg);

%% Content Decoding Searchlight
tic
cfg = [];
cfg.nFold=5;
cfg.gamma =0.2;
cfg.sl_radius = 4;
cfg.mask = 'stat_mask.nii'; % GM + has signal in each sub
cfg.data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
cfg.output_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\results\';
cfg.decoding_type = 'content';
cfg.fname = 'content_sl.nii';
for subj = 1:length(subjs)
    
    subject = subjs{subj};
    disp(subject)
    
    [hdr,acc] = content_decode(cfg,subject);
    output_path = fullfile(cfg.output_dir,subject,cfg.decoding_type);
    
    if ~isfolder(output_path)
        mkdir(output_path)
    end
    
    output_file = fullfile(output_path,cfg.fname);
    write_nii(hdr,acc,output_file)
   
end
toc


%% ROI analysis
%Decode visual ROI animate vs inanimate
cfg = [];
cfg.nFold=5;
cfg.gamma =0.2;
cfg.roi_file = 'visualROI.nii'; 
cfg.data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
cfg.roi_path = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_analysis\ROI';
cfg.output_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_analysis\ROI';
cfg.roi = 'visual';
cfg.nPerm = 25;
cfg.nBtrsp=10000;
cfg.vis = 'low';
cfg.subjects=subjs;

[vis_acc_low,vis_pval_low] = decode_ROI(cfg);

%decode frontal ROI animate vs inanimate
cfg = [];
cfg.nFold=5;
cfg.gamma =0.2;
cfg.roi_file = 'frontalROI.nii'; 
cfg.data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
cfg.roi_path = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_analysis\ROI';
cfg.output_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_analysis\ROI';
cfg.roi = 'frontal';
cfg.nPerm = 25;
cfg.nBtrsp=10000;
cfg.vis = 'high';
cfg.subjects=subjs;

[frontal_acc_high,frontal_pval_high] = decode_ROI(cfg);
  