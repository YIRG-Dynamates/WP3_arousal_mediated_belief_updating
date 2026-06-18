% This script demonstrates how the PRF model can be used to simulate pupil
% responses and how to fit the model's parameters to this simulated data.
% 
% 2022-12-09
% David Meijer, david.meijer@oeaw.ac.at

clearvars;
close all;

global dynamates_paths

%Add the model and its sub-functions to the path
model_path = fullfile(dynamates_paths.repository, 'modelling', 'krishnamurthy_based', 'replication','pupillometry','pupil_model');
addpath(genpath(model_path));    

%% Generate all stimuli for the full experiment

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
end

%For here (and speed) we will use the first block of trials only.
subject_data.trials_cell = trials_cell(:,1);                     

%Assign condition numbers to the trials
subject_data.trl_cond_nrs = ones(length(subject_data.trials_cell),1);       

%% 1. Call model code to produce some figures of predicted responses with default parameters       

options_struct.fit_settings.fit_param_names = {};                           %The names of the parameters to fit. Empty such that we don't fit anything.
options_struct.fit_settings.fit_param_nrs_per_cond = {};                    %Empty for each of the conditions (we have only one experimental condition)   

PRFfitResults_1 = PRFfitModel(subject_data,options_struct);  

%% 2. Call model code to simulate responses for one participant

options_struct.disp_settings.trials = false;                                %Display results for each trial (default = true)
options_struct.disp_settings.overall = false;                               %Display overall results (default = true)

subject_data.responses = '1';                                               %One simulated response per trial 
PRFfitResults_2 = PRFfitModel(subject_data,options_struct);

%% 3. Call model code to compute just a single log likelihood (LL)

subject_data.responses = PRFfitResults_2.generated_responses; %Use the responses of the simulated participant
PRFfitResults_3 = PRFfitModel(subject_data,options_struct);

%% 4. Fit parameters to the simulated dataset of above

options_struct.fit_settings.fit_param_names = {'AV_t_max','A_t_max'};       %The names of the parameters to fit 
options_struct.fit_settings.fit_param_nrs_per_cond = {[1 2]};               %Each of the parameters is fit using trials from the first and only condition

options_struct.fit_settings.optim_MLE_or_MAP = 'MLE';                       %Optimize parameters to obtain MLE or MAP?    
options_struct.fit_settings.optim_num_grid = 100;                           %Number of randomly selected grid points that are candidate starting points for the BADS searches
options_struct.fit_settings.optim_tol_mesh = 1e-3;                          %MESH tolerance: i.e. required precision of fitted parameters before BADS calls it converged
options_struct.fit_settings.optim_num_attempts = [1 4];                     %Number of BADS convergence attempts [MIN MAX]. The highest log-probability solution is chosen as best out of all converged solutions.

options_struct.fit_settings.gen_predictions = true;                         %Generate predictions with the fitted parameters (default = true) 
options_struct.disp_settings.trials = true;                                 %Display results for each trial (default = true) 
options_struct.disp_settings.overall = true;                                %Display overall results (default = true) 

PRFfitResults_4 = PRFfitModel(subject_data,options_struct);
