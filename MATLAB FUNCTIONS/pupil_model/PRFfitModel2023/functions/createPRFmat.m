function [PRFmat,PRFinfo] = createPRFmat(trial_struct,param_settings)
%Create a matrix of pupil impulse response functions (one per column). 
%The last column is an intercept of ones. 

%unpack trial_struct
trial_length = trial_struct.trial_length;  
stim_times_AV = trial_struct.stim_times_AV;   
stim_times_A = trial_struct.stim_times_A;  

%process trial_struct
time = 1:trial_length;

num_stim_AV = numel(stim_times_AV);
num_stim_A = numel(stim_times_A);

PRFinfo.stim_times = [stim_times_AV(:); stim_times_A(:)];
PRFinfo.stim_types = [ones(num_stim_AV,1); 2*ones(num_stim_A,1)];

%unpack param_settings
PRFinfo.delta_amp = [ones(num_stim_AV,1).*param_settings.AV_delta_amp; ones(num_stim_A,1).*param_settings.A_delta_amp];
PRFinfo.delta_lat = [ones(num_stim_AV,1).*param_settings.AV_delta_lat; ones(num_stim_A,1).*param_settings.A_delta_lat];
PRFinfo.t_max     = [ones(num_stim_AV,1).*param_settings.AV_t_max;     ones(num_stim_A,1).*param_settings.A_t_max    ];
PRFinfo.n_shape   = [ones(num_stim_AV,1).*param_settings.AV_n_shape;   ones(num_stim_A,1).*param_settings.A_n_shape  ];

PRFinfo.y_intercept = param_settings.y_intercept;

%Initialize PRF matrix
num_col = num_stim_AV+num_stim_A+1;     %+1 is for the intercept
PRFmat = ones(trial_length,num_col);

%Fill the matrix with pupil impulse response functions for each stimulus
for j = 1:(num_stim_AV+num_stim_A)
    PRFmat(:,j) = pupilrf(time,PRFinfo.n_shape(j),PRFinfo.t_max(j),PRFinfo.stim_times(j)+PRFinfo.delta_lat(j));
end

end %[EoF]
