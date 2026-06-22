function [post_d,latent_vars] = processOneStimulus(lambda,var_lik,current_d,param_settings,model_settings,fit_settings)
%Process one stimulus: Bayesian inference, updating the prior and computing latent variables   

%Extract some useful parameters and settings
hazard_rate = param_settings.cp_hazard_rate;
var_exp = param_settings.sd_exp^2;
mu_exp = param_settings.mu_exp;   

%Add experimental and sensory noise induced variances   
sd_sens_exp = sqrt(var_exp + var_lik);

%Update the prior (i.e. take a possible CP into account)
prior_d = exp(current_d);                                                                                       %1 exponential
prior_d = log(prior_d.*(1-hazard_rate)+hazard_rate)-log(prior_d.*hazard_rate+(1-hazard_rate));                  %2 logarithms    

%Compute the log-likelihood of observing lambda conditional on the velocity direction   
%log_lik_given_L = -0.5 * ((lambda - mu_exp)./sd_sens_exp).^2 - log(sd_sens_exp) - 0.5*log(2*pi);
%log_lik_given_R = -0.5 * ((lambda + mu_exp)./sd_sens_exp).^2 - log(sd_sens_exp) - 0.5*log(2*pi);
log_lik_L_minus_log_lik_R = (2*mu_exp*lambda)./(var_exp + var_lik);

%Compute the new decision variable 'post_d' --> this assumes multiplying of likelihood and prior!??   
%post_d = log_lik_given_L - log_lik_given_R + prior_d;
post_d = log_lik_L_minus_log_lik_R + prior_d;

%% Check the results using an alternative method of computation that is more intuitive, but slower (two exponentials more) and with more risks of numerical issues.    

if nargout >= 2 %These variables are used to compute the latent variables below..                               (we could change this dependency in future version)
    
    %Ensure stability of the latent variables
    stability_constant = 1e-9;
    stable = @(x) max(stability_constant,min(1-stability_constant,x));
    
    post_L_old = stable(1./(1+exp(-current_d)));                                                                %1 exponential
    %post_R_old = 1./(1+exp(current_d));
    post_R_old = 1-post_L_old; 
    
    prior_L = stable(post_L_old.*(1-hazard_rate) + post_R_old.*hazard_rate);
    %prior_R = post_R_old.*(1-hazard_rate) + post_L_old.*hazard_rate;
    prior_R = 1-prior_L;
    
    %prior_d_2 = log(prior_L)-log(prior_R);
    %assert(all(abs(prior_d-prior_d_2)<1e-6),['Error: prior_d not equal. Max difference is: ' num2str(max(abs(prior_d-prior_d_2)))]);
    
    lik_given_L = normpdf(lambda,mu_exp,sd_sens_exp);                                                           %2 exponentials
    lik_given_R = normpdf(lambda,-mu_exp,sd_sens_exp);
    post_L = stable( (lik_given_L.*prior_L) ./ (lik_given_L.*prior_L + lik_given_R.*prior_R) );
    %post_R = (lik_given_R.*prior_R) ./ (lik_given_L.*prior_L + lik_given_R.*prior_R);
    post_R = 1-post_L;
    
    %post_d_2 = log(lik_given_L.*prior_L)-log(lik_given_R.*prior_R);                                            %2 logarithms 
    %assert(all(abs(post_d-post_d_2)<1e-6),['Error: post_d not equal. Max difference is: ' num2str(max(abs(post_d-post_d_2)))]);
    
    
    %% Compute the "prior_entropy" latent variable
    if any(strcmp(fit_settings.latent_vars,'prior_entropy'))
        prior_entropy = -prior_L.*log2(prior_L)-prior_R.*log2(prior_R);                                         %Base 2 logarithm so that the entropy is bounded between 0 and 1
    end 

    %% Compute the surprisal latent variable
    if any(strcmp(fit_settings.latent_vars,'surprisal'))
        surprisal = -log2(lik_given_L.*prior_L + lik_given_R.*prior_R);                                         %Unit = "bit" or "shannon"
    end

    %% Compute the "post_prob_CP" latent variable 
    if any(strcmp(fit_settings.latent_vars,'post_prob_CP'))
        prob_CP = hazard_rate.*(lik_given_L.*post_R_old + lik_given_R.*post_L_old);
        prob_noCP = (1-hazard_rate).*(lik_given_L.*post_L_old + lik_given_R.*post_R_old);
        post_prob_CP = prob_CP ./ (prob_CP + prob_noCP);                                                        %Posterior probability of a change-point           
    end 

    %% Compute the "post_entropy" latent variable   
    if any(strcmp(fit_settings.latent_vars,'post_entropy'))
        post_entropy = -post_L.*log2(post_L)-post_R.*log2(post_R);                                              %Base 2 logarithm so that the entropy is bounded between 0 and 1
    end 

    %% Compute the "info_gain" latent variable (Jensen–Shannon distance) 
    if any(strcmp(fit_settings.latent_vars,'info_gain'))                                                         
        P = [prior_L, prior_R];
        Q = [post_L, post_R];
        M = mean([P;Q]);

        KL_div = @(p,q) sum(p.*log2(p./q),2);                                                                   %Bounded between 0 and 1 because we used a base 2 logarithm
        info_gain = sqrt(.5.*(KL_div(P,M)+KL_div(Q,M)));                                                        %See: https://en.wikipedia.org/wiki/Jensen%E2%80%93Shannon_divergence
    end 

    %% Collect all the requested latent variables in one structure
    for i=1:length(fit_settings.latent_vars)
        eval(['latent_vars.(fit_settings.latent_vars{i}) = ' fit_settings.latent_vars{i} ';']);
    end

end

end %[EoF]
