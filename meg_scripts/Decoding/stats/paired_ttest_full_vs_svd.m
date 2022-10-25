 dir = '../data/results';
 load('../data/time_axis.mat');
 
 cfg = [];
 cfg.train = 'squares';
 cfg.crossDir = 'Decoding/Cross/Temporal/Multiclass';
 cfg.accFile = 'multiclass_PAS';
 cfg.withinDir = 'Decoding/Cross/Temporal/Multiclass/SVD';

 
time = time(1:550);
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
        load(strcat('../data/results/',subject','/',cfg.crossDir,'/',[cfg.accFile,'_trainSquares']));
        acc =train_sq_cross_acc(1:550,1:550);
        disp('squares')
    elseif strcmp(cfg.train,'diamonds')
        load(strcat('../data/results/',subject','/',cfg.crossDir,'/',[cfg.accFile,'_trainDiamonds']));
        acc = train_di_cross_acc(1:550,1:550);
        disp('diamonds')
    end

    cross_acc(subj,:,:) = acc;


    %6D
    Acc = load(strcat('../data/results/',subject','/',cfg.withinDir,'/',[cfg.accFile,'_trainSquares_6D']));
    Acc = struct2cell(Acc); Acc = Acc{1};

    within_acc(subj,:,:) = Acc(1:550,1:550);

end
if remove
        cross_acc(12,:,:) = [];
        within_acc(12,:,:) = [];
end


cfg = [];cfg.paired = true;cfg.tail= 'two'; cfg.indiv_pval = 0.05; cfg.cluster_pval = 0.05;
disp(size(cross_acc))
disp(size(within_acc))
pVals_pair = cluster_based_permutationND(cross_acc,within_acc,cfg);
figure; imagsesc(pVals_pair);
save('../data/results/group/stats/paired/svd/6_v_full_squares','pVals_pair')


    
    