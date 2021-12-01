function  pval =  roi_RSA_vis(cfg)


    for subj = 1:length(cfg.subjects)
        
        subject = cfg.subjects{subj};

        disp(subject);
        data_dir = cfg.data_dir;
        beta_path = strcat(data_dir,subject,'\');

        % set random generator for repeatability
        rng(1,'twister')

        % load roi mask
        [hdr,mask]    = read_nii(fullfile(cfg.roi_path,cfg.roi_file));

        %% Get the data
        % load SPM file
        SPM = load(strcat(data_dir,subject,'\SPM.mat'));
        SPM = SPM.SPM;
        
        % get conscious betas
        conIdx = find(contains(SPM.xX.name,'Sn(1) conscious') );
        trials = SPM.xX.name(conIdx);
        
        %% create neural RDM
       
        disp('visibility included in model')
        fish_low = [];
        rooster_low = [];
        ball_low = [];
        can_low = [];
        fish_high = [];
        rooster_high = [];
        ball_high = [];
        can_high = [];

        %get med split value for visibility ratings
        med = getMedSplit(subject,data_dir);

        for trl = 1:length(trials)
            trial = trials(trl);
            trial = reverse(char(trial));


            if trial(12) == '1' && str2double(trial(7)) < med
                rooster_low = [rooster_low trl]; %get index of all rooster trials
            elseif trial(12) == '1' && str2double(trial(7)) >= med
                rooster_high = [rooster_high trl];
            elseif trial(12) == '2' && str2double(trial(7)) < med
                fish_low = [fish_low trl]; %get index of all rooster trials
            elseif trial(12) == '2' && str2double(trial(7)) >= med
                fish_high = [fish_high trl];
            elseif trial(12) == '3' && str2double(trial(7)) < med
                ball_low = [ball_low trl]; %get index of all rooster trials
            elseif trial(12) == '3' && str2double(trial(7)) >= med
                ball_high = [ball_high trl];    
            elseif trial(12) == '4' && str2double(trial(7)) < med
                can_low = [can_low trl]; %get index of all rooster trials
            elseif trial(12) == '4' && str2double(trial(7)) >= med
                can_high = [can_high trl]; 
            end
        end  

         %load Beta files
        Betas=[];
        for t = 1:length(conIdx)
            [~,beta] = read_nii(fullfile(beta_path,sprintf('beta_%04d.nii',conIdx(t))));
            Betas(t,:) = beta(mask>0);
        end
        Betas(:,isnan(Betas(1,:))) = []; %remove NaNs

        mean_rooster_low = mean(Betas(rooster_low,:),1);
        mean_rooster_high = mean(Betas(rooster_high,:),1);
        mean_fish_low = mean(Betas(fish_low,:),1);
        mean_fish_high = mean(Betas(fish_high,:),1);
        mean_ball_low = mean(Betas(ball_low,:),1);
        mean_ball_high = mean(Betas(ball_high,:),1);
        mean_can_low = mean(Betas(can_low,:),1);
        mean_can_high = mean(Betas(can_high,:),1);


        %correlate
        all_stims = zeros(8,length(mean_fish_high));
        all_stims(1,:) = mean_fish_low;
        all_stims(2,:) = mean_rooster_low;
        all_stims(3,:) = mean_ball_low;
        all_stims(4,:) = mean_can_low;
        all_stims(5,:) = mean_fish_high;
        all_stims(6,:) = mean_rooster_high;
        all_stims(7,:) = mean_ball_high;
        all_stims(8,:) = mean_can_high;
        corrs = pdist(all_stims,'correlation');
        nRDM = squareform(corrs);

        
        %save neural rdm
        outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},cfg.roi,cfg.model);
        if ~exist(outputDir,'dir'); mkdir(outputDir); end
        save(fullfile(outputDir,'neuralRDM.mat'),'nRDM')
        
        % Model RDM
        mRDM = load(strcat(data_dir,cfg.modelRDM));
        mRDM = mRDM.rdm;
        
        % Correlate neural RDM with model RDM
        nRDM_flat = reshape(nRDM,1,[])';
        mRDM_flat = reshape(mRDM,1,[])';
        
        rho = corr(nRDM_flat,mRDM_flat,'Type','Kendall');
        save(fullfile(cfg.output_dir,cfg.subjects{subj},cfg.roi,cfg.model,'true_rho.mat'),'rho');
        
       
   

        %% permutations with label swapping
        perm_rhos=[];
        for per = 1:cfg.nPerm
            %shuffle labels

            all_stims = NaN(8,max([length(rooster_high),...
                length(rooster_low),...
                length(fish_high),...
                length(fish_low),...
                length(ball_high),...
                length(ball_low),...
                length(can_high),...
                length(can_low)]));
                
            all_stims(1,1:length(rooster_low)) =rooster_low;
            all_stims(2,1:length(fish_low)) = fish_low;
            all_stims(3,1:length(can_low)) = can_low;
            all_stims(4,1:length(ball_low)) = ball_low;
            all_stims(5,1:length(rooster_high)) =rooster_high;
            all_stims(6,1:length(fish_high)) = fish_high;
            all_stims(7,1:length(can_high)) = can_high;
            all_stims(8,1:length(ball_high)) = ball_high;
            shuff_labels = randswap(all_stims,'full'); 


            mean_rooster_high = mean(Betas(rmmissing(shuff_labels(1,:)),:),1);
            mean_fish_high = mean(Betas(rmmissing(shuff_labels(2,:)),:),1);
            mean_can_high = mean(Betas(rmmissing(shuff_labels(3,:)),:),1);
            mean_football_high = mean(Betas(rmmissing(shuff_labels(4,:)),:),1);
            mean_rooster_low = mean(Betas(rmmissing(shuff_labels(1,:)),:),1);
            mean_fish_low = mean(Betas(rmmissing(shuff_labels(2,:)),:),1);
            mean_can_low = mean(Betas(rmmissing(shuff_labels(3,:)),:),1);
            mean_football_low = mean(Betas(rmmissing(shuff_labels(4,:)),:),1);

            %correlate
            all_stims = zeros(8,length(mean_fish_high));
            all_stims(1,:) = mean_fish_low;
            all_stims(2,:) = mean_rooster_low;
            all_stims(3,:) = mean_football_low;
            all_stims(4,:) = mean_can_low;
            all_stims(5,:) = mean_fish_high;
            all_stims(6,:) = mean_rooster_high;
            all_stims(7,:) = mean_football_high;
            all_stims(8,:) = mean_can_high;
            corrs = pdist(all_stims,'correlation');
            nRDM = squareform(corrs);


            % Model RDM
            mRDM = load(strcat(data_dir,cfg.modelRDM));
            mRDM = mRDM.rdm;

            % Correlate neural RDM with model RDM
            nRDM_flat = reshape(nRDM,1,[])';
            mRDM_flat = reshape(mRDM,1,[])';

            rho = corr(nRDM_flat,mRDM_flat,'Type','Kendall');
            perm_rhos = [perm_rhos rho];


        end
        
        %save rsa permutation results for each subject
        outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},cfg.roi,cfg.model);
        if ~exist(outputDir,'dir'); mkdir(outputDir); end
        save(fullfile(outputDir,'rsa_null_dist.mat'),'perm_rhos')
    end

    %% Bootstrap to create group level null distribution
    % loading permutations
    rho_perm = []; 
    for subj = 1:length(cfg.subjects)

        outputDir = fullfile(cfg.output_dir,cfg.subjects{subj},cfg.roi,cfg.model);

        if exist(fullfile(outputDir,'rsa_null_dist.mat'),'file')

            fprintf('Loading subj %d \n',subj)
            load(fullfile(outputDir,'rsa_null_dist.mat'),'perm_rhos')

            for p = 1:cfg.nPerm

                rho_perm(subj,p) = perm_rhos(p);
                         

            end        

           % clear perm_rhos

        else 
            fprintf('Sub %d not enough trials \n',subj)
        end
    end
    
    % creating bootstrapped null distribution 
    rho_btstrp = nan(cfg.nBtrsp,1);
    nSubs = size(rho_perm,1);
    for b = 1:cfg.nBtrsp

        if mod(b,100)==0; fprintf('\t Bootstrapping %d out of %d \n',b, cfg.nBtrsp); end

        rho = [];
        for s = 1:nSubs
            perm = randi(cfg.nPerm);
            rho = cat(2,rho,squeeze(rho_perm(s,perm)));
            
        end
        rho_btstrp(b) = nanmean(rho,2);
      
    end
    
    % compare to empirical distribution 
    emp_dist = [];
    for subj = 1:length(cfg.subjects)
        subject = cfg.subjects{subj};
        
        true_rho = load(fullfile(cfg.output_dir,cfg.subjects{subj},cfg.roi,cfg.model,'true_rho.mat'));
        emp_dist = [emp_dist true_rho.rho];
    end
    
    
    pval = sum(rho_btstrp > nanmean(emp_dist))/cfg.nBtrsp;
   
    fprintf('\t RSA within the %s ROI has a p value  of %d \n',cfg.roi,pval);
    
    %save the null distribution
    if ~exist(fullfile(cfg.output_dir,'Group',cfg.roi,cfg.model),'dir'); mkdir(fullfile(cfg.output_dir,'Group',cfg.roi,cfg.model)); end
    save(fullfile(cfg.output_dir,'Group',cfg.roi,cfg.model,'Group_Null_Distribution.mat'),'rho_btstrp')

    
end

