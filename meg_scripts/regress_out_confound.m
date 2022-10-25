function  regress_out_confound(cfg0,subject)

    %load data from .mat file
    load(strcat(cfg0.subj_path,subject,'/',subject,'_clean.mat'));

    cfg = [];
    cfg.keeptrials = 'yes';
    cfg.channel = 'MEG';
    tl_data = ft_timelockanalysis(cfg, data);
    
    cfg = [];
    confound_idx = cfg0.confound_idx; %index of confound column in trial data
    cfg.confound = data.trialinfo(:,confound_idx);
    cfg.normalize = 'false';
    cfg.output = 'residual';
    regressed_data = ft_regressconfound(cfg,tl_data);
    
    %save
    save(fullfile(cfg0.output_path,subject,[subject,'_regressed.mat']), 'regressed_data')
    
end
