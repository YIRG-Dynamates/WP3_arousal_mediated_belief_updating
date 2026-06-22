function exp_settings = setExperimentParams_SAC_dir()
%Define parameter values for the experiment.
%Output structure P contains the parameter values in its respective fields. 

exp_settings.num_trials_per_block = 48;

%All stimuli locations are in degrees visual angle
%Left = 90° 
%Right = -90°
%Straight ahead = 0°

%We restrict the range of all stimuli to -60 and +60
exp_settings.all_stimulus_range = [-60, 60];                        

%The first stimulus is sampled from a normal distribution centred on zero
exp_settings.first_stimulus_sd = 20; 

%---

%Set the change-point hazard rate
exp_settings.cp_hazard_rate = 1/6;      %This is the chance that each stimulus in a trial is a change-point (except for the first stimulus which is always a change point).

%Set the end-point hazard rate
exp_settings.ep_hazard_rate = 1/12;     %This is the chance that each stimulus in a trial is the last/target stimulus.

end %[EoF]
