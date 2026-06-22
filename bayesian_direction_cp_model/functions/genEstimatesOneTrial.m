function [post_d,latent_vars] = genEstimatesOneTrial(x_true,param_settings,model_settings,fit_settings) 
%Generate 'num_sim' posterior decision variables 'post_d' for the last direction in the trial. 
%Optionally, also compute latent variables for all stimuli in the trial. 

%Unpack
num_sim = fit_settings.num_sim_per_trial;

%Gather number of stimuli in sequence
num_stim = length(x_true);
num_diffs = num_stim-1;

%Initialize latent_vars structure fields
if nargout >= 2
    
    assert(length(fit_settings.latent_vars) >= 1,'Latent variables requested, but none specified to generate');
    
	num_diffs_temp = num_diffs; 
	if fit_settings.latent_last_only
		num_diffs_temp = 1;
	end
 
    for i=1:length(fit_settings.latent_vars)
        latent_vars.(fit_settings.latent_vars{i}).med = nan(1,num_diffs_temp);
        latent_vars.(fit_settings.latent_vars{i}).iqr = nan(1,num_diffs_temp);  
    end
end

%Initialize an uninfomative prior 
post_d_old = zeros(num_sim,1);

%Sample initial location estimates with associated uncertainty (sd) for first sound (t=0)   
sd_sens_gen = param_settings.sd_sens + param_settings.k_azimuth_sens*abs(x_true(1));
intrnl_loc_old = sd_sens_gen*min(max(-3,randn(num_sim,1)),3)+x_true(1);
intrnl_loc_sd_old = param_settings.sd_sens + param_settings.k_azimuth_sens*abs(intrnl_loc_old);

%Loop through all stimuli in the sequence
for t=1:num_diffs    
    
    %Sample location estimates with associated uncertainty (sd) for new sound
    sd_sens_gen = param_settings.sd_sens + param_settings.k_azimuth_sens*abs(x_true(t+1));
    intrnl_loc_new = sd_sens_gen*min(max(-3,randn(num_sim,1)),3)+x_true(t+1);
    intrnl_loc_sd_new = param_settings.sd_sens + param_settings.k_azimuth_sens*abs(intrnl_loc_new);
    
    %Estimate the current instantaneous velocity (lambda) and its uncertainty (variance)   
    lambda = intrnl_loc_new - intrnl_loc_old;
    var_lik = intrnl_loc_sd_new.^2 + intrnl_loc_sd_old.^2;
    
    %Temporarily set the hazard rate to be 1 (first diff only)
    if t==1 
        true_cp_hazard_rate = param_settings.cp_hazard_rate;
        param_settings.cp_hazard_rate = 1;
    end
    
    %Default with minimal computations for speed
    if nargout == 1
        
        %Update the direction estimates on every stimulus
        post_d = processOneStimulus(lambda,var_lik,post_d_old,param_settings,model_settings,fit_settings);
    
    %Compute estimates and latent variables   
    elseif nargout >= 2
        
        %Compute latent variables on every stimulus
        if ~fit_settings.latent_last_only
            [post_d,latent_vars_new] = processOneStimulus(lambda,var_lik,post_d_old,param_settings,model_settings,fit_settings);
            latent_vars = processLatentVariables(fit_settings,latent_vars,latent_vars_new,t);
        else
            %Compute latent variables on the last stimulus only
            if t < num_diffs
                post_d = processOneStimulus(lambda,var_lik,post_d_old,param_settings,model_settings,fit_settings);                  %Same as above, but no latent variables
            elseif t == num_diffs
                [post_d,latent_vars_new] = processOneStimulus(lambda,var_lik,post_d_old,param_settings,model_settings,fit_settings);
                latent_vars = processLatentVariables(fit_settings,latent_vars,latent_vars_new,1);                          %Note the "1" as input parameter
            end
        end
    end 
    
    %Return the true hazard rate parameter
    if t==1 
        param_settings.cp_hazard_rate = true_cp_hazard_rate;
    end
    
    %New sound locs (and uncertainty) become old sound locs (and uncertainty)   
    intrnl_loc_old = intrnl_loc_new;
    intrnl_loc_sd_old = intrnl_loc_sd_new;
    
    %Update current beliefs about the velocity direction
    post_d_old = post_d;
    
end

end %[EoF]
