% Show the starting time in the command window
disp('Matlab session started at: '); disp(datetime); 

% Set the maximum number of computation threads to the number of reserved cpus per task   
max_num_comp_threads = 2;
last_max_num_comp_threads = maxNumCompThreads(max_num_comp_threads);
disp(['Using ' num2str(max_num_comp_threads) ' out of ' num2str(last_max_num_comp_threads) ' available CPUs for this task']);

% Setup paths
addpath('fitting_functions')

% PROCID identifies the process id which goes from 0 to 26. 
% I use this to index the subjects.
subj_nr = str2double(getenv('SLURM_PROCID')) + 1;

% Run the fits
dir_exp_fitfun_1(subj_nr);
dir_exp_fitfun_2(subj_nr);
dir_exp_fitfun_3(subj_nr);
dir_exp_fitfun_4(subj_nr);

% Without this, the task hangs there waiting for the wall time 
exit