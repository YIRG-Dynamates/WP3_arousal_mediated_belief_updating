function S = setDefaults()
% Define the defaults parameter settings and parameter bounds. 

%Parameter values for params that can be fitted
S.param_settings.PRF_amp = 1;                                               %Fixed amplitude of the Pupil Response Function (this is multiplied with 'delta_amp' and 'boxcar_amp' if these are regressed)
S.param_settings.PRF_t_max = 930;                                           %Latency (in samples) at which the Pupil Response Function reaches its maximum
S.param_settings.PRF_n_shape = 10.1;                                        %Shape parameter for the Pupil Response Function

S.param_settings.delta_lat = 0;                                             %Latency offset (in samples) of the delta impulses
S.param_settings.boxcar_lat = 0;                                            %Latency offset (in samples) of the boxcar input functions
S.param_settings.boxcar_dur = 500;                                          %Duration (in samples) of the boxcar input functions

S.param_settings.auto_corr = 1;                                             %Auto-correlation of pupil-trace time-series   

%Model settings 
S.model_settings.fit_delta_amp = true;                                      %Regress to find the best fitting delta function (non-negative) amplitudes to model phasic input?
S.model_settings.fit_boxcar_amp = true;                                     %Regress to find the best fitting boxcar function amplitudes to model tonic input?

S.model_settings.use_t_distribution = true;                                 %Use t-distribution to robustly compute log-likelihoods? (alternative is to use a normal distribution)

%Fitting settings
S.fit_settings.param_log = {'PRF_amp','PRF_t_max','PRF_n_shape','boxcar_dur'};  %Fit these parameters in log space (lower bound is 0)                                           
S.fit_settings.param_logit = {'auto_corr'};                                     %Fit these parameters in logit space (bounded by 0 and 1)
                        
S.fit_settings.fit_param_names = {};                                        %The names of the parameters to fit (e.g. {'intercept','sd','slope','slope'}). By default we don't fit anything. Indices determine param numbers.
S.fit_settings.fit_param_nrs_per_cond = cell(1,1);                          %The number of cells defines the number of conditions. An integer c inside a vector of cell j means that parameter c belongs to condition j.
                                                                            %E.g. {[1 2 3],[1 2 4]} means that the first two parameters belong to both conditions, whereas param 3 is for cond 1 and param 4 for cond 2. 

S.fit_settings.optim_MLE_or_MAP = 'MLE';                                    %Optimize parameters to obtain MLE or MAP (using trapezoid priors, see below)    
S.fit_settings.optim_tol_mesh = 1e-6;                                       %BADS converges when the parameter values don't change more than optim_tol_mesh*(PUB-PLB) 
S.fit_settings.optim_num_attempts = [1 4];                                  %Number of BADS convergence attempts [MIN MAX]. The highest log-probability solution is chosen as best out of all converged solutions.
S.fit_settings.optim_num_grid = 1e3;                                        %Number of samples that are randomly drawn from within plausible bounds to find suitable starting points for BADS

S.fit_settings.gen_predictions = true;                                      %Should we generate predictions with the fitted parameters? Logical or ...
                                                                            %Set fit_settings.gen_predictions to a vector of positive integers indicating the indices of trials you wish to compute predictions for
%Display settings
S.disp_settings.overall = true;                                             %Should we display overall predictions? (Logical)
S.disp_settings.trials = true;                                              %Should we display predictions for each trial? Logical or ...
                                                                            %Set disp_settings.trials to a vector of positive integers indicating the indices of trials you wish to display predictions for
%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameter bounds %%% 
%%%%%%%%%%%%%%%%%%%%%%%%

% Parameter bounds are only used for parameters that are fitted. They are ignored for fixed parameter values.  
% The bounds can sometimes be more restrictive than the default setting because of the log/logit transformations that are used for fitted parameters.   

% Please note that the parameter bounds also define the prior probability distributions. 
% Priors are defined as trapezoids with highest probability between the plausible bounds, and linearly decreasing on either side towards the hard bounds). 

% Be realistic when changing the parameter bounds. Extraordinarily small/large bounds do not help the fitting algorithms!
% In fact, BADS convergence depends on the plausible bounds settings. The algorithm converges when the parameter values don't change more than optim_tol_mesh*(PUB-PLB).

% Default bounds:                           [Hard Lower, Plausible Lower, Plausible Upper, Hard Upper]    
S.fit_settings.bounds.PRF_amp =             [       1e-3          0.1            10            1000  ];                 %These are parameter values in the non-transformed space
S.fit_settings.bounds.PRF_t_max  =          [     100           500            1500            3000  ];                 
S.fit_settings.bounds.PRF_n_shape =         [       1             6              14              20  ];                 

S.fit_settings.bounds.delta_lat =           [    -250             0             100             250  ];                 %Don't use 0 as a lower bound for the log/logit transformed parameters
S.fit_settings.bounds.boxcar_lat  =         [    -250             0             100             250  ];                 %Likewise, don't use 1 as an upper bound for the logit transformed parameters
S.fit_settings.bounds.boxcar_dur =          [       1           100            1000           20000  ];                 %0 and 1 in those cases would lead to +/- inf problems.. 

S.fit_settings.bounds.auto_corr =           [       1e-6          0.01            0.99        1-1e-6 ];

end %[EOF]
