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
    %'sub13'
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
num_trials =zeros(length(subjects),5);
comparisons = {'1_and_2' '3_and_4'};
%%%square vs diamond temporal classifier%%%
for comp =1:length(comparisons)
    comparison = comparisons(comp);
    disp(comparison)
    for subj = 1:length(subjects)

        subject = subjects{subj};
        if contains(comparison, '3') && strcmp(subject, 'sub13') && ~contains(comparison,'4')
            %sub13 has no PAS3 ratings
            
            continue;
        end
        cfg=[];
        cfg.outputDir = 'Decoding/Within/Diag';
        cfg.nFold  = 5;
        cfg.gamma = 0.2;
        cfg.nMeanS = 7;
        cfg.plot  = false;
        cfg.correct = false; %correct trials only
        % target: square vs. diamond
        cfg.outputName = strcat('square_v_diamond_',string(comparison));
        cfg.conIdx{1,1} = 'data.trialinfo(:,1)==6'; 
        cfg.conIdx{2,1} = 'data.trialinfo(:,1)==7';
        if strcmp(comparison,'3_and_4')
            cfg.conIdx{3,1} = 'data.trialinfo(:,6)==3|data.trialinfo(:,6)==4';
        else
            cfg.conIdx{3,1} = strcat('data.trialinfo(:,6)==1|data.trialinfo(:,6)==2');
        end
        
        num_trial = diagDecode(cfg,subject);
        num_trials(subj,comp) =num_trial ;
        %TGwithin(cfg,subject)
    end
end

cfg.title = 'Squares vs. Diamonds in PAS 3 and 4  ';
cfg.accFile =  'square_v_diamond_3_and_4';
cfg.outputDir = 'Decoding/Within/Diag';
cfg.accDir = cfg.outputDir;
plot_mean_diag(cfg,subjects);
%mean_acc = plot_mean_within_temp_discrim(cfg,subjects);


%corrected one sample test for discrimination decoders
tic
cfg = [];
cfg.lowFile = 'square_v_diamond_1_and_2';
cfg.highFile = 'square_v_diamond_3_and_4';
cfg.withinDir ='Decoding/Within/Diag';

cfg.plot = true;
[ps_low,ps_high] = onesample_corrected_diag(cfg,subjects);
toc


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%within temporal generalisation classifier%%%

