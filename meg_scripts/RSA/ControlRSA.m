function  ControlRSA(cfg0,subject)

    %load data from .mat file
    load(strcat(cfg0.subj_path,subject,'/',subject,'_clean.mat'));

    cfg = [];
    cfg.keeptrials = 'yes';
    cfg.channel = cfg0.channels;
    tl_data = ft_timelockanalysis(cfg, data);
    
    %create design matrix of dummy coded predictors
    trial_info = tl_data.trialinfo;
    des_mat = zeros(length(trial_info),cfg0.num_predictors);
    for trl = 1:length(trial_info)
        %disp(trial_info(trl,6))
        if trial_info(trl,1) == 6
            des_mat(trl,0+trial_info(trl,6)) = 1;
        elseif trial_info(trl,1) == 7
            des_mat(trl,4+trial_info(trl,6)) = 1;
        end
    end
    
    %get betas
    cfg = [];
    cfg.confound = des_mat;
    cfg.normalize = 'false';
    cfg.output = 'beta';
    betas = ft_regressconfound(cfg,tl_data);
    betas = betas.beta;
    
    
    %create neural RDM for each time point
    nRDMs = {};
    for time = 1:size(betas,3)
        corrs = pdist(betas(:,:,time),'correlation');
        rdm = squareform(corrs);
        nRDMs(time) = {rdm};
    end
    
    
    %smooth nRDM
    nRDMs = cell2mat(permute(nRDMs,[1,3,2]));
    smoothnRDMs =zeros(size(nRDMs));
    window_sz = 60/4; %(window in ms/downsampling rate)
    smooth_filter = unifpdf(1:window_sz,1,window_sz);
    for i = 1:size(nRDMs,1)
        for j = 1:size(nRDMs,2)
            smoothnRDMs(i,j,:) = conv(squeeze(nRDMs(i,j,:)),smooth_filter,'same');
        end
    end
    
    
    % model RDM
    mRDM = load(fullfile(cfg0.mRDM_path,'no_graded_rdm.mat'));
    mRDM = mRDM.rdm;
    mRDM = tril(mRDM);
    idxs = itril(8,-1); %indices of lower triangle without diagonal
    mRDM_flat = mRDM(idxs);

    shuf_rhos = zeros(cfg0.nPerms,size(nRDMs,3));
    shufGrad_rhos = zeros(cfg0.nPerms,size(nRDMs,3));

    
    %loop over perms
    for p = 1:cfg0.nPerms
    
        if mod(p,100) == 0
        fprintf('\t Permutation %d out of %d \r',p,cfg0.nPerms);
        end

        [shuffledRDM, shuffGradedRDM] = shuffleRDM(mRDM_flat,idxs);
        
        % Correlate neural RDM with model RDMs
        
        for n = 1:size(nRDMs,3)
            nRDM = smoothnRDMs(:,:,n);
            nRDM = nRDM(idxs);
            
            rho = corr(nRDM,shuffledRDM,'Type','Kendall');
            shuf_rhos(p,n) =  rho;
    
            rho = corr(nRDM,shuffGradedRDM,'Type','Kendall');
            shufGrad_rhos(p,n) = rho;
    
        end
    
        
      
    end
    

    % Average over permutations
    avg_shuf_rhos = mean(shuf_rhos,1);
    avg_shufGrad_rhos = mean(shufGrad_rhos,1);

    %Save  average to subject directory
    outputDir = fullfile(cfg0.output_path,subject,'RSA','Control');
    if ~exist(outputDir,'dir'); mkdir(outputDir); end 
    save(fullfile(outputDir,'avg_shuf_rhos.mat'), 'avg_shuf_rhos')
    save(fullfile(outputDir,'avg_shufGrad_rhos.mat'), 'avg_shufGrad_rhos')

   
    
end
