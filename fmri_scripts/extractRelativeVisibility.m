%This script extracts the distribution of visibility ratings for each
%subject for animate and inamiate stimulus types. 
%These ratings can be from 1-4. We binarise it by performing a median split
%on the ratings (i.e. eveyrthing below median is low vis, anything equal or
%above the median is high vis)
%We check to see if there are
%atleast 10 trials in the low visibility and high visibility class. If
%there are less than 10 we must exclude this subject


subjs = {'S01'
        'S02'
        'S03'
        'S04'
        'S05'
        %'S06'
        %'S07'
        'S08'
        'S09'
        'S10'
        'S11'
        %'S12'
        'S13'
        'S14'
        'S15'
        'S16'
        'S17'
        %'S18'
        'S19'
        %'S20'
        'S21'
        'S22'
        'S23'
        'S24'
        'S25'
        'S26'
        'S27'
        %'S28'
        'S29'
        'S30'
        'S31'
        'S32'
        'S35'
        'S36'
        'S37'};
    
 
data_dir = 'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\';
output_dir =  'D:\bbarnett\Documents\ecobrain\fmri\fmri_data\visibility_rating_distributions\relative\median_split\';
count=0;
anim_low = [];
anim_high = [];
inanim_low = [];
inanim_high = [];
for subj = 1:length(subjs)
    
    fig = figure();
    
    subject = subjs{subj};
    
    SPM = load(strcat(data_dir,subject,'\SPM.mat'));
    SPM=SPM.SPM;
    

    %select only cnscious trials
    trials = {};
    for trl = 1:length(SPM.xX.name)
        if contains(SPM.xX.name(trl),' conscious')
            trials = [trials SPM.xX.name(trl)];
        end
    end

     

    all_ratings = [];

    for trial = 1:length(trials) %loop through trials to add up different visibility ratings

        trl = reverse(char(trials(trial)));
        if trl(7) == '1'
            all_ratings = [all_ratings 1];
        elseif trl(7) =='2'
            all_ratings = [all_ratings 2];
        elseif trl(7) == '3'
            all_ratings = [all_ratings 3];
        elseif trl(7) == '4'
            all_ratings = [all_ratings 4];
        else 
            disp(trl(7));
        end
    end

    med = median(all_ratings); %get median for split
  
    
    %split stims into animate and inanimate categories
    anim = {};
    inanim = {};
    
    for trial = 1:length(trials)
        trl = reverse(char(trials(trial)));
        if trl(12) == '1'
            anim = [anim char(trials(trial))];
        elseif trl(12) == '2'
            anim = [anim char(trials(trial))];
        elseif trl(12) == '3'
            inanim = [inanim char(trials(trial))];
        elseif trl(12) == '4'
            inanim = [inanim char(trials(trial))];
        else
            disp(char(trials(trial)));
        end
    end
    
    
    stims = {anim,inanim};
    stim_groups = {'animate','inanimate'};
    prev=false; %use this for counting number of subjects to exclude (i.e. who has < 10 trials in a stim class despite this process)
    
    anim_dist = [0 0]; %distribution of visual rating score for animate stims
    inanim_dist = [0 0]; %distribution of visual rating score for inanimate stims
    
    dists = {};
    
    relative = false; %are we using relative visual rating score?
    
    for stim = 1:length(stims) %loop through stim type (i.e. animate, inanimate)

        trials = stims(stim);
        trials = trials{1};
            
        vis_ratings_bin = [0,0];% binary distribution (i.e. low visibility, high visibility)
        
        for trial = 1:length(trials) %loop through trials to add up different visibility ratings

            trl = reverse(char(trials(trial)));
            if str2double(trl(7)) < med %if rating less than median rating
                vis_ratings_bin(1) = vis_ratings_bin(1)+1;  %add 1 to the low vis count
            elseif str2double(trl(7)) >= med %if rating equal to or greater than median rating
                vis_ratings_bin(2) = vis_ratings_bin(2)+1; %add 1 to high vis count
            else 
                disp(trl(7));
            end
        end
        
        dists{stim} = vis_ratings_bin;

    end
    
    anim_low = [anim_low dists{1}(1)];
    anim_high = [anim_high dists{1}(2)];
    inanim_low = [inanim_low dists{2}(1)];
    inanim_high = [inanim_high dists{2}(2)];
   
        %count number of subjects who STILL have < 10 ratings in either low
        %or high visibility class
        if  any(dists{1} < 10) || any(dists{2} < 10)
          
          count=count+1;
          disp(subject)
        end
   
    
        %plot distribution
        label = 'Relative Visibility Rating'; %for plotting
        %plot animate stims
        ax = subplot(1,2,1);
        X = categorical({'low','high'});
        X = reordercats(X,{'low','high'});
        bar(X,dists{1})
        ylim([0 96])
        title(stim_groups{1})
        xlabel(label)
        
        %plot inanimate stims
        ax = subplot(1,2,2);
        X = categorical({'low','high'});
        X = reordercats(X,{'low','high'});
        bar(X,dists{2})
        ylim([0 96])
        title(stim_groups{2})
        xlabel(label)
        
        sgtitle(subject)
       
        
   
    
    saveas(fig,strcat(output_dir,subject,'_med_split.jpg'))
         
      
    clear SPM dists meds vis_ratings vis_ratings_bin all_ratings
    
end
   
mean_anim_low = mean(anim_low);
mean_anim_high = mean(anim_high);
mean_inanim_low = mean(inanim_low);
mean_inanim_high = mean(inanim_high);