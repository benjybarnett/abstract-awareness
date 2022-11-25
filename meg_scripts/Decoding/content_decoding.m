load('../data/time_axis')
acc = zeros(17,675);
for subj = 1:length(subjects)
   subject = subjects{subj};

    disp(subject)
    file = strcat('../data/',subject,'/',subject,'_clean.mat');
    load(file)
    
    cfg = [];
    cfg.channel = 'MEG';
    cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) & (data.trialinfo(:,6) == 3 | data.trialinfo(:,6) ==4);
    data = ft_selectdata(cfg,data);
    
    
    cfg = [] ;  
    cfg.method           = 'mvpa';
    cfg.features         = 'chan';
    cfg.mvpa.classifier  = 'lda';
    cfg.mvpa.metric      = 'accuracy';
    cfg.mvpa.k           = 5;
    cfg.mvpa.repeat      = 1;
    cfg.design           = data.trialinfo(:,1);
    cfg.mvpa.preprocess = {'undersample'};
    
    
    stat = ft_timelockstatistics(cfg, data);
    
    acc(subj,:) = stat.accuracy;
end
