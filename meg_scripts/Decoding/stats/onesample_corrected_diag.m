function [pVals_onesamp_low,pVals_onesamp_high] = onesample_corrected_diag(cfg,subjects)


dir = '../data/results'; load('../data/time_axis.mat');
 
   
remove=false;
low_acc = zeros(length(subjects),length(time(1:550)));
high_acc=zeros(length(subjects),length(time(1:550)));
for subj =1:length(subjects)

    subject = convertCharsToStrings(subjects(subj));
    disp(subject)

    if strcmp(subject,'sub13') 
        remove = true;
        continue
    end 

    %discrimination decoding
    low_acc_ = load(strcat('../data/results/',subject','/',cfg.withinDir,'/',cfg.lowFile));
    low_acc_ = low_acc_.Accuracy;
    high_acc_ = load(strcat('../data/results/',subject','/',cfg.withinDir,'/',cfg.highFile));
    high_acc_ = high_acc_.Accuracy;


    low_acc(subj,:) = low_acc_(1:550,:);
    high_acc(subj,:) = high_acc_(1:550,:);
   
  
end
if remove
       low_acc(12,:,:) = [];
       high_acc(12,:,:) = [];
end



cfgS = [];cfgS.paired = false;cfgS.tail= 'one'; cfgS.indiv_pval = 0.05; cfgS.cluster_pval = 0.05;
disp(size(high_acc))
disp(size(low_acc))

pVals_onesamp_low = cluster_based_permutationND(low_acc,0.5,cfgS);
save(fullfile('../data/results/group/stats/one_sample/Decoding/Discrimination/',['pVals_',cfg.lowFile]),'pVals_onesamp_low')

pVals_onesamp_high = cluster_based_permutationND(high_acc,0.5,cfgS);
save(fullfile('../data/results/group/stats/one_sample/Decoding/Discrimination/',['pVals_',cfg.highFile]),'pVals_onesamp_high')


%plot
if cfg.plot


%diagonals
%plot diagonal of accuracy matrix
    time = time(1:550);
    figure;
    num_subjects = size(low_acc,1);
    all_diags = low_acc;
    std_dev = std(all_diags);
    
    disp(all_diags(10))

    
    diag_acc = mean(all_diags);
   
    diag_acc = diag_acc(:,1:550); %cut off last chunk

    CIs = [];
    for i =1:size(diag_acc,2)
        
        sd = std_dev(i);
        n = size(all_diags,1);
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    curve1 = diag_acc+CIs;
    curve2 =diag_acc-CIs;
    
    x2 = [time(1:550), fliplr(time(1:550))];
    
    
    inBetween = [curve1, fliplr(curve2)];
   
    diag_acc = smoothdata(diag_acc,'gaussian',5); %smooth for plotting

    fill(x2, inBetween,'b', 'FaceColor',[67 146 241]/255,'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time(1:550),diag_acc,'Color', [67 146 241]/255, 'LineWidth', 1);
    yline(0.5,'black--');
    xlim([time(1) time(end)]);
    ylim([0.4 0.65])
    xticks([0 0.5 1 1.5 2])
    xline(time(end));
    xlabel('Time (s)')
    ylabel('Accuracy')
    fig = gcf;
    hold on;
     x1 = NaN;
        x1s =[];
    %sig points on diag
    diago = pVals_onesamp_low;
    for h = 1:length(diago)
           if diago(h) ~= 1 && isnan(x1)
               x1 = h;
               x1s = [x1s x1];
               disp('hi')
               continue;
           end
           
           if diago(h) == 1 && ~isnan(x1)
              
               x2 = h-1;
               line([time(x1),time(x2)], [0.435,0.435],'Color','black');
               hold on;
               x1 = NaN;
               continue
           end
           
    end
    if ~ isnan(x1)
        line([time(x1),time(end)], [0.435,0.435],'Color','black');
    end
        

    %diag for high visibility trials i.e. PAS 3 and 4
     %figure;
    num_subjects = size(high_acc,1);
    all_diags = high_acc;
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
   
    diag_acc = smoothdata(diag_acc,'gaussian',5); %smooth for plotting
   
    fill(x2, inBetween,'b', 'FaceColor',[166 38 57]/255,'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,diag_acc,'Color', [166 38 57]/255, 'LineWidth', 1);
    yline(0.5,'black--');
    xlim([time(1) time(end)]);
    ylim([0.4 0.65])
    xticks([0 0.5 1 1.5 2])
    xline(time(end));
    xlabel('Time (s)')
    ylabel('Accuracy')
    fig = gcf;
    hold on;
     x1 = NaN;
        x1s =[];
    %sig points on diag
    diago = pVals_onesamp_high;
    for h = 1:length(diago(1:550))
           if diago(h) ~= 1 && isnan(x1)
               x1 = h;
               x1s = [x1s x1];
               disp('hi')
               continue;
           end
           
           if diago(h) == 1 && ~isnan(x1)
              
               x2 = h-1;
               line([time(x1),time(x2)], [0.435,0.435],'Color',[166 38 57]/255,'LineWidth',2);
               hold on;
               x1 = NaN;
               continue
           end
           
    end
    if ~ isnan(x1)
        line([time(x1),time(end)], [0.435,0.435],'Color',[166 38 57]/255,'LineWidth',2);
    end
        
end

end
    