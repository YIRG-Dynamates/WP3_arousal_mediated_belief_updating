function P = SetupScreen(S)
% Setup the screen for PTB

%Ensure that 'eyeTrackerActive' field is initialized to zero in case of early error catch (for ease of debugging)
P.eyeTrackerActive = 0; 

% Define some colours
P.white = WhiteIndex(S.screen_number);
P.grey = P.white/2;
P.red = [P.grey 0 0];
P.green = [0 P.grey 0];
P.darkgreen = [0 P.white/4 0];
P.blue = [0 0 P.white*3/4];
P.yellow = [P.white*3/4 P.white*3/8 0];

P.background = P.grey;                  %Set this before opening the screen, because one needs to set the background color at opening      
P.draw_color = 0;

% Are you debugging code
if S.PTBcode_debuging
    PsychDebugWindowConfiguration;      %Set up transparent Window that allows for debugging of code while running PTB
end 

% Take control of screen
[P.win,P.win_rect]=PsychImaging('OpenWindow',S.screen_number,P.background);    

% Various other screen settings
if ~S.PTBcode_debuging
    Priority(MaxPriority(P.win));       % Switch to realtime-priority to reduce timing jitter and interruptions caused by other applications and the operating system itself
    HideCursor;                         % Hide the cursor
    %ListenChar(2);                      % Prevent keyboard presses to be executed within MATLAB (we don't want to edit the scripts!). This cannot be used if KbQueue commands are required.            
    ListenChar(-1);                     %This new function suppresses keyboard input to the Matlab console but does not prevent the use of KbQueue commands.
end

% Enable antialiasing blending function (e.g. so we can use line smoothing in the DrawLines command)
Screen('BlendFunction', P.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Measure monitor refresh interval.
% Flip three times. Otherwise screen may start flickering (bug)
% Also call WaitSecs because the first call to this function can sometimes take unexpectedly long   
Screen('Flip',P.win);  WaitSecs(0.1);  Screen('Flip',P.win);  WaitSecs(0.1);  Screen('Flip',P.win);
% This will trigger a calibration loop of minimum 100 valid samples and return the estimated inter-flip-interval in 'ifi': interflip interval (in seconds).
% We require an accuracy of 1 ms == 0.001 secs. If this level of accuracy can't be reached, we time out after 5 seconds.  
[P.ifi,nrValidSamples,stddev] = Screen('GetFlipInterval',P.win,100,0.001,5);
disp(['Inter-flip interval (ifi) was measured to be ' num2str(round(P.ifi*1000*100)/100) ' ms (num_samples = ' num2str(nrValidSamples) ', SD = ' num2str(round(stddev*1000*100)/100) ' ms).']);
disp(['The screen''s frame rate is reported to be ' num2str(Screen('NominalFrameRate', P.win)) ' Hz.']);    

% Text Specifics
Screen('TextFont',P.win,'Arial');
Screen('TextSize',P.win,36);
Screen('TextStyle',P.win,0);                    %0=normal, 1=bold, 2=italic, 4=underline
Screen('TextColor',P.win,P.draw_color);

% Some useful screen-flip timing settings
P.flip_fraction_early_command = 0.2;            %How early should the command to flip at a certain time be given (time in flips: e.g. 0.2*ifi before the next flip)   
P.last_part_LeadIn_duration = 0.1;              %in seconds (should be enough to draw the first stimulus and send auditory start commands etc) - ensure that this is a multiple of the ifi for accurate timing!

end %[EOF]
