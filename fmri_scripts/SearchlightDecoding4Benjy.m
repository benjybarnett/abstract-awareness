tic
cfg = [];
cfg.nFold=5;
cfg.gamma =0.2;
statmask = 'stat_mask.nii'; % GM + has signal in each sub


data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
subject='S02';
beta_path = strcat(data_dir,subject,'\');

% set random generator for repeatability
rng(1,'twister')

%% Get the searchlight indices
slradius = 4; % radius for the searchlight in voxels 

% load grey matter mask and functional
[hdr,mask]    = read_nii(statmask);

% infer the searchlight  indices
[vind,mind] = searchlightIndices(mask>0,slradius);

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


%create list of indices of two classes: animate and inanimate. These are
%going to index the nTrials x nVoxels matrix we make, so will not idx the
%full list of beta files, but only the trials_needed
anim_idxs = {};
inanim_idxs = {};
Y = [];
for trl = 1:length(trials_needed)
    trial = trials_needed(trl);
    trial = reverse(char(SPM.xX.name(trial)));
  
    if trial(12) == '1' || trial(12) == '2'
        anim_idxs = [anim_idxs trl];
        
    elseif trial(12) == '3' || trial(12) == '4'
        inanim_idxs = [inanim_idxs trl];   
        
    end  
   

    %get labels (0 for low vis, 1 for high vis)
    if str2double(trial(7)) < med %if lower than median split
        Y = [Y 0]; %low vis label 
    elseif str2double(trial(7)) >= med %if equal or greater than median split
        Y = [Y 1]; %high vis label
    end
end
        

beta_files = {};
for trl = 1:length(trials_needed)
    trial = trials_needed(trl);
    file_name = strcat('beta_0',string(trial),'.nii');
    beta_files = [beta_files file_name];
end


for file = 1:length(beta_files)
    file_name = beta_files{file};
    %disp(file_name)
    [~, beta] = read_nii(strcat(beta_path,file_name));
    Betas(file,:) = beta(mask>0.5);
    
end

X_anim = Betas([anim_idxs{:}],:); %animate stim dataset
X_inanim = Betas([inanim_idxs{:}],:); %inanimate stim dataset

Y_anim = Y([anim_idxs{:}])'; %animate labels
Y_inanim = Y([inanim_idxs{:}])'; %inanimate labels


% downsample to get equal numbers per class
%balance the number of trials of each condition in train and test samples
idx_anim = balance_trials(double(Y_anim)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
idx_inanim = balance_trials(double(Y_inanim)+1,'downsample');

Y_anim = Y_anim(cell2mat(idx_anim));
Y_inanim = Y_inanim(cell2mat(idx_inanim));

X_anim = X_anim(cell2mat(idx_anim),:,:);
X_inanim = X_inanim(cell2mat(idx_inanim),:,:);

%% Loop over searchlights for decoding
fprintf('Using %d trials per class \n',sum(Y_inanim==1))
acc = nan(size(mask));
for s = 1:length(mind)
        
        if mod(s,2000) == 0 
            fprintf('Decoding from searchlight %d out of %d \n',s,length(mind))
        end
        
        % select those voxels
        X = X_inanim(:,mind{s}); %X is a nTrials vs. nVoxels in Searchlight matrix
        X(:,isnan(X(1,:))) = []; %remove NaNs
        

        
        num_trials = sum(Y_inanim==1);
        
        % n-fold cross-validation
        folds = createFolds(cfg,Y_inanim); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
        nTrials = size(X_inanim,1);
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
        % save accuracy per searchlight
        acc(vind{s}) = mean(yhat == Y_inanim); 
        
end

toc