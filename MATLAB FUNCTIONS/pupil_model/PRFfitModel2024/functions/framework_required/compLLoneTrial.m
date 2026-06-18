function LL_trial_struct = compLLoneTrial(trial_responses,trial_data,param_settings,model_settings,fit_settings)
%Compute log likelihood for one or more responses on this particular trial.   

%Compute one (model-predicted) pupil trace
[~,errors] = compOnePupilTrace(trial_data,param_settings,model_settings,trial_responses);
 
%Save the prediction errors, and use them to compute the LL in postprocessLLs.m
LL_trial_struct.errors = errors;

end %[EoF]
