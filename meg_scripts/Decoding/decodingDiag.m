function Xhat = decodingDiag(cfg,X,Y)
% function decodingDiag(cfg,X,Y)
%
% Trains a classifier on the data in X{1} and classifies the data in X{2}.
% Only testing on the samples used in the training set. I.e. no temporal
% geenralization.
% 
%     INPUT: X{n}  = a trials x features x sample points matrix. 
%            Y{n}  = a trials x 1 vector containing the class labels
%            cfg   = a configuration structure with the fields:
%                .nMeanS = amount of sample points to average over, default
%                is 0.
%                .gamma  = the shrinkage regularisation parameter for the
%                LDA classification
%    OUTPUT: Xhat  = sample point x test trials matrix of decoder
%    activations
%    See also TRAIN_LDA, DECODE_LDA
%


nSamplesTrain = size(X{1},3);
nTrialsTest   = size(X{2},1);

Xhat          = zeros(nSamplesTrain,nTrialsTest);

nMeanS        = cfg.nMeanS;



for s1 = 1:nSamplesTrain
    
    % define the training set
    if s1 <= nMeanS/2 || s1 >= nSamplesTrain - (nMeanS/2)
        Xhat(s1,:) = NaN;
    else
        train = squeeze(mean(X{1}(:,:,round(s1 - nMeanS/2):round(s1 + nMeanS/2)),3));
    if sum(isnan(train(1,:))) > 1
            Xhat(s1,:) = NaN;
    else
        
        if mod(s1,100) == 0
        fprintf('\t Training on sample %d out of %d \r',s1,nSamplesTrain);
        end
        
        % train the decoder
        decoder = train_LDA(cfg, Y{1}, train');
        
        %test decoder on same samples it trained on (but diffferen trials,
        %obvs!)
        test = squeeze(mean(X{2}(:,:,round(s1 - nMeanS/2):round(s1 + nMeanS/2)),3));

        % decoding
        Xhat(s1,:) = decode_LDA(cfg, decoder, test');
       
     end
     end
end
end


