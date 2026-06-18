function LL_trial = compLLoneTrial(trial_response,trial_struct,param_settings,model_settings,fit_settings)
%Compute one log likelihood for one or more responses on this particular trial   

%Compute one (model-predicted) pupil trace
y_pred = compOnePupilTrace(trial_struct,param_settings,model_settings,trial_response);
    
%Compute the log-likelihood of this prediction given the response
y = trial_response(:);
rmse = sqrt(sum((y-y_pred).^2)/size(y,1));
LL_trial = nansum(normlogpdf(y,y_pred,rmse));       %Note NANSUM!

end %[EoF]
