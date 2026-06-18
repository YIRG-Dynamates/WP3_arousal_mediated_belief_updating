function LL_trials = compLLallTrials(params,fitResultsStruct,ref_LL)
%Compute one column vector with the log-likelihood values for each trial.

% Check ref_LL input parameter (serves as a break from further computing LLs - used for speed-up during MCMC)   
if nargin < 3
    ref_LL = -inf;
end

% Unpack
trials_cell = fitResultsStruct.data.trials_cell;
trl_cond_nrs = fitResultsStruct.data.trl_cond_nrs;
responses = fitResultsStruct.data.responses;
num_trials = numel(trials_cell);

param_settings = fitResultsStruct.settings.param_settings;
model_settings = fitResultsStruct.settings.model_settings;
fit_settings = fitResultsStruct.settings.fit_settings;

% Back-transform the parameters and overwrite param_settings with the given values
params = transformParams(params,fit_settings.transforms,'trans2real');
param_settings = overwriteParams(params,param_settings,fit_settings);

% Subdivide the param_settings struct per condition
param_settings_cond = divideParamsPerCond(param_settings,fit_settings);

% Loop through all the trials and compute the log-likelihood for each
LL_trials = nan(num_trials,1); 
for i=1:num_trials 
    
    c = trl_cond_nrs(i);
    LL_trials(i) = compLLoneTrial(responses{i},trials_cell{i},param_settings_cond{c},model_settings,fit_settings);
    
    %Prematurely stop computing LL_trials if the current LL_total goes below some reference log-likelihood
    if sum(LL_trials) < ref_LL       
        return;
    end
end

end %[EoF]
