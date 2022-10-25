function tempCrossDecode(cfg,subject)
disp('loading..')
disp(subject)
% output directory
outputDir = fullfile('../data/results',subject,cfg.outputDir);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

load('frontal_parietal_sensors')
load('frontal_sensors')
%load data
data = load(strcat('../data/',subject,'/',subject,'_clean.mat'));
data = struct2cell(data); data = data{1};



% select meg channels  and appropriate trials from train set
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.trainIdx));
cfgS             = [];
if strcmp(cfg.channel, 'fronto_par')
    cfgS.channel     = fronto_parietal_sensors;
    disp('fronto par')
elseif strcmp(cfg.channel, 'frontal')
    disp('frontal')
    cfgS.channel     = frontal_sensors;
else
    cfgS.channel = 'MEG';
end
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
train_data            = ft_timelockanalysis(cfgS,data);


% select meg channels  and appropriate trials from train set
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.testIdx));
cfgS             = [];
if strcmp(cfg.channel, 'fronto_par')
    cfgS.channel     = fronto_parietal_sensors;
    disp('fronto par')
elseif strcmp(cfg.channel, 'frontal')
    disp('frontal')
    cfgS.channel     = frontal_sensors;
else
    cfgS.channel = 'MEG';
end
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
test_data            = ft_timelockanalysis(cfgS,data);


% check if the contrast already exists
%if ~exist(fullfile(outputDir,strcat(cfg.outputName, '.mat')),'file')
    
    
    % create labels and balance classes
    train_labels = eval(strcat('train_',cfg.conIdx{1}));%labels is a Ntrials length vector with 1 for one class and 0 for the other
    test_labels = eval(strcat('test_',cfg.conIdx{1}));
    
    %balance the number of trials of each condition in train and test
    %samples
    idx_train = balance_trials(double(train_labels)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
    idx_test = balance_trials(double(test_labels)+1,'downsample');
 
    
    Y_train = train_labels(cell2mat(idx_train));
    Y_test = test_labels(cell2mat(idx_test));
    
    X_train = train_data.trial(cell2mat(idx_train),:,:);
    X_test = test_data.trial(cell2mat(idx_test),:,:);
    
    
    % check for NaNs in train data
    nan_chidx = isnan(squeeze(X_train(1,:,1)));
    if sum(nan_chidx) > 0 
        fprintf('The following channels are NaNs, removing these \n');
        disp(train_data.label(nan_chidx));
        X_train(:,nan_chidx,:) = [];
    end
    
    % check for NaNs in test data
    nan_chidx = isnan(squeeze(X_test(1,:,1)));
    if sum(nan_chidx) > 0 
        fprintf('The following channels are NaNs, removing these \n');
        disp(test_data.label(nan_chidx));
        X_test(:,nan_chidx,:) = [];
    end
    
    
    fprintf('Using %d trials per class in training\n',sum(Y_train==1))
    fprintf('Using %d trials per class in testing\n',sum(Y_test==1))
    
    

   % n-fold cross-validation
    train_folds = createFolds(cfg,Y_train); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
    test_folds = createFolds(cfg,Y_test);
    nTrialsTrain = size(X_train,1); nSamplesTrain = size(X_test,3);
    nTrialsTest = size(X_test,1); nSamplesTest = size(X_test,3);
    Xhat = zeros(nSamplesTrain,nSamplesTest,nTrialsTest);
    for f = 1:cfg.nFold
        trainidx = setdiff(1:nTrialsTrain,train_folds{f}); %return indices of trials not in fold - used for training
        testidx = test_folds{f}; %return indices of trials in fold - used for testing
        x{1} = X_train(trainidx,:,:); x{2} = X_test(testidx,:,:); %split training and testing data into two cells in one cell array
        y{1} = Y_train(trainidx); y{2} = Y_test(testidx); %split training and testing labels into two cells in one cell array
        
        fprintf('Decoding fold %d out of %d \n',f,cfg.nFold)
        Xhat(:,:,testidx) = decodingCrossTime(cfg,x,y); %decode here
    end
    

    %1. Xhat > 0 finds all values in Xhat greater than 0, returning 1 in that element's location if element > 0 and 0 if element < 0.
    %2. the == etc. finds all values in the above boolean matrix that have the same value as Y, which are the correct trial labels
    %3. the mean function then takes an average of these values across all trials for each sample point
    Accuracy = squeeze(mean((Xhat>0)==permute(repmat(Y_test,1,nSamplesTrain,nSamplesTest),[2,3,1]),3));
    
    save(fullfile(outputDir,cfg.outputName),'Xhat','Y_train','Y_test','Accuracy','cfg','-v7.3');
%{
else
    warning('Contrast already exists, loading for plotting');
    if cfg.plot
        load(fullfile(outputDir,cfg.outputName),'Accuracy','cfg','Xhat','Y_test','test_data');
    end
end


%}


% plot

if cfg.plot
    
    
    time = test_data.time - 0.025;
    figure;
    subplot(2,3,[1 4]);
    imagesc(time,time,Accuracy); axis xy; colorbar
    xlabel('Time (s)'); ylabel('Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet') 
    
    subplot(2,3,2:3);
    plot(time,diag(Accuracy),'LineWidth',2); 
    hold on; plot(xlim,[0.5 0.5],'k--','LineWidth',2);
    xlabel('Time (s)'); ylabel('Accuracy');
    xlim([time(1) time(end)]); title('Diagonal decoding')
    
    subplot(2,3,5:6);
    m0 = diag(squeeze(mean(Xhat(:,:,Y_test==0),3)));
    m1 = diag(squeeze(mean(Xhat(:,:,Y_test==1),3)));
    plot(time,m1,'r','LineWidth',2); hold on;
    plot(time,m0,'k','LineWidth',2); 
    xlabel('Time (s)'); ylabel('Distance');
    xlim([time(1) time(end)]); 





end