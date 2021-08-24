function [vind,mind] = searchlightIndices(mask,slRadius)


dim = size(mask);                 % volume dimensions
nVolumeVoxels = prod(dim);
nMaskVoxels = sum(mask(:));

% determine searchlight voxel offsets relative to center voxel
% prototype searchlight
[dxi, dyi, dzi] = ndgrid(-ceil(slRadius) : ceil(slRadius));
PSL = (dxi .^ 2 + dyi .^ 2 + dzi .^ 2 <= slRadius .^ 2);
% spatial offsets
dxi = dxi(PSL);
dyi = dyi(PSL);
dzi = dzi(PSL);
% index offsets
PSL(dim(1), dim(2), dim(3)) = 0;
di = find(PSL);
cInd = find((dxi == 0) & (dyi == 0) & (dzi == 0));
di = di - di(cInd);                                                         %#ok<FNDSB>
clear PSL cInd

% mapping from volume to mask voxel indices
vvi2mvi = nan(nVolumeVoxels, 1);
vvi2mvi(mask) = 1 : nMaskVoxels;


fprintf(' running searchlight\n')
fprintf('  searchlight size: %d\n', size(di, 1))
tic
t = 0;
cmvi = 0;
for cvvi = 1 : nVolumeVoxels        % searchlight center volume voxel index
    % process only if center is within mask 
    if mask(cvvi)
        cmvi = cmvi + 1;            % searchlight center mask voxel index
        
        % searchlight center coordinates
        [xi, yi, zi] = ind2sub(dim, cvvi);
        % searchlight voxel coordinates; limit to volume boundaries
        ind = (xi + dxi >= 1) & (xi + dxi <= dim(1)) & ...
            (yi + dyi >= 1) & (yi + dyi <= dim(2)) & ...
            (zi + dzi >= 1) & (zi + dzi <= dim(3));
        % searchlight voxel volume indices
        vvi = cvvi + di(ind);
        % discard out-of-mask voxels
        vvi = vvi(mask(vvi) == 1);
        % translate to mask voxel indices
        mvi = vvi2mvi(vvi);
        
        vind{cmvi} = vvi; % volume indices
        mind{cmvi} = mvi; % mask indices
        
    end
    
    % progress
    nt = toc;
    if (nt - t > 30) || (cvvi == nVolumeVoxels)
        t = nt;
        fprintf(' %6.1f min  %6d voxels  %5.1f %%\n', ...
            t / 60, cmvi, cmvi / nMaskVoxels * 100)
    end
end
