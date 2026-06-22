function LL_trial_struct = compLLoneTrial(trial_responses,trial_data,param_settings,model_settings,fit_settings)
%Compute log likelihood for one or more responses on this particular trial.   

%Retrieve stimulus locations from trial_data
x_true = trial_data.x;

%Remove NaNs from responses
d_resp = trial_responses.d_resp;
d_resp = d_resp(~isnan(d_resp));
assert(~isempty(d_resp),'There are no non-NaN d_resp responses for this trial. Please remove this trial from the input before calling BdCPfitModel');

%Compute a probability density function for the responses
[LikeFun,LikeFun_grid] = compLikeFunOneTrial(x_true,param_settings,model_settings,fit_settings);

%Compute the log likelihood of every response
frequencies = sum(d_resp == LikeFun_grid,1);

%Check that all responses were present in the discrete LikeFun_grid   
assert(numel(d_resp) == sum(frequencies),'Some response values are not present in the LikeFun_grid (i.e. unknown responses!)');

%Finally, compute the overall log-likelihood for this trial
LL_trial_struct.LL = sum(frequencies.*log(LikeFun));
%LL = nansum(frequencies.*log(LikeFun));
%Use nansum to avoid 0*log(0)=NaN. However, nansum may hide unexpected errors, so it's better to avoid its use and ensure that the likelihood is not 0 by imposing a lapse_rate > 0. 

end %[EoF]
