function S = setDefaults()
% Define the defaults parameter settings and parameter bounds. 

%Parameter values for params that can be fitted
S.param_settings.AV_delta_amp = 1;                                          %Fixed amplitude of the AV delta function input signals (but see: model_settings.delta_amp_free)
S.param_settings.AV_delta_lat = 0;                                          %Latency of the AV delta function input signals 
S.param_settings.AV_t_max = 930;                                            %Latency (in samples) at which the pupil impulse response function reaches its maximum for AV stimuli
S.param_settings.AV_n_shape = 10.1;                                         %Shape parameter for the pupil impulse response function for AV stimuli

S.param_settings.A_delta_amp = 1;                                           %Fixed amplitude of the A delta function input signals (but see: model_settings.delta_amp_free)
S.param_settings.A_delta_lat = 0;                                           %Latency of the A delta function input signals
S.param_settings.A_t_max = 930;                                             %Latency (in samples) at which the pupil impulse response function reaches its maximum for A stimuli
S.param_settings.A_n_shape = 10.1;                                          %Shape parameter for the pupil impulse response function for A stimuli

S.param_settings.y_intercept = 0;                                           %Fixed y_intercept (amplitude offset) for all trials (but see: model_settings.trial_intercept_free)

%Model settings 
S.model_settings.delta_amp_free = true;                                     %Find the best fitting stimulus amplitudes by means of ordinary least squares regression?
S.model_settings.trial_intercept_free = true;                               %Find the best fitting y-intercept (amplitude offset) by means of ordinary least squares regression?

%Fitting settings
S.fit_settings.param_logit = {};                                            %Fit these parameters in logit space (bounded by 0 and 1)
S.fit_settings.param_log = {};                                              %Fit these parameters in log space (lower bound is 0)
         
S.fit_settings.fit_param_names = {};                                        %The names of the parameters to fit (e.g. {'cp_hazard_rate','sd_pred'}). By default we don't fit anything. Indices here determine the param numbers.
S.fit_settings.fit_param_nrs_per_cond = cell(1);                            %The number of cells defines the number of conditions. An integer c inside a vector of cell j means that parameter c belongs to condition j.
                                                                            %E.g. {[1 2]} means that the first two parameters belong to the first (and only) condition. 
                                                                            
S.fit_settings.optim_MLE_or_MAP = 'MLE';                                    %Optimize parameters to obtain MLE or MAP?    
S.fit_settings.optim_num_grid = 1e3;                                        %Number of randomly selected grid points that are candidate starting points for the BADS searches
S.fit_settings.optim_tol_mesh = 1e-3;                                       %The mesh is scaled between the plausible bounds (PUB-PLB = 1). BADS calls convergence when values change < optim_tol_mesh (BADS default = 1e-6).
S.fit_settings.optim_num_attempts = [1 4];                                  %Number of BADS convergence attempts [MIN MAX]. The highest log-probability solution is chosen as best out of all converged solutions.

S.fit_settings.gen_predictions = true;                                      %Should we generate predictions with the fitted parameters?
                         
%Display settings
S.disp_settings.trials = true;                                              %Should we display predictions for each trial?
S.disp_settings.overall = true;                                             %Should we display overall predictions?

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameter bounds %%%
%%%%%%%%%%%%%%%%%%%%%%%%

% Please, note that the parameter bounds are extremely important for two reasons.   
% 1) they also define the prior probability distributions, which will be defined as trapezoids with highest probability between the plausible bounds, and linearly decreasing on either side towards the hard bounds. 
% 2) BADS uses the plausible bounds to determine whether the algorithm has converged: In "optimParams.m" we set TolMesh to 1e-3. This means that BADS converges when the parameter values don't change more than 1e-3*(PUB-PLB). 
% Hence, be realistic when changing the parameter bounds. Extraordinarily small/large bounds do not aid the fitting algorithms, nor will they lead to plausible ELBO values (in case of VBMC).  

%Define default bounds:                   [Hard Lower, Plausible Lower, Plausible Upper, Hard Upper]    
S.fit_settings.bounds.AV_delta_amp  =   [     -10             0               2              10      ];                 %Don't use 0 as a lower bound for the log/logit transformed parameters
S.fit_settings.bounds.AV_delta_lat  =   [    -250             0             100             250      ];                 %Likewise, don't use 1 as an upper bound for the logit transformed parameters
S.fit_settings.bounds.AV_t_max      =   [     100           500            1500            3000      ];                 %0 and 1 in those cases would lead to +/- inf problems.. 
S.fit_settings.bounds.AV_n_shape    =   [       1             6              14              20      ];

S.fit_settings.bounds.A_delta_amp   =   [     -10             0               2              10      ];                 
S.fit_settings.bounds.A_delta_lat   =   [    -250             0             100             250      ];                 
S.fit_settings.bounds.A_t_max       =   [     100           500            1500            3000      ];                 
S.fit_settings.bounds.A_n_shape     =   [       1             6              14              20      ];

S.fit_settings.bounds.y_intercept   =   [     -10            -1               1              10      ];                 

end %[EOF]
