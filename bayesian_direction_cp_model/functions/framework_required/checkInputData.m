function checkInputData(fitResults)
%Do some model-specific checks on the input_data and model settings S

input_data = fitResults.data;
S = fitResults.settings;

num_trials = length(input_data.trials_cell);

%% Check necessary items in "trials_cell"
    
assert(all(cellfun(@(C) isfield(C,'x'),input_data.trials_cell)),'It appears that not all cells in input_data.trials_cell contain a field "x"');

%% Check necessary items in "responses"
if ischar(input_data.responses)
    
    %%% Simulate N responses %%%

elseif isempty(input_data.responses)
    
    %%% Generate model predictions %%%
    if S.fit_settings.gen_predictions
        
    end
    
else
    
    %%% Compute LLs %%%
    assert(all(cellfun(@(C) isfield(C,'d_resp'),input_data.responses)),'It appears that not all cells in input_data.responses contain a field "d_resp"');
    
    %%% Fit parameters to the responses? %%%
    if S.fit_settings.num_params > 0
        
    end
    
    %%% Compute predictions too? %%%
    if S.fit_settings.gen_predictions
        
    end
end

%% Check "trl_cond_nrs" against the expected number of conditions

uniq_cond_indices = unique(input_data.trl_cond_nrs(:));
assert(isequal(uniq_cond_indices',1:S.fit_settings.num_conds),'Check the "trl_cond_nrs": some expected condition indices are either not present or some entries exceed fit_settings.num_conds');

%% Check some other settings

%S.param_settings

%S.model_settings

%S.fit_settings

end %[EoF]