function diagCrossDecode(cfg,subject)
disp('loading..')
disp(subject)
% output directory
outputDir = fullfile('../data/results',subject,cfg.outputDir);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

%load data
data = load(strcat('../data/',subject,'/',subject,'_clean.mat'));
data = struct2cell(data); data = data{1};



% select meg channels  and appropriate trials from train set
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.trainIdx));
cfgS             = [];
cfgS.channel     = 'MEG';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
train_data            = ft_timelockanalysis(cfgS,data);


% select meg channels  and appropriate trials from train set
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.testIdx));
cfgS             = [];
cfgS.channel     = 'MEG';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
test_data            = ft_timelockanalysis(cfgS,data);



% check if the contrast already exists
%if ~exist(fullfile(outputDir,[cfg.outputName '.mat']),'file')
    
    
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
    
    

    
    
   
    nTrainTrials = size(X_train,1); nTrainSamples = size(X_train,3);
    nTestTrials = size(X_test,1); nTestSamples = size(X_test,3);
    Xhat = zeros(nTestSamples,nTestTrials);
   
    
    trainidx = 1:nTrainTrials; %use all trials in training set as this is cross classification
    testidx = 1:nTestTrials; %use all trials in test set
    x{1} = X_train(trainidx,:,:); x{2} = X_test(testidx,:,:); %split training and testing data into two cells in one cell array
    y{1} = Y_train(trainidx); y{2} = Y_test(testidx); %split training and testing labels into two cells in one cell array

    fprintf('Decoding')
    Xhat(:,testidx) = decodingDiag(cfg,x,y); %decode here

    

    %1. Xhat > 0 finds all values in Xhat greater than 0, returning 1 in that element's location if element > 0 and 0 if element < 0.
    %2. the == etc. finds all values in the above boolean matrix that have the same value as Y, which are the correct trial labels
    %3. the mean function then takes an average of these values across all trials for each sample point
    Accuracy = squeeze(mean((Xhat>0)==permute(repmat(Y_test,1,nTestSamples),[2,1]),2));
    
    save(fullfile(outputDir,cfg.outputName),'Xhat','Y_train','Y_test','Accuracy','cfg','-v7.3');
%{
    else
    warning('Contrast already exists, loading for plotting');
    load(fullfile(outputDir,cfg.outputName),'Accuracy','cfg');
end
%}
mean_acc = mean(Accuracy);



% plot
if cfg.plot
    figure;

    plot(test_data.time,Accuracy,'r','LineWidth',1.5); 
    hold on; 
    
    yline(mean_acc,'r--','LineWidth',1.5);
    
    plot(xlim,[0.5 0.5],'k--','LineWidth',2)
    
    xlabel('Time (s)'); ylabel('Accuracy');
    xlim([test_data.time(1) test_data.time(end)]); title('Diagonal decoding')

end