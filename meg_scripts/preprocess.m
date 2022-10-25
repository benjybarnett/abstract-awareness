function err = preprocess(subject, meg_path, events, prestim, poststim, demean,baselinewindow, downsample_freq)
    %%%This function will define trials and preprocess them.
    %%%It will then add data from external .data files to the fieldtrip
    %%%data structure in the data.trialinfo cell.
    %%%INPUTS:
            %%% subject : (string) denoting subject ID
            %%% meg_path : (string) path to meg data directory
            %%% events : (list) of event triggers 
            %%% prestim : (float) time before stim to include in trial
            %%% poststim : (float) time after stim to include in trial
            %%% demean : whether to baseline correct or not
            %%% baselinewindow: (list) time points over which to calculate baseline for deameaning
            %%% downsample_freq (int) freq to downsample to
            %%% save_to_file : (boolean) whether to save preprocessed data to .mat file, which will be savd in subject's folder

    %%%OUTPUTS:
            %%% data : (cell array) preprocessed data that is concatenated across files
            %%% subj_error : (boolean) if there was an error matching subject events from .fif fils with events from .data files
            
  

    disp(strcat('**********Working on subject ',subject,' ***************'))

    filenames = {...

    %CHECK IF FILES READING PROJECTED FILES OR ORIGINAL
        strcat('proj/PROJ0076_SUBJ00',subject(4:5),'_SER001_FILESNO001.fif')
        strcat('proj/PROJ0076_SUBJ00',subject(4:5),'_SER001_FILESNO002.fif')
        strcat('proj/PROJ0076_SUBJ00',subject(4:5),'_SER002_FILESNO001.fif')
        strcat('proj/PROJ0076_SUBJ00',subject(4:5),'_SER003_FILESNO001.fif')
        strcat('proj/PROJ0076_SUBJ00',subject(4:5),'_SER004_FILESNO001.fif')
        strcat('proj/PROJ0076_SUBJ00',subject(4:5),'_SER005_FILESNO001.fif')
            };
        %n.b for subject 20 need to comment out the second file. It exists
        %but there is no recoverable data in there
        
    n_filenames = length(filenames);  

    
    %%read in data
    split_files = {}; %blank cell array to hold the various data files of each subject to concatenate
    split_file_idx = 1;
    for filename_index = 1:n_filenames
        
        filename = filenames{filename_index};
        full_path = fullfile(meg_path, subject, filename);
        disp(full_path);
       
        if isfile(full_path) == 0
            %checks to see if file exists, if not we skip to next file.
            %necessary as different num files per subject
            continue
        end
        
        % define trials
        cfg = [];
        cfg.dataset = full_path;
        cfg.trialdef.prestim = prestim; % seconds  adjusted with 25 ms 
        cfg.trialdef.poststim = poststim; % seconds
        cfg.trialdef.eventvalue = events;
        cfg.trialfun = 'ft_trialfun_general';
        %edited the source code of this function so that it removes events
        %with length of one sample from the cfg.trl field. Can't copy it
        %and use it outside of source code since throws weird error?

        cfg.trialdef.eventtype = 'STI101';
        cfg = ft_definetrial(cfg);

        % preprocess

        cfg.demean = demean;
        cfg.baselinewindow = baselinewindow;
        cfg.lpfilter = 'yes';
        cfg.hpfilter = 'no';
        cfg.lpfreq = 100;
        cfg.padding= 7;
        cfg.dftfilter = 'yes';
        cfg.dftfreq = [50 100 150];
        
        
        
        if strcmp(subject, 'sub06') 
            %missing EOG data for sub06 so we only include MEG channels
            cfg.channel = 'MEG';
        end

        split_files{split_file_idx} = ft_preprocessing(cfg); %preprocess
        split_file_idx = split_file_idx + 1 ;

    end

    
    % concat split files
    cfg = [];
    cfg.keepsampleinfo='no'; 
    concat_data = ft_appenddata(cfg, split_files{:});
    disp(' concatenation of separate files complete');
    
    %%%%%%%%%%%Downsampling%%%%%%%%%
    cfg = [];
    cfg.resamplefs = downsample_freq;
    concat_data = ft_resampledata(cfg, concat_data);
    %%%%%%%%%%End downsampling%%%%%%%%%
    
    %fix sample info
    data = fixsampleinfo(concat_data);
    clear concat_data
    
    
    %add bandstop filter to remove remaining 50Hz and 100 Hz artefacts 
    cfg = [];
    cfg.bsfilter='yes';
    cfg.bsfreq = [49.5 50.5; 99.5 100.5]; 
    data = ft_preprocessing(cfg,data);
    
    
    %Add events from csv file
    [data,err] = add_events(data,meg_path,subject);
    if err
        disp('discrepancy when matching csv to trialinfo')
    end
    
    
  
    save(strcat('..\data\',subject,'\',subject,'_noBL'),'data','-v7.3')
    
    clear data 
    
   
    

end %end function


