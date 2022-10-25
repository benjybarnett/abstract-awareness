function [smoothed_data] = smooth_data(X,n)
    %INPUT X: 3D matrix of Ntrial x Nchannels x Nsamples
    %N: number of sample points to smooth over
    smoothed_data = zeros(size(X));
    
    for i = 1:size(X,1)
        smoothed_data(i,:,:) = ft_preproc_smooth(squeeze(X(i,:,:)),n);
    end
        


end