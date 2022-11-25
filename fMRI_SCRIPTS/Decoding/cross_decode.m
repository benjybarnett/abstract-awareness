function [hdr, acc] = cross_decode(cfg,subject)
    
    %Function to train LDA on one dataset (e.g. animate) and then test on
    %another (e.g. inanimate)
    data_dir = cfg.data_dir;
    beta_path = strcat(data_dir,subject,'\');

    % set random generator for repeatability
    rng(1,'twister')

    %% Get the searchlight indices
    slradius = cfg.sl_radius; % radius for the searchlight in voxels 

    % load grey matter mask and functional
    [hdr,mask]    = read_nii(cfg.mask);

    % infer the searchlight  indices
    [vind,mind,sl_centers] = searchlightIndices(mask>0,slradius);

    %% Read in the betas to get a nTrial x nVoxel(in mask) matrix
    %Read in trials
    SPM = load(strcat(data_dir,subject,'\SPM.mat'));
    SPM=SPM.SPM;
    %select only cnscious trials
    trials = {};
    reached_consc = false; %use this to find the index for first conscious trial - necessary as diff subjs have diff numbers of conscious trials so they first appear in different locations
    reached_uncon = false;
    for trl = 1:length(SPM.xX.name)
        if contains(SPM.xX.name(trl),' conscious')
            trials = [trials SPM.xX.name(trl)];
            if reached_consc == false
                first_consc_idx = trl;
                reached_consc = true;
            end
        elseif contains(SPM.xX.name(trl),'unconscious')
            if reached_uncon == false
                first_uncon_idx = trl;
                reached_uncon = true;
            end
        end
    end


    %now, we must check where to split subjects ratings into low and high
    %visual ratings
    med = getMedSplit(subject,data_dir);

    %store trial number of needed trials
    trials_needed = first_consc_idx:(first_uncon_idx-1); %if using all ratings we can store all trial numbers


    %create list of indices for train set and test set. These are
    %going to index the nTrials x nVoxels matrix we make, so will not idx the
    %full list of beta files, but only the trials_needed
    train_idxs = [];
    test_idxs = [];
    Y_train = [];
    Y_test =[];
    for trl = 1:length(trials_needed)
        trial = trials_needed(trl);
        trial = reverse(char(SPM.xX.name(trial)));

        if trial(12) == cfg.trainClass{1} || trial(12) == cfg.trainClass{2} %if trial in training set
            train_idxs = [train_idxs trl];
            %get labels (0 for low vis, 1 for high vis)
            if str2double(trial(7)) < med %if lower than median split
                Y_train = [Y_train 0]; %low vis label 
            elseif str2double(trial(7)) >= med %if equal or greater than median split
                Y_train = [Y_train 1]; %high vis label
            end
        elseif trial(12) == cfg.testClass{1} || trial(12) == cfg.testClass{2} %if trial in test set
            test_idxs = [test_idxs trl]; 
            %get labels (0 for low vis, 1 for high vis)
            if str2double(trial(7)) < med %if lower than median split
                Y_test = [Y_test 0]; %low vis label 
            elseif str2double(trial(7)) >= med %if equal or greater than median split
                Y_test = [Y_test 1]; %high vis label
            end
        end  

    end


    for trl = 1:length(train_idxs)
        trial = trials_needed(train_idxs(trl));
        if trial < 100 %i.e. if trial is 2 digits
            file_name = strcat('beta_00',string(trial),'.nii');
        else
            file_name = strcat('beta_0',string(trial),'.nii');
        end
        
        %disp(strcat(beta_path,file_name))
        beta_file = char(fullfile(beta_path,file_name));

        [~, beta] = read_nii(beta_file);
        train_Betas(trl,:) = beta(mask>0.5);
    end
    
    for trl = 1:length(test_idxs)
        trial = trials_needed(test_idxs(trl));
        if trial < 100 %i.e. if trial is 2 digits
            file_name = strcat('beta_00',string(trial),'.nii');
        else
            file_name = strcat('beta_0',string(trial),'.nii');
        end
        
        %disp(strcat(beta_path,file_name))
        beta_file = char(fullfile(beta_path,file_name));

        [~, beta] = read_nii(beta_file);
        test_Betas(trl,:) = beta(mask>0.5);
    end


    X_train = train_Betas; % dataset [nTrials x nVoxels]
    Y_train = Y_train'; % labels
    
    X_test = test_Betas; % dataset [nTrials x nVoxels]
    Y_test = Y_test'; % labels

    % downsample to get equal numbers per class
    %balance the number of trials of each condition in train samples
    train_idx = balance_trials(double(Y_train)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
    Y_train = Y_train(cell2mat(train_idx));
    X_train = X_train(cell2mat(train_idx),:,:);
    fprintf('Using %d trials per class in training set \n',sum(Y_train==1))
    
      % downsample to get equal numbers per class
    %balance the number of trials of each condition in test samples
    test_idx = balance_trials(double(Y_test)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
    Y_test = Y_test(cell2mat(test_idx));
    X_test = X_test(cell2mat(test_idx),:,:);
    fprintf('Using %d trials per class in test set \n',sum(Y_test==1))

    %% Loop over searchlights for decoding
  
    acc = nan(size(mask));
    for s = 1:length(mind)

            if mod(s,2000) == 0 
                fprintf('Decoding from searchlight %d out of %d \n',s,length(mind))
            end
            
            % select those voxels for training
            train_slX = X_train(:,mind{s}); %slX is a nTrials vs. nVoxels in Searchlight matrix
            train_slX(:,isnan(train_slX(1,:))) = []; %remove NaNs

            % select those voxels for testing
            test_slX = X_test(:,mind{s}); %slX is a nTrials vs. nVoxels in Searchlight matrix
            test_slX(:,isnan(test_slX(1,:))) = []; %remove NaNs
            
            % n-fold cross-validation
            train_folds = createFolds(cfg,Y_train); test_folds = createFolds(cfg,Y_test); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
            nTrialsTrain = size(train_slX,1); nTrialsTest = size(test_slX,1);
            Xhat = zeros(nTrialsTest,1);

            % do n Fold cross-validation 
            for f = 1:cfg.nFold
                trainidx = setdiff(1:nTrialsTrain,train_folds{f}); %return indices of trials not in fold - used for training
                testidx = test_folds{f}; %return indices of trials in fold - used for testing
                x{1} = train_slX(trainidx,:); x{2} = test_slX(testidx,:); %split training and testing data into two cells in one cell array
                y{1} = Y_train(trainidx); y{2} = Y_test(testidx); %split training and testing labels into two cells in one cell array

                %fprintf('Decoding fold %d out of %d \n',f,cfg.nFold)

                % train
                decoder = train_LDA(cfg,y{1}, x{1}');

                % test
                Xhat(testidx) = decode_LDA(cfg, decoder, x{2}');

            end

            yhat = Xhat > 0;
            % save accuracy per searchlight at the searchlight's center
            acc(sl_centers{s}) = mean(yhat == Y_test); 
            
           
    end

end