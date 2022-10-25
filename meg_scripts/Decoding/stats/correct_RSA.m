function [pVals] = correct_RSA(cfg,subjects)


dir = '../data/results'; load('../data/time_axis.mat');
 
   
all_rho = [];

    time = time(1:550);
    for subj =1:length(subjects)
        
        subject = subjects{subj};
        disp(subject)
        
        if cfg.regressed == true
        load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file,'regressed','rhos_no_diag.mat'));
        elseif cfg.noBL == true
        disp('loading no baseline corrected data')
        load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file,'noBL','rhos_no_diag.mat'));  
        load('noBL_time.mat')
        time = noBL_time(1:614)+0.025;
        else
        load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file,'frontal_sensors','rhos_no_diag.mat'));
        end
        %rhos = load(fullfile('../data/results/',subject,'RSA','Control','avg_shufGrad_rhos.mat'));
        %rhos = rhos.avg_shufGrad_rhos;
        if cfg.noBL 
            all_rho = [all_rho; rhos(1:614)];
        else
            all_rho = [all_rho; rhos(1:550)];
        end
        clear rhos
    end
    
cfgS = [];cfgS.paired = false;cfgS.tail= 'one'; cfgS.indiv_pval = 0.05; cfgS.cluster_pval = 0.05;
disp(size(all_rho))

pVals= cluster_based_permutationND(all_rho,0,cfgS);
%save(fullfile('../data/results/group/stats/one_sample/Decoding/Within/Temporal/multiclass/',['pVals_',cfg.diFile]),'pVals_onesamp_di')

disp(size(pVals))

%plot
if cfg.plot

%diagonals
%plot diagonal of accuracy matrix
    
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
    ylim([-0.25 0.6])
    %xticks([0 0.5 1 1.5]);
    xticks([-0.4 0 0.4 0.8 1.2 1.6]);xticklabels({-0.4 0 0.4 0.8 1.2 1.6})
    xlabel('Time (s)')
    ylabel("Dissimilarity Correlation (Kendall's Tau)")
    xline(time(end));
    x1=NaN;x1s=[];x2s = [];
    %sig points on diag
    diago = pVals;
    for h = 1:length(diago)
           if diago(h) ~= 1 && isnan(x1)
               x1 = h;
               x1s = [x1s x1];
               disp('hi')
               continue;
           end
           
           if diago(h) == 1 && ~isnan(x1)
              
               x2 = h-1;
               x2s = [x2s x2];
               %line([time(x1),time(x2)], [cfg.sig_height,cfg.sig_height],'Color',cfg.linecolor,'LineWidth', 2);
               hold on;
               x1 = NaN;
               continue
%            end
           
    end
    for i = 1:length(x1s)
        try
            line([time(x1s(i)),time(x2s(i))], [cfg.sig_height,cfg.sig_height],'Color',cfg.linecolor,'LineWidth', 2);
        catch 
            line([time(x1s(i)),time(end)], [cfg.sig_height,cfg.sig_height],'Color',cfg.linecolor,'LineWidth', 2);

        end
        

    
  
        
    end

end
end
    