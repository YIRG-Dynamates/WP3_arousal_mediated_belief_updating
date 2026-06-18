function pred_trial_struct = genPredictionsOneTrial(trial_data,param_settings,model_settings,fit_settings,trial_responses)
%Generate predictions for one trial 

%Compute one (model-predicted) pupil trace
[pupil_pred,~,PRFinfo] = compOnePupilTrace(trial_data,param_settings,model_settings,trial_responses);

%Collect in a structure
pred_trial_struct.pupil_pred = pupil_pred;
pred_trial_struct.PRFinfo = PRFinfo;

end %[EoF]
