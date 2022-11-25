function multiclass(cfg,subject)

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

% run PAS multiclass discriminator just on squares
cfgS = [];
cfgS.trials = (data.trialinfo(:,1) == 6);
cfgS.channel = cfg.channel;
square_data = ft_selectdata(cfgS,data);
cfgS = [];cfgS.keeptrials = true;cfgS.channel=cfg.channel;square_data = ft_timelockanalysis(cfgS,square_data);

for trial = 1:size(square_data.trial,1)
    square_data.trial(trial,:,:) = ft_preproc_smooth(squeeze(square_data.trial(trial,:,:)),cfg.nMeanS);
end

%time x time
cfgS = [] ;
cfgS.method          = 'mvpa';
cfgS.latency         = [];
cfgS.design          = square_data.trialinfo(:,6);
cfgS.features        = 'chan';
cfgS.generalize      = 'time';
cfgS.mvpa            = [];
cfgS.mvpa.classifier = 'multiclass_lda';
cfgS.mvpa.metric     = 'accuracy';
cfgS.mvpa.k          = cfg.nFold;
cfgS.mvpa.repeat     = 1;
cfgS.mvpa.preprocess = {'undersample'};
square_stat = ft_timelockstatistics(cfgS,square_data);
square_acc = square_stat.accuracy';
save(fullfile(outputDir,string(cfg.outputName{1})),'square_acc');

% run PAS multiclass discrimnator just on diamonds
cfgS = [];
cfgS.trials = (data.trialinfo(:,1) == 7);
cfgS.channel = cfg.channel;
diam_data = ft_selectdata(cfgS,data);
cfgS = [];cfgS.keeptrials = true;cfgS.channel=cfg.channel;diam_data = ft_timelockanalysis(cfgS,diam_data);


for trial = 1:size(diam_data.trial,1)
    diam_data.trial(trial,:,:) = ft_preproc_smooth(squeeze(diam_data.trial(trial,:,:)),cfg.nMeanS);
end

%time x time
cfgS = [] ;
cfgS.method          = 'mvpa';
cfgS.latency         = [];
cfgS.design          = diam_data.trialinfo(:,6);
cfgS.features        = 'chan';
cfgS.generalize = 'time';
cfgS.mvpa            = [];
cfgS.mvpa.classifier = 'multiclass_lda';
cfgS.mvpa.metric     = 'accuracy';
cfgS.mvpa.k          = cfg.nFold;
cfgS.mvpa.repeat = 1;
cfgS.mvpa.preprocess = {'undersample'};
diam_stat = ft_timelockstatistics(cfgS,diam_data);
diam_acc = diam_stat.accuracy';

save(fullfile(outputDir,string(cfg.outputName{1})),'square_acc');
save(fullfile(outputDir,string(cfg.outputName{2})),'diam_acc');

if cfg.plot
    figure;
    subplot(1,2,1)
    imagesc(time,time,diamond_acc); axis xy; colorbar
    xlabel('Time (s)'); ylabel('Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet') 
    title('diamond')

    subplot(1,2,2)
    imagesc(time,time,square_acc); axis xy; colorbar
    xlabel('Time (s)'); ylabel('Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet')
    title('square')
end
end