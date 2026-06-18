function [y_pred,errors,PRFinfo,PRFmat] = compOnePupilTrace(trial_struct,param_settings,model_settings,trial_response)
%Compute one (model-predicted) pupil trace

if nargin < 4
    trial_response = [];
end

%Create a PRF matrix
[PRFmat,PRFinfo] = createPRFmat(trial_struct,param_settings);
num_stim = PRFinfo.num_stim;

%Randomly assign event-related PRF amplitudes if no response data is available   
if isempty(trial_response)
    
    PRFinfo.delta_amp = rand(num_stim,1);                                       
    PRFinfo.boxcar_amp = randn(num_stim,1)/3;
    PRFinfo.y_intercept = randn(1); 
    
    %Compute the (model-predicted) pupil trace
    y_pred = PRFmat*[PRFinfo.delta_amp; PRFinfo.boxcar_amp; PRFinfo.y_intercept];
    
    errors = nan(size(y_pred)); %dummy
    
%Use constrained regression to find event-related PRF amplitudes
else
    
    %Obtain pupil trace
    pupil_resp = trial_response.pupil_resp(:);
    trial_length = trial_struct.trial_length;
    assert(numel(pupil_resp) == trial_length,'Number of samples in the pupil response is not equal to "trial_length"');
    
    %Prais-Winsten Transformation                                           
    rho = param_settings.auto_corr;                                         %autocorrelation of errors with order one: AR(1) model
    v = [sqrt(1-rho^2) ones(1,trial_length-1)];                             %helper vector to construct matrix w below
    w = diag(v) + diag(-rho*ones(1,trial_length-1),-1);                     %weight matrix (see: https://bookdown.org/mike/data_analysis/feasiable-prais-winsten.html)
    
    pupil_resp_trans = w*pupil_resp;                                        %Note that when rho=1, then this leads to the 'First Differences Procedure' (https://online.stat.psu.edu/stat462/node/189/)         
    PRFmat_trans = w*PRFmat;
    
    %Initialize model-prediction
    y_pred = nan(trial_length,1);
    errors = nan(trial_length,1);
    
    if ~all(isnan(pupil_resp_trans))
        
        %Remove NaNs
        i_nans = isnan(pupil_resp_trans);
        d = pupil_resp_trans(~i_nans);
        PRFmat_no_nans = PRFmat_trans(~i_nans,:);
        
        %Initialize regression coefficients and lower-bounds
        betas = nan(size(PRFmat_trans,2),1);
        LBs = [zeros(num_stim,1); -inf*ones(num_stim+1,1)];
        
        %Special case: Intercept only
        if ~model_settings.fit_delta_amp && ~model_settings.fit_boxcar_amp
            
            i_remove_regressors = [true(1,2*num_stim), false(1)];
            
            C = PRFmat_no_nans(:,end);
            x = mean(d);
        
        else
            
            %Remove regressors if they would only contain near zero values after removal of nans   
            i_remove_regressors = all(PRFmat_no_nans < eps,1);
        
            if model_settings.fit_delta_amp && model_settings.fit_boxcar_amp

                %Don't remove any of the other regressors
                
            elseif model_settings.fit_delta_amp && ~model_settings.fit_boxcar_amp
                
                %Remove boxcar regressors
                i_remove_regressors = i_remove_regressors | [false(1,num_stim), true(1,num_stim), false(1)];

            elseif ~model_settings.fit_delta_amp && model_settings.fit_boxcar_amp
                
                %Remove impulse regressors
                i_remove_regressors = i_remove_regressors | [true(1,num_stim), false(1,num_stim+1)];
                
            end
            
            %Constrained linear least squares
            %C*x = d
            %A*x <= b
            C = PRFmat_no_nans(:,~i_remove_regressors);
            b = -1*LBs(~i_remove_regressors);
            A = -1*eye(numel(b));                 %Negated identity matrix
            
            options = optimoptions('lsqlin','Algorithm','interior-point','Display','off');
            x = lsqlin(C,d,A,b,[],[],[],[],[],options);
            
        end
        
        %Save the regression residuals
        errors(~i_nans,1) = d - C*x;
        
        %Register the regression coefficients
        betas(~i_remove_regressors) = x;
        
        PRFinfo.delta_amp = betas(1:num_stim);                                       
        PRFinfo.boxcar_amp = betas(num_stim+(1:num_stim));
        
        %Compute the best fitting intercept for the non-transformed time-series   
        i_remove_cols = i_remove_regressors; i_remove_cols(end) = true;
        y_pred_tmp = PRFmat(~i_nans,~i_remove_cols)*betas(~i_remove_cols);
        PRFinfo.y_intercept = mean(pupil_resp(~i_nans)-y_pred_tmp);
        % if rho < 0.99
        %     PRFinfo.y_intercept = betas(end) / (1-rho);                                                                         %https://online.stat.psu.edu/stat462/node/189/
        % else 
        %     PRFinfo.y_intercept = mean(pupil_resp(~i_nans)) - mean(PRFmat(~i_nans,~i_remove_cols),1)*betas(~i_remove_cols);     %First Differences Procedure (see link above)
        % end
        
        %Predict the pupil-trace for all non-NaN samples
        y_pred(~i_nans,1) = y_pred_tmp + PRFinfo.y_intercept;               %This is a prediction without the autocorrelation!
        
    %if all NaN in trial_response    
    else
        
        PRFinfo.delta_amp = nan(num_stim,1);                                       
        PRFinfo.boxcar_amp = nan(num_stim,1);
        PRFinfo.y_intercept = NaN; 
        
    end
end

end %[EoF]
