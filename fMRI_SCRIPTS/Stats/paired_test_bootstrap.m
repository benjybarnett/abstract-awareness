function paired_test_bootstrap(cfg)
%% Create group null distributions 
    groupDir = fullfile(cfg.output_dir,'group\paired\');
    if ~exist(groupDir,'dir'); mkdir(groupDir); end
  

    % load grey matter mask and functional
    [hdr,mask]    = read_nii(cfg.mask);
    % loading permutations
    
    perms = [];
    for subj = 1:length(cfg.subjects)

        cross_outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},'cross');
        within_outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},'within');

        if exist(fullfile(cross_outputDir,'accuracyPerm.mat'),'file')

            fprintf('Loading subj %d \n',subj)
            cross_accuracy = load(fullfile(cross_outputDir,'accuracyPerm.mat'),'accuracy');
            cross_accuracy = struct2cell(cross_accuracy);
            cross_accuracy = cross_accuracy{1};
            within_accuracy = load(fullfile(within_outputDir,'accuracyPerm.mat'),'accuracy');
            within_accuracy = struct2cell(within_accuracy);
            within_accuracy = within_accuracy{1};

            for p = 1:cfg.nPerm

                cross_perm = cross_accuracy{cfg.order,p}(mask(:)>0);
                within_perm = within_accuracy{cfg.order,p}(mask(:)>0);          
                perms(subj,p,:) = cross_perm - within_perm; %calculate difference
            end        

            clear accuracy cross_perm within_perm

        else 
            fprintf('Sub %d not enough trials \n',subj)
        end
    end

    nanIdx = squeeze(perms(:,1,1))==0;
    perms(nanIdx,:,:) = []; 
    
    % creating bootstrapped null distribution 
    paired_btstrp = nan(cfg.nBtrsp,sum(mask(:)>0));
    nSubs = size(perms,1);
    disp(size(perms));
    for b = 1:cfg.nBtrsp

        if mod(b,100)==0; fprintf('\t Bootstrapping %d out of %d \n',b, cfg.nBtrsp); end

        acc_diff = []; 
        for s = 1:nSubs
            perm = randi(cfg.nPerm);
            acc_diff = cat(2,acc_diff,squeeze(perms(s,perm,:)));
            
        end
        paired_btstrp(b,:) = nanmean(acc_diff,2);
      
    end
    
    
    
    
    % compare to empirical distribution 
    [V,empirical_diffs] = read_nii(fullfile(groupDir,['mean_',cfg.empirical_map,'_diff.nii']));
   

    tmp = zeros(V.dim);
    pvals = sum(paired_btstrp > empirical_diffs(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'pValsPaired.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-pValsPaired.nii'));

    tmp = zeros(V.dim);
    pvals = sum(paired_btstrp < empirical_diffs(mask>0)')/cfg.nBtrsp;
    tmp(mask>0) = pvals;
    write_nii(V,tmp,fullfile(groupDir,'rpValsPaired.nii'));
    tmp(mask>0) = 1-pvals;
    write_nii(V,tmp,fullfile(groupDir,'1-rpValsPaired.nii'));

    
end