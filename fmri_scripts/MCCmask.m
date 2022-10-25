function [sig_vals,vals] = MCCmask(cfg)
% function MCCmask(cfg)
%
% corrects pvals for multiple comparisons and masks with stat mask to show only
% significant values

% q-value
if ~isfield(cfg,'qval'); cfg.qval = 0.01; end

% get mask
[~,mask]  = read_nii(cfg.mask);

% get the pvals
[~,pvals] = read_nii(fullfile(cfg.root,'group',cfg.decoding_type,['rpvals' cfg.pvals_map]));
pvals(mask>0) = 1-pvals(mask>0);

% get FDR sig threshold
[~,thresh] = fdr_bh(pvals(mask>0),cfg.qval); 
sig        = zeros(size(mask)); 
sig(mask>0) = pvals(mask==1)<=thresh;

% get stat vals
[V,vals]   = read_nii(fullfile(cfg.root,'group',cfg.decoding_type,['mean_',cfg.empirical_map]));
sig_vals   = zeros(V.dim);
sig_vals(sig>0) = vals(sig>0);

% write results
write_nii(V,sig_vals,fullfile(cfg.root,'group',cfg.decoding_type,['sig_' cfg.pvals_map]));

% print limits
maxNeg = min(sig_vals(sig_vals(:)~=0)); minNeg = max(sig_vals(sig_vals(:)<0));
maxPos = max(sig_vals(sig_vals(:)>0));  minPos = min(sig_vals(sig_vals(:)>0));
fprintf('Sig difference score between %.6f and %.6f - and %.6f and %.6f \n,',maxNeg,minNeg,minPos,maxPos)


