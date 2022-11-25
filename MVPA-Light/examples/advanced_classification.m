% ADVANCED CLASSIFICATION
%
% This tutorial covers more complex classification scenarios such as
% higher-dimensional data (time-frequency), searchlight analysis across
% multiple dimensions and precomputing of kernels.
%
% Contents:
% (1) Create a time-frequency dataset
% (2) Classification of 4D time-frequency data
% (3) Searchlight across time and frequency
% (4) Appending dimensions for faster searchlight analysis
% (5) Multiple feature dimensions
% (6) Time generalization, frequency generalization and electrode
%     generalization
% (7) Precompute kernel matrix
%
% Note: If you are new to working with MVPA-Light, make sure that you
% complete the introductory tutorials first:
% - getting_started_with_classification
% - getting_started_with_regression
% They are found in the same folder as this tutorial.

close all
clear

% Load data
[dat,clabel] = load_example_data('epoched2');

%% (1) Create a time-frequency dataset
% Most tutorial examples use 3D data which is [samples x features x time
% points]. MVPA-Light can deal with data of any dimensionality. As an
% example for a more complex analysis, we will consider time frequency data
% here. 
%
% To obtain time-frequency data, we will take the ERP example data and
% calculate calculate the spectrogram, yielding a [samples x channels x
% frequencies x time points] dataset of spectral power values. 
% The data will be saved in the struct freq.
sz = size(dat.trial);

% Set parameters for spectrogram
win= chebwin(20);
Fs = 1/mean(diff(dat.time));
noverlap = 18;
nfft = 64;

% get number of frequencies and time points
[S,F,T] = spectrogram(squeeze(dat.trial(1,1,:)), win, noverlap, nfft, Fs);

% Correct time T
T = T + dat.time(1);

freq = dat; 
freq.trial = zeros([sz(1:2), numel(F), numel(T)]);
freq.dimord = 'rpt_chan_freq_time';
freq.time = T;
freq.freq = F;

for nn=1:sz(1)
    for cc=1:sz(2)
        S = abs(spectrogram(squeeze(dat.trial(nn,cc,:)), win, noverlap, nfft, Fs));
        freq.trial(nn,cc,:,:) = S;
    end
end

% Baseline correction
pre = find(freq.time < 0);
BL = mean(mean(freq.trial(:,:,:,pre), 4),1);

% calculate relative baseline (the resultant signal can be interpreted as
% percent signal change
sz = size(freq.trial);
BLmat = repmat(BL, [sz(1) 1 1 sz(4)]);
freq.trial = (freq.trial - BLmat) ./ BLmat;

%% (2) Classification of 4D time-frequency data
% Based on the time-frequency data created in the previous section, we will
% use mv_classify to perform a classification for each time-frequency point 
% separately.
cfg = [];
cfg.classifier      = 'lda';
cfg.metric          = 'auc';

% mv_classify needs to be told which dimensions encode the samples and
% features. Samples are in dimension 1 and features in
% dimension 2. The last two dimensions  will be automatically devised as search
% dimensions. 
% Actually, this is the default setting but we will set the dimensions
% explicitly to make clear how the mechanism works.
cfg.sample_dimension    = 1;
cfg.feature_dimension   = 2;

% optional: provide the names of the dimensions for nice output
cfg.dimension_names = {'samples','channels','frequencies', 'time points'};

% we can now perform the classification
[~, result] = mv_classify(cfg, freq.trial, clabel);

% call mv_plot_result: results is the first argument, followed by the
% arguments definining the x-axis (time) and y-axis (frequency)
mv_plot_result(result, freq.time, freq.freq)

%%%%%% EXERCISE 1 %%%%%%
% Let us imagine that the order of the data dimensions is different. 
% Run the code 
% X = permute(freq.trial, [4 2 1 3]);
% Now the dimensions are [time points x channels x samples x frequencies].
% Can you change the parameters sample_dimension, feature_dimension, and
% the dimension_names such that mv_classify produces the same output as
% before (i.e. (classification for each time-frequency point)?
%%%%%%%%%%%%%%%%%%%%%%%%

%% (3) Searchlight across time and frequency
% In the previous section we calculated classification performance for each
% time-frequency point. However, each time points and each frequency were
% considered separately. Here, we define a 'larger' searchlight by also
% taking into account the immediately neighbouring time points and
% frequencies. To this end, we need to create neighbourhood matrices for
% each of the two search dimensions. Let's get the size of each dimension
% first
[nsamples, nchannels, nfrequencies, ntimes] = size(freq.trial);

% 1) create binary neighbourhood matrix for frequencies (includes a given
% frequency and the two immediately preceding and following frequencies)
O = ones(nfrequencies);
O = O - triu(O,2) - tril(O,-2);
freq_neighbours = O;

% Let's look at the first 5 rows and first 10 columns. We can see that e.g.
% for the 2nd frequency (row 2), the 1st, 2nd and 3rd frequencies are 
% considered as features. Taking into account neighbouring frequencies
% enlarges the feature space, giving the classifier potentially more useful
% information.
freq_neighbours(1:5,1:10)

% 2) create neighbourhood matrix for time points (include a given
% time point and the two immediately preceding and following time points)
O = ones(ntimes);
O = O - triu(O,2) - tril(O,-2);
time_neighbours = O;

