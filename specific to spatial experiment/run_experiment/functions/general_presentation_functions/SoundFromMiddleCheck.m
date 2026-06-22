function keyCode = SoundFromMiddleCheck(S,P,D,HRTF,KbResponseFlag)

if nargin < 5
    KbResponseFlag = false;
end

%Initialize output (to avoid unidentifiable errors)
keyCode = zeros(1,256);

if KbResponseFlag
    %Wait for a button press to start
    myTextCentre = 'Press any of the response buttons to start';
    boundsTextCentre = Screen(P.win,'TextBounds',myTextCentre); %[L,T,R,B] from [L=0,T=0]
    DrawFormattedText(P.win, myTextCentre, round(D.win_center_x-boundsTextCentre(3)/2), round(D.win_center_y-boundsTextCentre(4)/2), P.draw_color);
    Screen('DrawingFinished', P.win);                                                                                                                  %No more drawing commands
    Screen('Flip', P.win); 

    %First wait for all keys to be released
    [~, keyCode] = KbWait([], 2);

    %Quit if it was the ESCAPE key
    if keyCode(P.quitKey)
        return;
    end
end

locs = [0,20,-20];
text_above = cell(3,1);
text_above{1} = 'Position head so that sounds appear to come from the MIDDLE';
text_above{2} = 'Make sure that these sounds come from the LEFT';
text_above{3} = 'Make sure that these sounds come from the RIGHT';

for i=1:3

    %Create fake trials_cell just to generate an auditory signal at 0 degrees in exactly the same way as the true stimuli    
    trials_cell{1}.x = locs(i);
    P.trial_counter = 1; %TEMP - not saved
    S.timing.lead_out = 0; %TEMP - not saved 
    SoundStim = GenerateStimuli(S,P,trials_cell,HRTF);

    %Start to play sounds
    PsychPortAudio('FillBuffer',P.AudioHandle,SoundStim);                       % Buffer the Sound
    PsychPortAudio('Start', P.AudioHandle, 0);                                  % The nr of repetitions is set to '0', which means that the buffered sound is infinitely repeated until stopped manually.    

    %Put text on screen
    %myTextAbove = 'Position head so that sounds appear to come from fixation cross';
    myTextAbove = text_above{i};
    if KbResponseFlag
        myTextBelow = 'Press any response key when ready, or Q to quit';
    else
        myTextBelow = 'Press left mouse button when ready, or Q to quit';
    end
    boundsTextAbove = Screen(P.win,'TextBounds',myTextAbove); %[L,T,R,B] from [L=0,T=0]
    boundsTextBelow = Screen(P.win,'TextBounds',myTextBelow); %[L,T,R,B] from [L=0,T=0]
    DrawFormattedText(P.win, myTextAbove, round(D.win_center_x-boundsTextAbove(3)/2), round(D.aboveStartButton-boundsTextAbove(4)/2), P.draw_color);   %draw text above startButton
    DrawFormattedText(P.win, myTextBelow, round(D.win_center_x-boundsTextBelow(3)/2), round(D.belowStartButton-boundsTextBelow(4)/2), P.draw_color);   %draw text below startButton
    %Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);                                     %draw the fixation cross.
    Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
    Screen('DrawingFinished', P.win);                                                                                                                  %No more drawing commands
    Screen('Flip', P.win); 

    if KbResponseFlag

        %First wait for all keys to be released
        [~, keyCode] = KbWait([], 2);

    else
        %Wait for a mouse button press
        pressedBool = 0;
        while ~pressedBool
            if IsLinux 
                [Mousepressed, ~, ~, ~] = KbCheck(GetMouseIndices('slavePointer'));
            else
                [Mousepressed, ~, ~, ~] = KbCheck(GetMouseIndices);
            end
            [KeyboardPressed, ~, keyCode, ~] = KbCheck;
            if Mousepressed || keyCode(P.quitKey)
                pressedBool = 1;
            end
        end
    end
    
    % Stop playback of the active channel immediately (no timing is set)
    PsychPortAudio('Stop', P.AudioHandle);   
    
    if keyCode(P.quitKey)
        break;      
    end
end

end %[EOF]
