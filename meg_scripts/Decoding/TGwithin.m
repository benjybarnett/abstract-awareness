function TGwithin(cfg,subject)
%
% Temporal generalization within - use leave one out per class for decoding
% to maximimize use of small trial numbers 

% output directory
outputDir = fullfile('../data/results',subject,cfg.outputDir);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

% get MEG data
disp('loading..')
disp(subject)
data = load(strcat('../data/',subject,'/',subject,'_clean.mat'));
data = struct2cell(data); data = data{1};
disp('loaded data')


% select ony MEG channels and appropriate trials 
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},') & ',cfg.conIdx{3}));
cfgS             = [];
cfgS.channel     = 'MEG';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
data             = ft_timelockanalysis(cfgS,data);

% check if the contrast already exists
%if ~exist(fullfile(outputDir,[cfg.outputName '.mat']),'file')
    
    % create labels and balance classes
    labels = eval(cfg.conIdx{1});
    
    idx = balance_trials(double(labels)+1,'downsample');
    Y = labels(cell2mat(idx)); X = data.trial(cell2mat(idx),:,:);
    
    
    if size(X,1) == 0
        return
    end
    % check for NaNs in channels 
    nan_chidx = isnan(squeeze(X(1,:,1)));
    if sum(nan_chidx) > 0 
        fprintf('The following channels are NaNs, removing these \n');
        disp(data.label(nan_chidx));
        X(:,nan_chidx,:) = [];
    end
    
    fprintf('Using %d trials per class \n',sum(Y==1))
    
    % n-fold cross-validation
    folds = createFolds(cfg,Y);
    nTrials = size(X,1); nSamples = size(X,3);
    Xhat = zeros(nSamples,nSamples,nTrials);
    for f = 1:cfg.nFold
        trainidx = setdiff(1:nTrials,folds{f}); testidx = folds{f};
        x{1} = X(trainidx,:,:); x{2} = X(testidx,:,:);
        y{1} = Y(trainidx); y{2} = Y(testidx);
        
        fprintf('Decoding fold %d out of %d \n',f,cfg.nFold)
        Xhat(:,:,testidx) = decodingCrossTime(cfg,x,y);
    end
    
    Accuracy = squeeze(mean((Xhat>0)==permute(repmat(Y,1,nSamples,nSamples),[2,3,1]),3));
    
    save(fullfile(outputDir,cfg.outputName),'Accuracy');
%{
    warning('Contrast already exists, loading for plotting');
    load(fullfile(outputDir,cfg.outputName),'Accuracy','cfg');
end
%}
% plot
if cfg.plot
    figure;
    subplot(2,3,[1 4]);
    imagesc(data.time,data.time,Accuracy); axis xy; colorbar
    xlabel('Time (s)'); ylabel('Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet') 
    
    subplot(2,3,2:3);
    plot(data.time,diag(Accuracy),'LineWidth',2); 
    hold on; plot(xlim,[0.5 0.5],'k--','LineWidth',2);
    xlabel('Time (s)'); ylabel('Accuracy');
    xlim([data.time(1) data.time(end)]); title('Diagonal decoding')
    
    subplot(2,3,5:6);
    m0 = diag(squeeze(mean(Xhat(:,:,Y==0),3)));
    m1 = diag(squeeze(mean(Xhat(:,:,Y==1),3)));
    plot(data.time,m1,'r','LineWidth',2); hold on;
    plot(data.time,m0,'k','LineWidth',2); 
    xlabel('Time (s)'); ylabel('Distance');
    xlim([data.time(1) data.time(end)]); 
end


