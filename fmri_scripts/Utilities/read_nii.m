function [V,Y] = read_nii(inputFn)
%READ_NII(INPUTFN) Read NIFTI file into matlab workspace using a
%combination of SPM and optionally FSL tools
%
%   INPUTFN needs to be full filename of either a gzipped (.nii.gz) or
%   normal NIFTI file (.nii)
%
%   Output is structured according to SPM standards:
%       V is structure contaning the NIFTI header 
%       Y is array representing the image

% find out if .nii or .nii.gz
[~,~,fileExt] = fileparts(inputFn);

switch fileExt
    case '.gz'
        % if zipped, unzip first to temporary file
        unzipFn = [tempname '.nii'];
        
        % FSL can do this in one go (copy and unzip)  
        unix(['fslchfiletype NIFTI ' inputFn ' ' unzipFn]);
        
        % set logical zipFile to true
        zipFile = true;
        
    otherwise
        % if not zipped, continue using same input filename
        unzipFn = inputFn;
        zipFile = false;
end

% read in the image
V = spm_vol(unzipFn);
Y = spm_read_vols(V);

% in case of 4-D image
nVolumes = length(V);
if nVolumes > 1
    V = V(1);
    V.dim = [V.dim,nVolumes];
end
    
% only in case the inputFn was zipped, delete the temporary unzipped file!
if zipFile
    delete(unzipFn);
end