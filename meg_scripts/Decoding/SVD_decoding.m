
%%subjects
subjects = ...
            {   
           
           
    'sub02'
    'sub03'
    'sub04'
    'sub05'
    'sub06'
    'sub07'
    'sub08'
    'sub09'
    'sub10'
    'sub11'
    'sub12'
    %'sub13'
    'sub15'
    'sub16'
    'sub17'
    'sub18'
    'sub19'
    'sub20'
                       

         };

for subj = 1:length(subjects)
    
    subject = convertCharsToStrings(subjects(subj));
    disp(subject)
    


    load(strcat('../data/',subject,'/',subject,'_clean.mat'))
    cfg= [];
    cfg.trials = data.trialinfo(:,1) == 6 | data.trialinfo(:,1) == 7;
    data = ft_selectdata(cfg,data);

  
    
    %Reduce to 6 PCA
    cfg = [];
    cfg.method = 'svd';
    cfg.channel = 'MEG';
    cfg.numcomponent = 6;
    comp = ft_componentanalysis(cfg,data);
    cfgT = [];cfgT.keeptrials = 'true'; timelock = ft_timelockanalysis(cfgT,comp);
    disp('6 PC')
    
    %decode with 6 pc    
    cfgD=[];
    cfgD.outputDir = 'Decoding/Cross/Temporal/Multiclass/SVD';
    cfgD.nFold  = 5;
    cfgD.gamma = 0.2;
    cfgD.nMeanS = 7; 
    cfgD.plot  = false;
    cfgD.outputName = {'multiclass_PAS_trainSquares_6D';'multiclass_PAS_trainDiamonds_6D'};
    multiclass_cross_svd(cfgD,subject,timelock)

    disp('5 PC')
    %reduce to 5 PCA
    cfg.numcomponent = 5;
    comp = ft_componentanalysis(cfg,data);
    cfgT = [];cfgT.keeptrials = 'true'; timelock = ft_timelockanalysis(cfgT,comp);
    cfgD.outputName = {'multiclass_PAS_trainSquares_5D';'multiclass_PAS_trainDiamonds_5D'};
    multiclass_cross_svd(cfgD,subject,timelock)
    
    disp('4 PC')
    %reduce to 4 PCA
    cfg.numcomponent = 4;
    comp = ft_componentanalysis(cfg,data);
    cfgT = [];cfgT.keeptrials = 'true'; timelock = ft_timelockanalysis(cfgT,comp);
    cfgD.outputName = {'multiclass_PAS_trainSquares_4D';'multiclass_PAS_trainDiamonds_4D'};
    multiclass_cross_svd(cfgD,subject,timelock)

    disp('3 PC')
    %reduce to 3 PCA
    cfg.numcomponent = 3;
    comp = ft_componentanalysis(cfg,data);
    cfgT = [];cfgT.keeptrials = 'true'; timelock = ft_timelockanalysis(cfgT,comp);
    cfgD.outputName = {'multiclass_PAS_trainSquares_3D';'multiclass_PAS_trainDiamonds_3D'};
    multiclass_cross_svd(cfgD,subject,timelock)
    
    disp('2 PC')
    %reduce to 2 PCA
    cfg.numcomponent = 2;
    comp = ft_componentanalysis(cfg,data);
    cfgT = [];cfgT.keeptrials = 'true'; timelock = ft_timelockanalysis(cfgT,comp);
    cfgD.outputName = {'multiclass_PAS_trainSquares_2D';'multiclass_PAS_trainDiamonds_2D'};
    multiclass_cross_svd(cfgD,subject,timelock)

    disp('1 PC')
    %reduce to 1 PCA
    cfg.numcomponent = 1;
    comp = ft_componentanalysis(cfg,data);
    cfgT = [];cfgT.keeptrials = 'true'; timelock = ft_timelockanalysis(cfgT,comp);
    cfgD.outputName = {'multiclass_PAS_trainSquares_1D';'multiclass_PAS_trainDiamonds_1D'};
    multiclass_cross_svd(cfgD,subject,timelock)

end

