function P = SetupScreen(S)
% Setup the screen for PTB

% This is necessary in case of an early 'catch'
P.eyeTrackerActive = 0;

% Colours
P.white = WhiteIndex(S.screen_number);
P.grey = P.white/2;
P.red = [P.grey 0 0];
P.green = [0 P.grey 0];
P.darkgreen = [0 P.white/4 0];
P.blue = [0 0 P.white*3/4];
P.yellow = [P.white*3/4 P.white*3/8 0];

P.background = P.grey;                         
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

% Text Specifics
Screen('TextFont',P.win,'Arial');
Screen('TextSize',P.win,36);
Screen('TextStyle',P.win,0);                %0=normal, 1=bold, 2=italic, 4=underline
Screen('TextColor',P.win,P.draw_color);

% Measure monitor refresh interval.
% Flip three times. Otherwise screen may start flickering (bug)
% Also call WaitSecs because the first call to this function can sometimes take unexpectedly long   
Screen('Flip',P.win);  WaitSecs(0.1);  Screen('Flip',P.win);  WaitSecs(0.1);  Screen('Flip',P.win);
% This will trigger a calibration loop of minimum 100 valid samples and return the estimated inter-flip-interval in 'ifi': interflip interval (in seconds).
% We require an accuracy of 1 ms == 0.001 secs. If this level of accuracy can't be reached, we time out after 5 seconds.  
[P.ifi,nrValidSamples,stddev] = Screen('GetFlipInterval',P.win,100,0.001,5);
disp(['Inter-flip interval (ifi) was measured to be ' num2str(round(P.ifi*1000*100)/100) ' ms (num_samples = ' num2str(nrValidSamples) ', SD = ' num2str(round(stddev*1000*100)/100) ' ms).']);
disp(['The screen''s frame rate is reported to be ' num2str(Screen('NominalFrameRate', P.win)) ' Hz.']);    

% Define keys for input 

%P.quitKey   = KbName('ESCAPE');                                             % To exit the program
P.quitKey   = KbName('q');                                             % To exit the program

% if IsWin
%     P.leftMouseKey = KbName('left_mouse');                                  % To answer with Left Mouse button
%     P.rightMouseKey = KbName('right_mouse');                                % To answer with Right Mouse button
%     P.responseKeys = [P.quitKey,P.leftMouseKey,P.rightMouseKey];
% else
%     P.leftArrowKey = KbName('LeftArrow');                                   % To answer with Left Arrow button
%     P.rightArrowKey = KbName('RightArrow');                                 % To answer with Right Arrow button
%     P.responseKeys = [P.quitKey,P.leftArrowKey,P.rightArrowKey];
% end

if S.keyboard_layout_nr == 1 %Rotating wheel + keypad
    
    P.Rkey = KbName('r');               
    P.Lkey = KbName('l');       
    
    P.Conf1key = KbName('F4');  
    P.Conf2key = KbName('F3');
    P.Conf3key = KbName('F2');
    P.Conf4key = KbName('F1');
    
elseif S.keyboard_layout_nr == 2 %Keyboard
    
    P.Rkey = KbName('RightArrow');       
    P.Lkey = KbName('LeftArrow');       
    
    P.Conf1key = KbName('\\');      %'^°' on German keyboards???
    P.Conf2key = KbName('tab');
    P.Conf3key = KbName('CapsLock');
    P.Conf4key = KbName('LeftShift');
    
else
    error('Unknown keyboard layout number (not 1 or 2)')
end

P.Conf1key_alt = KbName('`~');  %Alternative on non-German keyboards

P.responseKeys = [P.quitKey,P.Rkey,P.Lkey,P.Conf1key,P.Conf1key_alt,P.Conf2key,P.Conf3key,P.Conf4key];

end %[EOF]
