tic

%%subjects
subjects = ...
            {   
           
           
    'sub02'
    'sub03'
    'sub04'
    'sub05'
    'sub06'
    'sub07'
    'sub08'
    'sub09'
    'sub10'
    'sub11'
    'sub12'
    'sub13'
    'sub15'
    'sub16'
    'sub17'
    'sub18'
    'sub19'
    'sub20'
                       

         };


%%%%MULTICLASSIFIER%%%
for subj = 1:length(subjects)

        subject = subjects{subj};
        
        cfg=[];
        cfg.outputDir = 'Decoding/Within/Temporal/Multiclass';
        cfg.nFold  = 5;
        cfg.gamma = 0.2;
        cfg.nMeanS = 7; 
        cfg.plot  = false;
    
  
        % target: all PAS ratings
        cfg.outputName = {};
        cfg.outputName = {'multiclass_PAS_squares';'multiclass_PAS_diamonds'};

        multiclass(cfg,subject)
        cfg.outputDir = 'Decoding/Cross/Temporal/Multiclass';
        cfg.outputName = {'multiclass_PAS_trainSquares';'multiclass_PAS_trainDiamonds'};
        multiclass_cross(cfg,subject)
        
 end

toc

