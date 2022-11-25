function multiclass_cross(cfg,subject)

% output directory
outputDir = fullfile('../data/results',subject,cfg.outputDir);
if ~exist(outputDir,'dir'); mkdir(outputDir); end


% get MEG data
disp('loading..')
disp(subject)


if cfg.regressed == true
    data = load(strcat('../data/',subject,'/',subject,'_regressed.mat'));
    disp('Regressed out contrast')
elseif cfg.noBL == true
    data = load(strcat('../data/',subject,'/',subject,'_noBL_clean.mat'));
    disp('No Baseline Correction Data')
else
   data = load(strcat('../data/',subject,'/',subject,'_clean.mat'));
end
data = struct2cell(data); data = data{1};
disp('loaded data')
load('../data/time_axis.mat')

% train PAS multiclass discriminator just on squares
cfgS = [];
cfgS.trials = (data.trialinfo(:,1) == 6);
cfgS.channel = cfg.channel;
square_data = ft_selectdata(cfgS,data);
cfgS = [];cfgS.keeptrials = true;cfgS.channel=cfg.channel;square_data = ft_timelockanalysis(cfgS,square_data);


% test PAS multiclass discrimnator just on diamonds
cfgS = [];
cfgS.trials = (data.trialinfo(:,1) == 7);
cfgS.channel = cfg.channel;
diam_data = ft_selectdata(cfgS,data);
cfgS = [];cfgS.keeptrials = true;cfgS.channel=cfg.channel;diam_data = ft_timelockanalysis(cfgS,diam_data);


%smooth
smoothed_di_data = zeros(size(diam_data.trial));
for trial = 1:size(diam_data.trial,1)
    smoothed_di_data(trial,:,:) = ft_preproc_smooth(squeeze(diam_data.trial(trial,:,:)),cfg.nMeanS);
end
smoothed_sq_data = zeros(size(square_data.trial));
for trial = 1:size(square_data.trial,1)
    smoothed_sq_data(trial,:,:) = ft_preproc_smooth(squeeze(square_data.trial(trial,:,:)),cfg.nMeanS);
end

%time x time
cfgS = [];
cfgS.classifier = 'multiclass_lda';
cfgS.metric = cfg.metric;
cfgS.preprocess ={'undersample'};
cfgS.repeat = 1;
%MY EDITED SCRIPT ALLOWS CROSS DECODING TO BE USED WITH CROSS
        %VALIDATION
train_sq_cross_acc = mv_classify_timextime_BOB(cfgS,smoothed_sq_data,square_data.trialinfo(:,6),smoothed_di_data,diam_data.trialinfo(:,6));
train_di_cross_acc = mv_classify_timextime_BOB(cfgS,smoothed_di_data,diam_data.trialinfo(:,6),smoothed_sq_data,square_data.trialinfo(:,6));
if strcmp(cfg.metric, 'accuracy')
    train_sq_cross_acc = train_sq_cross_acc'; %coz mvpa light has axes switched
    train_di_cross_acc = train_di_cross_acc'; %coz mvpa light has axes switched
end


save(fullfile(outputDir,string(cfg.outputName{1})),'train_sq_cross_acc');
save(fullfile(outputDir,string(cfg.outputName{2})),'train_di_cross_acc');

if cfg.plot
    figure;
    subplot(1,2,1)
    imagesc(time,time,train_sq_cross_acc); axis xy; colorbar
    xlabel('Time (s)'); ylabel('Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet') 
    title('train squares test diamonds')

    subplot(1,2,2)
    imagesc(time,time,train_di_cross_acc); axis xy; colorbar
    xlabel('Time (s)'); ylabel('Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet')
    title('train diamonds test squares')
end
end