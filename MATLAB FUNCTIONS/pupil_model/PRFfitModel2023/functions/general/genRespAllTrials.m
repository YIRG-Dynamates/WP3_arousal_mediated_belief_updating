function generated_responses = genRespAllTrials(N,fitResultsStruct)
%Generate N responses for all trials.

% Unpack
trials_cell = fitResultsStruct.data.trials_cell;
trl_cond_nrs = fitResultsStruct.data.trl_cond_nrs;
num_trials = numel(trials_cell);

param_settings = fitResultsStruct.settings.param_settings;
model_settings = fitResultsStruct.settings.model_settings;
fit_settings = fitResultsStruct.settings.fit_settings;

% Subdivide the param_settings struct per condition
param_settings_cond = divideParamsPerCond(param_settings,fit_settings);

% Loop through all the trials and collect the generated responses
generated_responses = cell(num_trials,N);
for i=1:num_trials 
    c = trl_cond_nrs(i);
    generated_responses(i,:) = genRespOneTrial(N,trials_cell{i},param_settings_cond{c},model_settings,fit_settings);
end

end %[EoF]
