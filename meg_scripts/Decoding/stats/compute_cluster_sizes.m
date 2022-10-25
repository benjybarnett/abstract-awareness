function [posSizes, negSizes, posLabels, negLabels, pVals] = compute_cluster_sizes(data1,data2,indiv_pval,one_two_tailed,mask,connectivity,paired)
% step 1, determine 'actual' p values
if strcmpi(one_two_tailed,'two')
    tail = 'both';
else
    tail = 'right';
end
% restrict data
for c = 1:size(data1)
    maskdata1(c,:,:) = data1(c,mask);
end
for c = 1:size(data2)
    maskdata2(c,:,:) = data2(c,mask);
end

pVals = ones(size(mask));
tVals = zeros(size(mask));
if paired
    [~,pVals(mask),~,stats] = ttest(maskdata1,maskdata2,indiv_pval,tail);
else
    [~,pVals(mask),~,stats] = ttest2(maskdata1,maskdata2,indiv_pval,tail);    
end
tVals(mask) = squeeze(stats.tstat);

% initialize clusters
signCluster  = squeeze(mean(data1,1) - mean(data2,1));

% use mask to restrict relevant info
pVals(~mask) = 1;
signCluster(~mask) = 0;

% step 2, apply threshold and determine positive and negative clusters
clusterMatrix = squeeze(pVals < indiv_pval);
posClusters = zeros(size(clusterMatrix));
negClusters = zeros(size(clusterMatrix));
posClusters(signCluster > 0) = clusterMatrix(signCluster > 0);
negClusters(signCluster < 0) = clusterMatrix(signCluster < 0);

% step 3, label clusters
if isempty(connectivity)
    posLabels = bwlabel(posClusters);
    negLabels = bwlabel(negClusters);
else
    % slightly more complex to find clusters in topomap data
    elecs2do = posClusters;
    posLabels = zeros(size(clusterMatrix)); % 
    cClust = 0;
    for c=1:numel(elecs2do)
        if elecs2do(c) == 1 % only look for a new cluster if this electrode has not been looked at yet
            [clustlabels, elecs2do] = find_elec_clusters(elecs2do,posClusters,c,connectivity);
            if sum(clustlabels) > 1
                cClust = cClust + 1;
                posLabels(clustlabels) = cClust;
            end
        end
    end
    elecs2do = negClusters;
    negLabels = zeros(size(clusterMatrix)); % 
    cClust = 0;
    for c=1:numel(elecs2do)
        if elecs2do(c) == 1 % only look for a new cluster if this electrode has not been looked at yet
            [clustlabels, elecs2do] = find_elec_clusters(elecs2do,negClusters,c,connectivity);
            if sum(clustlabels) > 1
                cClust = cClust + 1;
                negLabels(clustlabels) = cClust;
            end
        end
    end
end

% step 4 compute the sum of the t-stats in each of the clusters, separately
% for the positive and negative clusters
labels = 1:max(unique(posLabels));
for c = 1:numel(labels)
    posSizes(c) = sum(sum(tVals(posLabels==labels(c))));
end
labels = 1:max(unique(negLabels));
for c = 1:numel(labels)
    negSizes(c) = abs(sum(sum(tVals(negLabels==labels(c)))));
end
if ~exist('posSizes','var')
    posSizes = 0;
end
if ~exist('negSizes','var')
    negSizes = 0;
end