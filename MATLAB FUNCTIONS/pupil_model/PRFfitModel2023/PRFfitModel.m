function PRFfitResults = PRFfitModel(subject_data,options_struct)
% PRFfitResults = PRFfitModel(subject_data,options_struct)
%
% Fit the Pupil Response Function (PRF) model to a dataset of pupil size 
% timecourses (divided into trials of unequal length with stimuli at 
% certain times that are modelled as delta function inputs). The model is
% based on Denison, Parker & Carrasco (2020) Behavior Research Methods
% https://doi.org/10.3758/s13428-020-01368-6

% For example usage, please see 'modelPlay_1.m'
%
% N.B. Parameters are optimized using the "Bayesian Adaptive Direct Search"
% algorithm by Luigi Acerbi and Wei Ji Ma (Advances in NIPS, 2017; please 
% see https://github.com/lacerbi/bads/ for further information).  
%
% INPUTS
% * subject_data 
% A struct with the following fields:
%   *trials_cell
% A cell array of size [nTrials x 1]. Each cell contains a structure with
% information about the trial. Required fields are: 
% (1) "trial_length": a scalar for the number of samples in the trial, 
% (2) "stim_times_AV": a vector with sample indices of AV stimuli onsets,
% (3) "stim_times_A": a vector with sample indices of A stimuli onsets.
%   *responses (optional)
% A cell array of size [nTrials x 1], Each cell contains a vector with the 
% recorded (normalized) pupil size timecourse for this trial. Use NaN for 
% missing data. If the input parameter "responses" is omitted or empty, 
% then model parameters cannot be fitted. Instead, model predictions are 
% computed using the fixed parameter values (see below). Alternatively, the
% user may set "responses" to a character string of a positive integer N. 
% In this case N random responses per trial will be generated using the 
% model's inference rules. 
%   *trl_cond_nrs (optional)
% A numerical vector of size [nTrials x 1] containing the condition numbers
% of each trial. Leave empty or use ones(nTrials,1) if your dataset has
% only one experimental condition. The use of multiple conditions allows
% the user to fit the same parameter (e.g. hazard rate) once for each
% experimental condition (while other parameters may be shared across
% conditions). Also see "options_struct.fit_settings.fit_param_names" 
% and "options_struct.fit_settings.fit_param_nrs_per_cond".
%
% * options_struct (optional)
% Struct with various fields that are used as options in the BCP model. 
% Basically, this structure allows the user to deviate from the default
% settings that are found in "setDefaults.m" (replacement of defaults by
% options_struct inputs happens in "setOptions.m"). All settings for 
% 'param_settings', 'model_settings', 'fit_settings', and 'disp_settings' 
% can be changed. The following are especially important:
%
% - "fit_settings.fit_param_names"
%   A cell array of size [1 x nParams2Fit] with the names of the parameters 
%   to fit (one per cell). E.g. {'AV_t_max','A_t_max'}. Default = {};
%   
%   Choose from the following:  (Default ; [ LB     PLB    PUB     UB   ])
%   AV_delta_amp  =             [    1   ; [ -10      0      2     10   ]; 
%   AV_delta_lat  =             [    0   ; [-250      0    100    250   ]; 
%   AV_t_max      =             [  930   ; [ 100    500   1500   3000   ]; 
%   AV_n_shape    =             [   10.1 ; [   1      6     14     20   ];
%   A_delta_amp   =             [    1   ; [ -10      0      2     10   ];
%   A_delta_lat   =             [    0   ; [-250      0    100    250   ];
%   A_t_max       =             [  930   ; [ 100    500   1500   3000   ];
%   A_n_shape     =             [  10.1  ; [   1      6     14     20   ];
%   y_intercept   =             [   0    ; [ -10     -1      1     10   ]; 
%   for brief explanations of the parameters see "setDefaults.m".
%
%   Any of the above can instead be fixed parameters (they will not be fit 
%   if unmentioned in "fit_settings.fit_param_names"). In case of fixed 
%   parameters they will default to the values in parentheses. If you wish
%   to assign different fixed values to them, then add them as separate 
%   fields (e.g. options_struct.param_settings.PARAMNAME = VALUE). 
%
%   The parameter bounds (hard lower = LB, plausible lower = PLB,
%   plausible upper = PUB, hard upper = UB) that will be used for fitting 
%   are also given in the parentheses. Any of these can be changed by
%   adding them as vectors of size [1 x 4]. For example, set 
%   "options_struct.fit_settings.bounds.PARAMNAME = [1 3 7 10]".
%   Beware that the order should be preserved: [LB < PLB < PUB < UB].
%
%   N.B. If numel(fit_settings.fit_param_names) equals zero, then no 
%   parameters will be fitted. Instead, one log-likelihood will be computed
%   using all of the fixed parameter values.
%
% - "fit_settings.fit_param_nrs_per_cond"
%   A cell array of size [1 x nConditions]. Each cell should contain a
%   vector of size [1 x nParams2FitInThisCondition]. The vector in cell i
%   contains the indices of the 'fit_param_names' that belong to the i'th
%   experimental condition. For example, for two conditions, one may set
%   "fit_param_names = {'PARAMNAME1','PARAMNAME2','PARAMNAME3'}" and 
%   "fit_param_nrs_per_cond = {[1 3],[2 3]}". This would mean that the 
%   third parameter is fitted using trials from both conditions, while 
%   the first and second parameters are fitted using trials from the first
%   and second condition only, respectively. Set "fit_param_nrs_per_cond = 
%   {[1:length(fit_param_names)]} if there is only one experimental 
%   condition (all params belong to condition 1).
%
%
% OUTPUT
%
% *PRFfitResults
% A structure with various fields containing fitting results, generated
% responses or model predictions. Please explore the output by yourself.
%
%
% Author: David Meijer
% Affiliation: Acoustics Research Institute, Austrian Academy of Sciences
% Communication: MeijerDavid1@gmail.com
%
%
% Version: 07-12-2022

%% Add functions and subfolders to the Matlab path
me = mfilename;                                                             %what is my filename
pathstr = fileparts(which(me));                                             %get my location
addpath(genpath([pathstr filesep 'functions']));                                     

%% Assess input parameters

if ~isfield(subject_data, "trials_cell")               %Ensure that subject_data.trials_cell exists and is of the right type
    error('subject_data.trials_cell is required as input argument');
else
    assert(~isempty(subject_data.trials_cell),'subject_data.trials_cell must be non-empty');
    if ~isvector(subject_data.trials_cell)
        warning('subject_data.trials_cell will be treated as a vector: i.e. subject_data.trials_cell = subject_data.trials_cell(:);')
    end
    subject_data.trials_cell = subject_data.trials_cell(:);
    num_trials = length(subject_data.trials_cell);
    
    %Specific to this model:
    assert(all(cellfun(@(x) isfield(x,'trial_length'),subject_data.trials_cell)),'Each cell in subject_data.trials_cell must contain a "trial_length" field indicating the number of samples in the trial');
    assert(all(cellfun(@(x) isfield(x,'stim_times_AV'),subject_data.trials_cell)),'Each cell in subject_data.trials_cell must contain a "stim_times_AV" field indicating the sample indices of AV stimuli onsets');
    assert(all(cellfun(@(x) isfield(x,'stim_times_A'),subject_data.trials_cell)),'Each cell in subject_data.trials_cell must contain a "stim_times_A" field indicating the sample indices of A stimuli onsets');
end

if ~isfield(subject_data,"responses")
    subject_data.responses = [];                        %Empty: Don't fit anything, just generate predictions
elseif ~isempty(subject_data.responses)
    if ischar(subject_data.responses)                   %Character: Generate 'gen_N_resp' subject_data.responses for a hypothetical observer
        gen_N_resp = str2double(subject_data.responses);
        assert((mod(gen_N_resp,1) == 0) && (gen_N_resp > 0),'The number of subject_data.responses to be generated is not a valid positive integer');
    else
        %Cell array with responses for each trial: Use subject_data.responses to compute log-likelihoods and/or fit parameters 
        assert(iscell(subject_data.responses),'subject_data.responses mus be a cell array');
        assert(numel(subject_data.responses) == num_trials,'Cell array for subject_data.responses should have one cell per trial');
        if ~isequal(size(subject_data.responses), size(subject_data.trials_cell))
            warning('subject_data.responses will be treated as a vector: i.e. subject_data.responses = subject_data.responses(:);')
            subject_data.responses = subject_data.responses(:); 
        end
        
        %Specific to this model:
        assert(all(cellfun(@(x) isvector(x),subject_data.responses)),'All response cells must contain a vector of pupil sizes for this trial');
    end
end

if ~isfield(subject_data, "trl_cond_nrs") || isempty(subject_data.trl_cond_nrs)
    subject_data.trl_cond_nrs = ones(num_trials,1);
else
    if ~isvector(subject_data.trl_cond_nrs)
        warning('subject_data.trl_cond_nrs will be treated as a vector: i.e. subject_data.trl_cond_nrs = subject_data.trl_cond_nrs(:);')
    end
    subject_data.trl_cond_nrs = subject_data.trl_cond_nrs(:);
    assert(length(subject_data.trl_cond_nrs) == num_trials,'The number of "subject_data.trl_cond_nrs" does not match the number of trials in subject_data.trials_cell');
end

if (nargin < 2) || isempty(options_struct)  %If there is no options_struct or if empty, then use all defaults
    options_struct = struct([]);
else
    assert(isstruct(options_struct),'The 2nd input argument "options_struct" must be a structure whose fields describe non-default settings');
end

%Evaluate 'options_struct' and set default settings
S = setOptions(options_struct);

%Initialize output structure
PRFfitResults = [];
PRFfitResults.data = subject_data;
PRFfitResults.settings = S;

%Shuffle the random number generator and set it to the faster algorithm
rng('shuffle','simdTwister'); 
PRFfitResults.rng_seed = rng;                            %Save the seed

%% Perform the action!

if ischar(subject_data.responses) || isempty(subject_data.responses)
	
    assert(PRFfitResults.settings.fit_settings.num_params == 0,'Cannot fit parameters without subject_data.responses in the input argument');
    
    %Generate gen_N_resp subject_data.responses for a hypothetical observer    
    if ischar(subject_data.responses)
        PRFfitResults.generated_responses = genRespAllTrials(gen_N_resp,PRFfitResults); 
    
    else
        %Generate (and optionally plot) model predictions using the given/default parameters 
        if S.fit_settings.gen_predictions
            PRFfitResults.predictions = genPredictionsAllTrials(PRFfitResults);
        else
            warning('There are no responses to fit, and "fit_settings.gen_predictions" was turned off, so the program does nothing');
        end
    end
    
else
    
    %Responses are present, but no parameters are requested to be fitted
    if S.fit_settings.num_params == 0
        
        %Compute one log-likelihood value per trial for the given parameter values   
        params = [];
        PRFfitResults.LL_trials = compLLallTrials(params,PRFfitResults);
        PRFfitResults.LL_total = sum(PRFfitResults.LL_trials);
        
        %Generate (and optionally plot) model predictions using the given/default parameters 
        if S.fit_settings.gen_predictions
            PRFfitResults.predictions = genPredictionsAllTrials(PRFfitResults);
        end
        
    %Default fitting behaviour    
    else 
    
        %Attempt to add BADS to the path
        if ~exist('bads','file')
            try 
                addpath([fileparts(fileparts(pathstr)) filesep 'toolboxes' filesep 'bads']);       
                bads_options = bads('defaults');
            catch
                error('Failed to find BADS at the expected location. Please ensure that BADS is added to the Matlab path.')
            end
        end

        %Optimize parameters to find MLE or MAP
        PRFfitResults.fit = optimParams(PRFfitResults);
        
        %Report fitted params in command window
        disp(''); disp('Fitted parameter values:');
        disp(PRFfitResults.settings.fit_settings.fit_param_names);
        disp(PRFfitResults.fit.fittedParams); disp('');
        
        if S.fit_settings.gen_predictions
            %Generate (and optionally plot) model predictions using the fitted parameters
            PRFfitResults.predictions = genPredictionsAllTrials(PRFfitResults,PRFfitResults.fit.fittedParams);
        end
    end
end

end %[EoF]
