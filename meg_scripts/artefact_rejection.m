function artefact_rejection(cfg0, subject)

   
    %load data from .mat file
    load(strcat('../data/',subject,'/',subject,'.mat'));
    
    
    %get basic values
    time = data.time{1};
    nTrials = length(data.trial);
    
    %select only the MEG GRAD channels
    cfg = [];
    cfg.channel = {'MEGGRAD'
                    '-MEG0522'%7hz artifacts
                    '-MEG0533'%7hz artifacts
                    '-MEG0912'%7hz artifacts
                    '-MEG0913'%7hz artifacts
                    '-MEG0943'}; %7hz artifacts;
    temp_grad_data = ft_selectdata(cfg,data);
    temp_grad_data.trialinfo = [temp_grad_data.trialinfo, (1:nTrials)'];
    
    %overall artifacts 
    cfg = [];
    cfg.method = 'summary';
    temp_grad_data_overall = ft_rejectvisual(cfg, temp_grad_data); %save them
    removed_n_overall_grad = setdiff(1:nTrials, temp_grad_data_overall.trialinfo(:,end)); %return removed trials' indexes
   
    clear temp_grad_data_overall
    
    %select only the MEG MAG channels
    cfg = [];
    cfg.channel = {'MEGMAG'
                    '-MEG0522'%7hz artifacts
                    '-MEG0533'%7hz artifacts
                    '-MEG0912'%7hz artifacts
                    '-MEG0913'%7hz artifacts
                    '-MEG0943'}; %7hz artifacts;
    temp_mag_data = ft_selectdata(cfg,data);
    temp_mag_data.trialinfo = [temp_mag_data.trialinfo, (1:nTrials)'];
    
    %overall artifacts 
    cfg = [];
    cfg.method = 'summary';
    temp_mag_data_overall = ft_rejectvisual(cfg, temp_mag_data); %save them
    removed_n_overall_mag = setdiff(1:nTrials, temp_mag_data_overall.trialinfo(:,end)); %return removed trials' indexes
    clear temp_mag_data_overall
    
    
    %blinks during stimulus
    cfg = [];
    cfg.channel = 'EOG';
    tmp_eog_data = ft_selectdata(cfg,data);
    tmp_eog_data.trialinfo = [tmp_eog_data.trialinfo, (1:nTrials)'];
    
    %reshape into matrix with dimensions: [2 x nSamples x nTrials]
    X = reshape(cell2mat(tmp_eog_data.trial), [2, length(tmp_eog_data.time{1}), length(tmp_eog_data.trial)]);
    X_EOG1 = squeeze(X(1,:,:))';  %[nTrials x nSamples] - for first EOG channel
    X_EOG1 = (X_EOG1 - mean(X_EOG1(:))) ./ std(X_EOG1(:)); %z-score standardisation
    X_EOG2 = squeeze(X(2,:,:))'; %get second channel recordings
    X_EOG2 = (X_EOG2 - mean(X_EOG2(:))) ./ std(X_EOG2(:));
    
    %cut off is 2SD above the mean
    cutoff_z_EOG1 = mean(X_EOG1(:))+(2*std(X_EOG1(:))); 
    cutoff_z_EOG2 = mean(X_EOG2(:))+(2*std(X_EOG2(:)));
    
    %find indexes where signal exceeds cut off, store in [nTrials x nSamples] matrix
    blink_mask = (abs(X_EOG1) > cutoff_z_EOG1) | (abs(X_EOG2) > cutoff_z_EOG2);
    tmp                     = time >= cfg0.stimOn(1) & time <= cfg0.stimOn(2); %return nSample length array with boolean True at sample when stim was shown
    stim_on_mask            = repmat(tmp,[nTrials,1]); %create nTrials rows of above array
    removed_n_blinks        = tmp_eog_data.trialinfo(any(stim_on_mask & blink_mask, 2), end); %see if any of the samples have boolean True on blink mask and during stimulus and save trial 
    
    clear tmp_eog_data blink_mask stim_on_mask
    
    % Inspect blink trials in EOG channels
    cfg                     = [];
    cfg.channel             = 'EOG';
    cfg.artfctdef.blinks.artifact = data.sampleinfo(removed_n_blinks, :);    
    cfg.renderer            = 'painters';
    cfgart_eog            = ft_databrowser(cfg, data);
    
    
    
    % Inspect potentially contaminated trials in GRAD channels
    cfg                     = [];
    cfg.channel             = {'MEGGRAD'
                                '-MEG0522'%7hz artifacts
                                 '-MEG0533'%7hz artifacts
                                 '-MEG0912'%7hz artifacts
                                 '-MEG0913'%7hz artifacts
                                '-MEG0943'}; %7hz artifacts;
    cfg.artfctdef.grad.artifact = data.sampleinfo(removed_n_overall_grad, :);    
    cfg.renderer            = 'painters';
    cfg.viewmode            ='butterfly';
    cfgart_grad             = ft_databrowser(cfg, data);
    
    % Inspect potentially contaminated trials in MAG channels
    cfg                     = [];
    cfg.channel             = {'MEGMAG'
                                '-MEG0522'%7hz artifacts
                                '-MEG0533'%7hz artifacts
                                '-MEG0912'%7hz artifacts
                                '-MEG0913'%7hz artifacts
                                '-MEG0943'}; %7hz artifacts;
    cfg.artfctdef.mag.artifact = data.sampleinfo(removed_n_overall_mag, :); 
    cfg.renderer            = 'painters';
    cfg.viewmode            ='butterfly';
    cfgart_mag            = ft_databrowser(cfg, data);
    
    clear removed_n_overall_mag removed_n_overall_grad removed_n_blinks    
    
    % Save the artifacts
    
    save(strcat('..\data\',subject,'\',subject,'_cfgart_grad'),'cfgart_grad')
    save(strcat('..\data\',subject,'\',subject,'_cfgart_mag'),'cfgart_mag')
    save(strcat('..\data\',subject,'\',subject,'_cfgart_eog'),'cfgart_eog')

    
    % Reject the artifacts
    cfgart_grad.artfctdef.reject = 'complete';
    cfgart_mag.artfctdef.reject = 'complete';
    %cfgart_eog.artfctdef.reject = 'complete';
    grad_data               = ft_rejectartifact(cfgart_grad, data);
    mag_data                    = ft_rejectartifact(cfgart_mag, grad_data);
    data = ft_rejectartifact(cfgart_eog,mag_data);
    
    disp(size(data.trialinfo))
    
    % Save the data and clean up
    save(strcat('..\data\',subject,'\',subject,'_VAR'),'data','-v7.3')
    
    
    clear grad_data mag_data;


end