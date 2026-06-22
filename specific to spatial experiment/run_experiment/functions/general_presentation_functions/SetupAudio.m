function [P,HRTF] = SetupAudio(S,P,F)
% Prepare the audio device for PTB

%Set the required sound intensity offset in dB (volume level)
P.sound_intensity = -8;                                     

%Load the HRTF
HRTF = SOFAload(F.HRTF_file);
HRTF.Data.IR = HRTF.Data.IR ./ (max(max(max(abs(HRTF.Data.IR(SOFAfind(HRTF, 0, 0), :, :))))+eps));

%Set the audio-driver's mode (1 = playback only (no audio capture))
audioDeviceMode = 1;
%Set the reqLatencyClass level to 2; this means: Take full control over the audio device, even if this causes other sound applications to fail or shutdown.
if IsLinux 
    reqLatencyClass = 0;
else
    reqLatencyClass = 2;
end

if ~S.eeg_recording
    %Set the number of channels that we will be using (2: one for left, and one for right)     
    P.nAudioChannels = 2;
    %Open the audioDevice with the selected settings and the sampling frequency as determined earlier    
    P.AudioHandle = PsychPortAudio('Open',S.sound_device_idx,audioDeviceMode,reqLatencyClass,S.sound_sample_rate,P.nAudioChannels);
else
    %When recording EEG we open 2 more channels. These are used for sending the "sound triggers" to the EEG amplifier    
    P.nAudioChannels = 4;
    P.AudioHandle = PsychPortAudio('Open',S.sound_device_idx,audioDeviceMode,reqLatencyClass,S.sound_sample_rate,P.nAudioChannels,[],[],1:4);
end

% The visuo-audio delay (visual onset minus auditory onset) of the system depends on the computer we use. It is recommended to measure this manually (e.g. using a microphone and photo-diode). 
if strcmp(getenv('computername'),'EXPGRUEN')  
    latBias = 0.045;                                                        %Measured by DM+BB on 14-03-2022 (SD = 4.4 ms)
    PsychPortAudio('LatencyBias',P.AudioHandle,latBias);
end

% Generate some beep sound: 1000 Hz, 0.1 secs, 50% amplitude and fill it in the buffer for preheating playback (this avoids deformations of the first real auditory stimulus). 
mynoise = 0.5 * MakeBeep(1000,0.1,S.sound_sample_rate);
mynoise = repmat(mynoise,[P.nAudioChannels 1]);
% Preheat: run audio device a few times silently
PsychPortAudio('Volume',P.AudioHandle,0);
for i=1:3
    PsychPortAudio('FillBuffer',P.AudioHandle,mynoise);
    PsychPortAudio('Start',P.AudioHandle,1,0);                  %repetitions = 1 , when = 0 delay   
    PsychPortAudio('Stop',P.AudioHandle,1);                     %waitForEndOfPlayback = 1
end
% Set Volume to default level (1)
PsychPortAudio('Volume',P.AudioHandle,1);

end %[EOF]