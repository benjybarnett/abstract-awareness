function PreprocessingICA(cfg0,subjectdata)
% function PreprocessingICA(subjectdata)

% instead of running ICA for the three segments seperately, this version
% appends the data prior to the ICA in order to improve the estimation of
% the components. After the components are removed, the data is seperated
% again

% some settings
outputComp          = fullfile(cfg0.root,subjectdata.outputDir,'ICAData');
outputData          = fullfile(cfg0.root,subjectdata.outputDir,'CleanData');
if ~exist(outputComp,'dir'); mkdir(outputComp); end
if ~exist(outputData,'dir'); mkdir(outputData); end
VARData             = fullfile(cfg0.root,subjectdata.outputDir,'VARData');

%% Get the three data-segments

% load the VA removed data
nSegs = length(cfg0.segs);
segs  = cell(nSegs,1);
for s = 1:nSegs
    load(fullfile(VARData,['data' cfg0.segs{s}]),'data');
    segs{s} = data; clear data;
    segs{s}.trialinfo(:,3) = s;
end

% append the data from the three segments
cfg                 = [];
cfg.keepsampleinfo  = 'no';
appData             = ft_appenddata(cfg,segs{:});

chIdx = zeros(1,length(appData.label));
for c = 1:length(chIdx)
    chIdx(c) = length(appData.label{c}) == 5 & strcmp(appData.label{c}(1),'M');
end

% check if ICA already done
if ~exist(fullfile(outputComp,'comp.mat'),'file')
    
    % perform the independent component analysis (i.e., decompose the data)
    cfg                 = [];
    cfg.channel         = appData.label(chIdx==1);
    cfg.method          = 'runica';
    cfg.demean          = 'no';
    comp                = ft_componentanalysis(cfg,appData);
    
    % save the components
    save(fullfile(outputComp,'comp'),'comp','-v7.3')
    
else 
    load(fullfile(outputComp,'comp.mat'))
end

if ~exist(fullfile(outputData,['data' cfg0.segs{1} '.mat']),'file') % identify EOG and ECG components    
    
    % correlate to EEG
    ET = cell2mat(appData.trial);
    ET = ET(ismember(appData.label, {subjectdata.eyeTrackerX,subjectdata.eyeTrackerY,subjectdata.HeartRate}), :);
    
    r = corr(cell2mat(comp.trial)', ET');
    [ro, i] = sort(abs(r),'descend');
    
    %fprintf('Highest correlations: \n \t X: comp %d [%.4f] \n \t Y: comp %d [%.4f] \n \t HR: comp %d [%.4f] \n',i(1,1),r(i(1,1),1),i(1,2),r(i(1,2),2),i(1,3),r(i(1,3),3))
    
    if ~isempty(find(ro(1,:)<0.3,1)) % if some are below 0.3
        % manually check the components
        warning('low correlations, manually check components!')
        %return
    end
    
    % inspect these components
    figure;
    cfg                = [];
    cfg.component      = i(1,:);
    cfg.layout         = 'CTF275.lay';
    cfg.commment       = 'no';
    ft_topoplotIC(cfg,comp)
    
    % plot the time course
    tmp_comp = cell2mat(comp.trial);
    figure;
    nComps = length(cfg.component);
    for c = 1:nComps
        subplot(nComps,1,c);
        plot(tmp_comp(cfg.component(1,c),1:2000))
        title(sprintf('Component %d \n',cfg.component(1,c)))
    end
    
    % decide which components to remove and save decision
    comp_removed        = cfg.component;
    save(fullfile(outputComp,'comp'),'comp_removed','-append')
    
    % remove them from the data
    cfg                 = [];
    cfg.component       = comp_removed;
    cfg.demean          = 'no';
    appData             = ft_rejectcomponent(cfg, comp, appData);
    
    % seperate the segments again
    cfg                 = [];
    cfg.channels        = appData.label(chIdx==1);
    
    % save the CLEAN data    
    for s = 1:nSegs
       cfg.trials = appData.trialinfo(:,3) == s;
       data       = ft_selectdata(cfg,appData);
       save(fullfile(outputData,['data' cfg0.segs{s} '.mat']),'data','-v7.3'); clear data
    end
    
    clear comp comp_removed
else
    fprintf('\n Components already removed for segment %d, clean data saved \n',s)
end
clear data


