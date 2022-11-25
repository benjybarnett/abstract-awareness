function  plot_mean_RSA(cfg, subjects)
    all_rho = [];
    dir = '../data/results';
    load('../data/time_axis.mat');
   
    time = time(1:550);
    for subj =1:length(subjects)
        
        subject = subjects{subj};
        disp(subject)
        
        if cfg.regressed == false
        load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file,'rhos_no_diag.mat'));
        elseif cfg.regressed == true
        load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file,'regressed','rhos_no_diag.mat'));
        end

        
        
        all_rho = [all_rho; rhos(1:550)];
        clear rhos
    end
    
    disp(size(all_rho))
    mean_rho = mean(all_rho,1);
    
    std_dev = std(all_rho,1);
    CIs = [];
    for i =1:size(all_rho,2)
        sd = std_dev(i);
        n = size(all_rho,1);
        
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    disp(size(CIs))
    
    if cfg.regressed == false
    outputDir = fullfile('../data/results/group','RSA',cfg.mRDM_file);
    elseif cfg.regressed == true
    outputDir = fullfile('../data/results/group','RSA','regressed',cfg.mRDM_file);
    end

    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    save(fullfile(outputDir),'mean_rho','CIs');
    
    
    curve1 = mean_rho+CIs;
    curve2 =mean_rho-CIs;
    x2 = [time, fliplr(time)];
    
    
    
    inBetween = [curve1, fliplr(curve2)];
    %figure;
   
    fill(x2, inBetween,'b', 'FaceColor',cfg.shadecolor,'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time, mean_rho,'Color', cfg.linecolor, 'LineWidth', 1);
    xline(0,'black--');
    yline(0,'black--');
    xlim([time(1) time(end)]);
    ylim([-0.1 0.5])
    xline(time(end));
    
    
    %title(cfg.title);
    xlabel('Time (s)')
    ylabel("Dissimilarity Correlation (Kendall's Tau)")
    fig = gcf;
    saveas(fig,fullfile(outputDir,['RSA','.png']));
    
end
