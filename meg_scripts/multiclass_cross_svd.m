function multiclass_cross_svd(cfg,subject,lowd_data)

% output directory
outputDir = fullfile('../data/results',subject,cfg.outputDir);
if ~exist(outputDir,'dir'); mkdir(outputDir); end



% train PAS multiclass discriminator just on squares
cfgS = [];
cfgS.trials = (lowd_data.trialinfo(:,1) == 6);
%cfgS.channel = 'MEG';
square_data = ft_selectdata(cfgS,lowd_data);
%cfgS = [];cfgS.keeptrials = true;cfgS.channel='MEG';square_data = ft_timelockanalysis(cfgS,square_data);


% test PAS multiclass discrimnator just on diamonds
cfgS = [];
cfgS.trials = (lowd_data.trialinfo(:,1) == 7);
%cfgS.channel = 'MEG';
diam_data = ft_selectdata(cfgS,lowd_data);
%cfgS = [];cfgS.keeptrials = true;cfgS.channel='MEG';diam_data = ft_timelockanalysis(cfgS,diam_data);


%smooth
if size(diam_data.trial,2) ~= 1
    smoothed_di_data = zeros(size(diam_data.trial));
    for trial = 1:size(diam_data.trial,1)
        smoothed_di_data(trial,:,:) = ft_preproc_smooth(squeeze(diam_data.trial(trial,:,:)),cfg.nMeanS);
    end

    smoothed_sq_data = zeros(size(square_data.trial));
    for trial = 1:size(square_data.trial,1)
        smoothed_sq_data(trial,:,:) = ft_preproc_smooth(squeeze(square_data.trial(trial,:,:)),cfg.nMeanS);
    end
else % do this in 1D case because otherwise an error is thrown due to squeezing out two dimensions with 1D
    smoothed_di_data = zeros(size(diam_data.trial));
    disp(size(smoothed_di_data))
    disp(size(permute(diam_data.trial(1,:,:),[2 3 1])))
    for trial = 1:size(diam_data.trial,1)
        smoothed_di_data(trial,:,:) = ft_preproc_smooth(permute(diam_data.trial(trial,:,:),[2 3 1]),cfg.nMeanS);
    end

    smoothed_sq_data = zeros(size(square_data.trial));
    for trial = 1:size(square_data.trial,1)
        smoothed_sq_data(trial,:,:) = ft_preproc_smooth(permute(square_data.trial(trial,:,:),[2 3 1]),cfg.nMeanS);
    end
end

%diagonal classifier
cfgS = [];
cfgS.classifier = 'multiclass_lda';
cfgS.metric = 'accuracy';
cfgS.preprocess ={'undersample'};
cfgS.repeat = 1;
train_sq_cross_acc = mv_classify_timextime(cfgS,smoothed_sq_data,square_data.trialinfo(:,6),smoothed_di_data,diam_data.trialinfo(:,6));
train_di_cross_acc = mv_classify_timextime(cfgS,smoothed_di_data,diam_data.trialinfo(:,6),smoothed_sq_data,square_data.trialinfo(:,6));
train_sq_cross_acc = train_sq_cross_acc'; %coz mvpa light has axes switched
train_di_cross_acc = train_di_cross_acc'; %coz mvpa light has axes switched


save(fullfile(outputDir,cfg.outputName{1}),'train_sq_cross_acc');
save(fullfile(outputDir,cfg.outputName{2}),'train_di_cross_acc');

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