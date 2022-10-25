function [hdr, acc] = ContentDecodingSearchlightPermutationBOB(cfg)
    
    

    data_dir = cfg.data_dir;
    

    % set random generator for repeatability
    rng(1,'twister')

    %% Get the searchlight indices
    slradius = cfg.sl_radius; % radius for the searchlight in voxels 

    % load grey matter mask and functional
    [hdr,mask]    = read_nii(cfg.mask);

    % infer the searchlight  indices
    [vind,mind,sl_centers] = searchlightIndices(mask>0,slradius);
    
    for subj = 1:length(cfg.subjects)
        tic
        subject = cfg.subjects{subj};
        disp(subject);
        beta_path = strcat(data_dir,subject,'\');

        %% Read in the betas to get a nTrial x nVoxel(in mask) matrix
        %Read in trials
        SPM = load(strcat(data_dir,subject,'\SPM.mat'));
        SPM=SPM.SPM;
        %select only cnscious trials
        conIdx = find(contains(SPM.xX.name,'Sn(1) conscious'));
        trials = SPM.xX.name(conIdx);


        %now, we must check where to split subjects ratings into low and high
        %visual ratings
        med = getMedSplit(subject,data_dir);

        %store trial number of needed trials
        trials_needed = conIdx; 


        %create list of indices. These are
        %going to index the nTrials x nVoxels matrix we make, so will not idx the
        %full list of beta files, but only the trials_needed
        idxs = [];
        Y = [];
        for trl = 1:length(trials_needed)
            trial = trials_needed(trl);
            trial = reverse(char(SPM.xX.name(trial))); 
    
            %remove low vis trials 
            if str2double(trial(7)) < med
                continue
            else
                idxs = [idxs trl];
            end
    
    
            %get labels (0 for animate, 1 for inanimate)
            if trial(12) == '1' || trial(12) == '2' %if animate
                Y = [Y 0]; 
            elseif trial(12) == '3' || trial(12) == '4' %if inanimate
                Y = [Y 1]; 
            end
        end


        for trl = 1:length(idxs)
            trial = trials_needed(idxs(trl));
            if trial < 100 %i.e. if trial is 2 digits
                file_name = strcat('beta_00',string(trial),'.nii');
            else
                file_name = strcat('beta_0',string(trial),'.nii');
            end

            %disp(strcat(beta_path,file_name))
            beta_file = char(fullfile(beta_path,file_name));

            [~, beta] = read_nii(beta_file);
            Betas(trl,:) = beta(mask>0.5);
        end

        
        X= Betas; % dataset [nTrials x nVoxels]
        Y = Y'; % labels


        % downsample to get equal numbers per class
        %balance the number of trials of each condition in animate samples
        idx = balance_trials(double(Y)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
        Y= Y(cell2mat(idx));
        X = X(cell2mat(idx),:,:);
        fprintf('Using %d trials per class  \n',sum(Y==1))



        %% Loop over searchlights for decoding
        accuracy   = cell(1,cfg.nPerm);  

        for per = 1:cfg.nPerm
            fprintf('\t Permutation %d out of %d \n',per,cfg.nPerm)

            %permute labels
            Y_labels = Y(randperm(length(Y)));

            accuracy{1,per} = zeros(hdr.dim); 

            for s = 1:length(mind)

                    if mod(s,2000) == 0 
                        fprintf('Decoding from searchlight %d out of %d \n',s,length(mind))
                    end

                    % select voxels for training and testing
                    slX = X(:,mind{s}); %slX is a nTrials vs. nVoxels in Searchlight matrix
                    slX(:,isnan(slX(1,:))) = []; %remove NaNs

                    % n-fold cross-validation 
                    train_folds = createFolds(cfg,Y_labels); test_folds = createFolds(cfg,Y); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
                    nTrialsTrain = size(slX,1); nTrialsTest = size(slX,1);
                    Xhat = zeros(nTrialsTest,1);

                    % do n Fold cross-validation 
                    for f = 1:cfg.nFold
                        trainidx = setdiff(1:nTrialsTrain,train_folds{f}); %return indices of trials not in fold - used for training
                        testidx = test_folds{f}; %return indices of trials in fold - used for testing
                        x{1} = slX(trainidx,:); x{2} = slX(testidx,:); %split training and testing data into two cells in one cell array
                        y{1} = Y_labels(trainidx); %these are shuffled labels for training
                        y{2} = Y(testidx); %split training and testing labels into two cells in one cell array
                        % train on shuffled labels
                        decoder = train_LDA(cfg,y{1}, x{1}');
                        % test
                        Xhat(testidx) = decode_LDA(cfg, decoder, x{2}');
                    end
                    yhat = Xhat > 0;
                    % save accuracy per searchlight at the searchlight's center
                    accuracy{1,per}(sl_centers{s}) = mean(yhat == Y); 
                    
            end
        end
     % save
    outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},cfg.decoding_type);
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    save(fullfile(outputDir,'accuracyPerm.mat'),'accuracy')
    
    clear accuracy
    toc
    end


    %% Create group null distributions 
    groupDir = fullfile(cfg.output_dir,'group\content\');
    if ~exist(groupDir,'dir'); mkdir(groupDir); end

    % loading permutations
    acc_perm = []; 
    for subj = 1:length(cfg.subjects)

        outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},'content');

        if exist(fullfile(outputDir,'accuracyPerm.mat'),'file')

            fprintf('Loading subj %d \n',subj)
            load(fullfile(outputDir,'accuracyPerm.mat'),'accuracy')

            for p = 1:cfg.nPerm

                acc_perm(subj,p,:) = accuracy{1,p}(mask(:)>0);

            end        

            clear accuracy

        else 
            fprintf('Sub %d not enough trials \n',subj)
        end
    end

    nanIdx = squeeze(acc_perm(:,1,1))==0;
    acc_perm(nanIdx,:,:) = []; 
    
    % creating bootstrapped null distribution 
    acc_btstrp = nan(cfg.nBtrsp,sum(mask(:)>0));
    nSubs = size(acc_perm,1);
    for b = 1:cfg.nBtrsp

        if mod(b,100)==0; fprintf('\t Bootstrapping %d out of %d \n',b, cfg.nBtrsp); end

        acc = []; 
        for s = 1:nSubs
            perm = randi(cfg.nPerm);
            acc = cat(2,acc,squeeze(acc_perm(s,perm,:)));
        end
        acc_btstrp(b,:) = nanmean(acc,2);
    end

    
    % compare to empirical distribution 
    [V,acc] = read_nii(fullfile(groupDir,'content_sl.nii'));

    tmp = zeros(V.dim);
    pvals = sum(acc_btstrp > acc(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'pValsAcc.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-pValsAcc.nii'));

    tmp = zeros(V.dim);
    pvals = sum(acc_btstrp < acc(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'rpValsAcc.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-rpValsAcc.nii'));

  
​

