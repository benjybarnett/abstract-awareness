vis_low_all = [];
vis_high_all = [];
fro_low_all = [];
fro_high_all = [];

for subj = 1:length(subjs)
    
    subject = subjs(subj);
    
    vis_low = load(cell2mat(fullfile(cfg.output_dir,subject,'visual','low','true_acc.mat')));
    vis_low = vis_low.acc;
    vis_high = load(cell2mat(fullfile(cfg.output_dir,subject,'visual','high','true_acc.mat')));
    vis_high = vis_high.acc;
    
    fro_low = load(cell2mat(fullfile(cfg.output_dir,subject,'frontal','low','true_acc.mat')));
    fro_low = fro_low.acc;
    fro_high = load(cell2mat(fullfile(cfg.output_dir,subject,'frontal','high','true_acc.mat')));
    fro_high = fro_high.acc;
    
    vis_low_all = [vis_low_all vis_low];
    vis_high_all = [vis_high_all vis_high];
    
    fro_low_all = [fro_low_all fro_low];
    fro_high_all = [fro_high_all fro_high];
    
end

mean_vis_low = mean(vis_low_all);
vis_low_upCI = mean_vis_low + 1.96*(std(vis_low_all)/sqrt(length(subjs)));
vis_low_lowCI = mean_vis_low - 1.96*(std(vis_low_all)/sqrt(length(subjs)));


mean_vis_high = mean(vis_high_all);
vis_high_upCI = mean_vis_high + 1.96*(std(vis_high_all)/sqrt(length(subjs)));
vis_high_lowCI = mean_vis_high - 1.96*(std(vis_high_all)/sqrt(length(subjs)));

mean_fro_low = mean(fro_low_all);
fro_low_upCI = mean_fro_low + 1.96*(std(fro_low_all)/sqrt(length(subjs)));
fro_low_lowCI = mean_fro_low - 1.96*(std(fro_low_all)/sqrt(length(subjs)));


mean_fro_high = mean(fro_high_all);
fro_high_upCI = mean_fro_high + 1.96*(std(fro_high_all)/sqrt(length(subjs)));
fro_high_lowCI = mean_fro_high - 1.96*(std(fro_high_all)/sqrt(length(subjs)));

%can do standard paired t test here
[h,p,ci,stats] = ttest(vis_low_all,fro_low_all);

%plot
x = categorical({'Visual'; 'Frontal'});
y = [mean_vis_low, mean_fro_low; mean_vis_high, mean_fro_high]';
errhigh = [vis_low_upCI-mean_vis_low   vis_high_upCI-mean_vis_high;  fro_low_upCI-mean_fro_low fro_high_upCI-mean_fro_high];
errlow = [vis_low_lowCI-mean_vis_low vis_high_lowCI-mean_vis_high; fro_low_lowCI-mean_fro_low  fro_high_lowCI-mean_fro_high];
figure;
bar(x,y);
colors = [67 146 241;
    166 38 57]/255;

%hold on

hBar = bar(y , 'grouped','FaceColor','flat');
hBar(1).CData = colors(1,:);
hBar(2).CData = colors(2,:);

[ngroups,nbars] = size(y);
x = nan(nbars,ngroups);
for i = 1:nbars
    x(i,:) = hBar(i).XEndPoints;
end

hold on
errorbar(x',y,errlow,errhigh,'.black')
ylim([0.4 0.65])
yline(0.5,'--')

hold off

set(gca,'XTick',[])
colors = [67 146 241;
    166 38 57]/255;
b.CData = colors;
hold on 
er = errorbar(x,data,errlow,errhigh);
er.Color = [0 0 0];
er.LineStyle = 'none';




