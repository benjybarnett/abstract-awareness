%THIS SCRIPT DOES SEARCHLIGHT ANALYSIS USING CROSS DECODERS THAT ALSO HAVE
%A CROSS VALIDATION PROCEDURE.
rmpath('/Users/bbarnett/Documents/ecobrain/MVPA-Light\startup')
addpath('/Users/bbarnett/Documents/ecobrain/MVPA-light-searchlight\MVPA-Light-master/startup')
startup_MVPA_Light

load('../data/time_axis')
grad_acc_sq = zeros(17,8,102,1);
grad_acc_di = zeros(17,8,102,1);
mag_acc_sq = zeros(17,8,102,1);
mag_acc_di = zeros(17,8,102,1);
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
    %cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) & (data.trialinfo(:,6) == 3 | data.trialinfo(:,6) ==4);
    cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) ;
    mag_data = ft_selectdata(cfg,data);

    cfg = [];
    cfg.channel = 'MEGGRAD';
    %cfg.trials = data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7 & (data.trialinfo(:,6) == 3 | data.trialinfo(:,6) ==4);
    cfg.trials = (data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7) ;
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
    %split squares and diamonds for MAG
    cfgS = [];
    cfgS.trials = (mag_data.trialinfo(:,1) == 6);
    cfgS.channel = 'MEGMAG';
    sq_data_mag = ft_selectdata(cfgS,mag_data);
    cfgS = [];cfgS.keeptrials = true;cfgS.channel='MEGMAG';sq_data_mag = ft_timelockanalysis(cfgS,sq_data_mag);

    cfgS = [];
    cfgS.trials = (mag_data.trialinfo(:,1) == 7);
    di_data_mag = ft_selectdata(cfgS,mag_data);
    cfgS = [];cfgS.keeptrials = true;cfgS.channel='MEGMAG';di_data_mag = ft_timelockanalysis(cfgS,di_data_mag);


    %split squares and diamonds for GRAD
    cfgS = [];
    cfgS.trials = (grad_data.trialinfo(:,1) == 6);
    cfgS.channel = 'MEGGRAD';
    sq_data_grad = ft_selectdata(cfgS,grad_data);
    cfgS = [];cfgS.keeptrials = true;cfgS.channel='MEGGRAD';sq_data_grad = ft_timelockanalysis(cfgS,sq_data_grad);

    cfgS = [];
    cfgS.trials = (grad_data.trialinfo(:,1) == 7);
    di_data_grad = ft_selectdata(cfgS,grad_data);
    cfgS = [];cfgS.keeptrials = true;cfgS.channel='MEGGRAD';di_data_grad = ft_timelockanalysis(cfgS,di_data_grad);
    
    %figure;
    samples_of_interest = [76,101,126,151,176,201,226,251];
    for i = 1:length(samples_of_interest)
        disp(i)
        cfg = [];
        %cfg.method = 'mvpa';
        %cfg.features = 'time';
        %cfg.latency = [i/10 (i/10)+0.01];
        cfg.repeat = 1;
        cfg.classifier = 'multiclass_lda';
        cfg.design = mag_data.trialinfo(:,6);
        cfg.k = 5;
        cfg.lambda = 0.2;
        cfg.preprocess = {'undersample'};
        cfg.neighbours = create_neigh_mat(mag_neighbours);
        cfg.sample_dimension = 1;
        cfg.feature_dimension = 3;
        cfg.dimension_names = {'trials' 'channels' 'time points'};

        %mags
       
        %we are now just doing classification at the 8 time points of interest
        %using time point + 5 samples as our features
        %using neighbours to define the searchlight spheres
        %TO DO: check if current set up runs ok, plot topographies, then add in cross validation
        [perf_sq,~] = mv_classify_BOB(cfg,sq_data_mag.trial(:,:,samples_of_interest(i):samples_of_interest(i)+5),sq_data_mag.trialinfo(:,6),di_data_mag.trial(:,:,samples_of_interest(i):samples_of_interest(i)+5),di_data_mag.trialinfo(:,6));
        [perf_di,~] = mv_classify_BOB(cfg,di_data_mag.trial(:,:,samples_of_interest(i):samples_of_interest(i)+5),di_data_mag.trialinfo(:,6),sq_data_mag.trial(:,:,samples_of_interest(i):samples_of_interest(i)+5),sq_data_mag.trialinfo(:,6));
        

        mag_acc_sq(subj,i,:,:) = perf_sq;
        mag_acc_di(subj,i,:,:) = perf_di;


        %grads
        cfg.neighbours = create_neigh_mat(grad_neighbours);
        cfg.design = grad_data.trialinfo(:,6);
        %MY EDITED SCRIPT ALLOWS CROSS DECODING TO BE USED WITH CROSS
        %VALIDATION
        [perf_sq,~] = mv_classify_BOB(cfg,sq_data_grad.trial(:,:,samples_of_interest(i):samples_of_interest(i)+5),sq_data_grad.trialinfo(:,6),di_data_grad.trial(:,:,samples_of_interest(i):samples_of_interest(i)+5),di_data_grad.trialinfo(:,6));
        [perf_di,~] = mv_classify_BOB(cfg,di_data_grad.trial(:,:,samples_of_interest(i):samples_of_interest(i)+5),di_data_grad.trialinfo(:,6),sq_data_grad.trial(:,:,samples_of_interest(i):samples_of_interest(i)+5),sq_data_grad.trialinfo(:,6));
        

        cfgS=[];
        data = [];
        data.label = grad_data.label;
        data.time = 0;
        data.dimord = 'chan_time';
        data.acc = perf_sq;
        grad_data_c = ft_combineplanar(cfgS,data); %combine gradiometers
        grad_acc_sq(subj,i,:,:) = grad_data_c.avg;


        cfgS=[];
        data = [];
        data.label = grad_data.label;
        data.time = 0;
        data.dimord = 'chan_time';
        data.acc = perf_di;
        grad_data_c = ft_combineplanar(cfgS,data); %combine gradiometers
        grad_acc_di(subj,i,:,:) = grad_data_c.avg;


    end
    
