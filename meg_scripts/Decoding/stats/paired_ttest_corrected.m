 dir = '../data/results';
 load('../data/time_axis.mat');
 load('noBL_time.mat');
 time = noBL_time;
 
 cfg = [];
 cfg.train = 'squares';
 cfg.crossDir = 'Decoding/Cross/Temporal/Multiclass';
 cfg.accFile = 'multiclass_PAS';
 cfg.withinDir = 'Decoding/Within/Temporal/Multiclass';

 
time = time(1:620);
remove=false;
cross_acc = zeros(length(subjects),length(time),length(time));
within_acc = zeros(length(subjects),length(time),length(time));
for subj =1:length(subjects)

    subject = convertCharsToStrings(subjects(subj));
    disp(subject)

    if strcmp(subject,'sub13') 
        remove = true;
        continue
    end

    %cross
    if strcmp(cfg.train,'squares')
        load(strcat('../data/results/',subject','/',cfg.crossDir,'/',[cfg.accFile,'_trainSquares_noBL_cv']));
        acc =train_sq_cross_acc(1:620,1:620);
        disp('squares')
    elseif strcmp(cfg.train,'diamonds')
        load(strcat('../data/results/',subject','/',cfg.crossDir,'/',[cfg.accFile,'_trainDiamonds_noBL_cv']));
        acc = train_di_cross_acc(1:620,1:620);
        disp('diamonds')
    end

    cross_acc(subj,:,:) = acc;


    %within
    Acc = load(strcat('../data/results/',subject','/',cfg.withinDir,'/',[cfg.accFile,'_',cfg.train,'_noBL']));
    Acc = struct2cell(Acc); Acc = Acc{1};

    within_acc(subj,:,:) = Acc(1:620,1:620);

end
if remove
        cross_acc(12,:,:) = [];
        within_acc(12,:,:) = [];
end


cfg = [];cfg.paired = true;cfg.tail= 'two'; cfg.indiv_pval = 0.05; cfg.cluster_pval = 0.05;
disp(size(cross_acc))
disp(size(within_acc))
pVals_pair = cluster_based_permutationND(cross_acc,within_acc,cfg);


    
    