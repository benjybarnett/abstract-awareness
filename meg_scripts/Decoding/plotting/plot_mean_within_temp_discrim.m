function mean_acc= plot_mean_within_temp_discrim(cfg, subjects)

    
    dir = '../data/results';
    load('../data/time_axis.mat');

    acc = zeros(length(subjects),length(time),length(time));
  
    remove =false;
    for subj =1:length(subjects)
        
        subject = convertCharsToStrings(subjects(subj));
        disp(subject)
        
        if strcmp(subject,'sub13') && contains(cfg.accFile,'3') 
            remove = true;
            continue
        end
        Acc = load(strcat('../data/results/',subject','/',cfg.accDir,'/',cfg.accFile), 'Accuracy');
       
        Acc = struct2cell(Acc); Acc = Acc{1};
       
        
        acc(subj,:,:) = Acc;
        
        
        clear Acc
    end
    if remove
            acc(12,:,:) = [];
    end
    mean_acc = squeeze(mean(acc,1));
   
    
    diags = [];
    for i = 1:size(acc,1)
        diags = [diags diag(squeeze(acc(i,:,:)))];
    end
    std_dev = std(diags');
    
    
    total_diag = diag(mean_acc)';
    

    CIs = [];
    for i =1:size(total_diag,2)
        
        sd = std_dev(i);
        n = size(acc,1);
        
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    
    outputDir = fullfile(dir,'group',cfg.accDir);
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    save(fullfile(outputDir,cfg.accFile),'mean_acc','total_diag');
    
    figure;
    %subplot(2,3,[1 4]);
    imagesc(time,time,mean_acc); axis xy; colorbar
    xlabel('Time (s)'); ylabel('Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis([0.45 0.65])
    colormap('jet')
    title(cfg.title);
    fig = gcf;
    saveas(fig,fullfile(outputDir,[cfg.accFile,'.png']));
    
    figure;
      
    
    curve1 = total_diag+CIs;
    curve2 =total_diag-CIs;
    
    x2 = [time, fliplr(time)];
    
    
    inBetween = [curve1, fliplr(curve2)];
    
   
    fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,total_diag,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.5,'black--');
    xlim([time(1) time(end)]);
    ylim([0.4 0.7])
    xline(time(end));
    title(cfg.title);
    xlabel('Time (s)')
    ylabel('Accuracy')
    fig = gcf;
    saveas(fig,fullfile(dir,'group','Decoding/Within/Diag',[cfg.accFile,'.png']));
    
end