cfg = [];
cfg.sample_dimension = 1;
cfg.feature_dimension  = 2;
cfg.dimension_names = {'samples','channels','frequencies', 'time points'};

% Store both neighbourhood matrices together in a cell array
cfg.neighbours = {freq_neighbours, time_neighbours};
cfg.classifier  = 'naive_bayes';            % we use Naive Bayes this time

% this might take a while...
rng(21)
[~, result] = mv_classify(cfg, freq.trial, clabel);

% Let's plot the result
mv_plot_result(result, freq.time, freq.freq)
% The resultant time-frequency map looks smoother. This is because of taking
% into account neighbouring times/frequencies.

%%%%%% EXERCISE 2 %%%%%%
% We want information not only for each time-frequency point, but also for
% each electrode separately. Can you modify the cfg struct such that we get
% classification performance for electrodes x frequencies x time points?
%%%%%%%%%%%%%%%%%%%%%%%%

%% (4) Appending dimensions for faster searchlight analysis
% Searchlight analysis can get quite sluggish. This is because mv_classify
% is looping over all searchlight dimensions and performing a separate
% analysis each time. 
% An alternative way is to append all searchlight dimensions to the
% training data and pass all of them to the train function of the 
% classifier at once.
% This requires bespoke code in the train/test function of the classifier.  
% At the moment, this is only supported by the Naive Bayes classifier. 
% To use this option, set cfg.append = 1. 

rng(21)
cfg = [];
cfg.classifier      = 'naive_bayes';
cfg.dimension_names = {'samples','channels','frequencies', 'time points'};
cfg.neighbours      = {freq_neighbours, time_neighbours};
cfg.append          = 1;
[perf, result] = mv_classify(cfg, freq.trial, clabel);

% This was much faster, but the result is the same as before
mv_plot_result(result, freq.time, freq.freq)

%% (5) Multiple feature dimensions
% With multi-dimensional data, we can still opt to search only across one
% of the dimensions. For instance, we can perform a classification across
% time. To achieve this, both the channels and the frequencies have to
% act as features at the same time. This is easily done by setting the 
% feature_dimension to include both channels (dimension 2) and frequencies 
% (dimension 3).

cfg = [];
cfg.dimension_names     = {'samples','channels','frequencies', 'time points'};
cfg.feature_dimension   = [2 3];

% Since cfg.flatten = 1 per default, both feature dimension will be 
% flattened into a single feature vector of length channels x frequencies.
% The result is a time x time map of classification accuracies.
[~, result] = mv_classify(cfg, freq.trial, clabel);

% The resultant classification performance is not great though
mv_plot_result(result, freq.time)

%%%%%% EXERCISE 3 %%%%%%
% Compare the classification performance to classification across time of 
% the original 3D ERP data (using the dat struct). What do you notice?
%%%%%%%%%%%%%%%%%%%%%%%%

%% (6) Time generalization, frequency generalization and electrode generalization
% Building on the example in the previous section, we can still perform
% generalization if we only have one search dimension. As before, we simply
% designate channels and frequencies as features. Additionally, we designate 
% the time points (dimension 4) as generalization dimension.
cfg = [];
cfg.dimension_names = {'samples', 'channels', 'frequencies', 'time points'};
cfg.sample_dimension            = 1;
cfg.feature_dimension           = [2, 3];       % channels and frequencies serves as features
cfg.generalization_dimension    = 4;            % time serves for generalization

