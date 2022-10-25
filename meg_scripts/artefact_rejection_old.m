
function [artf_eog,artf_mag, artf_grad] = artefact_rejection_old(data, subject, method, browser)
    %%%This function performs artefact rejection. It will visualise the EOG, then GRAD
    %%%channels, then the MAG channels. This allows for
    %%%interpretation of plots for trial- or channel-wise signal for
    %%%different subsets of channels.

    %%%INPUTS:
        %%% data : subject's data
        %%% subject: (string) subject ID
        %%% method: (string) trial- or channel-wise visualisations
        %%% browser : (boolean) true if using ft_databroswer, false if
                %%% using ft_rejectvisual
  
    %%%OUTPUT:
        %%% artf : data structure, only important if browser == true, since
                %%% otherwise the data is edited in place.
                
   

    %%%%%%%%%%ARTEFACT REJECTION%%%%%%%%%%%%%
    cfg          = [];
    cfg.method   = method;
    cfg.channel  = 'EOG';
    cfg.keepchannels = 'yes';
    if (browser == false)
        artf_eog = ft_rejectvisual(cfg, data);
        cfg.channel  = 'MEGMAG';
        artf_mag = ft_rejectvisual(cfg, artf_eog);
        cfg.channel  = 'MEGGRAD';
        artf_grad = ft_rejectvisual(cfg, artf_mag);

    elseif (browser == true)
        artf_eog=ft_databrowser(cfg, data);
        cfg.channel = 'MEGMAG';
        artf_mag = ft_databrowser(cfg,artf_eog);
        cfg.channel = 'MEGGRAD';
        artf_grad = ft_databrowser(cfg,artf_mag);
    end

end %end function