end

mean_acc_grad_sq = zeros(8,102);
mean_acc_grad_di = zeros(8,102);

mean_acc_mag_sq = zeros(8,102);
mean_acc_mag_di = zeros(8,102);


for i = 1:size(mag_acc_sq,2)
   
    mean_acc_grad_sq(i,:) = mean(grad_acc_sq(:,i,:));
    mean_acc_grad_di(i,:) = mean(grad_acc_di(:,i,:));

    mean_acc_mag_sq(i,:) = mean(mag_acc_sq(:,i,:));
    mean_acc_mag_di(i,:) = mean(mag_acc_di(:,i,:));

end


save('../data/results/group/searchlight/cross/mean_acc_mag_sq','mean_acc_mag_sq')
save('../data/results/group/searchlight/cross/mean_acc_mag_di','mean_acc_mag_di')
save('../data/results/group/searchlight/cross/mean_acc_grad_sq','mean_acc_grad_sq')
save('../data/results/group/searchlight/cross/mean_acc_grad_di','mean_acc_grad_di')



load('../data/results/group/searchlight/cross/mean_acc_mag_sq')
load('../data/results/group/searchlight/cross/mean_acc_mag_di')
load('../data/results/group/searchlight/cross/mean_acc_grad_sq')
load('../data/results/group/searchlight/cross/mean_acc_grad_di')

for i = 1:size(mean_acc_mag_sq)
    subplot(2,4,i)
    cfgS = [];
    cfgS.xlim =[0.0 0];
    cfgS.zlim = [0.25 0.35];
    cfgS.layout = 'neuromag306mag.lay';
    cfgS.parameter = 'acc';
    
   
    data = [];
    data.label = mag_data.label;
    data.time = 0;
    data.dimord = 'chan_time';
    data.acc = mean_acc_mag_sq(i,:);
    cfgS.comment = 'no';
    ft_topoplotER(cfgS,data); colorbar
    title(strcat(string(i/10), ' ms'))
    %sgtitle('mag square')
end
