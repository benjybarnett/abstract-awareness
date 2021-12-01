function [mean_acc,pval] = decode_ROI(cfg)

%function to cross decode using a multivoxel pattern taken from an ROI
%No searchlight procedure here.
for subj = 1:length(cfg.subjects)
    subject = cfg.subjects{subj};
    
    disp(subject);
    data_dir = cfg.data_dir;
    beta_path = strcat(data_dir,subject,'\');

    % set random generator for repeatability
    rng(1,'twister')

    % load roi mask
    [hdr,mask]    = read_nii(fullfile(cfg.roi_path,cfg.roi_file));
    
    %% Get the data
    % load SPM file
    SPM = load(strcat(data_dir,subject,'\SPM.mat'));
    SPM = SPM.SPM;
    
    % get conscious betas
    conIdx = find(contains(SPM.xX.name,'Sn(1) conscious') );
    trials = SPM.xX.name(conIdx);
    
    %create list of indices for trial type (animate / inanimate). These are
    %going to index the nTrials x nVoxels matrix we make
    Y=[];
    for trl = 1:length(trials)
        trial = trials(trl);
        trial = reverse(char(trial));
       

        if trial(12) == '1' || trial(12) == '2' %if trial is animate stim
            Y = [Y 0]; %0 for animate
        elseif trial(12) == '3' || trial(12) == '4' %if trial is inanimate stim
            Y = [Y 1]; %1 for inanimate
        end  
    end

    %load Beta files
    Betas=[];
    for t = 1:length(conIdx)
        [~,beta] = read_nii(fullfile(beta_path,sprintf('beta_%04d.nii',conIdx(t))));
        Betas(t,:) = beta(mask>0);
    end
    Y=Y';
    
    % downsample
    idx = balance_trials(double(Y)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
    Y = Y(cell2mat(idx));
    X = Betas(cell2mat(idx),:,:);
    fprintf('Using %d trials per class  \n',sum(Y==1))
    
    
    % n-fold cross-validation
    folds = createFolds(cfg,Y); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
    nTrials = size(X,1);
    Xhat = zeros(nTrials,1);

    % do n Fold cross-validation 
    for f = 1:cfg.nFold
        trainidx = setdiff(1:nTrials,folds{f}); %return indices of trials not in fold - used for training
        testidx = folds{f}; %return indices of trials in fold - used for testing
        x{1} = X(trainidx,:); x{2} = X(testidx,:); %split training and testing data into two cells in one cell array
        y{1} = Y(trainidx); y{2} = Y(testidx); %split training and testing labels into two cells in one cell array

        %fprintf('Decoding fold %d out of %d \n',f,cfg.nFold)

        % train
        decoder = train_LDA(cfg,y{1}, x{1}');

        % test
        Xhat(testidx) = decode_LDA(cfg, decoder, x{2}');

    end

    yhat = Xhat > 0;
    % save accuracy per searchlight at the searchlight's center
    acc = mean(yhat == Y); 
    
    % save true accuracies
    outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},cfg.roi);
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    save(fullfile(outputDir,'true_acc.mat'),'acc')
    
    
    %% Permutation with label swapping
    accuracy   = cell(1,cfg.nPerm);
    for per = 1:cfg.nPerm
       fprintf('\t Permutation %d out of %d \n',per,cfg.nPerm)
       
        %permute labels for both data conditions
        Y_perm = Y(randperm(length(Y)));
        
        % n-fold cross-validation
        folds = createFolds(cfg,Y_perm); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
        nTrials = size(X,1);
        Xhat = zeros(nTrials,1);

        % do n Fold cross-validation 
        for f = 1:cfg.nFold
            trainidx = setdiff(1:nTrials,folds{f}); %return indices of trials not in fold - used for training
            testidx = folds{f}; %return indices of trials in fold - used for testing
            x{1} = X(trainidx,:); x{2} = X(testidx,:); %split training and testing data into two cells in one cell array
            y{1} = Y_perm(trainidx); %shuffled labels for training
            
            % train
            decoder = train_LDA(cfg,y{1}, x{1}'); %training on shuffled labels
            % test
            Xhat(testidx) = decode_LDA(cfg, decoder, x{2}');

        end

        yhat = Xhat > 0;
        % save accuracy 
        accuracy{per} = mean(yhat == Y);
        
       
    end
    % save
    save(fullfile(outputDir,'accuracyPerm.mat'),'accuracy')
end
    
    
    %% Bootstrap to create group level null distribution
    % loading permutations
    acc_perm = []; 
    for subj = 1:length(cfg.subjects)

        outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},cfg.roi);

        if exist(fullfile(outputDir,'accuracyPerm.mat'),'file')

            fprintf('Loading subj %d \n',subj)
            load(fullfile(outputDir,'accuracyPerm.mat'),'accuracy')

            for p = 1:cfg.nPerm

                acc_perm(subj,p) = accuracy{p};
                         

            end        

            clear accuracy

        else 
            fprintf('Sub %d not enough trials \n',subj)
        end
    end
    
    % creating bootstrapped null distribution 
    acc_btstrp = nan(cfg.nBtrsp,1);
    nSubs = size(acc_perm,1);
    for b = 1:cfg.nBtrsp

        if mod(b,100)==0; fprintf('\t Bootstrapping %d out of %d \n',b, cfg.nBtrsp); end

        acc = [];
        for s = 1:nSubs
            perm = randi(cfg.nPerm);
            acc = cat(2,acc,squeeze(acc_perm(s,perm)));
            
        end
        acc_btstrp(b) = nanmean(acc,2);
      
    end

    % compare to empirical distribution 
    emp_dist = [];
    for subj = 1:length(cfg.subjects)
        subject = cfg.subjects{subj};
        
        true_acc = load(fullfile(cfg.output_dir,cfg.subjects{subj},cfg.roi,'true_acc.mat'));
        emp_dist = [emp_dist true_acc.acc];
    end
    
    
    pval = sum(acc_btstrp > mean(emp_dist))/cfg.nBtrsp;
    mean_acc = mean(emp_dist);
    fprintf('\t Accuracy within the %s ROI has a mean of %d and a p value  of %d \n',cfg.roi,mean_acc,pval);

end