di_fullD = [];
sq_fullD = [];
di6 = [];
sq6 = [];
di5 = [];
sq5 = [];
di4 = [];
sq4 = [];
di3 = [];
sq3 = [];
di2 = [];
sq2 = [];
di1 = [];
sq1 = [];
for subj = 1:length(subjects)
    
    subject = convertCharsToStrings(subjects(subj));
    disp(subject)
    
    
    %get multiclassifier decoding accuracy in specific time window on full D data
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/multiclass_PAS_trainSquares'));
    diag_sq = diag(train_sq_cross_acc);
    %get window of interest
    window_diag_sq =diag_sq(82:296);
    %get mean accuracy in this time window
    mean_acc_fullD = mean(window_diag_sq,'all');
    sq_fullD = [sq_fullD mean_acc_fullD];
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/multiclass_PAS_trainDiamonds'));
    diag_di = diag(train_di_cross_acc);
    %get window of interest
    window_diag_di =diag_di(82:325);
    %get mean accuracy in this time window
    mean_acc_fullD = mean(window_diag_di,'all');
    di_fullD = [di_fullD mean_acc_fullD];
    

    %6D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_6D'));
    diag_sq = diag(train_sq_cross_acc);
    %get window of interest
    window_diag_sq =diag_sq(82:296);
    %get mean accuracy in this time window
    mean_acc_6D = mean(window_diag_sq,'all');
    sq6 = [sq6 mean_acc_6D];
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_6D'));
    diag_di = diag(train_di_cross_acc);
    %get window of interest
    window_diag_di =diag_di(82:325);
    %get mean accuracy in this time window
    mean_acc_6D = mean(window_diag_di,'all');
    di6 = [di6 mean_acc_6D];
    
    %5D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_5D'));
    diag_sq = diag(train_sq_cross_acc);
    %get window of interest
    window_diag_sq =diag_sq(82:296);
    %get mean accuracy in this time window
    mean_acc_5D = mean(window_diag_sq,'all');
    sq5 = [sq5 mean_acc_5D];
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_5D'));
    diag_di = diag(train_di_cross_acc);
    %get window of interest
    window_diag_di =diag_di(82:325);
    %get mean accuracy in this time window
    mean_acc_5D = mean(window_diag_di,'all');
    di5 = [di5 mean_acc_5D];
    
    %4D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_4D'));
    diag_sq = diag(train_sq_cross_acc);
    %get window of interest
    window_diag_sq =diag_sq(82:296);
    %get mean accuracy in this time window
    mean_acc_4D = mean(window_diag_sq,'all');
    sq4 = [sq4 mean_acc_4D];
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_4D'));
    diag_di = diag(train_di_cross_acc);
    %get window of interest
    window_diag_di =diag_di(82:325);
    %get mean accuracy in this time window
    mean_acc_4D = mean(window_diag_di,'all');
    di4 = [di4 mean_acc_4D];
    
    
    %3D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_3D'));
    diag_sq = diag(train_sq_cross_acc);
    %get window of interest
    window_diag_sq =diag_sq(82:296);
    %get mean accuracy in this time window
    mean_acc_3D = mean(window_diag_sq,'all');
    sq3 = [sq3 mean_acc_3D];
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_3D'));
    diag_di = diag(train_di_cross_acc);
    %get window of interest
    window_diag_di =diag_di(82:325);
    %get mean accuracy in this time window
    mean_acc_3D = mean(window_diag_di,'all');
    di3 = [di3 mean_acc_3D];
    
    %2D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_2D'));
   diag_sq = diag(train_sq_cross_acc);
    %get window of interest
    window_diag_sq =diag_sq(82:296);
    %get mean accuracy in this time window
    mean_acc_2D = mean(window_diag_sq,'all');
    sq2 = [sq2 mean_acc_2D];
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_2D'));
    diag_di = diag(train_di_cross_acc);
    %get window of interest
    window_diag_di =diag_di(82:325);
    %get mean accuracy in this time window
    mean_acc_2D = mean(window_diag_di,'all');
    di2 = [di2 mean_acc_2D];
    
    %1D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_1D'));
    diag_sq = diag(train_sq_cross_acc);
    %get window of interest
    window_diag_sq =diag_sq(82:296);
    %get mean accuracy in this time window
    mean_acc_1D = mean(window_diag_sq,'all');
    sq1 = [sq1 mean_acc_1D];
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_1D'));
    diag_di = diag(train_di_cross_acc);
    %get window of interest
    window_diag_di =diag_di(82:325);
    %get mean accuracy in this time window
    mean_acc_1D = mean(window_diag_di,'all');
    di1 = [di1 mean_acc_1D];

