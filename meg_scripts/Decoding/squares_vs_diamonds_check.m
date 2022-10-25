load('../data/time_axis')
acc = zeros(17,675);
for subj = 1:length(subjects)
       subject = convertCharsToStrings(subjects(subj));
       if strcmp(subject,'sub13')
           continue
       end
       disp(subject)
    file = strcat('../data/',subject,'/',subject,'_clean.mat');
load(file)

cfg = [];
cfg.channel = 'MEG';
cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) & (data.trialinfo(:,6) == 3 | data.trialinfo(:,6) ==4);
%cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) ;
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

avg_acc = mean(acc,1);
plot(time,avg_acc)
xlim([min(time) max(time)])
yline(0.5)
ylim([0.4 0.7])