[~, result] = mv_classify(cfg, freq.trial, clabel);

% Time x time plot
mv_plot_result(result, freq.time, freq.time)

% In the literature, generalization has mostly be performed for time
% points. However, there is nothing stopping you from performing
% generalization across any of the other dimensions. Whether it makes sense
% will depend on your data and your research question.
%
% Let us start by performing frequency generalization. The result will be a
% frequency x frequency map of classification results. To achieve this, we
% only need to swap time and frequency dimensions.

cfg.feature_dimension  = [2, 4];   % now time is also a feature dimension
cfg.generalization_dimension = 3;  % now frequency is the generalization dimension

[~, result] = mv_classify(cfg, freq.trial, clabel);

% The result is interesting. Training at low frequencies <10 Hz gives us
% decent testing performance even at higher frequencies.
mv_plot_result(result, freq.freq, freq.freq)

%%%%%% EXERCISE 4 %%%%%%
% Perform an electrode x electrode generalization on the time-frequency
% data. 
% For comparison, also perform an electrode x electrode generalization on 
% the original data (dat struct).
%%%%%%%%%%%%%%%%%%%%%%%%

%% (7) Precompute kernel matrix
% Kernel methods (e.g. SVM) operate on kernel matrices which are calculated
% from the samples in the train functions. The computation of the kernel 
% matrix takes some time. It can be more efficient to precompute the kernel
% matrix i.e. compute it on the full dataset first and then pass it as
% data. mv_classify supports kernel matrices as input data.

% To precompute the kernel, we can use the compute_kernel_matrix function.
% We need to set the kernel hyperparameters first.
cfg_kernel = [];
cfg_kernel.kernel              = 'rbf';
cfg_kernel.gamma               = .1;
cfg_kernel.regularize_kernel   = 0.001;
X_kernel = compute_kernel_matrix(cfg_kernel, dat.trial);

% To understand what happened, let us compare the sizes of the original
% data with the size of X_kernel
size(dat.trial)
size(X_kernel)

% We see that the data is [samples x channels x time points] whereas our
% kernel matrix is [samples x samples x time points]. In other words, the
% compute_kernel_matrix function assumes that the 2nd dimension is the
% features. We can now pass on the kernel matrix to mv_classify. Just make
% sure to set the hyperparameter kernel='precomputed'
cfg = [];
cfg.classifier              = 'svm';
cfg.hyperparameter          = [];
cfg.hyperparameter.kernel   = 'precomputed';
tic;
perf = mv_classify_across_time(cfg, X_kernel, clabel);
time1 = toc;
fprintf('Computation time with precomputed kernels: %2.2fs\n', time1)

% Let us compare how the performance changes when we use the same kernel
% without pre-computation
cfg = [];
cfg.classifier              = 'svm';
cfg.hyperparameter          = [];
cfg.hyperparameter.kernel   = 'rbf';
cfg.hyperparameter.gamma    = .1;
cfg.hyperparameter.regularize_kernel   = 0.001;

tic;
perf = mv_classify_across_time(cfg, dat.trial, clabel);
time2 = toc;

fprintf('Computation time without precomputed kernels: %2.2fs\n', time2)

% Comparing computation times we see that precomputing kernels indeed
% speeds up things (for a fair comparison the time it takes to precompute
% the kernel should be taken into account as well, but if you do it it's
% still faster)

%%%%%% EXERCISE 5 %%%%%%
% Try precomputing a RBF kernel for the time-frequency data (freq struct).
% Compare computation time with / without kernel.
%%%%%%%%%%%%%%%%%%%%%%%%

% Congrats, you finished the tutorial! You are now a MVPA-Light wizard!

%% SOLUTIONS TO THE EXERCISES
%% SOLUTION TO EXERCISE 1
% Run the code from the question
X = permute(freq.trial, [4 2 1 3]);

% Since the data is now [time points x channels x samples x frequencies]
% the samples are dimension 3 whereas the features are still in dimension 2
cfg.sample_dimension = 3;
cfg.feature_dimension  = 2;
cfg.dimension_names = { 'time points','channels','samples','frequencies'};

[~, result] = mv_classify(cfg, X, clabel);

