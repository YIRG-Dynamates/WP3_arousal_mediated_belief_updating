% This script demonstrates how the PRF model can be used to simulate
% responses and how to fit the model's parameters to (simulated) data.
% 
% 2024-07-28
% David Meijer, david.meijer@oeaw.ac.at

clearvars;
close all;

%Add the model and its sub-functions to the path
model_path = fileparts(cd);                                                 %Assuming that we are in "various" folder now
addpath(genpath(model_path));    

%% Generate all stimuli for the full experiment

global dynamates_paths

%Use default set of trials 
gen_trials_path = fullfile(dynamates_paths.repository, 'Experiment', 'krishnamurthy_replication', 'run_experiment', 'functions', 'genTrials_SAC');
addpath(gen_trials_path);

%Load default set of trials for the experiment, but shuffle the order within each block   
[av_trials_cell, ~] = genAllTrials_SAC();
[a_trials_cell, ~] = genAllTrials_SAC();

%The default set of trials contains 6 full blocks. But we will only use the first three (twice: repeated for A and AV trials; such that there are 6 main task blocks again)
av_trials_cell = av_trials_cell(:,1:3);
a_trials_cell = a_trials_cell(:,1:3);

%Add whether or not a visual stimulus should be presented
for i=1:numel(av_trials_cell)
    av_trials_cell{i}.present_vis = ones(1,length(av_trials_cell{i}.x));
    av_trials_cell{i}.present_vis(end) = 0;
    a_trials_cell{i}.present_vis = zeros(1,length(a_trials_cell{i}.x));
end

%Change the order of the AV blocks such that the trials can be mixed (below) while ensuring that the same trial does not appear twice within one block (i.e. once as an A, and once as an AV trial)   
shuffle_options = {[2 3 1],[3 1 2]};
AV_shuffle_blocks_option = randi(2,1);
av_trials_cell = av_trials_cell(:,shuffle_options{AV_shuffle_blocks_option});

%Rearrange cells to reorder the conditions as alternating trials
[num_trials_per_block,num_blocks_per_cond] = size(a_trials_cell); 
trials_cell = [av_trials_cell(:) a_trials_cell(:)]';    
trials_cell = reshape(trials_cell,[num_trials_per_block,2*num_blocks_per_cond]);

%Assign condition numbers to the trials
trl_cond_nrs = ones(size(trials_cell));
trl_cond_nrs(2:2:end) = 2;

%Add jitter in the lead_in timing of each stimulus (in ms)
for i=1:numel(trials_cell)
    trials_cell{i}.timing_lead_in = 750 + round(rand()*250);                %750 to 1000 ms lead in times
end

%%%
%Until now, the trial generation was as in the experiment. Now, we'll deviate for model fitting purposes    
%%%

%Add the trial length and stimulus times per trial
for i=1:numel(trials_cell)
    trials_cell{i}.trial_length = 500*numel(trials_cell{i}.x) + 1000;
    
    trials_cell{i}.stim_times_AV = find(trials_cell{i}.present_vis)*500-499;
    trials_cell{i}.stim_times_A = find(~trials_cell{i}.present_vis)*500-499;
    
    trials_cell{i}.event_times = (1:numel(trials_cell{i}.x))*500-499;
end

%% 1. Produce some figures of predicted pupil response traces with some pre-set parameters       

input_data = [];
options_struct = [];

%Put the data into the input_data structure
input_data.trials_cell = trials_cell(:,1);                                                  %Use the first block of trials only for speed?
input_data.trl_cond_nrs = trl_cond_nrs(:,1); 

%Set some parameter values (declare at least one explicitly for both conditions to avoid errors - the others will be duplicated automatically)
t_max = 1000;
n_shape = 9;
multiplier = 1 / pupilrf(t_max,n_shape,t_max);                                              %Use this just for visualization here. It ensures that the maximum amplitude of the PRF is one.

options_struct.param_settings.PRF_amp = multiplier*[1.5 1];                                 %Fixed amplitude of the Pupil Response Function (this is multiplied with 'delta_amp' and 'boxcar_amp' if these are regressed) - note two conditions!
options_struct.param_settings.PRF_t_max = t_max;                                            %Latency (in samples) at which the Pupil Response Function reaches its maximum
options_struct.param_settings.PRF_n_shape = n_shape;                                        %Shape parameter for the Pupil Response Function

options_struct.param_settings.delta_lat = 100;                                              %Latency offset (in samples) of the delta impulses
options_struct.param_settings.boxcar_lat = -100;                                            %Latency offset (in samples) of the boxcar input functions
options_struct.param_settings.boxcar_dur = 500;                                             %Duration (in samples) of the boxcar input functions

PRFfitResults_1 = PRFfitModel(input_data,options_struct);  

%% 2. Simulate responses for one participant with the pre-set parameters

input_data.responses = '1';                                                                 %One simulated response per trial 
PRFfitResults_2 = PRFfitModel(input_data,options_struct);

%% 3. Call model to compute just a single log likelihood (LL)

options_struct.fit_settings.gen_predictions = true;                                         %Also plot predictions (to see the fits)

input_data.responses = PRFfitResults_2.generated_responses;                                 %Use the responses of the simulated participant

%With the correct param settings
tic; PRFfitResults_3a = PRFfitModel(input_data,options_struct); T=toc;               
disp('LL with correct params: '); disp(PRFfitResults_3a.LL_total);
disp(['Elapsed time is ' num2str(T) ' seconds']); 

%Remove the correct parameter settings and compute again with defaults
param_settings_backup = options_struct.param_settings;
options_struct = rmfield(options_struct,'param_settings');
S = setDefaults();
options_struct.param_settings.PRF_amp = multiplier*[1,1]*S.param_settings.PRF_amp;          %Explicitly declare two conditions to avoid errors                        

tic; PRFfitResults_3b = PRFfitModel(input_data,options_struct); T=toc;                      %This LL with default params should be lower than the one above
disp('LL with default params: '); disp(PRFfitResults_3b.LL_total);
disp(['Elapsed time is ' num2str(T) ' seconds']); 

%% 4. Fit parameters to the simulated dataset (this takes a long time!)

options_struct.fit_settings.fit_param_names = {'PRF_amp','PRF_amp',...                      %The names of the parameters to fit  
                                               'PRF_t_max','PRF_n_shape','delta_lat','boxcar_lat','auto_corr'};                 
                                           
options_struct.fit_settings.fit_param_nrs_per_cond = {[1 3:7], [2 3:7]};                    %Fit two separate PRF_amplitudes for the two conditions (AV & A), share all other parameters.

options_struct.fit_settings.optim_MLE_or_MAP = 'MLE';                                       %Optimize parameters to obtain MLE or MAP?    
options_struct.fit_settings.optim_num_grid = 100;                                           %Number of randomly selected grid points that are candidate starting points for the BADS searches
options_struct.fit_settings.optim_tol_mesh = 1e-3;                                          %MESH tolerance: i.e. required precision of fitted parameters before BADS calls it converged
options_struct.fit_settings.optim_num_attempts = [1 4];                                     %Number of BADS convergence attempts [MIN MAX]. The highest log-probability solution is chosen as best out of all converged solutions.

options_struct.fit_settings.gen_predictions = true;                                         %Generate predictions with the fitted parameters (default = true) 
options_struct.disp_settings.overall = true;                                                %Display overall results (default = true) 

PRFfitResults_4 = PRFfitModel(input_data,options_struct);

disp('Compare with the backed-up correct parameters:'); 
disp(param_settings_backup);
