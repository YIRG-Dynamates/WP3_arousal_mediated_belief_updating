% This script demonstrates how the BdCP model can be used to simulate
% responses and how to fit the model's parameters to this simulated data.
% 
% 2023-06-06
% David Meijer, david.meijer@oeaw.ac.at

clearvars;
close all;

%Add the model and its sub-functions to the path
model_path = fileparts(cd);                                                     %Assuming that we are in "various" folder now
addpath(genpath(model_path));      

%% Generate all stimuli for the full experiment

global dynamates_paths

%Generate a set of trials:
gen_trials_path = fullfile(dynamates_paths.repository, 'Experiment', 'spatial_directions', 'run_experiment', 'functions', 'genTrials_SAC_dir');
addpath(gen_trials_path);

MAA = 3;
num_blocks = 5;
trials_cell = genAllTrials_SAC_dir_copy(num_blocks,MAA);                    %Use custom function for here which makes use of the functions in the experiment folder

%Ignore the block structure
input_data.trials_cell = trials_cell(:);                                            

%% 1. Produce some figures of predicted responses with some pre-set parameters       

%Settings that were used in the experiment: 
mu_exp = 3*MAA;
sd_exp = 1*MAA;

options_struct = [];

%Assume user has full knowledge of the generative model 
options_struct.param_settings.cp_hazard_rate = 1/5;                             %assumed changepoint hazard rate 
options_struct.param_settings.sd_sens = MAA;                                    %sigma of (auditory) sensory noise on velocity (i.e. equivalent to MAA)
options_struct.param_settings.sd_exp = sd_exp;                                  %sigma of both modes of the bimodal generative distribution of nu's
options_struct.param_settings.mu_exp = mu_exp;                                  %Left/right (+/-) offset of the bimodal generative distribution of nu's

%Don't fit anything (default)
options_struct.fit_settings.fit_param_names = {};                               %The names of the parameters to fit. Empty such that we don't fit anything.
options_struct.fit_settings.fit_param_nrs_per_cond = {};                        %Empty for each of the conditions (we have only one experimental condition)   

%Display only the first ten trials
options_struct.disp_settings.trials = 1:10;                                     %Display only the first ten trials

%Call the model
BdCPfitResults_1 = BdCPfitModel(input_data,options_struct);  

%% 2. Simulate responses for one participant with the pre-set parameters

input_data.responses = '1';                                                     %One simulated response per trial 
BdCPfitResults_2 = BdCPfitModel(input_data,options_struct);

%% 3. Call model to compute just a single log likelihood (LL)

options_struct.fit_settings.gen_predictions = false;                            %Don't create predictions (therefore also no figures)

input_data.responses = BdCPfitResults_2.generated_responses;                    %Use the responses of the simulated participant

%With the correct param settings
tic; BdCPfitResults_3a = BdCPfitModel(input_data,options_struct); T=toc;               
disp('LL with correct params: '); disp(BdCPfitResults_3a.LL_total);
disp(['Elapsed time is ' num2str(T) ' seconds']); 

%Remove the correct parameter settings and compute again with defaults
param_settings_backup = options_struct.param_settings;
options_struct = rmfield(options_struct,'param_settings');

tic; BdCPfitResults_3b = BdCPfitModel(input_data,options_struct); T=toc;        %This LL with default params should be lower than the one above
disp('LL with default params: '); disp(BdCPfitResults_3b.LL_total);
disp(['Elapsed time is ' num2str(T) ' seconds']); 

%% 4. Fit parameters to the simulated dataset

options_struct.param_settings.sd_exp = sd_exp;                              
options_struct.param_settings.mu_exp = mu_exp;

options_struct.fit_settings.fit_param_names = {'cp_hazard_rate','sd_sens'}; %The names of the parameters to fit 
options_struct.fit_settings.fit_param_nrs_per_cond = {[1 2]};               %Each of the parameters is fit using trials from the first and only condition

options_struct.fit_settings.optim_MLE_or_MAP = 'MLE';                       %Optimize parameters to obtain MLE or MAP?    
options_struct.fit_settings.optim_num_grid = 100;                           %Number of randomly selected grid points that are candidate starting points for the BADS searches
options_struct.fit_settings.optim_tol_mesh = 1e-3;                          %MESH tolerance: i.e. required precision of fitted parameters before BADS calls it converged
options_struct.fit_settings.optim_num_attempts = [1 4];                     %Number of BADS convergence attempts [MIN MAX]. The highest log-probability solution is chosen as best out of all converged solutions.

options_struct.fit_settings.gen_predictions = true;                         %Generate predictions with the fitted parameters (default = true) 
options_struct.disp_settings.trials = 1:10;                                 %Display results for the first ten trials (default = true) 
options_struct.disp_settings.overall = true;                                %Display overall results (default = true) 

BdCPfitResults_4 = BdCPfitModel(input_data,options_struct);

disp('Compare with the backed-up correct parameters:'); 
disp(param_settings_backup);
