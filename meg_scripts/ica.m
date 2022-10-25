function ica(subject)
% function PreprocessingICA(subjectdata)

output_dir = strcat('..\data\',subject,'\',subject);

filename = strcat(output_dir,'_noBL_VAR.mat');


data = load(filename);
data = data.data;


% check if ICA already done
if ~exist(strcat('..\data\',subject,'\',subject,'_noBL_comp.mat'),'file')
    
    
    
    % perform the independent component analysis (i.e., decompose the data)
    cfg                 = [];
    if strcmp(subject,'sub16MF')
        cfg.runica.pca = 60;
    elseif strcmp(subject, 'sub02') || strcmp(subject, 'sub03')  
        cfg.runica.pca = 305;
    elseif strcmp(subject, 'sub19')
        cfg.runica.pca = 304;
    %elseif strcmp(subject,'sub16') %only for nonBL corrected data
     %   cfg.runica.pca = 303;
    end
    
    cfg.channel         = 'MEG';
    cfg.method          = 'runica';
    cfg.demean          = 'no';
    comp                = ft_componentanalysis(cfg,data);
    
    % save the components
    save(strcat(output_dir,'_noBL_comp'),'comp','-v7.3')
    
else 
    load(strcat(output_dir,'_noBL_comp.mat'))
end

if ~exist(strcat(output_dir,'_noBL_clean.mat'),'file') % identify EOG components    
    
    % correlate to EOG
    ET = cell2mat(data.trial);
    ET = ET(ismember(data.label, {'EOG001','EOG002'}),:);
    
    r = corr(cell2mat(comp.trial)', ET'); %get Ncomponent x 2 list of correlations with EOG channel
    [ro, i] = sort(abs(r),'descend'); %sort this list in descending order. ro is Ncomponent x 2 channel with corr values
					%and i is a Ncomponent x 2 list with indices of components in same order as ro list
    
    
    fprintf('Highest correlations: \n \t EOG001: comp %d [%.4f] \n \t EOG002: comp %d [%.4f]',i(1,1),r(i(1,1),1),i(1,2),r(i(1,2),2))
    
    if ~isempty(find(ro(1,:)<0.3,1)) % if some are below 0.3
        % manually check the components
        warning('low correlations, manually check components!')
        %return
    end
    

    % inspect these components
    figure;
    cfg                = [];
    if i(1,1) == i(1,2)
        cfg.component      = i(1,1);
    else
        cfg.component       = i(1,:);
    end
    cfg.layout = 'neuromag306all.lay';
    cfg.commment       = 'no';
    ft_topoplotIC(cfg,comp)
   
 
    
    % plot the time course
    tmp_comp = cell2mat(comp.trial);
    figure;
    nComps = length(cfg.component);
    for c = 1:nComps
        subplot(nComps,1,c);
        plot(tmp_comp(cfg.component(1,c),1:2000))
        title(sprintf('Component %d \n',cfg.component(1,c)))
    end
    drawnow
    
    %print top 10 correlations of components with EOG
    
    for j = 1:10
        disp('components')
        disp(i(j,:))
        disp('corr')
        disp(ro(j,:))
    end
    
   
    
    % decide which components to remove and save decision
    remove_comp = input('Enter the components you would like to remove in the format [a b]');
    comp_removed        = remove_comp;
   
    
    
    %view plots of all components to find heart artefacts
    %time course of the independent components
    n_total_comp = length(ro);
    pos = 1;
    figure('Units','normalized','Position',[0 0 1 1])
    for c = 1:n_total_comp
        if mod(c,40) == 0
            figure('Units','normalized','Position',[0 0 1 1])
            pos=1;
        end
        subplot(20,2,pos)
        plot(tmp_comp(c,1:2000))
        xlabel("   "+newline+"   ")
        title(sprintf('Component %d \n',c))
        pos= pos+1;
    end
    
    drawnow
    
    ecg_comp = input('Enter the component(s) with ECG artefacts');
    %plot topography to check
    figure('Units','normalized','Position',[0 0 1 1])
    cfg = [];
    cfg.component = ecg_comp;
    disp(ecg_comp)
    cfg.layout = 'neuromag306all.lay';
    cfg.commment       = 'no';
    ft_topoplotIC(cfg,comp)
    
    drawnow
    
    remove = input('Which of these components would you like to remove? Press enter if none');
    comp_removed = [comp_removed remove];
    disp('Removing the following components:')
    disp(comp_removed);
    
    % remove them from the data
    cfg = [];
    cfg.component       = comp_removed;
    cfg.demean ='no';
    data             = ft_rejectcomponent(cfg, comp, data);

    
    save(strcat(output_dir,'_noBL_comp'),'comp_removed','-append')
    

    % save the CLEAN data    
    save(strcat(output_dir,'_noBL_clean.mat'),'data','-v7.3'); clear data
    
    
    clear data comp comp_removed
else
   fprintf('\n Components already removed, clean data saved \n')

end

clear data

end


