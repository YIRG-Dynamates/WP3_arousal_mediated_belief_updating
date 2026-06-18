function [y_trans, best_lambda] = boxcox_auto_2(data)

    if any(data <= 0)
        error('Box-Cox requires strictly positive data.');
    end

    obj = @(lam) -boxcox_llf(data, lam);
    best_lambda = fminbnd(obj, -5, 5);

    if abs(best_lambda) < 1e-8
        y_trans = log(data);
    else
        y_trans = (data.^best_lambda - 1) / best_lambda;
    end
end


function llf = boxcox_llf(data, lambda)

    n = length(data);

    if abs(lambda) < 1e-8
        y_trans = log(data);
    else
        y_trans = (data.^lambda - 1) / lambda;
    end

    sigma2 = var(y_trans) * (n-1) / n;

    llf = -n/2 * log(sigma2) + (lambda-1) * sum(log(data));
end