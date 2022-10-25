function confusion_plots(cfg,subjects)


    dir = '../data/results'; load('../data/time_axis.mat');


    remove=false;
    diag_conf_di = zeros(length(subjects),550,4,4);
    diag_conf_sq = zeros(length(subjects),550,4,4);
    for subj =1:length(subjects)

        subject = convertCharsToStrings(subjects(subj));
        disp(subject)

        if strcmp(subject,'sub13') 
            remove = true;
            continue
        end

        %cross

        load(strcat('../data/results/',subject','/',cfg.confDir,'/',cfg.diFile));
        load(strcat('../data/results/',subject','/',cfg.confDir,'/',cfg.sqFile));

        for train_point = 1:size(train_di_cross_acc,1)

            diag_conf_di(subj,train_point,:,:) = train_di_cross_acc(train_point,:,:,train_point);
            diag_conf_sq(subj,train_point,:,:) = train_sq_cross_acc(train_point,:,:,train_point);

        end

    end
    if remove
           diag_conf_di(12,:,:,:) = [];
           sq_conf_di(12,:,:,:) = [];
    end

    
    %%%%DIAMONDS%%%%%%%%%%
    
    %confidence intervals
    std_dev = std(diag_conf_di,1);
   

    CIs = [];
    for i =1:size(diag_conf_di,2)
        sd = std_dev(i);
        n = size(diag_conf_di,1);
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    %average confusion matrices 
    di_conf_grp = squeeze(mean(diag_conf_di,1));
    sq_conf_grp = squeeze(mean(diag_conf_sq,1));
    
    %the confusion matrices above are dim [550 x 4 x 4]
    %they have a 4 x 4 confusion matrix for every time point
    %each row is the true label and each column corresponds to the label
    %predicted by the classifier. The (i,j)-th element of the matrix
    %specifies how often class i has been classified as class j. The
    %Diagonal contains correctly classified cases.
    
    %per decoder, we want four plots, one for each PAS rating. In each of
    %those plots, there will be four lines plotting the proportion of
    %trials classified as each PAS rating (i.e. one line for correct
    %classifications and three for incorrect)
    
    time = time(1:10:550);
    titles = {'NE','BG','ACE','CE'};
    for true_class = 1:size(di_conf_grp,2)
       
        
        
        %each loop will be a new plot
        %choose evry 10th element for smoothing
        PAS_1 = di_conf_grp(1:10:550,true_class,1);
        PAS_2 = di_conf_grp(1:10:550,true_class,2);
        PAS_3 = di_conf_grp(1:10:550,true_class,3);
        PAS_4 = di_conf_grp(1:10:550,true_class,4);
        conditions = {PAS_1; PAS_2;PAS_3; PAS_4};

        f = figure;
        f.Position = [200 300 250 350];
        
        curve1 = cell2mat(conditions(true_class))'+CIs(1:10:550);
        curve2 =cell2mat(conditions(true_class))'-CIs(1:10:550);
        x2 = [time, fliplr(time)];
        inBetween = [curve1, fliplr(curve2)];
        
        ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],	[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560]};		
        f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
        f.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hold on;
        chance = yline(0.25,'--','LineWidth', 1.4,'Color','black');
        chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
        
        plot(time,PAS_1,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
        plot(time,PAS_2,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
        plot(time,PAS_3,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
        plot(time,PAS_4,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
      
        xlim([min(time),max(time)])
        ylim([0.1 0.4])
        
        if true_class == 1
            [pos,hobj,~,~] = legend('NE', 'BG', 'ACE', 'CE');
            hl = findobj(hobj,'type','line');
            set(hl,'LineWidth',3);
            ht = findobj(hobj,'type','text');
            set(ht,'FontSize',6);
            set(ht,'FontName','Arial');
            set(pos,'position',[0.705 0.175 0.1 0.1])
        end
       
        xlabel('Time (seconds)','FontName','Arial')
        ylabel('Proportion Classified','FontName','Arial')
        title(titles(true_class),'FontName','Arial')
        mkdir(fullfile(dir,'group',cfg.outputDir))
        saveas(f,char(fullfile(dir,'group',cfg.outputDir,strcat(titles(true_class),'_diamonds.png'))))
    end

   
    
    
    %%%%Squares%%%%%%%%%%
    
    %confidence intervals
    std_dev = std(diag_conf_sq,1);
   

    CIs = [];
    for i =1:size(diag_conf_sq,2)
        sd = std_dev(i);
        n = size(diag_conf_sq,1);
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    %average confusion matrices 
    sq_conf_grp = squeeze(mean(diag_conf_sq,1));
    
    for true_class = 1:size(sq_conf_grp,2)
       
        
        
        %each loop will be a new plot
        %choose evry 10th element for smoothing
        PAS_1 = sq_conf_grp(1:10:550,true_class,1);
        PAS_2 = sq_conf_grp(1:10:550,true_class,2);
        PAS_3 = sq_conf_grp(1:10:550,true_class,3);
        PAS_4 = sq_conf_grp(1:10:550,true_class,4);
        conditions = {PAS_1; PAS_2;PAS_3; PAS_4};

        f = figure;
        f.Position = [200 300 250 350];
        
        curve1 = cell2mat(conditions(true_class))'+CIs(1:10:550);
        curve2 =cell2mat(conditions(true_class))'-CIs(1:10:550);
        x2 = [time, fliplr(time)];
        inBetween = [curve1, fliplr(curve2)];
        
        f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
        f.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hold on;
        chance = yline(0.25,'--','LineWidth', 1.4,'Color','black');
        chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
        
        plot(time,PAS_1,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
        plot(time,PAS_2,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
        plot(time,PAS_3,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
        plot(time,PAS_4,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
      
        xlim([min(time),max(time)])
        ylim([0.1 0.4])
        
        if true_class == 1
            [pos,hobj,~,~] = legend('NE', 'BG', 'ACE', 'CE');
            hl = findobj(hobj,'type','line');
            set(hl,'LineWidth',3);
            ht = findobj(hobj,'type','text');
            set(ht,'FontSize',6);
            set(ht,'FontName','Arial');
            set(pos,'position',[0.705 0.175 0.1 0.1])
        end
       
        xlabel('Time (seconds)','FontName','Arial')
        ylabel('Proportion Classified','FontName','Arial')
        title(titles(true_class),'FontName','Arial')
        mkdir(fullfile(dir,'group',cfg.outputDir))
        saveas(f,char(fullfile(dir,'group',cfg.outputDir,strcat(titles(true_class),'_squares.png'))))
    end
   

end