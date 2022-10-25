function plot_mean_temp(cfg, subjects)

    
    dir = '../data/results';
    load('../data/time_axis.mat');
    
    all_acc = zeros(length(subjects),length(time),length(time));
    remove=false;
    for subj =1:length(subjects)
        
        subject = convertCharsToStrings(subjects(subj));
        disp(subject)
        
        if strcmp(subject,'sub13') && contains(cfg.accFile,'PAS3') 
            remove = true;
            
            continue
        end
        load(strcat('../data/results/',subject','/',cfg.accDir,'/',cfg.accFile), 'Accuracy');
        acc = Accuracy;
        
        all_acc(subj,:,:) = acc;
        
        clear acc Accuracy
    end
    
    if remove
            all_acc(12,:,:) = [];
            
    end
    num_subjects = size(all_acc,1);
    
    mean_acc = squeeze(mean(all_acc,1));
   
    outputDir = fullfile(dir,'group',cfg.accDir);
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    save(fullfile(outputDir,cfg.accFile),'mean_acc');
    
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
    
    
    %plot diagonal of accuracy matrix
    figure;
    all_diags = zeros(num_subjects,length(time));
    for i = 1:size(all_acc,1)
        all_diags(i,:) = diag(squeeze(all_acc(i,:,:)));
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