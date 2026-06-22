function [LikeFun,LikeFun_grid,latent_vars] = compLikeFunOneTrial(x_true,param_settings,model_settings,fit_settings)
%Compute a likelihood function for the model-predicted responses. 

%Unpack
lapse_rate = param_settings.lapse_rate;

%Generate a bunch of velocity estimation responses for this trial
if nargout <= 2
    post_d = genEstimatesOneTrial(x_true,param_settings,model_settings,fit_settings);
else %Also compute latent variables
    [post_d,latent_vars] = genEstimatesOneTrial(x_true,param_settings,model_settings,fit_settings);
end

%Quick check that the estimates do not contain NaNs
assert(~any(isnan(post_d)),'NaNs are present in the posterior decision variables post_d! Something is likely wrong.');

%There are only two possible responses (2AFC task)
LikeFun_grid = [-1, 1];                                                     %right = -1, left = 1 

%Compute the likelihood function: predicted probabability of a response
LikeFun = sum(sign(post_d) == LikeFun_grid)./fit_settings.num_sim_per_trial;

%Correct for lapse rate
LikeFun = lapse_rate.*[.5 .5] + (1-lapse_rate)*LikeFun; 

end %[EoF]
