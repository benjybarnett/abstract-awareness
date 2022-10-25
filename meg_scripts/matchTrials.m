function matchTrials(subject)

    %load non baseline corrected data
    bl_data = load(strcat('../data/',subject,'/',subject,'_noBL.mat'));
    bl_data = bl_data.data;

    %load fully preprocessed original data
    load(strcat('../data/',subject,'/',subject,'_clean.mat'));

    bl_trials = bl_data.trialinfo;
    pp_trials = data.trialinfo;

    %find indices of rows in non-rejected data that exist in pp data
    rowIdx = {};
    for row = 1:length(pp_trials)
        rowIdx{row} = find(ismember(bl_trials, pp_trials(row,:),'rows'));

    end
    rowIdx = vertcat(rowIdx{:});
    
    %reject same trials
    cfg =[];
    cfg.trials = rowIdx;
    data = ft_selectdata(cfg,bl_data);
    
    %save
    save(strcat('../data/',subject,'/',subject,'_noBL_VAR.mat'),'data','-v7.3'); clear data bl_data

    
end