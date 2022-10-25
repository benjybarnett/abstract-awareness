addpath('/Users/bbarnett/Documents/ecobrain/MVPA-Light\startup')
rmpath('/Users/bbarnett/Documents/ecobrain/MVPA-light-searchlight\MVPA-Light-master/startup')
startup_MVPA_Light
load('../data/time_axis')
grad_acc = zeros(17,8,102,1);
mag_acc = zeros(17,8,102,1);
for subj = 1:length(subjects)
       subject = convertCharsToStrings(subjects(subj));
       if strcmp(subject,'sub13')
           continue
       end
       disp(subject)
    file = strcat('../data/',subject,'/',subject,'_clean.mat');
load(file)

cfg = [];
cfg.channel = 'MEGMAG';
cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) & (data.trialinfo(:,6) == 3 | data.trialinfo(:,6) ==4);
%cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) ;
mag_data = ft_selectdata(cfg,data);

cfg = [];
cfg.channel = 'MEGGRAD';
cfg.trials = data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7 & (data.trialinfo(:,6) == 3 | data.trialinfo(:,6) ==4);
%cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) ;
grad_data = ft_selectdata(cfg,data);


%neighbours
cfg = [];
cfg.method = 'triangulation';
cfg.layout = 'neuromag306mag.lay';
cfg.channel = mag_data.label;
mag_neighbours = ft_prepare_neighbours(cfg);

cfgS = [];cfgS.keeptrials = true;mag_data = ft_timelockanalysis(cfgS,mag_data);
for trial = 1:size(mag_data.trial,1)
    mag_data.trial(trial,:,:) = ft_preproc_smooth(squeeze(mag_data.trial(trial,:,:)),7);
end

cfg = [];
cfg.method = 'triangulation';
cfg.layout = 'neuromag306planar.lay';
cfg.channel = grad_data.label;
grad_neighbours = ft_prepare_neighbours(cfg);

cfgS = [];cfgS.keeptrials = true;grad_data = ft_timelockanalysis(cfgS,grad_data);
for trial = 1:size(grad_data.trial,1)
    grad_data.trial(trial,:,:) = ft_preproc_smooth(squeeze(grad_data.trial(trial,:,:)),7);
end
%searchlight
%figure;
for i = 1:8
    cfg = [];
    cfg.method = 'mvpa';
    cfg.features = 'time';
    cfg.latency = [i/10 (i/10)+0.02];
    cfg.mvpa.repeat = 1;
    cfg.mvpa.classifier = 'lda';
    cfg.design = mag_data.trialinfo(:,1);
    cfg.k = 5;
    cfg.mvpa.preprocess = {'undersample'};
    cfg.neighbours = mag_neighbours;
    cfg.avgovertime = 'no';

    
%mags
    stat = ft_timelockstatistics(cfg,mag_data);
    mag_acc(subj,i,:,:) = stat.accuracy;
    
    
    %grads
    cfg.neighbours = grad_neighbours;
    cfg.design = grad_data.trialinfo(:,1);
    stat = ft_timelockstatistics(cfg,grad_data);
    
    cfgS=[];
    data = [];
    data.label = stat.label;
    data.time = 0;
    data.dimord = 'chan_time';
    data.acc = stat.accuracy;
    grad_data_c = ft_combineplanar(cfgS,data); %combine gradiometers
    grad_acc(subj,i,:,:) = grad_data_c.avg;
   
end


end


mean_acc_grad = zeros(8,102);
mean_acc_mag = zeros(8,102);

for i = 1:size(grad_acc,2)
    mean_acc_grad(i,:) = mean(grad_acc(:,i,:));
    mean_acc_mag(i,:) = mean(mag_acc(:,i,:));
end

save('../data/results/group/searchlight/sq_v_diam/mean_acc_mag','mean_acc_mag')
save('../data/results/group/searchlight/sq_v_diam/mean_acc_grad','mean_acc_grad')
for i = 1:size(mean_acc_grad)
    subplot(2,4,i)
    cfgS = [];
    cfgS.xlim =[0.0 0];
    cfgS.zlim = [0.5 0.6];
    cfgS.layout = 'neuromag306cmb.lay';
    cfgS.parameter = 'acc';
    cfgS.comment ='no';
   
    data = [];
    data.label = grad_data_c.label;
    data.time = 0;
    data.dimord = 'chan_time';
    data.acc = mean_acc_grad(i,:);
    
    ft_topoplotER(cfgS,data); colorbar
    title(strcat(string(i/10), ' ms'))
    %sgtitle('gradiometers')
end