comparisons = {{'data.trialinfo(:,6)==1','data.trialinfo(:,6)==2','data.trialinfo(:,1)==6','PAS1_vs_PAS2_square'}
                {'data.trialinfo(:,6)==2','data.trialinfo(:,6)==4','data.trialinfo(:,1)==6','PAS2_vs_PAS4_square'}
                {'data.trialinfo(:,6)==3','data.trialinfo(:,6)==4','data.trialinfo(:,1)==6','PAS3_vs_PAS4_square'}
                {'data.trialinfo(:,6)==2','data.trialinfo(:,6)==3','data.trialinfo(:,1)==6','PAS2_vs_PAS3_square'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==3','data.trialinfo(:,1)==6','PAS1_vs_PAS3_square'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==4','data.trialinfo(:,1)==6','PAS1_vs_PAS4_square'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==2','data.trialinfo(:,1)==7','PAS1_vs_PAS2_diamond'}
                {'data.trialinfo(:,6)==2','data.trialinfo(:,6)==4','data.trialinfo(:,1)==7','PAS2_vs_PAS4_diamond'}
                {'data.trialinfo(:,6)==3','data.trialinfo(:,6)==4','data.trialinfo(:,1)==7','PAS3_vs_PAS4_diamond'}
                {'data.trialinfo(:,6)==2','data.trialinfo(:,6)==3','data.trialinfo(:,1)==7','PAS2_vs_PAS3_diamond'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==3','data.trialinfo(:,1)==7','PAS1_vs_PAS3_diamond'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==2','data.trialinfo(:,1)==7','PAS1_vs_PAS2_diamond'}};
num_trials_within_temp = zeros(length(subjects),length(comparisons),1);
for comp = 1:length(comparisons)
    disp(comp)
    for subj = 1:length(subjects)

        comparison = comparisons{comp};
        subject = subjects{subj};
        
        if contains(comparison(4), 'PAS3') && strcmp(subject, 'sub13')
            %sub13 has no PAS3 ratings
            num_trials_within_temp(subj,comp) = NaN;
            continue;
        end

        cfg=[];
        cfg.outputDir = 'Decoding/Within/Temporal';
        cfg.gamma = 0.2;
        cfg.nFold = 5;
        cfg.nMeanS = 7;
        cfg.plot  = false;
        cfg.channel='all';
        % target: e.g. PAS 1 vs PAS 2 within squares
        cfg.outputName = string(comparison(4));
        cfg.conIdx{1,1} = string(comparison(1));
        cfg.conIdx{2,1} = string(comparison(2));
        cfg.withinStimIdx = string(comparison(3)); %e.g within square

        num_trial = tempDecode(cfg,subject);
        num_trials_within_temp(subj,comp) = num_trial;
    end
end
cfg.title = 'Within Decoding: PAS 1 vs. 2';
cfg.accFile = '';
cfg.accDir = 'Decoding/Within/Temporal';
cfg.outputDir = 'Decoding/Within/Temporal';
plot_mean_within_temp(cfg,subjects)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%cross condition diagonal classifier%%%
comparisons = {{'data.trialinfo(:,6)==1','data.trialinfo(:,6)==4','PAS1_vs_PAS4_diag'}
                {'data.trialinfo(:,6)==2','data.trialinfo(:,6)==4','PAS2_vs_PAS4_diag'}
                {'data.trialinfo(:,6)==3','data.trialinfo(:,6)==4','PAS3_vs_PAS4_diag'}
                {'data.trialinfo(:,6)==2','data.trialinfo(:,6)==3','PAS2_vs_PAS3_diag'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==3','PAS1_vs_PAS3_diag'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==2','PAS1_vs_PAS2_diag'}};
%%%cross condition diagonal classifier%%%
 for comp =1:length(comparisons)
    
    comparison = comparisons{comp};

    for subj = 1:length(subjects)

         subject = subjects{subj};


         if contains(comparison(3), 'PAS3') && strcmp(subject, 'sub13')
                %sub13 has no PAS3 ratings
                continue;
         end



        cfg=[];
        cfg.outputDir = 'Decoding/Cross/Diag/trainSquares';
        cfg.nFold  = 5;
        cfg.gamma = 0.2;
        cfg.nMeanS = 7;
        cfg.plot  = 0;
        cfg.channel='all';

        % target: PAS 2 vs PAS 4
        cfg.outputName = string(comparison(3));
        cfg.conIdx{1,1} = string(comparison(1)); 
        cfg.conIdx{2,1} = string(comparison(2)); 
    
        %train on squares, test diamonds
        cfg.trainIdx = 'data.trialinfo(:,1)==6'; 
        cfg.testIdx = 'data.trialinfo(:,1)==7';


        diagCrossDecode(cfg,subject);


    end
end
cfg.title = 'Cross Decoding PAS 1 vs. 4 (Train: Squares, Test: Diamonds)';
cfg.accFile ='PAS1_vs_PAS4_diag';
cfg.accDir = 'Decoding/Cross/Diag/trainSquares';
plot_mean_diag(cfg,subjects)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%cross condition temproal generalization classifier%%%
comparisons = {{'data.trialinfo(:,6)==1','data.trialinfo(:,6)==4','PAS1_vs_PAS4'}
                {'data.trialinfo(:,6)==2','data.trialinfo(:,6)==4','PAS2_vs_PAS4'}
                {'data.trialinfo(:,6)==3','data.trialinfo(:,6)==4','PAS3_vs_PAS4'}
                {'data.trialinfo(:,6)==2','data.trialinfo(:,6)==3','PAS2_vs_PAS3'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==3','PAS1_vs_PAS3'}
                {'data.trialinfo(:,6)==1','data.trialinfo(:,6)==2','PAS1_vs_PAS2'}};
for comp =1:length(comparisons)
    
    comparison = comparisons{comp};
     
    for subj = 1:length(subjects)

        subject = subjects{subj};
        
        if contains(comparison(3), 'PAS3') && strcmp(subject, 'sub13')
            %sub13 has no PAS3 ratings
            continue;
        end
        
        cfg=[];
        cfg.outputDir = 'Decoding/Cross/Temporal/trainSquares';
        cfg.nFold  = 5;
        cfg.gamma = 0.2;
        cfg.nMeanS = 7;
        cfg.plot  = 0;
        

        % target: PAS x vs PAS y
        cfg.outputName = string(comparison(3));
        cfg.conIdx{1,1} = string(comparison(1));
        cfg.conIdx{2,1} = string(comparison(2));
        
        %train on squares, test diamonds
        cfg.trainIdx = 'data.trialinfo(:,1)==6'; 
        cfg.testIdx = 'data.trialinfo(:,1)==7';


        tempCrossDecode(cfg,subject);


    end

end
cfg = [];
cfg.outputDir = 'Decoding/Cross/Temporal/trainDiamonds';
cfg.title = 'Cross Decoding PAS 3 vs. 4 (Train: Diamonds, Test: Squares)';
cfg.accFile = 'PAS3_vs_PAS4';
cfg.accDir = 'Decoding/Cross/Temporal/trainDiamonds';
plot_mean_temp(cfg,subjects)
cfg.outputName = cfg.accFile;
cfg.plot=true;
[t,p,h] = one_sample_ttest(cfg,subjects);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%MULTICLASSIFIER%%%
%%%%MULTICLASSIFIER%%%



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
        cfg.outputName = {'multiclass_PAS_squares2';'multiclass_PAS_diamonds2'};

        multiclass(cfg,subject)

       
        cfg.metric = 'accuracy';
        cfg.outputDir = 'Decoding/Cross/Temporal/Multiclass';
        cfg.outputName = {'multiclass_PAS_trainSquares_cv2';'multiclass_PAS_trainDiamonds_cv2'};
        multiclass_cross(cfg,subject)
        toc
        
        
end
toc
cfg.title = ' ';
cfg.accFile = 'multiclass_PAS_trainDiamonds_cv2';
cfg.accDir = 'Decoding/Cross/Temporal/Multiclass';
cfg.outputDir = 'Decoding/Cross/Temporal/Multiclass';
plot_multiclass_temp(cfg,subjects) 

%%%%% Get confusion matrix for each subject for confusion plots%%%%
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


%%%%%%%%Plot topography of weights%%%%%%
tic
for subj = 1:length(subjects)

        subject = subjects{subj};
       
        
        
        cfg=[];
        cfg.outputDir = 'Decoding/weights/squares_vs_diamonds';
        

        % target: PAS x vs PAS y
        cfg.outputName ='squares_vs_diamonds';
        cfg.conIdx{1,1} = 'data.trialinfo(:,1)==6';
        cfg.conIdx{2,1} = 'data.trialinfo(:,1)==7';
        cfg.conIdx{3,1} = 'data.trialinfo(:,6) == 3 | data.trialinfo(:,6) == 4';
        
       
        if contains(cfg.outputName, 'PAS3') && strcmp(subject, 'sub13')
            %sub13 has no PAS3 ratings
            continue;
        end
        
        cfg.sample = 88; %110 sample is peak accuracy in PAS 1 vs PAS 4 within class decoder
        %cfg.sample = 141; %126 is 0.3015 seconds
        %cfg.sample = 95; %95 is 0.1775 = peak acc sor square vs diamonds decoding in PAS 3&4 combined

        weights = get_weights(cfg,subject);
        
end
toc
cfg =[];
cfg.sample = 110;
cfg.weightDir = 'Decoding/weights/trainSquares';
cfg.weightFile = strcat('PAS1_vs_PAS4_',string(cfg.sample));
cfg.title = 'LDA Weights: PAS 1 vs PAS 4 (Peak cross decoding accuracy 0.2375ms)';
plot_weights_topo(cfg,subjects);




%%%%%%%%%%%t-test between within and cross codnition accuracy%%%%%

tic
cfg = [];
cfg.accFile = 'multiclass_PAS_trainDiamonds_cv2';
cfg.crossDir = 'Decoding/Cross/Temporal/Multiclass';
cfg.withinDir = 'Decoding/Within/Temporal/Multiclass';
cfg.outputName = 'multi_within_v_cross_diamonds2';
cfg.train = 'diamonds';
cfg.plot = true;
cfg.title= 'Multiclass within diamonds vs cross train on diamonds';
[t,p,h] = paired_ttest_multiclass(cfg,subjects);
toc

%%%%%%%%%%%one sample t test of diagonal classifiers%%%%%%%%%%%


tic
cfg = [];
cfg.accFile = 'multiclass_PAS_diamonds';
cfg.accDir ='Decoding/Within/Temporal/multiclass';
cfg.outputName = 'multiclass_PAS_diamonds';
cfg.plot = true;
cfg.title= 'Multi class within diamonds decoder';
[t,p,h] = one_sample_ttest(cfg,subjects);
toc



%corrected one sample test for both cross decoders
%%%WARNING NEED TO GO INTO FUNCTION TO EDIT OUTPUT DIRECTORies
%%% and make them not hard coded
tic
cfg = [];
cfg.diFile = 'multiclass_PAS_trainDiamonds_cv2';
cfg.sqFile = 'multiclass_PAS_trainSquares_cv2';
cfg.crossDir ='Decoding/Cross/Temporal/multiclass';
cfg.withinDir ='Decoding/Within/Temporal/multiclass';

cfg.plot = true;
[ps_sq,ps_di] = onesample_corrected(cfg,subjects);
toc


%correcting the dimensionality reduced data%
dimensions = {'1D' '2D' '3D' '4D' '5D' '6D'};
for dim = 1:length(dimensions)
    dimension = dimensions(dim);
    
    cfg = [];
    cfg.diFile = strcat('multiclass_PAS_trainDiamonds_',dimension);
    cfg.sqFile = strcat('multiclass_PAS_trainSquares_',dimension);
    cfg.crossDir ='Decoding/Cross/Temporal/multiclass/SVD';
    cfg.plot = false;
    cfg.dim = dimension;
    [ps_di,ps_sq] = onesample_corrected(cfg,subjects);

end



%%%%%Proprotion classified i.e. confnusion matirx plots%%%%%
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
%{
cfg.linecolor = '#019E15';
cfg.shadecolor = '#019E15';
cfg.mRDM_file = 'no_graded_specific_rdm';
plot_mean_RSA(cfg,subjects)
%}
%hold on;
cfg.linecolor = '#62A6E3';
cfg.shadecolor = '#62A6E3';
cfg.mRDM_file = 'graded_specific_rdm';
plot_mean_RSA(cfg,subjects)
%%%

%correct - run these 6 chunks together to produce plot
figure;
cfg=[];
cfg.regressed = false;
cfg.plot=true;
cfg.mRDM_file = 'no_graded_rdm';
cfg.linecolor = '#1B998B';
cfg.shadecolor = '#1B998B';
cfg.sig_height =-0.075;
pVals = correct_RSA(cfg,subjects);

cfg=[];
cfg.regressed = false;
cfg.plot=true;
cfg.mRDM_file = 'graded_rdm';
cfg.linecolor = '#bc42f5';
cfg.shadecolor = '#bc42f5';
cfg.sig_height =-0.095;
pVals = correct_RSA(cfg,subjects);

cfg=[];
cfg.regressed = false;
cfg.plot=true;
cfg.mRDM_file = 'graded_specific_rdm';
cfg.linecolor = '#FFA500';
cfg.shadecolor = '#FFA500';
cfg.sig_height =-0.115;
pVals = correct_RSA(cfg,subjects);
set(gca,'box','off')

hold on
cfg=[];
cfg.regressed = false;
cfg.mRDM_file = {'graded_rdm','no_graded_rdm'};
cfg.plot=true;
cfg.linecolor{1} = '#bc42f5';
cfg.linecolor{2} = '#1B998B';
cfg.sig_height = -0.15;
pVals = correct_RSA_paired(cfg,subjects);
set(gca,'FontSize',18);
hold on

hold on
cfg = [];
cfg.regressed = false;
cfg.mRDM_file = {'graded_rdm','graded_specific_rdm'};
cfg.plot=true;
cfg.linecolor{1} = '#bc42f5';
cfg.linecolor{2} = '#FFA500';
cfg.sig_height = -0.17;
pVals = correct_RSA_paired(cfg,subjects);
set(gca,'FontSize',18);

hold on
cfg=[];
cfg.regressed = false;
cfg.mRDM_file = {'graded_specific_rdm','no_graded_rdm'};
cfg.plot=true;
cfg.linecolor{1} = '#FFA500';
cfg.linecolor{2} = '#1B998B';
cfg.sig_height = -0.19;
pVals = correct_RSA_paired(cfg,subjects);
set(gca,'FontSize',18);


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
%plot
figure;
cfg=[];
cfg.regressed = false;
cfg.plot=true;
cfg.mRDM_file = 'graded_rdm';
cfg.linecolor = '#bc42f5';
cfg.shadecolor = '#bc42f5';
cfg.sig_height =-0.08;
pVals = correct_RSA(cfg,subjects);

cfg=[];
cfg.regressed = false;
cfg.plot=true;
cfg.mRDM_file = 'no_graded_rdm';
cfg.linecolor = '#CB4D6C';
cfg.shadecolor = '#CB4D6C';
cfg.sig_height =-0.06;
pVals = correct_RSA(cfg,subjects);



cfg=[];
cfg.plot=true;
cfg.regressed = false;
cfg.mRDM_file = 'graded_specific_rdm';
cfg.linecolor = '#1322E9';
cfg.shadecolor = '#1322E9';
cfg.sig_height =-0.1;
pVals = correct_RSA(cfg,subjects);
set(gca,'box','off')

hold on
cfg=[];
cfg.regressed = false;
cfg.mRDM_file = {'graded_rdm','no_graded_rdm'};
cfg.plot=true;
cfg.linecolor{1} = '#bc42f5';
cfg.linecolor{2} = '#CB4D6C';
cfg.sig_height = -0.15;
pVals = correct_RSA_paired(cfg,subjects);
set(gca,'FontSize',18);
hold on

hold on
cfg = [];
cfg.regressed = false;
cfg.mRDM_file = {'graded_rdm','graded_specific_rdm'};
cfg.plot=true;
cfg.linecolor{1} = '#bc42f5';
cfg.linecolor{2} = '#1322E9';
cfg.sig_height = -0.17;
pVals = correct_RSA_paired(cfg,subjects);
set(gca,'FontSize',18);



%%%


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
%%%




%% RSA
cfg = [];
cfg.num_predictors = 8; 
cfg.subj_path = subjects_path;
cfg.output_path = 'D:\bbarnett\Documents\ecobrain\data\results';
cfg.mRDM_path = 'D:\bbarnett\Documents\ecobrain\scripts\';
cfg.mRDM_file ='no_graded_rdm';
cfg.channels = 'MEG';
cfg.regressed = false;
cfg.noBL = true;
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
%{
cfg.linecolor = '#019E15';
cfg.shadecolor = '#019E15';
cfg.mRDM_file = 'no_graded_specific_rdm';
plot_mean_RSA(cfg,subjects)
%}
%hold on;
cfg.linecolor = '#62A6E3';
cfg.shadecolor = '#62A6E3';
cfg.mRDM_file = 'graded_specific_rdm';
plot_mean_RSA(cfg,subjects)
%%%

%correct - run these 6 chunks together to produce plot
figure;
cfg=[];
cfg.regressed = false;
cfg.noBL = true;
cfg.plot=true;
cfg.mRDM_file = 'no_graded_rdm';
cfg.linecolor = '#1B998B';
cfg.shadecolor = '#1B998B';
cfg.sig_height =-0.075;
pVals = correct_RSA(cfg,subjects);

cfg=[];
cfg.regressed = false;
cfg.noBL = true;
cfg.plot=true;
cfg.mRDM_file = 'graded_rdm';
cfg.linecolor = '#bc42f5';
cfg.shadecolor = '#bc42f5';
cfg.sig_height =-0.095;
pVals = correct_RSA(cfg,subjects);

cfg=[];
cfg.regressed = false;
cfg.noBL = true;
cfg.plot=true;
cfg.mRDM_file = 'graded_specific_rdm';
cfg.linecolor = '#FFA500';
cfg.shadecolor = '#FFA500';
cfg.sig_height =-0.115;
pVals = correct_RSA(cfg,subjects);
set(gca,'box','off')


    hold on
    cfg=[];
    cfg.regressed = false;
    cfg.noBL = true;
    cfg.mRDM_file = {'graded_rdm','no_graded_rdm'};
    cfg.plot=true;
    cfg.linecolor{1} = '#bc42f5';
    cfg.linecolor{2} = '#1B998B';
    cfg.sig_height = -0.15;
    pVals = correct_RSA_paired(cfg,subjects);
    set(gca,'FontSize',18);
    hold on
  

hold on
cfg = [];
cfg.regressed = false;
cfg.noBL = true;
cfg.mRDM_file = {'graded_rdm','graded_specific_rdm'};
cfg.plot=true;
cfg.linecolor{1} = '#bc42f5';
cfg.linecolor{2} = '#FFA500';
cfg.sig_height = -0.17;
pVals = correct_RSA_paired(cfg,subjects);
set(gca,'FontSize',18);

hold on
cfg=[];
cfg.regressed = false;
cfg.noBL = true;
cfg.mRDM_file = {'graded_specific_rdm','no_graded_rdm'};
cfg.plot=true;
cfg.linecolor{1} = '#FFA500';
cfg.linecolor{2} = '#1B998B';
cfg.sig_height = -0.19;
pVals = correct_RSA_paired(cfg,subjects);
set(gca,'FontSize',18);

%% Multiclass Decoding

for subj = 1:length(subjects)
        
        subject = subjects{subj};

        cfg = [];
        cfg.channel = 'MEG';
        cfg.outputDir = 'Decoding/Within/Temporal/Multiclass';
        cfg.nFold  = 5;
        cfg.nMeanS = 7; 
        cfg.plot  = false;

        cfg.regressed = false;
        cfg.noBL = true;
        % target: all PAS ratings
        cfg.outputName = {};
        cfg.outputName = {'multiclass_PAS_squares_noBL';'multiclass_PAS_diamonds_noBL'};

        multiclass(cfg,subject)

       
        cfg.metric = 'accuracy';
        cfg.outputDir = 'Decoding/Cross/Temporal/Multiclass';
        cfg.outputName = {'multiclass_PAS_trainSquares_noBL_cv';'multiclass_PAS_trainDiamonds_noBL_cv'};
        multiclass_cross(cfg,subject)
        
        
        
end
toc
cfg.title = ' ';
cfg.accFile = 'multiclass_PAS_trainSquares_noBL_cv';
cfg.accDir = 'Decoding/Cross/Temporal/Multiclass';
cfg.outputDir = 'Decoding/Cross/Temporal/Multiclass';
plot_multiclass_temp(cfg,subjects) 

% Correct one sample
tic
cfg = [];
cfg.diFile = 'multiclass_PAS_diamonds_noBL';
cfg.sqFile = 'multiclass_PAS_squares_noBL';
cfg.crossDir ='Decoding/Cross/Temporal/multiclass';
cfg.withinDir ='Decoding/Within/Temporal/multiclass';

cfg.plot = true;
[ps_sq,ps_di] = onesample_corrected(cfg,subjects);
toc


%% Graveyard
%create power spectrum
cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.channel = 'MEG';
cfg.taper ='hanning';
power= ft_freqanalysis(cfg,data);
dims=size(power.powspctrm);
n_channels = dims(1);
for i = 1:n_channels
   
    disp(i)
    plot(power.freq,power.powspctrm(i,:))
    xlim([2 40])
    ylim([0 6e-27])
    xline(7,'--r');
    xline(14,'--r');
    xline(21,'--r');
    xline(28,'--r');
    xline(35,'--r');
    
end

%power spectrum plot
figure;
hold on;
xlim([2 150])
ylim([0 7e-24])
plot(power.freq, power.powspctrm,'linewidth',1)
xlabel('Frequency (Hz)')
ylabel('Power (\mu V^2)')

%plot topography of power spectrum. I.e. where on head were different
%frequencies
cfg = [];
cfg.xlim =[0 2];
cfg.zlim = 'maxmin';
cfg.layout = 'neuromag306all.lay';
%cfg.highlightchannel = {'MEG2612'}
%cfg.highlight = 'on';
%cfg.highlightcolor = [1 0 0];
%cfg.highlightsize = 15;
cfg.parameter = 'powspctrm'; % the default 'avg' is not present in the data
figure; ft_topoplotER(cfg,power); colorbar


%multiclass DEcoding in different regions
%output_names = {'frontal';'fronto_parietal'; 'parietal'};
output_names = {'frontal'};
for i = 1:length(output_names)
    %REMOVE OUTER LOOP OF OUTPUT NAMES TO RUN THIS ANALYSIS ON ALL CHANNELS
    if i ==1
        channel = frontal_sensors;
    elseif i ==2
        channel = fronto_parietal_sensors;
    elseif i == 3
        channel = parietal_sensors;
    end
    disp(channel);
    
    for subj = 1:length(subjects)

            subject = subjects{subj};

            cfg = [];
            cfg.channel = channel;
            cfg.outputDir = 'Decoding/Within/Temporal/Multiclass';
            cfg.nFold  = 5;
            cfg.gamma = 0.2;
            cfg.nMeanS = 7; 
            cfg.plot  = false;
            
            %{
            % target: all PAS ratings
            cfg.outputName = {};
            cfg.outputName = {strcat('multiclass_PAS_squares_',output_names(i));strcat('multiclass_PAS_diamonds',output_names(i))};

            multiclass(cfg,subject)
            
           %}
            
            cfg.outputDir = 'Decoding/Cross/Temporal/Multiclass';
            cfg.outputName = {strcat('multiclass_PAS_trainSquares_',output_names(i),'_cv');strcat('multiclass_PAS_trainDiamonds_',output_names(i),'_cv')};
            multiclass_cross(cfg,subject)

    end
end
cfg.title = ' ';
cfg.accFile = 'multiclass_PAS_Squares_frontal';
cfg.accDir = 'Decoding/Within/Temporal/Multiclass';
cfg.outputDir = 'Decoding/Within/Temporal/Multiclass';
plot_multiclass_temp(cfg,subjects) 
