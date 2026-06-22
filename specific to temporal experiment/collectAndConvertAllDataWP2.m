%Script that creates one trials_cell for all subjects with converted data to use in the model.

clearvars;
close all;

%Add paths
global dynamates_paths
gen_trials_path = fullfile(dynamates_paths.repository, 'Experiment','wp2_temporal_predictions','run_experiment_DM','functions','genTrials_SAC_tempo');
addpath(gen_trials_path);

data_path = 'DataCollectionWP2';
addpath('fitting_functions_wp2');

%Subject IDs (hardcoded)
subj_IDs = {'S001'; 'S002'; 'S003'; 'S004'; 'S005'; ...
            'S007'; 'S008'; 'S009'; 'S010'; 'S011'; ...
            'S012'; 'S014'; 'S016'; 'S017'; 'S019'; ...
            'S021'; 'S022'; 'S023'; 'S024'; 'S025'; ...
            'S026'; 'S027'; 'S028'; 'S029'; 'S030'; ...
            'S031'; 'S032'}; 

num_subj = numel(subj_IDs);
  
%Initialize file to save
save('behav_data_WP2.mat','subj_IDs','num_subj','-v7.3');

%Loop through subjects, collect the trials_cells and save the data
for j_subj=1:num_subj
    disp(['Collecting data of subject ' subj_IDs{j_subj}]);
    [trials_cell,block_settings] = LoadDataOneSubj_wp2(data_path,subj_IDs{j_subj});
    eval(['trials_cell_' subj_IDs{j_subj} ' = trials_cell;']);
    eval(['block_settings_' subj_IDs{j_subj} ' = block_settings;']);
    save('behav_data_WP2.mat',['trials_cell_' subj_IDs{j_subj}],['block_settings_' subj_IDs{j_subj}],'-append');
end
