function generated_responses_trial = genRespOneTrial(N,trial_struct,param_settings,model_settings,fit_settings)
%Generate N responses for one particular trial. 

%Initialize output
generated_responses_trial = cell(1,N);

%Define parameters names
param_names = {'AV_delta_amp';'AV_delta_lat';'AV_t_max';'AV_n_shape'; ...
                'A_delta_amp'; 'A_delta_lat'; 'A_t_max'; 'A_n_shape'; ...
                'y_intercept'};

%Get number of stimuli
num_stim = [ones(4,1)*numel(trial_struct.stim_times_AV); ones(4,1)*numel(trial_struct.stim_times_A); 1];


%Generate N responses with noise-disturbed parameters
for j_resp=1:N
    
    param_settings_tmp = param_settings;
    
    %Prepare parameters one by one (expand and add noise)
    for j=1:numel(param_names)
        
        %Expand parameters for each stimulus
        param_settings_tmp.(param_names{j}) = ones(num_stim(j),1).*param_settings_tmp.(param_names{j}); 

        %Add independent noise to each parameter with SD equal to (PUB-PLB)/6
        SD = (fit_settings.bounds.(param_names{j})(3)-fit_settings.bounds.(param_names{j})(2))/6;
        noise = SD*randn([num_stim(j),1]);
        param_settings_tmp.(param_names{j}) = param_settings_tmp.(param_names{j})+noise; 

        %Ensure that the parameters don't go out of bounds
        param_settings_tmp.(param_names{j}) = max(param_settings_tmp.(param_names{j}),fit_settings.bounds.(param_names{j})(1));
        param_settings_tmp.(param_names{j}) = min(param_settings_tmp.(param_names{j}),fit_settings.bounds.(param_names{j})(4));
    end

    %Compute a response given the noise-corrupted parameter settings
    generated_responses_trial{j_resp} = compOnePupilTrace(trial_struct,param_settings_tmp,model_settings);
end
    
end %[EoF]