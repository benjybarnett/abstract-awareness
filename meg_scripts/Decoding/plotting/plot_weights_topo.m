function plot_weights_topo(cfg, subjects)

    dir = '../data/results';
    

    all_weights = zeros(length(subjects),306);
    load('neuromag_sensor_labels.mat')
    remove = false;
    for subj =1:length(subjects)
        
        subject = convertCharsToStrings(subjects(subj));
        disp(subject)
        
        if strcmp(subject,'sub13') && contains(cfg.weightFile,'PAS3')  
            remove = true;
            continue
        end
        load(strcat('../data/results/',subject','/',cfg.weightDir,'/',cfg.weightFile));
        all_weights(subj,:) = abs(weights);
        clear weights
        
    end
    
    if remove
        all_weights(12,:) = [];
    end
    
    avg_weights = mean(all_weights,1);
    data = [];
    data.label = labels;
    data.time = 0;
    data.dimord = 'chan_time';
    data.weights = avg_weights';
  
    
    cfgS=[];
   
    grad_data_c = ft_combineplanar(cfgS,data); %combine gradiometers
   
    
    figure('Position', [10 10 1250 400])
    
    subplot(1,2,1)
    cfgS = [];
    cfgS.xlim ='maxmin';
    cfgS.zlim = [1.4e-12 4.5e-12];
    cfgS.layout = 'neuromag306cmb.lay';
    cfgS.channel = 'MEGGRAD';
    cfgS.parameter = 'avg'; 
    ft_topoplotER(cfgS,grad_data_c); colorbar
    title('Gradiometers')
    
    subplot(1,2,2)
    cfgS = [];
    cfgS.xlim ='maxmin';
    cfgS.zlim = [0.4e-13 3e-13];
    cfgS.layout = 'neuromag306all.lay';
    cfgS.channel = 'MEGMAG';
    cfgS.parameter = 'weights'; 
    ft_topoplotER(cfgS,data); colorbar
    title('Magnetometers')
 
    sgtitle(cfg.title);
    
    

end