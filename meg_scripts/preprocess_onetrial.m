function [data, subj_error] = preprocess_onetrial(subject, meg_path)
    %Preprocesses data as one long trial
    subj_error = false;

    disp(strcat('**********Working on subject ',subject,' ***************'))

    filenames = {...

        strcat('PROJ0076_SUBJ00',subject(4:5),'_SER001_FILESNO001.fif')
            };
        %n.b for subject 20 need to comment our the second file. It exists
        %but there is no recoverable data in there
        
    n_filenames = length(filenames);  

    
    %%read in data
    split_files = {}; %blank cell array to hold the various data files of each subject to concatenate
    split_file_idx = 1;
    for filename_index = 1:n_filenames
        
        filename = filenames{filename_index};
        full_path = fullfile(meg_path, subject, filename);

       
        if isfile(full_path) == 0
            %checks to see if file exists, if not we skip to next file.
            %necessary as different num files per subject
            continue
        end

       
        
        
        
        cfg = [];
        cfg.dataset = full_path;
        cfg.continuous = 'yes';
        %cfg.demean = 'yes';
        %cfg.baselinewindow = [-0.175 0.025];
        cfg.lpfilter = 'no';
        cfg.hpfilter = 'no';
        cfg.dftfilter = 'yes';
     
        split_files{split_file_idx} = ft_preprocessing(cfg);
        split_file_idx = split_file_idx + 1 ;
        
        
    

    data = split_files{1};
    

    
end %end function
end


