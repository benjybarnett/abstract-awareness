function MCCmask(cfg)
% function MCCmask(cfg)
%
% corrects pvals for multiple comparisons and masks with stat mask to show only
% significant values

% q-value
if ~isfield(cfg,'qval'); cfg.qval = 0.05; end

% get mask
[~,mask]  = read_nii(cfg.mask);

% get the pvals
[~,pvals] = read_nii(fullfile(cfg.root,'GroupResults',cfg.dir,['rpval_' cfg.map]));
pvals(mask>0) = 1-pvals(mask>0);

% get FDR sig threshold
[~,thresh] = fdr_bh(pvals(mask>0),cfg.qval); 
sig        = zeros(size(mask)); 
sig(mask>0) = pvals(mask==1)<=thresh;

% get stat vals
[V,vals]   = read_nii(fullfile(cfg.root,'GroupResults',cfg.dir,['tval_' cfg.map]));
sig_vals   = zeros(V.dim);
sig_vals(sig>0) = vals(sig>0);

% write results
write_nii(V,sig_vals,fullfile(cfg.root,'GroupResults',cfg.dir,['sig_' cfg.map]));

% print limits
maxNeg = min(sig_vals(sig_vals(:)~=0)); minNeg = max(sig_vals(sig_vals(:)<0));
maxPos = max(sig_vals(sig_vals(:)>0));  minPos = min(sig_vals(sig_vals(:)>0));
fprintf('Sig tvals between %.2f and %.2f - and %.2f and %.2f \n,',maxNeg,minNeg,minPos,maxPos)


