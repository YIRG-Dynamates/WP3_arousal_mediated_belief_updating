function predictions = genPredictionsAllTrials(fitResultsStruct,fitted_params,max_trial)
% Generate predictions for all (or some) trials and optionally plot results

%Unpack settings
param_settings = fitResultsStruct.settings.param_settings;
model_settings = fitResultsStruct.settings.model_settings;
fit_settings = fitResultsStruct.settings.fit_settings;
disp_settings = fitResultsStruct.settings.disp_settings;

%Set max_trial (or fit_settings.gen_predictions) to a lower integer if you don't wish to compute predictions for all trials
if nargin < 3
    if islogical(fit_settings.gen_predictions)  %Don't use fit_settings.gen_predictions
        max_trial = numel(fitResultsStruct.data.trials_cell);     
    else                                        %Use fit_settings.gen_predictions to set the maximum number of trials
        assert(isnumeric(fit_settings.gen_predictions) && isscalar(fit_settings.gen_predictions),'If not a logical, then "fit_settings.gen_predictions" should be a postive numeric scalar');
        assert(round(fit_settings.gen_predictions) > 0,'If not a logical, then "fit_settings.gen_predictions" should be a postive numeric scalar');
        max_trial = round(fit_settings.gen_predictions);
    end
end

%Continue unpacking
trials_cell = fitResultsStruct.data.trials_cell(1:max_trial);
trl_cond_nrs = fitResultsStruct.data.trl_cond_nrs(1:max_trial);

%Deal with responses (in case of plotting results against predictions)
if isempty(fitResultsStruct.data.responses)
    responses = cell(max_trial,1);
else
    responses = fitResultsStruct.data.responses(1:max_trial);
end

%Overwrite param_settings with the fitted 'params' 
if nargin >= 2
    param_settings = overwriteParams(fitted_params,param_settings,fit_settings);
end         

%Subdivide the param_settings struct per condition
param_settings_cond = divideParamsPerCond(param_settings,fit_settings);

%Loop through all the trials and collect the predicted responses
predictions = cell(max_trial,1);
for i=1:max_trial 
    c = trl_cond_nrs(i);
    predictions{i} = genPredictionsOneTrial(trials_cell{i},param_settings_cond{c},model_settings,fit_settings,responses{i});
    
    %Plot predictions for this trial
    if disp_settings.trials
        plotOneTrial(trials_cell{i},responses{i},predictions{i},c,param_settings_cond{c},model_settings,fit_settings);
    end
end

%Plot predictions overview for all trials
if disp_settings.overall
    plotallTrials(trials_cell,trl_cond_nrs,predictions,responses);
end

end %[EoF]