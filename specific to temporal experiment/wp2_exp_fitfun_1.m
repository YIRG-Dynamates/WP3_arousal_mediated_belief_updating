function wp2_exp_fitfun_1(subj_nr)
%Fit the data of a single subject (subj_nr)

%Add paths
addpath('bads-master');
addpath('bayesian_direction_cp_model');

%Load behavioral data of this subject
load('behav_data_WP2.mat','subj_IDs');
subj_str = subj_IDs{subj_nr};
clear('subj_IDs');

load('behav_data_WP2.mat',['trials_cell_' subj_str]);
eval(['trials_cell = trials_cell_' subj_str ';']);
eval(['clear(["trials_cell_' subj_str '"])']);

%Create one column vector
trials_cell = trials_cell(:);

%Collect the stimuli locations (transformed SOAs)
subject_data = [];
subject_data.trials_cell = cell(numel(trials_cell),1);                      
for j=1:numel(trials_cell)
    subject_data.trials_cell{j}.x = trials_cell{j}.x;
end

%Collect the responses
subject_data.responses = cell(numel(trials_cell),1);                      
for j=1:numel(trials_cell)
    subject_data.responses{j}.d_resp = trials_cell{j}.TempoDirResponse;
end

%Set fitting options
options_struct = [];

%Assume user has full knowledge of the generative model 
options_struct.param_settings.sd_exp = trials_cell{end}.sd_exp;             %sigma of both modes of the bimodal generative distribution of nu's
options_struct.param_settings.mu_exp = trials_cell{end}.mu_exp;             %Left/right (+/-) offset of the bimodal generative distribution of nu's
options_struct.param_settings.cp_hazard_rate = 1/5;                                      %Assumed hazard rate is the same as the true hazard rate

options_struct.fit_settings.fit_param_names = {'sd_sens'};                  %The names of the parameters to fit 
options_struct.fit_settings.fit_param_nrs_per_cond = {1};                   %Each of the parameters is fit using trials from the first and only condition

options_struct.fit_settings.bounds.sd_sens = [0.1 0.5 2 10];                %Adjust the parameter bounds, because we expect an sd_sens of about 1 (with JND-transformed SOAs as input)

options_struct.fit_settings.optim_MLE_or_MAP = 'MLE';                       %Optimize parameters to obtain MLE or MAP?    
options_struct.fit_settings.optim_num_grid = 50;                            %Number of randomly selected grid points that are candidate starting points for the BADS searches
options_struct.fit_settings.optim_tol_mesh = 1e-4;                          %MESH tolerance: i.e. required precision of fitted parameters before BADS calls it converged
options_struct.fit_settings.optim_num_attempts = [4 4];                     %Number of BADS convergence attempts [MIN MAX]. The highest log-probability solution is chosen as best out of all converged solutions.

options_struct.fit_settings.gen_predictions = true;                         %Generate predictions with the fitted parameters (default = true)
options_struct.disp_settings.trials = false;                                %Display results for each trial (default = true)
options_struct.disp_settings.overall = false;                               %Display overall results (default = true)

%Run the model fits!
cStart = clock; 
BdCPfitResults = BdCPfitModel(subject_data,options_struct);

%Report computation time in command window
fprintf('Finished fit 1 for subject %i (%s),\nElapsed time (days hours:minutes:seconds) %s \n', ... 
                                              subj_nr, subj_str, datestr(etime(clock,cStart)/86400,'dd HH:MM:SS'));
%Save the data
save_path = fullfile('fitted_data_wp2',subj_str);
if ~exist(save_path,'dir')
    mkdir(save_path);
end
save(fullfile(save_path,[subj_str '_BdCPfitResults_1.mat']),'subj_str','BdCPfitResults','-v7.3');

end %[EoF]                                          
