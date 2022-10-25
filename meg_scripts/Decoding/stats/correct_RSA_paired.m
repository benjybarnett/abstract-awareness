function [pVals] = correct_RSA_paired(cfg,subjects)


dir = '../data/results'; load('../data/time_axis.mat');
 
   
    rhos_1s = [];
    rhos_2s = [];
    dir = '../data/results';
    load('../data/time_axis.mat');
   
    time = time(1:550);
    for subj =1:length(subjects)
        
        subject = subjects{subj};
        disp(subject)
        
        
        if cfg.regressed == true
        rhos_1 = load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file{1},'regressed','rhos_no_diag.mat'));
        rhos_2 = load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file{2},'regressed','rhos_no_diag.mat'));
        elseif cfg.noBL == true
        disp('loading baseline no corrected data')
        rhos_1 = load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file{1},'noBL','rhos_no_diag.mat'));
        rhos_2 = load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file{2},'noBL','rhos_no_diag.mat'));
        load('noBL_time.mat')
        time = noBL_time(1:620);
        else
        rhos_1 = load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file{1},'frontal_sensors','rhos_no_diag.mat'));
        rhos_2 = load(fullfile('../data/results/',subject,'RSA',cfg.mRDM_file{2},'frontal_sensors','rhos_no_diag.mat'));
        %rhos_2 = load(fullfile('../data/results/',subject,'RSA','Control','avg_shuf_rhos.mat'));
        
        end  

        rhos_1 = rhos_1.rhos;
        rhos_2 = rhos_2.rhos;
        %rhos_2 = rhos_2.avg_shuf_rhos;
        disp(size(rhos_1))
        
        if cfg.noBL 
        rhos_1s = [rhos_1s; rhos_1(1:620)];
        rhos_2s = [rhos_2s; rhos_2(1:620)];       
        else
        rhos_1s = [rhos_1s; rhos_1(1:550)];
        rhos_2s = [rhos_2s; rhos_2(1:550)];
        end

        

        clear rhos
    end
    
cfgS = [];cfgS.paired = true;cfgS.tail= 'two'; cfgS.indiv_pval = 0.05; cfgS.cluster_pval = 0.05;
disp(size(rhos_1s))

pVals= cluster_based_permutationND(rhos_1s,rhos_2s,cfgS);
%save(fullfile('../data/results/group/stats/one_sample/Decoding/Within/Temporal/multiclass/',['pVals_',cfg.diFile]),'pVals_onesamp_di')

%disp(pVals)

%plot

if cfg.plot

    %{
    begin_sig = 0;
    for p = 1:length(pVals)
        if pVals(p) < 1
            begin_sig = p;
            break
        end
    end
    end_sig = 550;
    %}
    idxs = 1:1:550;
    pVals = pVals(1:550);
    if length(unique(pVals))>1
        sigIdxs = idxs(pVals ~=1);
        begin_sig = sigIdxs(1);
        end_sig = sigIdxs(end);
        disp(begin_sig)
        disp(end_sig)
        
        
        x1=NaN;x1s=[];x2s = [];
    
        diago = pVals;
        
        
        for h = 1:length(diago)
               if diago(h) ~= 1 && isnan(x1)
                   x1 = h;
                   x1s = [x1s x1];
                   disp('hi')
                   continue;
               end
               
               if diago(h) == 1 && ~isnan(x1)
                   disp('ggg')
                   x2 = h-1;
                   x2s = [x2s x2];
                   %plot([time(x1),time(x2)], [cfg.sig_height,cfg.sig_height],'Color',cfg.linecolor,'Marker','*');
                   hold on;
                   x1 = NaN;
                   continue
               end
               
        end
        
        for i = 1:length(x1s)
            disp('h')
            %x1 is starting point of sig line
            try
                line1 = time(x1s(i)):0.1:time(x2s(i));
                line2 = time(x1s(i))+0.05:0.1:time(x2s(i));
                
            catch
                
                line1 = time(x1s(i)):0.1:time(end);
                line2 = time(x1s(i))+0.05:0.1:time(end);
            end
            
            scatter(line1, repmat(cfg.sig_height,[1,size(line1,2)]),7,'MarkerFaceColor',cfg.linecolor{1},'MarkerEdgeColor',cfg.linecolor{1});
            scatter(line2, repmat(cfg.sig_height,[1,size(line2,2)]),7,'MarkerFaceColor',cfg.linecolor{2},'MarkerEdgeColor',cfg.linecolor{2});
            
            
    
        
      
            
        end
    end

end
end