% dimensions are now flipped because time points comes before frequencies
% in the data
mv_plot_result(result)

%% SOLUTION TO EXERCISE 2
% So far elecrodes have been used as features. To move the searchlight
% across the electrodes, too, we need to set the feature dimension to []
cfg.feature_dimension = [];

% We also need to add a neighbourhood matrix for electrodes. For now, we
% only want to consider each electrode separately, therefore we add an
% identity matrix. If you want to group neighbouring electrodes, refer to
% the searchlight examples in getting_started_with_classification
% The order of the neighbourhood matrices needs to be the same as the order
% of the dimensions. Since electrodes come before frequencies and time
% points, we need to add the identity matrix as first element.
cfg.neighbours  = [eye(size(freq.trial,2)) cfg.neighbours];

% Let's reduce the number of folds/repetitions so that the analysis runs
% faster
cfg.k           = 2;
cfg.repeat      = 1;

% Now an analy
[perf, result] = mv_classify(cfg, freq.trial, clabel);

% 3D images cannot be currently plotted using mv_plot_result, so let's just
% confirm that the size is correct
size(perf)

%% SOLUTION TO EXERCISE 3
% We can calculate the performance on the original ERP data by simply using
% the dat struct. 
cfg = [];
[perf, result] = mv_classify(cfg, dat.trial, clabel);

% If we plot the result, we see that the performance is much better than
% for the flattened time-frequency data, although the latter has more
% features. One possible explanation is that the time-frequency data
% contains a lot of frequencies with little information about the classes.
% Additionally, the phase information (which is dicarded when calculating
% spectral power) could be relevant to classification, too.
mv_plot_result(result, dat.time)

%% SOLUTION TO EXERCISE 4
% For electrode x electrode generalization, we just need to change
% feature_dimension and generalization_dimension again
cfg = [];
cfg.dimension_names = {'samples', 'electrodes', 'frequencies', 'time points'};
cfg.feature_dimension           = [3, 4];
cfg.generalization_dimension    = 2;

[~, result] = mv_classify(cfg, freq.trial, clabel);

% Electrode x electrode plot
mv_plot_result(result)
set(gca,'XTick',1:numel(freq.label), 'XTickLabel', freq.label)
set(gca,'YTick',1:numel(freq.label), 'YTickLabel', freq.label)

% Using the original dat struct
cfg = [];
cfg.feature_dimension           = 3;
cfg.generalization_dimension    = 2;
[~, result] = mv_classify(cfg, dat.trial, clabel);

mv_plot_result(result)
set(gca,'XTick',1:numel(freq.label), 'XTickLabel', freq.label)
set(gca,'YTick',1:numel(freq.label), 'YTickLabel', freq.label)
% Overall accuracy is again higher for the original ERP data

%% SOLUTION TO EXERCISE 5
% The analysis is very similar. However, we cannot use
% mv_classify_across_time any more because the data is now 4-dimensional.
% We have to use mv_classify instead and set the sample and feature
% dimensions.

% precompute kernel
cfg_kernel = [];
cfg_kernel.kernel              = 'rbf';
cfg_kernel.gamma               = .1;
cfg_kernel.regularize_kernel   = 0.001;

cfg = [];
cfg.classifier              = 'svm';
cfg.hyperparameter          = [];
cfg.hyperparameter.kernel   = 'precomputed';
cfg.sample_dimension        = [1 2]; % dimensions 1 and 2 are [samples x samples]
cfg.feature_dimension       = []; % with precomputed kernels we have no feature dimension, only the kernel matrix

tic;
% we want to take into account both percomputation and classification for
% timing
X_kernel = compute_kernel_matrix(cfg_kernel, freq.trial);
perf = mv_classify(cfg, X_kernel, clabel);
time1 = toc;

fprintf('Computation time with precomputed kernels: %2.2fs\n', time1)

% without pre-computation
cfg = [];
cfg.classifier              = 'svm';
cfg.hyperparameter          = [];
cfg.hyperparameter.kernel   = 'rbf';
cfg.hyperparameter.gamma    = .1;
cfg.hyperparameter.regularize_kernel   = 0.001;

tic;
perf = mv_classify(cfg, X_kernel, clabel);
time2 = toc;

fprintf('Computation time without precomputed kernels: %2.2fs\n', time2)

% Again, precomputing kernels makes the computations faster