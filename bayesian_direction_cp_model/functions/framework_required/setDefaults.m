function S = setDefaults()
% Define the defaults parameter settings and parameter bounds. 

%Parameter values for params that can be fitted
S.param_settings.cp_hazard_rate = 1/5;                                      %Assumed hazard rate is the same as the true hazard rate
S.param_settings.sd_sens = 4;                                               %sigma of (auditory) sensory noise on velocity (i.e. equivalent to MAA)
S.param_settings.k_azimuth_sens = 0;                                        %if k>0, sensory noise increases linearly with k*abs(azimuth)
S.param_settings.lapse_rate = 0.01;                                         %lapse rate 
S.param_settings.sd_exp = 4;                                                %sigma of assumed experimental noise (see generative model)
S.param_settings.mu_exp = 4;                                                %mu of assumed experimental noise (see generative model)

%Model settings
S.model_settings.dummy = [];                                                %Just make sure that the field "model_settings" exists to avoid errors

%Fitting settings
S.fit_settings.param_logit = {'cp_hazard_rate','lapse_rate'};               %Fit these parameters in logit space (bounded by 0 and 1)
S.fit_settings.param_log = {'sd_sens','k_azimuth_sens','sd_exp','mu_exp'};  %Fit these parameters in log space (lower bound is 0)
         
S.fit_settings.fit_param_names = {};                                        %The names of the parameters to fit (e.g. {'cp_hazard_rate','sd_pred'}). By default we don't fit anything. Indices here determine the param numbers.
S.fit_settings.fit_param_nrs_per_cond = cell(1);                            %The number of cells defines the number of conditions. An integer c inside a vector of cell j means that parameter c belongs to condition j.
                                                                            %E.g. {[1 2]} means that the first two parameters belong to the first (and only) condition. 
                                                                            
S.fit_settings.num_sim_per_trial = 1e3;                                     %Number of simulated responses per trial
S.fit_settings.optim_MLE_or_MAP = 'MLE';                                    %Optimize parameters to obtain MLE or MAP?    
S.fit_settings.optim_num_grid = 1e3;                                        %Number of randomly selected grid points that are candidate starting points for the BADS searches
S.fit_settings.optim_tol_mesh = 1e-3;                                       %The mesh is scaled between the plausible bounds (PUB-PLB = 1). BADS calls convergence when values change < optim_tol_mesh (BADS default = 1e-6).
S.fit_settings.optim_num_attempts = [1 4];                                  %Number of BADS convergence attempts [MIN MAX]. The highest log-probability solution is chosen as best out of all converged solutions.

S.fit_settings.gen_predictions = true;                                      %Should we generate predictions with the fitted parameters?
S.fit_settings.latent_last_only = false;                                    %Only generate latent variables for the last stimulus of each trial?      

%Set all the latent variables that you wish to compute (all by default)
S.fit_settings.latent_vars = {'lambda','var_lik','prior_d','post_d', ...
                              'prior_entropy','surprisal','post_prob_CP','post_entropy','info_gain'};
                          
%Display settings
S.disp_settings.trials = true;                                              %Should we display predictions for each trial?
S.disp_settings.overall = true;                                             %Should we display overall predictions?

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameter bounds %%% 
%%%%%%%%%%%%%%%%%%%%%%%%

% Parameter bounds are only used for parameters that are fitted. They are ignored for fixed parameter values.  
% The bounds can sometimes be more restrictive than the default setting because of the log/logit transformations that are used for fitted parameters.   

% Please note that the parameter bounds also define the prior probability distributions. 
% Priors are defined as trapezoids with highest probability between the plausible bounds, and linearly decreasing on either side towards the hard bounds). 

% Be realistic when changing the parameter bounds. Extraordinarily small/large bounds do not help the fitting algorithms!
% In fact, BADS convergence depends on the plausible bounds settings. The algorithm converges when the parameter values don't change more than optim_tol_mesh*(PUB-PLB).

%Define default bounds:                   [Hard Lower, Plausible Lower, Plausible Upper, Hard Upper]    
S.fit_settings.bounds.cp_hazard_rate  =   [   1e-9          0.1             0.9             1-1e-9   ];                 %Don't use 0 as a lower bound for the log/logit transformed parameters
S.fit_settings.bounds.sd_sens         =   [   1e-2          1               7              20        ];                 %Likewise, don't use 1 as an upper bound for the logit transformed parameters
S.fit_settings.bounds.k_azimuth_sens  =   [   1e-9          1e-3            0.1             1        ];                 %0 and 1 in those cases would lead to +/- inf problems.. 
S.fit_settings.bounds.lapse_rate      =   [   1e-9          1e-3            0.1             1-1e-9   ];
S.fit_settings.bounds.sd_exp          =   [   1e-2          1               7              20        ];                 %N.B. These are parameter values in the non-transformed space
S.fit_settings.bounds.mu_exp          =   [   1e-2          1               7              20        ];          

end %[EOF]
