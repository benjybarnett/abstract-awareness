function  RSA(cfg0,subject)
    
%function to extract betas vectors needed to form neural RDM.
%Produces a beta vector of Nsensor length for each condition at each time
%point
    %load data from .mat file
        
    if cfg0.regressed ==  true
        data = load(strcat(cfg0.subj_path,subject,'/',subject,'_regressed.mat'));
        data = data.regressed_data;
    elseif cfg0.noBL == true
        disp('no baseline corrected data loading')
        load(strcat(cfg0.subj_path,subject,'/',subject,'_noBL_clean.mat'));
    else
        load(strcat(cfg0.subj_path,subject,'/',subject,'_clean.mat'));
    end

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
    mRDM = load(fullfile(cfg0.mRDM_path,[cfg0.mRDM_file,'.mat']));
    mRDM = mRDM.rdm;
    idxs = itril(8,-1); %indices of lower triangle without diagonal
    mRDM = mRDM(idxs);
    % Correlate neural RDM with model RDM
    rhos = [];
    for n = 1:size(nRDMs,3)
        nRDM = smoothnRDMs(:,:,n);
        nRDM = nRDM(idxs);
       % nRDM_flat = reshape(tril(nRDM),1,[])';
        %mRDM_flat = reshape(tril(mRDM),1,[])';

        rho = corr(nRDM,mRDM,'Type','Kendall');
        rhos = [rhos rho];
    end

    
    %save
    if cfg0.regressed == true
        outputDir = fullfile(cfg0.output_path,subject,'RSA',cfg0.mRDM_file,'regressed');
    elseif cfg0.noBL == true
        outputDir = fullfile(cfg0.output_path,subject,'RSA',cfg0.mRDM_file,'noBL');
    else
        outputDir = fullfile(cfg0.output_path,subject,'RSA',cfg0.mRDM_file);

    end
    if ~exist(outputDir,'dir'); mkdir(outputDir); end 
    save(fullfile(outputDir,'rhos_no_diag.mat'), 'rhos')
    
end
