function generated_responses_trial = genRespOneTrial(N,trial_data,param_settings,model_settings,fit_settings)
%Generate N responses for one particular trial. 

%Initialize output
generated_responses_trial = cell(1,N);

%Retrieve stimulus locations from trial_data
x_true = trial_data.x;

%Compute a probability function for the responses (probability for 2AFC options)   
[LikeFun,LikeFun_grid] = compLikeFunOneTrial(x_true,param_settings,model_settings,fit_settings);

%Randomly sample from the response PDF
generated_responses = LikeFun_grid((rand([N 1]) > LikeFun(1))+1);  %[0;1] --> [1;2] --> [LikeFun_grid(1);LikeFun_grid(2)]

%Save responses in the cell-array
for j=1:N
    generated_responses_trial{1,j}.d_resp = generated_responses(j);
end

end %[EoF]
