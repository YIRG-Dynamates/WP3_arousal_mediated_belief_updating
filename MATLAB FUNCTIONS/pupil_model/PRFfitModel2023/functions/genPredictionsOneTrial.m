function predictions_trial = genPredictionsOneTrial(trial_struct,param_settings,model_settings,fit_settings,trial_response)
%Generate predictions for one trial and optionally plot results

%Compute one (model-predicted) pupil trace
[y_pred,PRFinfo] = compOnePupilTrace(trial_struct,param_settings,model_settings,trial_response);

%Collect in a structure
predictions_trial.y_pred = y_pred;
predictions_trial.PRFinfo = PRFinfo;

end %[EoF]