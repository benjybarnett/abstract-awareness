function weights = get_weights(cfg, subject)

% output directory
outputDir = fullfile('../data/results',subject,cfg.outputDir);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

%load data
disp('loading..')
disp(subject)
data = load(strcat('../data/',subject,'/',subject,'_clean.mat'));
data = struct2cell(data); data = data{1};
disp('loaded data')
% select meg channels  and appropriate trials 
trls = eval(strcat('(',cfg.conIdx{1}," | ",cfg.conIdx{2},") & ",cfg.conIdx{3}));
cfgS             = [];
cfgS.channel     = 'MEG';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
data            = ft_timelockanalysis(cfgS,data);




% create labels and balance classes
labels = eval(strcat(cfg.conIdx{1}));%labels is a Ntrials length vector with 1 for one class and 0 for the other
%balance the number of trials of each condition
%samples
idx = balance_trials(double(labels)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
Y = labels(cell2mat(idx));
X = data.trial(cell2mat(idx),:,:);

% check for NaNs in train data
nan_chidx = isnan(squeeze(X(1,:,1)));
if sum(nan_chidx) > 0 
    fprintf('The following channels are NaNs, removing these \n');
    disp(train_data.label(nan_chidx));
    X(:,nan_chidx,:) = [];
end


fprintf('Using %d trials per class in training\n',sum(Y==1))



%separate data from each class and isolate  the sample of interest
class0 = X(Y==0,:,cfg.sample);
class1 = X(Y==1,:,cfg.sample);


%take mean of classes
u0 = mean(class0,1);
u1 = mean(class1,1);

%take difference of means

weights = u1 - u0;

%mag_weights = weights(1:3:end);
%grad_weights = setdiff(weights,mag_weights);

save(fullfile(outputDir,strcat(cfg.outputName,'_',string(cfg.sample))),'weights');

end
