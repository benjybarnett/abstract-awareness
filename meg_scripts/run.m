addpath D:/bbarnett/Documents/ecobrain/scripts/utilities/
addpath D:/bbarnett/Documents/ecobrain/scripts/Decoding/
addpath D:/bbarnett/Documents/ecobrain/scripts/Decoding/plotting/
addpath D:/bbarnett/Documents/ecobrain/scripts/Decoding/stats/

addpath('D:/bbarnett/Documents/ecobrain/MVPA-Light\startup')
addpath D:/bbarnett/Documents/ecobrain/fieldtrip-master-MVPA/
addpath D:/bbarnett/Documents/ecobrain/HalfVectorization/
startup_MVPA_Light
ft_defaults
meg_path = 'B:\Data\';
subjects_path = 'D:\bbarnett\Documents\ecobrain\data\';


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
    'sub15'
    'sub16'
    'sub17'
    'sub18'
    'sub19'
    'sub20'
                       

         };
    
%% PREPROCESSING
%Define trial lengths, preprocess, and concatenate across different data files.
events = [6 7 9]; %square diamond catch 
prestim = 0.175;
poststim = 2.525;
baselinewindow = [-0.175 0.025];
downsample_freq = 250;

for subj = 1:length(subjects)
    
    subject = subjects{subj};
    
    preprocess(subject,meg_path, events,...
        prestim, poststim, baselinewindow, downsample_freq);
     
end
%%%

%%%ARTEFACT REJECTION%%%
cfg0 = [];
cfg0.stimOn = [0.025 0.058];
for subj = 1:length(subjects)
    
    subject = subjects{subj};
    artefact_rejection(cfg0, subject)
    
end
%%%

%%%ICA%%%
for subj = 1:length(subjects)
    
    subject = subjects{subj};
    ica(subject);

end
%%%

%%%Regress Out Contrast
cfg = [];
cfg.confound_idx = 3; %index of confound in trialinfo data
cfg.subj_path = subjects_path;
cfg.output_path = 'D:\bbarnett\Documents\ecobrain\data';
for subj = 1:length(subjects)
    
    subject = subjects{subj};
    disp(subject)
    regress_out_confound(cfg,subject);
    
end


%% DECODING
%Multiclass classification

tic
for subj = 1:length(subjects)
        tic
        subject = subjects{subj};

        cfg = [];
        cfg.channel = 'MEG';
        cfg.outputDir = 'Decoding/Within/Temporal/Multiclass';
        cfg.nFold  = 5;
        cfg.nMeanS = 7; 
        cfg.plot  = false;

        cfg.regressed = false;
        cfg.noBL = false;
        % target: all PAS ratings
        cfg.outputName = {};
        cfg.outputName = {'multiclass_PAS_squares';'multiclass_PAS_diamonds'};

        multiclass(cfg,subject)

       
        cfg.metric = 'accuracy';
        cfg.outputDir = 'Decoding/Cross/Temporal/Multiclass';
        cfg.outputName = {'multiclass_PAS_trainSquares_cv';'multiclass_PAS_trainDiamonds_cv'};
        multiclass_cross(cfg,subject)
        toc
        
        
end
toc


% Get confusion matrix for each subject for confusion plots
for subj = 1:length(subjects)

        subject = subjects{subj};

        cfg = [];
        cfg.channel = 'MEG';
        cfg.outputDir = 'Decoding/Within/Temporal/Multiclass';
        cfg.nFold  = 5;
        cfg.gamma = 0.2;
        cfg.nMeanS = 7; 
        cfg.plot  = false;
        cfg.metric = 'confusion';

        if ~ strcmp(subject,'sub02')
            % target: all PAS ratings
            cfg.outputName = {};
            cfg.outputName = {strcat('multiclass_PAS_squares_conf');strcat('multiclass_PAS_diamonds_conf')};

            multiclass(cfg,subject)
        end
       

        cfg.outputDir = 'Decoding/Cross/Temporal/Multiclass';
        cfg.outputName = {'multiclass_PAS_trainSquares_cv_conf';'multiclass_PAS_trainDiamonds_cv_conf'};
        multiclass_cross(cfg,subject)

end


%Proportion classified i.e. confusion matirx plots
cfg = [];
cfg.outputDir = 'Decoding/Cross/Diag/Multiclass';
cfg.confDir = '/Decoding/Cross/Temporal/Multiclass/';
cfg.sqFile = 'multiclass_PAS_trainSquares_cv_conf';
cfg.diFile = 'multiclass_PAS_trainDiamonds_cv_conf';
confusion_plots(cfg,subjects);


%% RSA
cfg = [];
cfg.num_predictors = 8; 
cfg.subj_path = subjects_path;
cfg.output_path = 'D:\bbarnett\Documents\ecobrain\data\results';
cfg.mRDM_path = 'D:\bbarnett\Documents\ecobrain\scripts\';
cfg.mRDM_file ='graded_specific_rdm';
cfg.channels = 'MEG';
cfg.regressed = true;
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    RSA(cfg,subject);
    
end
%plot
cfg.linecolor = '#ED217C';
cfg.shadecolor = '#ED217C';
cfg.mRDM_file = 'no_graded_rdm';
plot_mean_RSA(cfg,subjects)
%hold on;
cfg.linecolor = '#1B998B';
cfg.shadecolor = '#1B998B';
cfg.mRDM_file= 'graded_rdm';
plot_mean_RSA(cfg,subjects)
%hold on;
cfg.linecolor = '#62A6E3';
cfg.shadecolor = '#62A6E3';
cfg.mRDM_file = 'graded_specific_rdm';
plot_mean_RSA(cfg,subjects)
%%%


%CONTROL RSA
cfg = [];
cfg.num_predictors = 8; 
cfg.subj_path = subjects_path;
cfg.output_path = 'D:\bbarnett\Documents\ecobrain\data\results';
cfg.mRDM_path = 'D:\bbarnett\Documents\ecobrain\scripts\';
%cfg.mRDM_file ='graded_specific_rdm';
cfg.channels = 'MEG';
cfg.nPerms = 1000;
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    ControlRSA(cfg,subject);
end


%% Redoing PreProcessing without Baseline Correction

%Define trial lengths, preprocess, and concatenate across different data files.
events = [6 7 9]; %square diamond catch 
prestim = 0.475;
poststim = 2.525;
downsample_freq = 250;
demean = 'no';
baselinewindow = [];
meg_path = 'D:\bbarnett\Documents\ecobrain\data\raw\';

errs = [];
for subj = 1:length(subjects)
    
    subject = subjects{subj};
    
    err = preprocess(subject,meg_path, events,...
        prestim, poststim,demean, baselinewindow, downsample_freq);
    errs = [errs err];
     
end

%Remove same trials as first VAR did
for subj = 1:length(subjects)
    subject = subjects{subj};
    matchTrials(subject);
end

%ICA
for subj = 1:length(subjects)
    
    subject = subjects{subj};
    ica(subject);
    
end





