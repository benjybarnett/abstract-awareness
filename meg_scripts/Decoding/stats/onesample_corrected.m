function [pVals_onesamp_sq,pVals_onesamp_di] = onesample_corrected(cfg,subjects)


dir = '../data/results'; load('../data/time_axis.mat');
 load('noBL_time.mat');
 time= noBL_time;
   
remove=false;
di_acc = zeros(length(subjects),length(time(1:620)),length(time(1:620)));
sq_acc=zeros(length(subjects),length(time(1:620)),length(time(1:620)));
for subj =1:length(subjects)

    subject = convertCharsToStrings(subjects(subj));
    disp(subject)

    if strcmp(subject,'sub13') 
        remove = true;
        continue
    end

    %cross
       
    %load(strcat('../data/results/',subject','/',cfg.crossDir,'/',cfg.diFile));
    %load(strcat('../data/results/',subject','/',cfg.crossDir,'/',cfg.sqFile));

    %within
    load(strcat('../data/results/',subject','/',cfg.withinDir,'/',cfg.diFile));
    load(strcat('../data/results/',subject','/',cfg.withinDir,'/',cfg.sqFile));


    di_acc(subj,:,:) = diam_acc(1:620,1:620);
    sq_acc(subj,:,:) = square_acc(1:620,1:620);
    %di_acc(subj,:,:) = train_di_cross_acc(1:620,1:620);
    %sq_acc(subj,:,:) = train_sq_cross_acc(1:620,1:620);
  
end
if remove
       di_acc(12,:,:) = [];
       sq_acc(12,:,:) = [];
end



cfgS = [];cfgS.paired = false;cfgS.tail= 'one'; cfgS.indiv_pval = 0.05; cfgS.cluster_pval = 0.05;
disp(size(sq_acc))
disp(size(di_acc))

pVals_onesamp_di = cluster_based_permutationND(di_acc,0.25,cfgS);
save(fullfile('../data/results/group/stats/one_sample/Decoding/Within/Temporal/multiclass/',['pVals_',cfg.diFile]),'pVals_onesamp_di')

pVals_onesamp_sq = cluster_based_permutationND(sq_acc,0.25,cfgS);
save(fullfile('../data/results/group/stats/one_sample/Decoding/Within/Temporal/multiclass/',['pVals_',cfg.sqFile]),'pVals_onesamp_sq')

%{
pVals_onesamp_cross_di =ps;
pVals_onesamp_cross_sq = qs;
save('../data/results/group/stats/one_sample/Decoding/Within/Temporal/multiclass/pVals_onesamp_cross_di_frontal.mat','pVals_onesamp_cross_di')
save('../data/results/group/stats/one_sample/Decoding/Within/Temporal/multiclass/pVals_onesamp_cross_sq_frontal.mat','pVals_onesamp_cross_di')
%}
%plot
if cfg.plot
di_mask = pVals_onesamp_di(1:620,1:620);figure; 
colormap jet;
imAlpha = ones(size(di_mask));
imAlpha(di_mask==1)=0;

train_di_acc = load(fullfile('../data/results/group/Decoding/Within/Temporal/Multiclass/',cfg.diFile));
train_di_acc = train_di_acc.total_mean_acc;

%subplot(2,3,[1 4]);
imagesc(time(1:620),time(1:620),train_di_acc(1:620,1:620),'AlphaData',imAlpha); axis xy;
xticks([0 0.5 1 1.5 2]);xticklabels({0 ,0.5 ,1, 1.5, 2});yticks([0 0.5 1 1.5 ]);yticklabels({0 ,0.5 ,1, 1.5 });
colorbar;
xlabel('Time (s)'); ylabel('Time (s)');
%hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
%hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
caxis([0.1 0.4])
colormap('jet')
%title('Within Diamond Decoding');
fig = gcf;
set(gca,'color',[0 0 0]);


sq_mask = pVals_onesamp_sq(1:620,1:620);figure; 
colormap jet;
imAlpha = ones(size(sq_mask));
imAlpha(sq_mask==1)=0;

train_sq_acc = load(fullfile('../data/results/group/Decoding/Within/Temporal/Multiclass/',cfg.sqFile));
train_sq_acc = train_sq_acc.total_mean_acc;

%subplot(2,3,[1 4]);
imagesc(time(1:620),time(1:620),train_sq_acc(1:620,1:620),'AlphaData',imAlpha); axis xy;
xticks([0 0.5 1 1.5 2]);xticklabels({0 ,0.5 ,1, 1.5, 2});yticks([0 0.5 1 1.5 ]);yticklabels({0 ,0.5 ,1, 1.5 });
colorbar;
xlabel('Time (s)'); ylabel('Time (s)');
%hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
%hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
caxis([0.1 0.4])

colormap('jet')
%title('Within Square Decoding ');
fig = gcf;
set(gca,'color',[0 0 0]);

%diagonals
%plot diagonal of accuracy matrix
    time = time(1:620);
    figure;
    num_subjects = size(di_acc,1);
    all_diags = zeros(num_subjects,length(time(1:620)));
    for i = 1:size(di_acc,1)
        all_diags(i,:) = diag(squeeze(di_acc(i,1:620,1:620)));
    end
    std_dev = std(all_diags);
    
    disp(all_diags(10))

    
    diag_acc = mean(all_diags);
   
    diag_acc = diag_acc(:,1:620); %cut off last chunk

    CIs = [];
    for i =1:size(diag_acc,2)
        
        sd = std_dev(i);
        n = size(all_diags,1);
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    curve1 = diag_acc+CIs;
    curve2 =diag_acc-CIs;
    
    x2 = [time(1:620), fliplr(time(1:620))];
    
    
    inBetween = [curve1, fliplr(curve2)];
   
   
    fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time(1:620),diag_acc,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.25,'black--');
    xlim([time(1) time(end)]);
    ylim([0.2 0.4])
    xline(time(end));
    xlabel('Time (s)')
    ylabel('Accuracy')
    fig = gcf;
    hold on;
     x1 = NaN;
        x1s =[];
    %sig points on diag
    diago = diag(pVals_onesamp_di);
    for h = 1:length(diago)
           if diago(h) ~= 1 && isnan(x1)
               x1 = h;
               x1s = [x1s x1];
               disp('hi')
               continue;
           end
           
           if diago(h) == 1 && ~isnan(x1)
              
               x2 = h-1;
               line([time(x1),time(x2)], [0.38,0.38],'Color','black');
               hold on;
               x1 = NaN;
               continue
           end
           
    end
    if ~ isnan(x1)
        line([time(x1),time(end)], [0.38,0.38],'Color','black');
    end
        

    %diag for square training decoder
     figure;
    num_subjects = size(sq_acc,1);
    all_diags = zeros(num_subjects,length(time));
    for i = 1:size(sq_acc,1)
        all_diags(i,:) = diag(squeeze(sq_acc(i,1:620,1:620)));
    end
    std_dev = std(all_diags);
    
    disp(all_diags(10))

    
    diag_acc = mean(all_diags);
   


    CIs = [];
    for i =1:size(diag_acc,2)
        
        sd = std_dev(i);
        n = size(all_diags,1);
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    curve1 = diag_acc+CIs;
    curve2 =diag_acc-CIs;
    
    x2 = [time, fliplr(time)];
    
    
    inBetween = [curve1, fliplr(curve2)];
   
   
    fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,diag_acc,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.25,'black--');
    xlim([time(1) time(end)]);
    ylim([0.2 0.4])
    xline(time(end));
    xlabel('Time (s)')
    ylabel('Accuracy')
    fig = gcf;
    hold on;
     x1 = NaN;
        x1s =[];
    %sig points on diag
    diago = diag(pVals_onesamp_sq);
    for h = 1:length(diago(1:620))
           if diago(h) ~= 1 && isnan(x1)
               x1 = h;
               x1s = [x1s x1];
               disp('hi')
               continue;
           end
           
           if diago(h) == 1 && ~isnan(x1)
              
               x2 = h-1;
               line([time(x1),time(x2)], [0.38,0.38],'Color','black');
               hold on;
               x1 = NaN;
               continue
           end
           
    end
    if ~ isnan(x1)
        line([time(x1),time(end)], [0.38,0.38],'Color','black');
    end
        
end

end
    