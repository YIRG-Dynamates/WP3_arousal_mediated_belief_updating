function [y_pred,PRFinfo,PRFmat] = compOnePupilTrace(trial_struct,param_settings,model_settings,trial_response)
%Compute one (model-predicted) pupil trace

if nargin < 4
    trial_response = [];
end

%Create a PRF matrix
[PRFmat,PRFinfo] = createPRFmat(trial_struct,param_settings);
i_remove_regressors = false(1,size(PRFmat,2)-1);

%Should we use regression to find stimuli amplitudes and/or intercept values?
if ~isempty(trial_response)
    if ~all(isnan(trial_response))
        
        %Remove regressors if they would only contain near zero values after removal of nans   
        nans = isnan(trial_response(:));
        i_remove_regressors = all(PRFmat(~nans,:) < eps,1);
        PRFmat(:,i_remove_regressors) = [];
        i_remove_regressors(end) = [];                                      %The intercept is never removed
        
        if model_settings.delta_amp_free && model_settings.trial_intercept_free
            betas = lm_fast(PRFmat,trial_response);
            PRFinfo.delta_amp(i_remove_regressors) = NaN;                   %Set amplitude estimates to NaN if we cannot estimate them
            PRFinfo.delta_amp(~i_remove_regressors) = betas(1:(end-1));
            PRFinfo.y_intercept = betas(end);
        elseif model_settings.delta_amp_free && ~model_settings.trial_intercept_free
            betas = lm_fast(PRFmat(:,1:(end-1)),trial_response);
            PRFinfo.delta_amp(i_remove_regressors) = NaN;                   %Set amplitude estimates to NaN if we cannot estimate them
            PRFinfo.delta_amp(~i_remove_regressors) = betas;
        elseif ~model_settings.delta_amp_free && model_settings.trial_intercept_free
            PRFinfo.y_intercept = lm_fast(PRFmat(:,end),trial_response);
        end
    else %if all NaN in trial_response
        if model_settings.delta_amp_free; PRFinfo.delta_amp(:) = NaN; end
        if model_settings.trial_intercept_free; PRFinfo.y_intercept = NaN; end
    end
else %if isempty(trial_response)
    %Do nothing: leave delta_amps and intercept at preset values
end

%Compute the (model-predicted) pupil trace
y_pred = PRFmat*[PRFinfo.delta_amp(~i_remove_regressors); PRFinfo.y_intercept];

end %[EoF]
