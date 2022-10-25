function diagCrossDecode_split(cfg,subject)

% output directory
outputDir = fullfile('../data/results',subject,cfg.outputDir);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

%load data
data = load(strcat('../data/',subject,'/',subject,'_clean.mat'));
data = struct2cell(data); data = data{1};

%remove all trials except those belonging to two classes of interest
%need this step as below we still use the whole data structure, and it
%assumes only existence of 2 classes (when creating labels)
cfgR = [];
cfgR.trials = eval(strcat(cfg.conIdx{1}," | ",cfg.conIdx{2}));
data = ft_selectdata(cfgR,data);


% select GRAD channels  and appropriate trials from train set
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.trainIdx));
cfgS             = [];
cfgS.channel     = 'MEGGRAD';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
grad_train_data            = ft_timelockanalysis(cfgS,data);


% select GRAD channels  and appropriate trials from train set
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.testIdx));
cfgS             = [];
cfgS.channel     = 'MEGGRAD';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
grad_test_data            = ft_timelockanalysis(cfgS,data);



% select MAG channels  and appropriate trials from train set
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.trainIdx));
cfgS             = [];
cfgS.channel     = 'MEGMAG';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
mag_train_data            = ft_timelockanalysis(cfgS,data);


% select mag channels  and appropriate trials from train set
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.testIdx));
cfgS             = [];
cfgS.channel     = 'MEGMAG';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
mag_test_data            = ft_timelockanalysis(cfgS,data);



% check if the contrast already exists
if ~exist(fullfile(outputDir,[cfg.outputName '.mat']),'file')
    
    
    % create labels and balance classes
    train_labels = eval(strcat('grad_train_',cfg.conIdx{1}," & grad_train_",cfg.trainIdx));%labels is a Ntrials length vector with 1 for one class and 0 for the other
    test_labels = eval(strcat('grad_test_',cfg.conIdx{1}," & grad_test_",cfg.testIdx));
    
    %balance the number of trials of each condition in train and test
    %samples
    idx_train = balance_trials(double(train_labels)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
    idx_test = balance_trials(double(test_labels)+1,'downsample');
    disp(size(idx_train))
    disp(idx_train)
    
    Y_train = train_labels(cell2mat(idx_train));
    Y_test = test_labels(cell2mat(idx_test));
    
    grad_X_train = grad_train_data.trial(cell2mat(idx_train),:,:);
    grad_X_test = grad_test_data.trial(cell2mat(idx_test),:,:);
    disp(size(grad_X_train))
    
    mag_X_train = mag_train_data.trial(cell2mat(idx_train),:,:);
    mag_X_test = mag_test_data.trial(cell2mat(idx_test),:,:);
    disp(size(mag_X_train))
    
    % check for NaNs in train data
    nan_chidx = isnan(squeeze(grad_X_train(1,:,1)));
    if sum(nan_chidx) > 0 
        fprintf('The following channels are NaNs, removing these \n');
        disp(grad_train_data.label(nan_chidx));
        grad_X_train(:,nan_chidx,:) = [];
    end
    
    % check for NaNs in test data
    nan_chidx = isnan(squeeze(grad_X_test(1,:,1)));
    if sum(nan_chidx) > 0 
        fprintf('The following channels are NaNs, removing these \n');
        disp(grad_test_data.label(nan_chidx));
        grad_X_test(:,nan_chidx,:) = [];
    end
    
    % check for NaNs in train data
    nan_chidx = isnan(squeeze(mag_X_train(1,:,1)));
    if sum(nan_chidx) > 0 
        fprintf('The following channels are NaNs, removing these \n');
        disp(mag_train_data.label(nan_chidx));
        mag_X_train(:,nan_chidx,:) = [];
    end
    
    % check for NaNs in test data
    nan_chidx = isnan(squeeze(mag_X_test(1,:,1)));
    if sum(nan_chidx) > 0 
        fprintf('The following channels are NaNs, removing these \n');
        disp(mag_test_data.label(nan_chidx));
        mag_X_test(:,nan_chidx,:) = [];
    end
    
    
    fprintf('Using %d trials per class in training\n',sum(Y_train==1))
    fprintf('Using %d trials per class in testing\n',sum(Y_test==1))
    
    %smooth data
    if strcmp(cfg.smooth,'yes')
        grad_X_train = smooth_data(grad_X_train,cfg.smooth_n);
        grad_X_test = smooth_data(grad_X_test,cfg.smooth_n);
        
        mag_X_train = smooth_data(mag_X_train,cfg.smooth_n);
        mag_X_test = smooth_data(mag_X_test,cfg.smooth_n);
    end
    

    
    % n-fold cross-validation grad channels
    train_folds = createFolds(cfg,Y_train); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
    test_folds = createFolds(cfg,Y_test); %create own test fold so test set classes are balanced across folds
    
    nTrainTrials = size(grad_X_train,1); nTrainSamples = size(grad_X_train,3);
    nTestTrials = size(grad_X_test,1); nTestSamples = size(grad_X_test,3);
    grad_Xhat = zeros(nTestSamples,nTestTrials);
    mag_Xhat = zeros(nTestSamples,nTestTrials);
    for f = 1:cfg.nFold
        trainidx = setdiff(1:nTrainTrials,train_folds{f}); %return indices of trials not in training fold - used for training
        testidx = test_folds{f}; %return indices of trials in test fold - used for testing
        grad_x{1} = grad_X_train(trainidx,:,:); grad_x{2} = grad_X_test(testidx,:,:); %split training and testing data into two cells in one cell array
        y{1} = Y_train(trainidx); y{2} = Y_test(testidx); %split training and testing labels into two cells in one cell array
        
        fprintf('Decoding fold %d out of %d \n',f,cfg.nFold)
        %disp(decodingDiag(cfg,x,y))
        grad_Xhat(:,testidx) = decodingDiag(cfg,grad_x,y); %decode here
        
        mag_x{1} = mag_X_train(trainidx,:,:); mag_x{2} = mag_X_test(testidx,:,:); %split training and testing data into two cells in one cell array
        
        fprintf('Decoding fold %d out of %d \n',f,cfg.nFold)
        %disp(decodingDiag(cfg,x,y))
        mag_Xhat(:,testidx) = decodingDiag(cfg,mag_x,y); %decode here
    end
    

    %1. Xhat > 0 finds all values in Xhat greater than 0, returning 1 in that element's location if element > 0 and 0 if element < 0.
    %2. the == etc. finds all values in the above boolean matrix that have the same value as Y, which are the correct trial labels
    %3. the mean function then takes an average of these values across all trials for each sample point
    grad_accuracy = squeeze(mean((grad_Xhat>0)==permute(repmat(Y_test,1,nTestSamples),[2,1]),2));
    mag_accuracy = squeeze(mean((mag_Xhat>0)==permute(repmat(Y_test,1,nTestSamples),[2,1]),2));
    
    save(fullfile(outputDir,cfg.outputName),'grad_accuracy','mag_accuracy');
else
    warning('Contrast already exists');
    
end





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