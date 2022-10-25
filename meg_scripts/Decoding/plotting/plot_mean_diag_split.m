function plot_mean_diag_split(cfg, subjects)

    all_grad_acc = [];
    all_mag_acc = [];
    dir = '../data/results';
    load('../data/time_axis.mat');
   
    for subj =1:length(subjects)
        
        subject = convertCharsToStrings(subjects(subj));
        disp(subject)
        load(strcat('../data/results/',subject','/',cfg.accDir,'/',cfg.accFile),'mag_accuracy', 'grad_accuracy');
        
        
        all_mag_acc = [all_mag_acc mag_accuracy];
        all_grad_acc = [all_grad_acc grad_accuracy];
        clear mag_accuracy grad_accuracy
    end
    
    mean_grad_acc = mean(all_grad_acc');
    mean_mag_acc = mean(all_mag_acc');
    
    std_dev = std(all_grad_acc');
    grad_CIs = [];
    for i =1:size(all_grad_acc',2)
        
        sd = std_dev(i);
        n = size(all_grad_acc',1);
        grad_CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    std_dev = std(all_mag_acc');
    mag_CIs = [];
    for i =1:size(all_mag_acc',2)
        
        sd = std_dev(i);
        n = size(all_mag_acc',1);
        mag_CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    outputDir = fullfile('../data/results/group',cfg.accDir);
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    save(fullfile(outputDir,cfg.accFile),'mean_grad_acc','mean_mag_acc','mag_CIs','grad_CIs');
    
    grad_curve1 = mean_grad_acc+grad_CIs;
    grad_curve2 =mean_grad_acc-grad_CIs;
    x2 = [time, fliplr(time)];
    grad_inBetween = [grad_curve1, fliplr(grad_curve2)];
    
    mag_curve1 = mean_mag_acc+mag_CIs;
    mag_curve2 =mean_mag_acc-mag_CIs;
    
    mag_inBetween = [mag_curve1, fliplr(mag_curve2)];
    figure;
   
    fill(x2, grad_inBetween,'blue','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    q = plot(time, mean_grad_acc,'blue','LineWidth', 1);
    hold on;
    fill(x2, mag_inBetween,'r','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    p = plot(time, mean_mag_acc,'r', 'LineWidth', 1);
    yline(0.5,'black--');
    xlim([time(1) time(end)]);
    ylim([0.4 0.7])
    xline(time(end));
    title(cfg.title);
    xlabel('Time (s)')
    ylabel('Accuracy')
    legend([q,p],'grad','mag');
    fig = gcf;
    saveas(fig,fullfile(outputDir,[cfg.accFile,'.png']));
    
end