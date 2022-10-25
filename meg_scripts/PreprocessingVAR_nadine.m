function PreprocessingVAR(cfg0,subjectdata)
% function PreprocessingVAR(cfg0,subjectdata)
% Visual artefact rejection as part of the preprocessing progress. 

% some settings
outputDir               = fullfile(cfg0.root,subjectdata.outputDir,'VARData');
if ~exist(outputDir,'dir'); mkdir(outputDir); end
PreprocData             = fullfile(cfg0.root,subjectdata.outputDir,'PreprocData');

%% Loop over data segments
dataSegs                = cfg0.dataName;
nSeg                    = numel(dataSegs);

for s = 1:nSeg
    
    [~,name,~] = fileparts(cfg0.dataName{s});
    artSave    = ['art' name(5:end)];   
    
    % load the data
    load(fullfile(PreprocData,cfg0.dataName{s}),'data')
    
    % get some basic values
    time                    = data.time{1};
    nTrials                 = length(data.trial);
    
    % select only the MEG channels
    cfg                     = [];
    chIdx = zeros(1,length(data.label));
    for c = 1:length(chIdx) 
        chIdx(c) = length(data.label{c}) == 5 & strcmp(data.label{c}(1),'M');
    end
    cfg.channel             = data.label(chIdx==1);
    tmp_data                = ft_selectdata(cfg,data);
    tmp_data.trialinfo      = [tmp_data.trialinfo, (1:nTrials)'];
    
    % Overall artifacts
    cfg                     = [];
    cfg.method              = 'summary';
    tmp_data_overall        = ft_rejectvisual(cfg, tmp_data); % save them
    removed_n_overall       = setdiff(1:nTrials, tmp_data_overall.trialinfo(:, end));
    clear tmp_data_overall;
    
    % Muscle artifacts
    iNan = cell(nTrials);
    for in = 1:length(tmp_data.trial)
        iNan{in} = isnan(tmp_data.trial{in});
        tmp_data.trial{in}(iNan{in}) = 0;
    end
    
    cfg                     = [];
    cfg.hpfilter            = 'yes';
    cfg.hpfreq              = 100;
    tmp_data_filtered       = ft_preprocessing(cfg, tmp_data);
    
    for in = 1:length(tmp_data.trial)
        tmp_data_filtered.trial{in}(iNan{in}) = nan;
    end
    
    tmp_data_muscle         = ft_rejectvisual([], tmp_data_filtered);
    removed_n_muscle        = setdiff(1:nTrials, tmp_data_muscle.trialinfo(:, end));
    clear tmp_data_muscle tmp_data_filtered;
    
    % Blinks during stimulus
    cfg                     = [];
    cfg.channel             = {subjectdata.eyeTrackerX,subjectdata.eyeTrackerZ};
    tmp_data                = ft_selectdata(cfg, data);
    tmp_data.trialinfo      = [tmp_data.trialinfo, (1:nTrials)'];
    
    X = reshape(cell2mat(tmp_data.trial), [2, length(tmp_data.time{1}), length(tmp_data.trial)]);
    X_EOGv = squeeze(X(1, :, :))';
    X_EOGv = (X_EOGv - mean(X_EOGv(:))) ./ std(X_EOGv(:));
    X_pupDil = squeeze(X(2, :, :))';
    X_pupDil = (X_pupDil - mean(X_pupDil(:))) ./ std(X_pupDil(:));
    
    cutoff_z_EOGv = mean(X_EOGv(:))+(2*std(X_EOGv(:)));
    cutoff_z_pupDil = mean(X_pupDil(:))+(2*std(X_pupDil(:)));
    
    blinkMask               = (abs(X_EOGv) > cutoff_z_EOGv) | (abs(X_pupDil) > cutoff_z_pupDil);
    tmp                     = time >= cfg0.stimOn(s,1) & time <= cfg0.stimOn(s,2);
    stimOnMask              = repmat(tmp,[nTrials,1]);
    removed_n_blinks        = tmp_data.trialinfo(any(stimOnMask & blinkMask, 2), end);
    
    clear tmp_data blinkMask stimOnMask
    
    % Inspect potentially contaminated trials
    cfg                     = [];
    cfg.channel             = cat(1,data.label(chIdx==1),{'EEG057', 'EEG058'}');
    cfg.megscale = 1;
    cfg.artfctdef.overall.artifact = data.sampleinfo(removed_n_overall, :);
    cfg.artfctdef.muscle.artifact = data.sampleinfo(removed_n_muscle, :);
    cfg.artfctdef.blinks.artifact = data.sampleinfo(removed_n_blinks, :);    
    cfg.preproc.hpfilter    = 'no';
    cfg.preproc.hpfreq      = 100;
    cfg.renderer            = 'painters';
    cfgart                  = ft_databrowser(cfg, data);
    
    clear removed_n_overall removed_n_muscle removed_n_blinks    
    
    % Save the artifacts
    save(fullfile(outputDir,artSave),'cfgart')
    
    % Reject the artifacts
    cfgart.artfctdef.reject = 'complete';
    data                    = ft_rejectartifact(cfgart, data);
    
    % Save the data and clean up
    save(fullfile(outputDir,name),'data','-v7.3')
    clear data cfgart
    
end

