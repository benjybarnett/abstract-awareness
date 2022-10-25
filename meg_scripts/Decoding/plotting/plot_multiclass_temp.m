function plot_multiclass_temp(cfg, subjects)

    
    dir = '../data/results';
    load('../data/time_axis.mat');
    load('noBL_time.mat');

    
    time = noBL_time(1:620);
    disp(time)
    all_acc = zeros(length(subjects),length(time),length(time));
    remove=false;
    for subj =1:length(subjects)
        
        subject = convertCharsToStrings(subjects(subj));
        disp(subject)
        
        if strcmp(subject,'sub13') %remove because has no PAS 3
            remove = true;
            continue
        end
        Acc = load(strcat('../data/results/',subject','/',cfg.accDir,'/',cfg.accFile));
        
        Acc = struct2cell(Acc); Acc = Acc{1};
       
       all_acc(subj,:,:) = Acc(1:620,1:620);
        
        clear temporary
    end
    
    if remove
            all_acc(12,:,:) = [];
            
            
    end
    num_subjects = size(all_acc,1);
    
    
    
    all_acc = all_acc(:,1:620,1:620);
  
    
    total_mean_acc = squeeze(mean(all_acc,1));
    
    all_diags = zeros(2,length(time));
    for i = 1:size(all_acc,1)
        all_diags(i,:) = diag(squeeze(all_acc(i,:,:)));
    end
    
    std_dev = std(all_diags);

    
    total_diag = diag(total_mean_acc)';
   

    CIs = [];
    for i =1:size(all_diags,2)
        
        sd = std_dev(i);
        
        n = size(all_acc,1);
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    %disp(CIs)
    outputDir = fullfile(dir,'group',cfg.accDir);
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    save(fullfile(outputDir,cfg.accFile),'total_mean_acc','total_diag');
    
    figure;
    %subplot(2,3,[1 4]);
    imagesc(time,time,total_mean_acc); axis xy; colorbar
    xlabel('Time (s)'); ylabel('Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis([0.1 0.4])
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
    yline(0.25,'black--');
    xlim([time(1) time(end)]);
    ylim([0.2 0.4])
    xline(time(end));
    title(cfg.title);
    xlabel('Time (s)')
    ylabel('Accuracy')
    fig = gcf;
    saveas(fig,fullfile(dir,'group','Decoding/Within/Diag',[cfg.accFile,'.png']));
    
end