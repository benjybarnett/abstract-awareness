function CrossDecodingSearchlightPermutation(cfg)
% function CrossDecodingSearchlight(cfg)

% set random generator for repeatability
rng(1,'twister')

%% Get the searchlight indices
slradius = cfg.radius;

% load grey matter mask and functional
[hdr,mask]    = read_nii(cfg.statmask);

% infer the searchlight  indices
[vind,mind,sl_centers] = searchlightIndices(mask>0,slradius);
nSearchlights = length(mind);

for sub = 1:length(cfg.subjects)
    
    %% Get the data
    % load SPM file
    load(fullfile(cfg.root,cfg.subjects{sub},cfg.dir,'SPM.mat'),'SPM');
    
    % get imagery and perception betas
    conIdx = find(contains(SPM.xX.name,'Sn(1) conscious'));
    imaIdx = find(contains(SPM.xX.name,'Sn(1) imagery'));
    
    % get visibility data
    load(fullfile(cfg.root,cfg.subjects{sub},'ROIdata','ROIdata.mat'),...
        'visibilityCP','visibilityIM');
    
    Betas = cell(2,1); Y_labels = cell(2,1);
    for d = 1:2
        
        % load data
        if d == 1; tidx = conIdx; else; tidx = imaIdx; end
        visibility = nan(length(tidx),1);
        for t = 1:length(tidx)
            
            if mod(t,50)==0
                fprintf('\t Reading in beta %d out of %d \n',t,length(tidx))
            end
            
            name   = SPM.xX.name{conIdx(t)};
            visibility(t) = str2double(name(end-6)); % visibility
            
            [~,beta] = read_nii(fullfile(cfg.root,cfg.subjects{sub},cfg.dir,...
                sprintf('beta_%04d.nii',conIdx(t))));
            Betas{d}(t,:) = beta(mask>0);
        end
        
        if d == 1; visibility = visibilityCP; else; visibility = visibilityIM; end
        
        % downsample
        labels = double(eval(cfg.labels{1}))+1;
        idx    = balance_trials(labels,'downsample');
        fprintf('Modality %d: %d trials per class \n',d,length(idx{1}));
        
        Y_labels{d} = labels(cell2mat(idx(:)));
        Betas{d} = Betas{d}(cell2mat(idx(:)),:);
    end
    
    
    %% Do decoding per searchlight
    if length(Y_labels{1}) > 10 && length(Y_labels{2}) > 10 % only if there are enough trials
    % decoding settings
    cfgD.gamma = cfg.gamma;
    accuracy   = cell(2,cfg.nPerm);         
    
    for per = 1:cfg.nPerm
        fprintf('\t Permutation %d out of %d \n',per,cfg.nPerm)
        
        Y_labelsP = Y_labels{1}(randperm(length(Y_labels{1})));
        Y_labelsI = Y_labels{2}(randperm(length(Y_labels{2})));
        
        accuracy{1,per} = zeros(hdr.dim); accuracy{2,per} = zeros(hdr.dim);
        
        % run over searchlights
        for s = 1:length(mind)
            
            if s >= (nSearchlights/10) && mod(s,(nSearchlights/10)) == 0
                fprintf('Progress: %d percent of searchlights \n',round((s/nSearchlights)*100))
            end
            
            % mask the betas
            x = cell(2,1);
            for d = 1:2
                x{d} = Betas{d}(:,mind{s});
                x{d}(:,isnan(x{d}(1,:))) = [];
            end
            
            % decoding
            % train perc test ima
            decoder = train_LDA(cfgD,Y_labelsP==1,x{1}');
            Yhat    = decode_LDA(cfgD,decoder,x{2}');
            accuracy{1,per}(vind{s}) = mean((Yhat > 0)==(Y_labels{2}'==1));
            
            % train ima test perc
            decoder = train_LDA(cfgD,Y_labelsI==1,x{2}');
            Yhat    = decode_LDA(cfgD,decoder,x{1}');
            accuracy{2,per}(vind{s}) = mean((Yhat>0)==(Y_labels{1}'==1));
            clear x
        end
    end    
    
    % save
    outputDir = fullfile(cfg.root,cfg.subjects{sub},cfg.outputDir);
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    save(fullfile(outputDir,'accuracyPerm.mat'),'accuracy')
    
    clear accuracy
    end
end

%% Create group null distributions 
groupDir = fullfile(cfg.root,'GroupResuts',cfg.outputDir);
if ~exist(groupDir,'dir'); mkdir(groupDir); end

% loading permutations
accPI_perm = []; 
accIP_perm = []; 
for sub = 1:length(cfg.subjects)
    
    outputDir = fullfile(cfg.root,cfg.subjects{sub},cfg.outputDir);
    
    if exist(fullfile(outputDir,'accuracyPerm.mat'),'file')
        
        fprintf('Loading sub %d \n',sub)
        load(fullfile(outputDir,'accuracyPerm.mat'),'accuracy')
                
        for p = 1:cfg.nPerm
            
            accPI_perm(sub,p,:) = accuracy{1,p}(mask(:)>0);
            accIP_perm(sub,p,:) = accuracy{2,p}(mask(:)>0);          
            
        end        
        
        clear accuracy
        
    else 
        fprintf('Sub %d not enough trials \n',sub)
    end
end
nanIdx = squeeze(accPI_perm(:,1,1))==0;
accIP_perm(nanIdx,:,:) = []; accPI_perm(nanIdx,:,:) = [];

% creating bootstrapped null distribution 
accPI_btstrp = nan(cfg.nBtrsp,sum(mask(:)>0));
accIP_btstrp = nan(cfg.nBtrsp,sum(mask(:)>0));
nSubs = size(accIP_perm,1);
for b = 1:cfg.nBtrsp
    
    if mod(b,100)==0; fprintf('\t Bootstrapping %d out of %d \n',b, cfg.nBtrsp); end

    accPI = []; accIP = [];
    for s = 1:nSubs
        perm = randi(cfg.nPerm);
        accPI = cat(2,accPI,squeeze(accPI_perm(s,perm,:)));
        accIP = cat(2,accIP,squeeze(accIP_perm(s,perm,:)));
    end
    accPI_btstrp(b,:) = nanmean(accPI,2);
    accIP_btstrp(b,:) = nanmean(accIP,2);
end
    
% compare to empirical distribution 
[~,acc] = read_nii(fullfile(groupDir,'accuracy.nii'));
[~,PI] = read_nii(fullfile(groupDir,'accuracyPI.nii'));
[V,IP] = read_nii(fullfile(groupDir,'accuracyIP.nii'));

tmp = zeros(V.dim);
pvals = sum(accPI_btstrp > PI(mask>0)')/cfg.nBtrsp;
tmp(mask>0) = pvals;
write_nii(V,tmp,fullfile(groupDir,'pValsPI.nii'));
tmp(mask>0) = 1-pvals;
write_nii(V,tmp,fullfile(groupDir,'1-pValsPI.nii'));

tmp = zeros(V.dim);
pvals = sum(accPI_btstrp < PI(mask>0)')/cfg.nBtrsp;
tmp(mask>0) = pvals;
write_nii(V,tmp,fullfile(groupDir,'rpValsPI.nii'));
tmp(mask>0) = 1-pvals;
write_nii(V,tmp,fullfile(groupDir,'1-rpValsPI.nii'));

tmp = zeros(V.dim);
pvals = sum(accIP_btstrp > IP(mask>0)')/cfg.nBtrsp;
tmp(mask>0) = pvals;
write_nii(V,tmp,fullfile(groupDir,'pValsIP.nii'));
tmp(mask>0) = 1-pvals;
write_nii(V,tmp,fullfile(groupDir,'1-pValsIP.nii'));

tmp = zeros(V.dim);
pvals = sum(accIP_btstrp < IP(mask>0)')/cfg.nBtrsp;
tmp(mask>0) = pvals;
write_nii(V,tmp,fullfile(groupDir,'rpValsIP.nii'));
tmp(mask>0) = 1-pvals;
write_nii(V,tmp,fullfile(groupDir,'1-rpValsIP.nii'));

tmp = zeros(V.dim);
pvals = sum(((accPI_btstrp+accIP_btstrp)./2) > acc(mask>0)')/cfg.nBtrsp;
tmp(mask>0) = pvals;
write_nii(V,tmp,fullfile(groupDir,'pVals.nii'));
tmp(mask>0) = 1-pvals;
write_nii(V,tmp,fullfile(groupDir,'1-pVals.nii'));

tmp = zeros(V.dim);
pvals = sum(((accPI_btstrp+accIP_btstrp)./2) < acc(mask>0)')/cfg.nBtrsp;
tmp(mask>0) = pvals;
write_nii(V,tmp,fullfile(groupDir,'rpVals.nii'));
tmp(mask>0) = 1-pvals;
write_nii(V,tmp,fullfile(groupDir,'1-rpVals.nii'));


