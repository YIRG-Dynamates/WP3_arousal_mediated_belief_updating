function pred_trial_struct = genPredictionsOneTrial(trial_data,param_settings,model_settings,fit_settings,trial_responses)
%Generate predictions for one trial 

%Retrieve stimulus locations from trial_data
x_true = trial_data.x;

%Do the work! Compute the estimates and latent variables etc. for this stimulus
[LikeFun,LikeFun_grid,latent_vars] = compLikeFunOneTrial(x_true,param_settings,model_settings,fit_settings);

%Save in output struct
pred_trial_struct.LikeFun = LikeFun;
pred_trial_struct.LikeFun_grid = LikeFun_grid;
pred_trial_struct.latent_vars = latent_vars;

end %[EoF]
