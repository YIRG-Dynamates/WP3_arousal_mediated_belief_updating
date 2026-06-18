function S = setOptions(options_struct)
%Obtain the full settings struct including defaults and user-given options

%Create empty input struct if not given
if nargin < 1 || isempty(options_struct)
    options_struct = struct; 
end

%Set defaults
S = setDefaults;

%Overwrite the defaults with values from the options_struct
fieldname_blocks = {'param_settings','model_settings','fit_settings','disp_settings'};
for i=1:numel(fieldname_blocks)
    if isfield(options_struct,fieldname_blocks{i})
        option_fields = fieldnames(options_struct.(fieldname_blocks{i}));
        for j=1:length(option_fields)
            %If the subfield is called 'bounds', then copy each subfield in the bounds structure separately   
            if strcmp(option_fields{j},'bounds') && strcmp(fieldname_blocks{i},'fit_settings')
                %Quick check on the bounds structure in OptionsStruct
                if ~isstruct(options_struct.fit_settings.bounds)
                    error('OptionsStruct.fit_settings.bounds must be a structure containing a separate field for each of the parameters: i.e. a 1x4 array of [LB, PLB, PUB, UB] for each parameter.');
                end
                bound_fields = fieldnames(options_struct.fit_settings.bounds);
                for k=1:length(bound_fields)
                    assert(isequal(size(options_struct.fit_settings.bounds.(bound_fields{k})),[1 4]), ...
                          'OptionsStruct.fit_settings.bounds must be a structure containing a separate field for each of the parameters: i.e. a 1x4 array of [LB, PLB, PUB, UB] for each parameter.');
                    S.fit_settings.bounds = options_struct.fit_settings.bounds.(bound_fields{k});
                end
            %Otherwise, (not 'bounds') copy the given values directly
            else
                S.(fieldname_blocks{i}).(option_fields{j}) = options_struct.(fieldname_blocks{i}).(option_fields{j});
            end
        end
    end
end

%Find the number of conditions
S.fit_settings.num_conds = numel(S.fit_settings.fit_param_nrs_per_cond);
param_fields = fieldnames(S.param_settings);
for j=1:length(param_fields)
    S.fit_settings.num_conds = max(S.fit_settings.num_conds,numel(S.param_settings.(param_fields{j})));
end

%Ensure that all parameters are duplicated for the number of conditions
for j=1:length(param_fields)
    if numel(S.param_settings.(param_fields{j})) < S.fit_settings.num_conds
        if numel(S.param_settings.(param_fields{j})) == 1
            S.param_settings.(param_fields{j}) = repmat(S.param_settings.(param_fields{j}),[1 S.fit_settings.num_conds]);
        else
            error(['The number of conditions does not match the number of parameter values for ' param_fields{j}]);
        end
    end
end

%Overwrite the parameters that we will fit with NaNs
S.fit_settings.num_params = numel(S.fit_settings.fit_param_names);
fprintf('There are %i free parameters\n', S.fit_settings.num_params)
if S.fit_settings.num_params > 0
    for i=1:S.fit_settings.num_conds
        for j=1:numel(S.fit_settings.fit_param_nrs_per_cond{i})
            param_nr = S.fit_settings.fit_param_nrs_per_cond{i}(j);
            param_name = S.fit_settings.fit_param_names{param_nr};
            S.param_settings.(param_name)(i) = NaN;
        end
    end
end

%Determine which transform is necessary for which of the parameters-to-fit
S.fit_settings.transforms = cell(1,S.fit_settings.num_params);
for i=1:S.fit_settings.num_params
    if any(strcmp(S.fit_settings.fit_param_names{i},S.fit_settings.param_log))
        S.fit_settings.transforms{i} = 'log';
    elseif any(strcmp(S.fit_settings.fit_param_names{i},S.fit_settings.param_logit))
        S.fit_settings.transforms{i} = 'logit';
    else
        S.fit_settings.transforms{i} = 'none';
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Check the bounds and transform them to log/logit domain %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Collect the bounds for the parameters of interest
S.fit_settings.bounds.LB = nan(1,S.fit_settings.num_params);
S.fit_settings.bounds.PLB = nan(1,S.fit_settings.num_params);
S.fit_settings.bounds.PUB = nan(1,S.fit_settings.num_params);
S.fit_settings.bounds.UB = nan(1,S.fit_settings.num_params);
for i=1:S.fit_settings.num_params
    
    S.fit_settings.bounds.LB(i) = S.fit_settings.bounds.(S.fit_settings.fit_param_names{i})(1);
    S.fit_settings.bounds.PLB(i) = S.fit_settings.bounds.(S.fit_settings.fit_param_names{i})(2);
    S.fit_settings.bounds.PUB(i) = S.fit_settings.bounds.(S.fit_settings.fit_param_names{i})(3);
    S.fit_settings.bounds.UB(i) = S.fit_settings.bounds.(S.fit_settings.fit_param_names{i})(4);
    
    %Check the lower and upper bounds for the transformed parameters that we fit
    if strcmp(S.fit_settings.transforms{i},{'log'}) || strcmp(S.fit_settings.transforms{i},{'logit'})                               
        if S.fit_settings.bounds.LB(i) <= 0                                                      
            error('Lower bound for log/logit-transformed parameters must be larger than zero to avoid -inf issues. E.g. set to 1e-9');
        end      
    end
    if strcmp(S.fit_settings.transforms{i},{'logit'})
        if S.fit_settings.bounds.UB(i) >= 1
            error('Upper bound for logit-transformed parameters must be smaller than one to avoid inf issues. E.g. set to 1-1e-9');
        end
    end
    
    %Check that the bounds are in the right order
    if any([~(S.fit_settings.bounds.LB(i) < S.fit_settings.bounds.PLB(i)), ~(S.fit_settings.bounds.PLB(i) < S.fit_settings.bounds.PUB(i)), ~(S.fit_settings.bounds.PUB(i) < S.fit_settings.bounds.UB(i))])
        error('Check the parameter bounds: they should be in the following order: LB < PLB < PUB < UB')
    end
end

%Transform the bounds (to log or logit space, in which we fit the parameters)
S.fit_settings.bounds_transf.LB = transformParams(S.fit_settings.bounds.LB,S.fit_settings.transforms,'real2trans');
S.fit_settings.bounds_transf.PLB = transformParams(S.fit_settings.bounds.PLB,S.fit_settings.transforms,'real2trans');
S.fit_settings.bounds_transf.PUB = transformParams(S.fit_settings.bounds.PUB,S.fit_settings.transforms,'real2trans');
S.fit_settings.bounds_transf.UB = transformParams(S.fit_settings.bounds.UB,S.fit_settings.transforms,'real2trans');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Check the fixed parameter values %%% --> This part is meant to be a sanity check on the parameters that are not fitted but can be set freely by the user    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:length(param_fields)
    param_name = param_fields{i};
    for c=1:S.fit_settings.num_conds
        param_value = S.param_settings.(param_name)(c);
        if ~isnan(param_value)
            if param_value < S.fit_settings.bounds.(param_name)(1)
                error(['The fixed parameter value for ' param_name ' (cond nr = ' num2str(c) ') is smaller than the lower bound for this parameter. Please ensure sensible parameter values and bounds.']);
            elseif param_value > S.fit_settings.bounds.(param_name)(4)
                error(['The fixed parameter value for ' param_name ' (cond nr = ' num2str(c) ') is larger than the upper bound for this parameter. Please ensure sensible parameter values and bounds.']);
            end
        end
    end
end

end %[EOF]
