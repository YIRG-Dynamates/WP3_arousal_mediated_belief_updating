function [Stimuli,total_duration] = GenerateStimuli(S,P,trials_cell,HRTF)
% Generate the sound sequence by calling "generate_stimulus"

params = [];
params.sound_duration = S.timing.stim_duration;
params.ISI = S.timing.ISI;                          %The ISI is added after every stimulus, 
                                                    %also the last one (but not before the first one)

params.silence_start = 0;                           %begin with silence in seconds
params.silence_end = S.timing.lead_out;             %end with silence in seconds -- allow more time for the eye-tracker and EEG analysis

params.fs = S.sound_sample_rate;
params.sound_intensity = P.sound_intensity;

Stimuli = generate_stimulus(trials_cell{P.trial_counter,1}.x,HRTF,params);

%Compute the total sound duration in seconds
num_stim = length(trials_cell{P.trial_counter,1}.x);
total_duration = num_stim*(params.sound_duration+params.ISI)+params.silence_end;

%We have changed the setting from stereo to Quadrophonie(4 chans) for the Lautsprecher device through windows settings.  
%Add on/off signals to align the EEG system with the sound presentation
if S.eeg_recording
    sound_length_samples = round(params.sound_duration*params.fs);
    SOA_length_samples = round((params.sound_duration+params.ISI)*params.fs);
    y = zeros(1,size(Stimuli,2));
    for i=1:length(trials_cell{P.trial_counter,1}.x)
        sound_beg = 1+(i-1)*SOA_length_samples;
        sound_end = sound_length_samples+(i-1)*SOA_length_samples;
        y(sound_beg:sound_end) = 1;
    end
    Stimuli = [Stimuli; y; y];  %Add 2 additional channels for "triggers"
end

end %[EOF]
