function latent_vars = processLatentVariables(fit_settings,latent_vars,latent_vars_new,stim_nr)
%Reduce memory size of the latent variables: save mean and SD instead of values for each simulation.

for i=1:length(fit_settings.latent_vars)
    
    var_name = fit_settings.latent_vars{i};
    
    %Quick fix for potential errors... 
    i_okay = isfinite(latent_vars_new.(var_name)) & ~isnan(latent_vars_new.(var_name));
    if sum(~i_okay) > 0
        warning(['Excluded ' num2str(sum(~i_okay)) ' simulated values for ' var_name ' because of Inf or NaNs']);
        
        keyboard;
        
    end
    
    %Compute median and interquartile range (iqr)
    Q = quantile(latent_vars_new.(var_name),[.25 .50 .75]);
    latent_vars.(var_name).med(1,stim_nr) = Q(2);
    latent_vars.(var_name).iqr(1,stim_nr) = Q(3)-Q(1);
    
end
                
end %[EoF]
