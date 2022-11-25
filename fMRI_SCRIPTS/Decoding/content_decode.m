function [hdr, acc] = content_decode(cfg,subject)
    
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


    X = Betas; % dataset [nTrials x nVoxels]
    Y = Y'; % labels

    % downsample to get equal numbers per class
    %balance the number of trials of each condition in train and test samples
    idx = balance_trials(double(Y)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
    Y = Y(cell2mat(idx));
    X = X(cell2mat(idx),:,:);
    fprintf('Using %d trials per class \n',sum(Y==1))

    %% Loop over searchlights for decoding
  
    acc = nan(size(mask));
    for s = 1:length(mind)

            if mod(s,2000) == 0 
                fprintf('Decoding from searchlight %d out of %d \n',s,length(mind))
            end
            
            % select those voxels
            slX = X(:,mind{s}); %slX is a nTrials vs. nVoxels in Searchlight matrix
            slX(:,isnan(slX(1,:))) = []; %remove NaNs

            % n-fold cross-validation
            folds = createFolds(cfg,Y); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
            nTrials = size(slX,1);
            Xhat = zeros(nTrials,1);

            % do n Fold cross-validation 
            for f = 1:cfg.nFold
                trainidx = setdiff(1:nTrials,folds{f}); %return indices of trials not in fold - used for training
                testidx = folds{f}; %return indices of trials in fold - used for testing
                x{1} = slX(trainidx,:); x{2} = slX(testidx,:); %split training and testing data into two cells in one cell array
                y{1} = Y(trainidx); y{2} = Y(testidx); %split training and testing labels into two cells in one cell array

                %fprintf('Decoding fold %d out of %d \n',f,cfg.nFold)

                % train
                decoder = train_LDA(cfg,y{1}, x{1}');

                % test
                Xhat(testidx) = decode_LDA(cfg, decoder, x{2}');

            end

            yhat = Xhat > 0;
            % save accuracy per searchlight at the searchlight's center
            acc(sl_centers{s}) = mean(yhat == Y); 
            
           
    end

end