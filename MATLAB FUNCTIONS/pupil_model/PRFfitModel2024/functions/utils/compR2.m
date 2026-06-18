function R2 = compR2(y,y_pred)
%Compute R squared, coefficient of determination (i.e. fraction of variance
%explained) for model predictions (y_pred) against true data (y).

assert(isequal(size(y),size(y_pred)),'y and y_pred need to be same size');

%remove nans
nans = isnan(y) | isnan(y_pred);
y(nans) = [];
y_pred(nans) = [];

%compute R squared
if isempty(y)
    R2 = NaN;
else
    SSE = sum((y-y_pred).^2);     %sum of squared errors
    SST = sum((y-mean(y)).^2);    %sum of squares total
    R2 = 1-SSE/SST;               %note that R squared can be negative 
end                               %e.g. if no intercept was used during OLS

end %[EoF]
