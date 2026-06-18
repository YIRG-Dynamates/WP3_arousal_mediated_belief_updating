% found on the internet to circumvent the boxcox transform from th
% efinancial toolbox, which i dont have

function [y_trans, best_lambda] = boxcox_auto(data)
    % 1. Find optimal lambda using fminsearch
    % We minimize the negative log-likelihood
    obj = @(lam) -boxcox_llf(data, lam);
    best_lambda = fminsearch(obj, 0); % Start search at lambda = 0

    % 2. Apply transformation
    if best_lambda == 0
        y_trans = log(data);
    else
        y_trans = (data.^best_lambda - 1) / best_lambda;
    end
end

function llf = boxcox_llf(data, lambda)
    % Log-Likelihood Function for Box-Cox
    n = length(data);
    y_trans = (data.^lambda - 1) / lambda;
    if lambda == 0, y_trans = log(data); end
    
    sigma2 = var(y_trans) * (n-1) / n;
    % Log-likelihood formula
    llf = -n/2 * log(sigma2) + (lambda-1) * sum(log(data));
end