end
squares = [sq6; sq5; sq4; sq3; sq2; sq1];
diamonds = [di6; di5; di4; di3; di2; di1];
sq_ts = zeros(6,6);
sq_ps = zeros(6,6);
di_ts = zeros(6,6);
di_ps = zeros(6,6);
for i = 1: 6
    comp1 = squares(i,:);
    comp1_di = diamonds(i,:);
    for j = 1:6
        comp2 = squares(j,:);
        comp2_di = diamonds(j,:);
        [h,p,ci,stats] = ttest(comp1,comp2);
        t = stats.tstat;
        sq_ts(i,j) = t;
        sq_ps(i,j) = p;
        
        [h,p,ci,stats] = ttest(comp1_di,comp2_di);
        t = stats.tstat;
        di_ts(i,j) = t;
        di_ps(i,j) = p;
    end   
end

ii = ones(size(sq_ts)); idx = tril(ii); sq_ts(~idx) = nan;  sq_ps(~idx) = nan;di_ts(~idx) = nan;  di_ps(~idx) = nan;
sq_ps = round(sq_ps,3);
p_labels_sq = num2cell(sq_ps);
p_labels_sq = cellfun(@num2str, p_labels_sq, 'UniformOutput',false);
di_ps = round(di_ps,3);
p_labels_di = num2cell(di_ps);
p_labels_di = cellfun(@num2str, p_labels_di, 'UniformOutput',false);
for p = 1:size(p_labels_sq,1)
    for q = 1:size(p_labels_sq,2)
        
     p_labels_sq(p,q) = strcat('p = ',{' ' }, p_labels_sq(p,q));
     p_labels_di(p,q) = strcat('p = ',{' ' }, p_labels_di(p,q));
    end
end
x = repmat(1:6,6,1);y =x';
figure; imagesc(abs(sq_ts),'AlphaData',~isnan(abs(sq_ts)));cb = colorbar;set(get(cb,'label'),'string','t-values');
xlabel('Dimensions')
ylabel('Dimensions')
text(x(:),y(:)',p_labels_sq,'HorizontalAlignment','Center','FontSize',8)
colormap(flipud(autumn))
title('train squares from 500ms - 980ms')

figure; imagesc(abs(di_ts),'AlphaData',~isnan(abs(di_ts)));cb = colorbar;set(get(cb,'label'),'string','t-values');
xlabel('Dimensions')
ylabel('Dimensions')
text(x(:),y(:)',p_labels_di,'HorizontalAlignment','Center','FontSize',8)
colormap(flipud(autumn))
title('train diamonds from 500ms - 1100ms')


%plot mean accuracies

mean_grp_sq = [mean(sq1),mean(sq2),mean(sq3),mean(sq4),mean(sq5),mean(sq6)];
mean_grp_di = [mean(di1),mean(di2),mean(di3),mean(di4),mean(di5),mean(di6)];

%confidence intervals

sd = std(squares,0,2);
n = size(squares,2);

CIs= 1.96*(sd/sqrt(n));
curve1 = mean_grp_sq'+CIs;
curve2 =mean_grp_sq'-CIs;
x2 = [1:6, fliplr(1:6)];

inBetween =[curve1', fliplr(curve2')];

figure;

fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
hold on;
plot(1:6, mean_grp_sq,'-gs','Color', '#0621A6', 'LineWidth', 1,'MarkerSize',10,...
    'MarkerFaceColor',[0 0 0]);
yline(0.25,'black--');
ylim([0.23 0.29])
xticks([1 2 3 4 5 6])
xticklabels({'1D','2D','3D','4D','5D','6D'});
ylabel('Mean Accuracy')
title('train squares from 500ms - 980ms')


sd = std(diamonds,0,2);
n = size(diamonds,2);
CIs= 1.96*(sd/sqrt(n));
curve1 = mean_grp_di'+CIs;
curve2 =mean_grp_di'-CIs;
x2 = [1:6, fliplr(1:6)];
inBetween =[curve1', fliplr(curve2')];
figure;fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
hold on;
plot(1:6, mean_grp_di,'-gs','Color', '#0621A6', 'LineWidth', 1,'MarkerSize',10,...
    'MarkerFaceColor',[0 0 0]);
