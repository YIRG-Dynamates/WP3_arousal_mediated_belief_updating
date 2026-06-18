function [PRFmat,PRFinfo] = createPRFmat(trial_struct,param_settings)
%Create a matrix of pupil impulse response functions (one per column). 
%The last column is an intercept of ones. 

%unpack trial_struct
trial_length = trial_struct.trial_length;  
event_times = trial_struct.event_times;   
num_stim = numel(event_times);

%unpack param_settings
PRF_amp = param_settings.PRF_amp;
PRF_t_max = param_settings.PRF_t_max;
PRF_n_shape = param_settings.PRF_n_shape;

delta_lat = round(param_settings.delta_lat); 
boxcar_lat = round(param_settings.boxcar_lat); 
boxcar_dur = round(param_settings.boxcar_dur); 

%Create PRF and convolve with boxcar
extra_for_neg_lat = ceil(max([0,-delta_lat,-boxcar_lat]));
PRF_impulse = PRF_amp * pupilrf(1:(trial_length+extra_for_neg_lat),PRF_n_shape,PRF_t_max);
boxcar = ones(1,boxcar_dur) / boxcar_dur;     %Area under curve is 1
PRF_boxcar = filter(boxcar,1,PRF_impulse);
%figure; plot(time,PRF_impulse,'b'); hold on; plot(time,PRF_boxcar,'r');

%Initialize PRF matrix
PRFmat = [zeros(trial_length,2*num_stim), ones(trial_length,1)];            %last column is for intercept         

%Fill the matrix with pupil response functions for each stimulus
for j = 1:num_stim
    
    %impulse response
    beg_idx = event_times(j)+delta_lat;
    if beg_idx < 1
        first_sample = 2-beg_idx;
        beg_idx = 1;
    else
        first_sample = 1;
    end
    last_sample = trial_length-beg_idx+first_sample;
    PRFmat(beg_idx:trial_length,j) = PRF_impulse(first_sample:last_sample);
    
    %boxcar response
    beg_idx = event_times(j)+boxcar_lat;
    if beg_idx < 1
        first_sample = 2-beg_idx;
        beg_idx = 1;
    else
        first_sample = 1;
    end
    last_sample = trial_length-beg_idx+first_sample;
    PRFmat(beg_idx:trial_length,j+num_stim) = PRF_boxcar(first_sample:last_sample);
end

%Set-up a PRF info structure
PRFinfo.event_times = event_times;
PRFinfo.trial_length = trial_length;
PRFinfo.num_stim = num_stim;

PRFinfo.PRF_amp = ones(num_stim,1).*PRF_amp;                 %All stimuli share the same PRF                                    
PRFinfo.PRF_t_max = ones(num_stim,1).*PRF_t_max;                                           
PRFinfo.PRF_n_shape = ones(num_stim,1).*PRF_n_shape;                                       

PRFinfo.delta_lat = ones(num_stim,1).*delta_lat;
PRFinfo.boxcar_lat = ones(num_stim,1).*boxcar_lat;
PRFinfo.boxcar_dur = ones(num_stim,1).*boxcar_dur;

end %[EoF]
