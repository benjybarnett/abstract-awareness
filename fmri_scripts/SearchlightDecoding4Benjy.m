cfg = [];
statmask = 'stat_mask.nii'; % GM + has signal in each sub
addpath('Utilities');
addpath 'D:\bbarnett\Documents\ecobrain\spm12';
addpath 'D:\bbarnett\Documents\ecobrain\fmri\fmri_analysis\'

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

for trl = 1:length(trials_needed)
    trial = reverse(char(SPM.xX.name(trl)));
    disp(trial)
    if trial(12) == '1' || trial(12) == '2'
        anim_idxs = [anim_idxs trl];
    elseif trial(12) == '3' || trial(12) == '4'
        inanim_idxs = [inanim_idxs trl];   
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
    disp(file_name)
    [~, beta] = read_nii(strcat(beta_path,file_name));
    Betas(file,:) = beta(mask>0.5);
end

anim_betas = Betas([anim_idxs{:}],:); %animate stim dataset
inanim_betas = Betas([inanim_idxs{:}],:); %inanimate stim dataset

X = betas;

Y = labels; % get the training labels (visibility) 

% downsample to get equal numbers per class


%% Loop over searchlights for decoding
acc = nan(size(mask));
for s = 1:length(mind)
        
        if mod(s,2000) == 0 
            fprintf('Decoding from searchlight %d out of %d \n',s,length(mind))
        end
        
        % select those voxels
        x = Betas{d}(:,mind{s});
        x(:,isnan(x{d}(1,:))) = [];
        
        % do n Fold cross-validation 
        for f = 1:nFold
            
            % train
            
            % test
            
        end
        
        % save accuracy per searchlight
        acc(vind{s}) = mean(yhat == Y); 
        
end

