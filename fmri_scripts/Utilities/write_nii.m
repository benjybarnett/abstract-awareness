function write_nii(V,Y,outputFn)
%WRITE_NII(V,Y,OUTPUTFN) Write numerical array to disk as (gzipped) NIFTI
%file using a combination of SPM and optionally FSL tools
%
%   Input: 
%       V           SPM-style NIFTI header structure 
%       Y           Image in 3-D array or vectorized form, use 4-D array to 
%                     automatically create 4-D NIFTI
%       OUTPUTFN    Full filename of file-to-be-written, include .nii.gz as 
%                     file extension to achieve gzipping 

% if the file already exists, delete it first to prevent errors
if ~exist(outputFn,'file'); else delete(outputFn); end

% find out if user wants .nii or .nii.gz
[filePath,fileName,fileExt] = fileparts(outputFn);

switch fileExt
    case '.gz'
        % here user wants to gzip final output, but first we need to write
        % an unzipped NIFTI using spm_write_vol and therefore we redefine
        % output filename to .nii
        unzipFn = fullfile(filePath,fileName);
        
        zipFile = true;
                
        % again perform check to see if unzipped output filename already
        % exists and if so delete it to prevent later gzip errors
        if ~exist(unzipFn,'file'); else delete(unzipFn); end
     
    case '.nii'
        % do not gzip, keep current output filename
        unzipFn = outputFn;
        zipFile = false;   
end

% write to disk
if length(V.dim) <= 3
    
    % change filename to unzipped output filename
    V.fname = unzipFn;

    % use SPM to write NIFTI
    % reshaping enables handling of vectorized 3-D arrays
    spm_write_vol(V,reshape(Y,V.dim)); 
    
elseif length(V.dim) == 4
    
    % first use SPM, later FSL to merge to 4-D
    nFiles  = V.dim(4);         % size of 4th dimension
    tmpFns  = cell(1,nFiles);   % array to store the temp NIFTIs
    V.dim   = V.dim(1:3);       % size of 3-D image
      
    % loop over the 4th dimension and create temp NIFTIs
    for iFile = 1:nFiles
        V.fname         = [int2str(iFile) 'test.nii']; % create tempname
        tmpFns{iFile}   = V.fname;           % store this name
        spm_write_vol(V,Y(:,:,:,iFile));     % write the image 
    end
    
    % merge the temp NIFTIs into 4-D NIFTI using FSL
    % note that FSL gzips the new file, no matter what
    concatImgStr = sprintf('%s ', tmpFns{:});
    unix(['fslmerge -t ' outputFn ' ' concatImgStr]);
    
    % remove all the temp NIFTIs
    for f = 1:length(tmpFns)
        delete(tmpFns{f});
    end
    
    % if user did not want zipped output
    if ~zipFile
        gunzip([outputFn '.gz']);
    end
    
    % if user wanted zipped file, we do nothing as FSL has already zipped
    zipFile = false;
    
else
    error('Only 3-D or 4-D NIFTIs supported currently')  
end

% zip final NIFTI if needed
if zipFile
     gzip(unzipFn);
     delete(unzipFn);
end