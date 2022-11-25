sq_ps ='D:\bbarnett\Documents\ecobrain\data\results\group\stats\one_sample\Decoding\Within\Temporal\multiclass\pVals_multiclass_PAS_squares_regressed';
di_ps = 'D:\bbarnett\Documents\ecobrain\data\results\group\stats\one_sample\Decoding\Within\Temporal\multiclass\pVals_multiclass_PAS_diamonds_regressed';
cfg = [];
cfg.diFile = 'multiclass_PAS_diamonds_regressed';
cfg.sqFile = 'multiclass_PAS_squares_regressed';
cfg.crossDir ='Decoding/Cross/Temporal/multiclass';
cfg.withinDir ='Decoding/Within/Temporal/multiclass';

dir = '../data/results'; load('../data/time_axis.mat');
time = time(1:550);
%load('noBL_time.mat');
%time= noBL_time(1:550)+0.025;
remove=false;
di_acc = zeros(length(subjects),length(time(1:550)),length(time(1:550)));
sq_acc=zeros(length(subjects),length(time(1:550)),length(time(1:550)));
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
   
    di_acc(subj,:,:) = diam_acc(1:550,1:550);
    sq_acc(subj,:,:) = square_acc(1:550,1:550);
    %di_acc(subj,:,:) = train_di_cross_acc(1:550,1:550);
    %sq_acc(subj,:,:) = train_sq_cross_acc(1:550,1:550);
  
end
if remove
       di_acc(12,:,:) = [];
       sq_acc(12,:,:) = [];
end

%% Plot
 %Create Mask of Significant P Values
    load(strcat(sq_ps,'.mat'))
    sq_mask = pVals_onesamp_sq(1:550, 1:550);
    colormap jet;
    imAlpha = ones(size(sq_mask));
    imAlpha(sq_mask==1)=0.5;

    %Calculate Mean Accuracy
    mean_sq_acc = squeeze(mean(sq_acc,1));

    %plot
    figure
    
    imagesc(time,time,mean_sq_acc,'AlphaData',imAlpha); axis xy;
    xticks([-0.4 0 0.4 0.8 1.2 1.6]);xticklabels({-0.4 0 0.4 0.8 1.2 1.6});yticks([-0.4 0 0.4 0.8 1.2 1.6 ]);yticklabels({-0.4 0 0.4 0.8 1.2 1.6});
    colorbar;
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'black'); hold on; plot(xlim,[0 0],'black');
    %hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis([0.1 0.4])
    colormap('jet')
    
    hold on;

    %plot outline of significant clusters
    Z = ones(10,10);
    idx = (sq_mask~=1); 
        bnd = bwboundaries(idx);

   
    bnd1 = bnd(1);
    bnd1=bnd1{1,1};
    for coods = 1:length(bnd1)
       
        h1 = plot(  time(bnd1(coods,2))-0.005:0.005:time(bnd1(coods,2)), time(bnd1(coods,1))-0.005:0.005:time(bnd1(coods,1)),'linewidth',0.5,'color','#36454F');
        %h1.Color(4) = 0.1;
    end


    
    load(strcat(di_ps,'.mat'))
    di_mask = pVals_onesamp_di(1:550, 1:550);
    colormap jet;
    imAlpha = ones(size(di_mask));
    imAlpha(di_mask==1)=0.5;

    %Calculate Mean Accuracy
    mean_di_acc = squeeze(mean(di_acc,1));

    %plot
    figure
    
    imagesc(time,time,mean_di_acc,'AlphaData',imAlpha); axis xy;
    xticks([-0.4 0 0.4 0.8 1.2 1.6]);xticklabels({-0.4 0 0.4 0.8 1.2 1.6});yticks([-0.4 0 0.4 0.8 1.2 1.6 ]);yticklabels({-0.4 0 0.4 0.8 1.2 1.6});
    colorbar;
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'black'); hold on; plot(xlim,[0 0],'black');
    %hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis([0.1 0.4])
    colormap('jet')
    
    hold on;
    %plot outline of significant clusters
    Z = ones(10,10);
    idx = (di_mask~=1) ;
    
    bnd = bwboundaries(idx);
    
    bnd1 = bnd(1);
    bnd1=bnd1{1,1};
    for coods = 1:length(bnd1)
       
        h1 = plot(  time(bnd1(coods,2))-0.005:0.005:time(bnd1(coods,2)), time(bnd1(coods,1))-0.005:0.005:time(bnd1(coods,1)),'linewidth',0.5,'color','#36454F');
        %h1.Color(4) = 0.1;
    end
   
   
    