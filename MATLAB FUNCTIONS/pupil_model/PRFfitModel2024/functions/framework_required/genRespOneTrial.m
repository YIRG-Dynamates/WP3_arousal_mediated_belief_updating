function generated_responses_trial = genRespOneTrial(N,trial_data,param_settings,model_settings,fit_settings)
%Generate N responses for one particular trial. 

%Initialize output
generated_responses_trial = cell(1,N);

%Generate N pupil responses
for j_resp=1:N
    
    param_settings_tmp = param_settings;
    
    %Compute a response given the noise-corrupted parameter settings
    generated_responses_trial{1,j_resp}.pupil_resp = compOnePupilTrace(trial_data,param_settings_tmp,model_settings);
end

end %[EoF]
