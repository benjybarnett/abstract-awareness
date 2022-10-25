function [t,p,h] = paired_ttest_multiclass(cfg, subjects)


    dir = '../data/results';
    load('../data/time_axis.mat');
    
    
    outputDir = fullfile(dir,'group','stats','cross_vs_within');
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    
%if ~exist(fullfile(outputDir,[cfg.outputName '.mat']),'file')
    
    all_acc1 = zeros(length(subjects),length(time),length(time));
    all_acc2 = zeros(length(subjects),length(time),length(time));
    remove=false;
    
    for subj =1:length(subjects)
        
        subject = convertCharsToStrings(subjects(subj));
        disp(subject)
        
        if strcmp(subject,'sub13') 
            remove = true;
            continue
        end
        
        if strcmp(cfg.train,'squares')
            load(strcat('../data/results/',subject','/',cfg.crossDir,'/',cfg.accFile));
            acc =train_sq_cross_acc;
        elseif strcmp(cfg.train,'diamonds')
            load(strcat('../data/results/',subject','/',cfg.crossDir,'/',cfg.accFile));
            acc = train_di_cross_acc;
        end
        all_acc1(subj,:,:) = acc;
        
        clear acc 
        
        if strcmp(cfg.train,'squares')
            load(strcat('../data/results/',subject','/',cfg.withinDir,'/','multiclass_PAS_squares2.mat'), 'square_acc');
            acc = square_acc;
        elseif strcmp(cfg.train,'diamonds')
            load(strcat('../data/results/',subject','/',cfg.withinDir,'/','multiclass_PAS_diamonds2.mat'), 'diam_acc');
            acc = diam_acc;
        end
        
        all_acc2(subj,:,:) = acc;
        clear acc Accuracy 
        
       
        
    end

    
    if remove
            all_acc1(12,:,:) = [];
            all_acc2(12,:,:) = [];
    end
    
    
    for subj = 1:size(all_acc1,1)
        flat1 = reshape(squeeze(all_acc1(subj,:,:)).',1,[]);
        flat2 = reshape(squeeze(all_acc2(subj,:,:)).',1,[]);

        acc1_flat(subj,:) = flat1;
        acc2_flat(subj,:) = flat2;
    end

    t_s = zeros(1,length(time)^2);
    p_s = zeros(1,length(time)^2);
    h_s = zeros(1,length(time)^2);


    for i = 1:size(acc1_flat,2)

      
            [h,p,~,stats] = ttest(acc1_flat(:,i),acc2_flat(:,i));
            t = stats.tstat;
            t_s(i) = t;
            p_s(i) = p;
            h_s(i) = h;
    end
    
    
    h = reshape(h_s,[length(time),length(time)])';
    p = reshape(p_s,[length(time),length(time)])';
    t = reshape(t_s,[length(time),length(time)])';
%else
 %   load(fullfile(outputDir,[cfg.outputName '.mat']));
   
%end
    if cfg.plot
        figure; 
        ax(1) = subplot(1,2,1);
        imagesc(time,time,h); axis xy; colorbar
        xlabel('Time (s)'); ylabel('Time (s)');
        hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
        hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k');
        hold on; xL = get(ax(1),'XLim') ;plot(xL,xL,'k-');
        colormap(ax(1),'summer')
        title('Reject Null Hypothesis');
        
        ax(2) = subplot(1,2,2);
        imagesc(time,time,t); axis xy; colorbar
        xlabel('Time (s)'); ylabel('Time (s)');
        hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
        hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k');
         hold on; xL = get(ax(2),'XLim') ;plot(xL,xL,'k--');
        caxis([-10 10])
        colormap(ax(2),'jet')
        title('t values: cross - within');
        sgtitle(cfg.title);

       
    

    end
    
    
    save(fullfile(outputDir,cfg.outputName),'h','p','t');


    
end

