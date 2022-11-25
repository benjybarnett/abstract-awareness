function [hdr, acc] = WithinDecodingSearchlightPermutationBOB(cfg)
    
    

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


        %create list of indices for animate set and inanimate set. These are
        %going to index the nTrials x nVoxels matrix we make
        anim_idxs = [];
        inanim_idxs = [];
        Y_anim = [];
        Y_inanim =[];
        for trl = 1:length(trials)
            trial = trials(trl);
            trial = reverse(char(trial));

            if trial(12) == '1' || trial(12) == '2' %if trial in animate set
                anim_idxs = [anim_idxs trl];
                %get labels (0 for low vis, 1 for high vis)
                if str2double(trial(7)) < med %if lower than median split
                    Y_anim = [Y_anim 0]; %low vis label 
                elseif str2double(trial(7)) >= med %if equal or greater than median split
                    Y_anim = [Y_anim 1]; %high vis label
                end
            elseif trial(12) == '3' || trial(12) == '4' %if trial in test set
                inanim_idxs = [inanim_idxs trl]; 
                %get labels (0 for low vis, 1 for high vis)
                if str2double(trial(7)) < med %if lower than median split
                    Y_inanim = [Y_inanim 0]; %low vis label 
                elseif str2double(trial(7)) >= med %if equal or greater than median split
                    Y_inanim = [Y_inanim 1]; %high vis label
                end
            end  

        end


        for trl = 1:length(anim_idxs)
            trial = trials_needed(anim_idxs(trl));
            if trial < 100 %i.e. if trial is 2 digits
                file_name = strcat('beta_00',string(trial),'.nii');
            else
                file_name = strcat('beta_0',string(trial),'.nii');
            end

            %disp(strcat(beta_path,file_name))
            beta_file = char(fullfile(beta_path,file_name));

            [~, beta] = read_nii(beta_file);
            anim_Betas(trl,:) = beta(mask>0.5);
        end

        for trl = 1:length(inanim_idxs)
            trial = trials_needed(inanim_idxs(trl));
            if trial < 100 %i.e. if trial is 2 digits
                file_name = strcat('beta_00',string(trial),'.nii');
            else
                file_name = strcat('beta_0',string(trial),'.nii');
            end

            %disp(strcat(beta_path,file_name))
            beta_file = char(fullfile(beta_path,file_name));

            [~, beta] = read_nii(beta_file);
            inanim_Betas(trl,:) = beta(mask>0.5);
        end


        X_anim = anim_Betas; % dataset [nTrials x nVoxels]
        Y_anim = Y_anim'; % labels

        X_inanim = inanim_Betas; % dataset [nTrials x nVoxels]
        Y_inanim = Y_inanim'; % labels

        % downsample to get equal numbers per class
        %balance the number of trials of each condition in animate samples
        anim_idx = balance_trials(double(Y_anim)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
        Y_anim = Y_anim(cell2mat(anim_idx));
        X_anim = X_anim(cell2mat(anim_idx),:,:);
        fprintf('Using %d trials per class in animate set \n',sum(Y_anim==1))

        % downsample to get equal numbers per class
        %balance the number of trials of each condition in inanimate samples
        inanim_idx = balance_trials(double(Y_inanim)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
        Y_inanim = Y_inanim(cell2mat(inanim_idx));
        X_inanim = X_inanim(cell2mat(inanim_idx),:,:);
        fprintf('Using %d trials per class in inanimate set \n',sum(Y_inanim==1))

        %% Loop over searchlights for decoding
        accuracy   = cell(2,cfg.nPerm);  

        for per = 1:cfg.nPerm
            fprintf('\t Permutation %d out of %d \n',per,cfg.nPerm)

            %permute labels for both data conditions
            Y_labels_anim = Y_anim(randperm(length(Y_anim)));
            Y_labels_inanim = Y_inanim(randperm(length(Y_inanim)));

            accuracy{1,per} = zeros(hdr.dim); accuracy{2,per} = zeros(hdr.dim);

            for s = 1:length(mind)

                    if mod(s,2000) == 0 
                        fprintf('Decoding from searchlight %d out of %d \n',s,length(mind))
                    end

                    % select these animate voxels for training and testing
                    anim_slX = X_anim(:,mind{s}); %slX is a nTrials vs. nVoxels in Searchlight matrix
                    anim_slX(:,isnan(anim_slX(1,:))) = []; %remove NaNs

                    % select these inanimate voxels for training and testing
                    inanim_slX = X_inanim(:,mind{s}); %slX is a nTrials vs. nVoxels in Searchlight matrix
                    inanim_slX(:,isnan(inanim_slX(1,:))) = []; %remove NaNs

                    % n-fold cross-validation when training and testing
                    % within animate
                    train_folds = createFolds(cfg,Y_labels_anim); test_folds = createFolds(cfg,Y_anim); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
                    nTrialsTrain = size(anim_slX,1); nTrialsTest = size(anim_slX,1);
                    Xhat = zeros(nTrialsTest,1);

                    % do n Fold cross-validation 
                    for f = 1:cfg.nFold
                        trainidx = setdiff(1:nTrialsTrain,train_folds{f}); %return indices of trials not in fold - used for training
                        testidx = test_folds{f}; %return indices of trials in fold - used for testing
                        x{1} = anim_slX(trainidx,:); x{2} = anim_slX(testidx,:); %split training and testing data into two cells in one cell array
                        y{1} = Y_labels_anim(trainidx); %these are shuffled labels for training
                        y{2} = Y_anim(testidx); %split training and testing labels into two cells in one cell array
                        % train on shuffled labels
                        decoder = train_LDA(cfg,y{1}, x{1}');
                        % test
                        Xhat(testidx) = decode_LDA(cfg, decoder, x{2}');
                    end
                    yhat = Xhat > 0;
                    % save accuracy per searchlight at the searchlight's center
                    accuracy{1,per}(sl_centers{s}) = mean(yhat == Y_anim); 


                    % n-fold cross-validation when training and testing
                    % within animate
                    train_folds = createFolds(cfg,Y_labels_inanim); test_folds = createFolds(cfg,Y_inanim); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
                    nTrialsTrain = size(inanim_slX,1); nTrialsTest = size(inanim_slX,1);
                    Xhat = zeros(nTrialsTest,1);

                    % do n Fold cross-validation 
                    for f = 1:cfg.nFold
                        trainidx = setdiff(1:nTrialsTrain,train_folds{f}); %return indices of trials not in fold - used for training
                        testidx = test_folds{f}; %return indices of trials in fold - used for testing
                        x{1} = inanim_slX(trainidx,:); x{2} = inanim_slX(testidx,:); %split training and testing data into two cells in one cell array
                        y{1} = Y_labels_inanim(trainidx);%these are the shuffled labels for training
                        y{2} = Y_inanim(testidx); %split training and testing labels into two cells in one cell array
                        % train on shuffled labels
                        decoder = train_LDA(cfg,y{1}, x{1}');
                        % test
                        Xhat(testidx) = decode_LDA(cfg, decoder, x{2}');
                    end
                    yhat = Xhat > 0;
                    % save accuracy per searchlight at the searchlight's center

                    accuracy{2,per}(sl_centers{s}) = mean(yhat == Y_inanim); 

            end
        end
     % save
    outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},cfg.decoding_type);
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    save(fullfile(outputDir,'accuracyPerm.mat'),'accuracy')
    
    clear accuracy
    end


    %% Create group null distributions 
    groupDir = fullfile(cfg.output_dir,'group\within\');
    if ~exist(groupDir,'dir'); mkdir(groupDir); end

    % loading permutations
    accA_perm = []; 
    accI_perm = []; 
    for subj = 1:length(cfg.subjects)

        outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},'within');

        if exist(fullfile(outputDir,'accuracyPerm.mat'),'file')

            fprintf('Loading subj %d \n',subj)
            load(fullfile(outputDir,'accuracyPerm.mat'),'accuracy')

            for p = 1:cfg.nPerm

                accA_perm(subj,p,:) = accuracy{1,p}(mask(:)>0);
                accI_perm(subj,p,:) = accuracy{2,p}(mask(:)>0);          

            end        

            clear accuracy

        else 
            fprintf('Sub %d not enough trials \n',subj)
        end
    end

    nanIdx = squeeze(accA_perm(:,1,1))==0;
    accA_perm(nanIdx,:,:) = []; accI_perm(nanIdx,:,:) = [];
    
    % creating bootstrapped null distribution 
    accA_btstrp = nan(cfg.nBtrsp,sum(mask(:)>0));
    accI_btstrp = nan(cfg.nBtrsp,sum(mask(:)>0));
    nSubs = size(accA_perm,1);
    for b = 1:cfg.nBtrsp

        if mod(b,100)==0; fprintf('\t Bootstrapping %d out of %d \n',b, cfg.nBtrsp); end

        accA = []; accI = [];
        for s = 1:nSubs
            perm = randi(cfg.nPerm);
            accA = cat(2,accA,squeeze(accA_perm(s,perm,:)));
            accI = cat(2,accI,squeeze(accI_perm(s,perm,:)));
        end
        accA_btstrp(b,:) = nanmean(accA,2);
        accI_btstrp(b,:) = nanmean(accI,2);
    end

    
    % compare to empirical distribution 
    %[~,acc] = read_nii(fullfile(groupDir,'accuracy.nii'));
    [~,A] = read_nii(fullfile(groupDir,'animate.nii'));
    [V,I] = read_nii(fullfile(groupDir,'inanimate.nii'));

    tmp = zeros(V.dim);
    pvals = sum(accA_btstrp > A(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'pValsA.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-pValsA.nii'));

    tmp = zeros(V.dim);
    pvals = sum(accA_btstrp < A(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'rpValsA.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-rpValsA.nii'));

    tmp = zeros(V.dim);
    pvals = sum(accI_btstrp > I(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'pValsI.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-pValsI.nii'));

    tmp = zeros(V.dim);
    pvals = sum(accI_btstrp < I(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'rpValsI.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-rpValsI.nii'));
%{
    tmp = zeros(V.dim);
    pvals = sum(((accIA_btstrp+accAI_btstrp)./2) > acc(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'pVals.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-pVals.nii'));

    tmp = zeros(V.dim);
    pvals = sum(((accIA_btstrp+accAI_btstrp)./2) < acc(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'rpVals.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-rpVals.nii'));
%}

