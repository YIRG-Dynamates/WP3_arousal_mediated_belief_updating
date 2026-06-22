function dir_exp_fitfun_4(subj_nr)
%Fit the data of a single subject (subj_nr)

%Add paths
addpath('bads-master');
addpath('bayesian_direction_cp_model');

%Load behavioral data
data_path = 'final_behav_eye_data_dir_exp';
load(fullfile(data_path,'subj_nrs.mat'),'subj_nrs');
subj_ID = subj_nrs{subj_nr,1};

trials_cell_all = cell(200+300,1);
trials_cell = LoadDataOneSubj(data_path,subj_ID);
trials_cell_all(1:200,1) = reshape(trials_cell,[4*50 1]);                   %4 blocks of 50 trials
for i=1:3
    %Add data for MAA tasks at 0, 20 and 40 degrees
    load(fullfile(data_path,subj_ID,[subj_ID '_MA' num2str(i+1) '_Trials_100.mat']),'trials_cell');
    idx = 200+(1:100)+(i-1)*100;
    trials_cell_all(idx,1) = trials_cell;
end
trials_cell = trials_cell_all;

%Keep only trials_cell{}.x in the data to fit
subject_data = [];
subject_data.trials_cell = cell(numel(trials_cell),1);
for j=1:numel(trials_cell)
    subject_data.trials_cell{j}.x = trials_cell{j}.x;
end

%Collect the responses
subject_data.responses = cellfun(@(x) x.LocResponse,trials_cell);

%Set fitting options
options_struct = [];

%Assume user has full knowledge of the generative model 
options_struct.param_settings.sd_exp = trials_cell{1}.sd_exp;               %sigma of both modes of the bimodal generative distribution of nu's
options_struct.param_settings.mu_exp = trials_cell{1}.mu_exp;               %Left/right (+/-) offset of the bimodal generative distribution of nu's

options_struct.fit_settings.fit_param_names = {'sd_sens','k_azimuth_sens'}; %The names of the parameters to fit 
options_struct.fit_settings.fit_param_nrs_per_cond = {[1 2]};               %Each of the parameters is fit using trials from the first and only condition

options_struct.fit_settings.optim_MLE_or_MAP = 'MLE';                       %Optimize parameters to obtain MLE or MAP?    
options_struct.fit_settings.optim_num_grid = 1000;                          %Number of randomly selected grid points that are candidate starting points for the BADS searches
options_struct.fit_settings.optim_tol_mesh = 1e-4;                          %MESH tolerance: i.e. required precision of fitted parameters before BADS calls it converged
options_struct.fit_settings.optim_num_attempts = [10 10];                   %Number of BADS convergence attempts [MIN MAX]. The highest log-probability solution is chosen as best out of all converged solutions.

options_struct.fit_settings.gen_predictions = false;                        %Generate predictions with the fitted parameters (default = true)
options_struct.disp_settings.trials = false;                                %Display results for each trial (default = true)
options_struct.disp_settings.overall = false;                               %Display overall results (default = true)

%Run the model fits!
cStart = clock; 
BdCPfitResults = BdCPfitModel(subject_data,options_struct);

%Save the data
save_path = fullfile('fitted_data_dir_exp',subj_ID);
if ~exist(save_path,'dir')
    mkdir(save_path);
end
save(fullfile(save_path,[subj_ID '_BdCPfitResults_4.mat']),'subj_ID','BdCPfitResults','-v7.3');

%Report computation time in command window
fprintf('Finished fit 4 and saved data for subject %i (%s),\nElapsed time (days hours:minutes:seconds) %s \n', ... 
                                              subj_nr, subj_ID, datestr(etime(clock,cStart)/86400,'dd HH:MM:SS'));

end %[EoF]                                          