yline(0.25,'black--');
ylim([0.23 0.29])
xticks([1 2 3 4 5 6])
xticklabels({'1D','2D','3D','4D','5D','6D'});
ylabel('Mean Accuracy')
title('train diamonds from 500ms - 1100 ms')


%plot diagonal accuracies for each PC data

di_fullD = [];
sq_fullD = [];
di6 = [];
sq6 = [];
di5 = [];
sq5 = [];
di4 = [];
sq4 = [];
di3 = [];
sq3 = [];
di2 = [];
sq2 = [];
di1 = [];
sq1 = [];
for subj = 1:length(subjects)
    
    subject = convertCharsToStrings(subjects(subj));
    disp(subject)
    
    
    %get multiclassifier decoding accuracy in specific time window on full D data
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/multiclass_PAS_trainSquares'));
    sq_fullD = [sq_fullD diag(train_sq_cross_acc)];
    
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/multiclass_PAS_trainDiamonds'));
    di_fullD = [di_fullD diag(train_di_cross_acc)];
  

    %6D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_6D'));
    sq6 = [sq6 diag(train_sq_cross_acc)];
    
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_6D'));
    di6 = [di6 diag(train_di_cross_acc)];
    
    
    %5D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_5D'));
    sq5 = [sq5 diag(train_sq_cross_acc)];
  
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_5D'));
    di5 = [di5 diag(train_di_cross_acc)];
    
    
    %4D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_4D'));
    sq4 = [sq4 diag(train_sq_cross_acc)];
    
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_4D'));
    di4 = [di4 diag(train_di_cross_acc)];
   
    
    %3D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_3D'));
    sq3 = [sq3 diag(train_sq_cross_acc)];
 
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_3D'));
    di3 = [di3 diag(train_di_cross_acc)];
   
    
    %2D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_2D'));
    sq2 = [sq2 diag(train_sq_cross_acc)];
    
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_2D'));
    di2 = [di2 diag(train_di_cross_acc)];
    
    
    %1D
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainSquares_1D'));
    sq1 = [sq1 diag(train_sq_cross_acc)];
    
    
    load(strcat('../data/results/',subject,'/Decoding/Cross/Temporal/Multiclass/SVD/multiclass_PAS_trainDiamonds_1D'));
    di1 = [di1 diag(train_di_cross_acc)];
    

end

fullD = mean(diag_sq_full,2);
mean_6d = mean(sq6,2);
mean_5d = mean(sq5,2);
mean_4d = mean(sq4,2);
mean_3d = mean(sq3,2);
mean_2d = mean(sq2,2);
mean_1d = mean(sq1,2);

figure; plot(time(1:550),fullD(1:550));xlim([time(1) time(end)]);

hold on;
ax = plot(time(1:550),mean_6d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_5d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_4d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_3d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_2d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_1d(1:550));xlim([time(1) time(end)]);
xlim([time(1) time(550)])
legend('full dimensions','6 dimensions','5 dimensions','4 dimensions','3 dimensions','2 dimensions','1 dimensions')
xlabel('Time (ms)')
xticks([0 0.5 1 1.5 2])
ylabel('Accuracy')


fullD = mean(diag_di_full,2);
mean_6d = mean(di6,2);
mean_5d = mean(di5,2);
mean_4d = mean(di4,2);
mean_3d = mean(di3,2);
mean_2d = mean(di2,2);
mean_1d = mean(di1,2);
figure; plot(time(1:550),fullD(1:550));xlim([time(1) time(end)]);

hold on;
ax = plot(time(1:550),mean_6d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_5d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_4d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_3d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_2d(1:550));xlim([time(1) time(end)]);
ax = plot(time(1:550),mean_1d(1:550));xlim([time(1) time(end)]);
xlim([time(1) time(550)])
legend('full dimensions','6 dimensions','5 dimensions','4 dimensions','3 dimensions','2 dimensions','1 dimensions')
xlabel('Time (ms)')
xticks([0 0.5 1 1.5 2])
ylabel('Accuracy')