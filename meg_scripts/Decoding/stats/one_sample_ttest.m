function [t_s,p_s,h_s] = one_sample_ttest(cfg, subjects)


    dir = '../data/results';
    load('../data/time_axis.mat');
    
    
    outputDir = fullfile(dir,'group','stats','one_sample',cfg.accDir);
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    
%if ~exist(fullfile(outputDir,[cfg.outputName '.mat']),'file')
    
    all_acc = zeros(length(subjects),length(time),length(time));
   
    remove=false;
    if contains(cfg.accDir,'Cross')
        for subj =1:length(subjects)

            subject = convertCharsToStrings(subjects(subj));
            disp(subject)

            if strcmp(subject,'sub13') %&& contains(cfg.accFile,'PAS3') 
                remove = true;
                continue
            end
            load(strcat('../data/results/',subject','/',cfg.accDir,'/',cfg.accFile));
            
            acc = train_sq_cross_acc;
            all_acc(subj,:,:) = acc;

            
            %clear acc Accuracy

        end
    elseif contains(cfg.accDir,'Within')
        for subj =1:length(subjects)
            subject = convertCharsToStrings(subjects(subj));
            disp(subject)

            if strcmp(subject,'sub13') && contains(cfg.accFile,'3') 
                remove = true;
                continue
            end
            if contains(cfg.accFile,'square')
                Acc = load(strcat('../data/results/',subject','/',cfg.accDir,'/',cfg.accFile));
       
                 Acc = struct2cell(Acc); Acc = Acc{1};
       
        
                 all_acc(subj,:,:) = Acc;
        
        
        clear Acc
            else
            %sqAcc = load(strcat('../data/results/',subject','/',cfg.accDir,'/',cfg.accFile,'_square'), 'Accuracy');
            diAcc = load(strcat('../data/results/',subject','/',cfg.accDir,'/',cfg.accFile));
            %sqAcc = struct2cell(sqAcc); sqAcc = sqAcc{1};
            diAcc = struct2cell(diAcc); diAcc = diAcc{1};

            %temporary = zeros(2,length(time),length(time));
            %temporary(1,:,:) = sqAcc;
            %temporary(2,:,:) = diAcc;

            %all_acc(subj,:,:) = mean(squeeze(temporary));
            all_acc(subj,:,:) = diAcc;
            clear temporary
            end
        end
    end

    
    if remove
            all_acc(12,:,:) = [];
    end
    
    all_diags = zeros(size(all_acc,1),length(time));
    for i = 1:size(all_acc,1)
        all_diags(i,:) = diag(squeeze(all_acc(i,:,:)));
    end
    
    
    
    t_s = zeros(1,length(time));
    p_s = zeros(1,length(time));
    h_s = zeros(1,length(time));
    
    
    for subj = 1:size(all_diags,2)
       
       [h,p,~,stats] = ttest(all_diags(:,subj),0.25);
       
       t = stats.tstat;
       
       t_s(subj) = t;
       p_s(subj) = p;
       h_s(subj) = h;
    end
    


%else
 %    load(fullfile(outputDir,[cfg.outputName '.mat']));
%end   
  
    if cfg.plot
        figure;
        std_dev = std(all_diags);
    
        

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
        hold on;
        x1 = NaN;
        x1s =[];
        
        for h = 1:length(h_s)
           if h_s(h) == 1 && isnan(x1)
               x1 = h;
               x1s = [x1s x1];
               continue;
           end
           
           if h_s(h) == 0 && ~isnan(x1)
              
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
        
        
        xlim([time(1) time(end)]);
        ylim([0.2 0.4])
        xline(time(end));
        title(cfg.title);
        xlabel('Time (s)')
        ylabel('Accuracy')
        fig = gcf;
        saveas(fig,fullfile(dir,'group','Decoding/Within/Diag',[cfg.accFile,'.png']));
    

end
    
    
    save(fullfile(outputDir,cfg.outputName),'h_s','p_s','t_s','all_diags');


    
end

