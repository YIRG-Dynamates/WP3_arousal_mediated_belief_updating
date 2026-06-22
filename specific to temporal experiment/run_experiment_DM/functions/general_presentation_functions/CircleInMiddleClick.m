function keyCode = CircleInMiddleClick(S,P,D,myTextAbove,myTextBelow,myTextCentre,KbResponseFlag)

if nargin < 7
    KbResponseFlag = false;
end

%Initialize keyCode
[~, ~, keyCode, ~] = KbCheck;

%Find the size of the text
boundsTextAbove = Screen(P.win,'TextBounds',myTextAbove); %[L,T,R,B] from [L=0,T=0]
boundsTextBelow = Screen(P.win,'TextBounds',myTextBelow); %[L,T,R,B] from [L=0,T=0]
boundsTextCentre = Screen(P.win,'TextBounds',myTextCentre); %[L,T,R,B] from [L=0,T=0]

% Check whether the mouse is moved to the startButton, presed and released again      
previous_pressed = 0;
continueBool = 0;
while ~continueBool
    % Get the current position of the mouse
    [mX, mY, ~] = GetMouse(P.win);

    % Find position in visual angles            
    xRel2Center = mX-D.win_center_x;
    yRel2Center = mY-D.win_center_y;
    X_angle = atand(xRel2Center / D.dist2Screen_inPixWidth);
    Y_angle = atand(yRel2Center / D.dist2Screen_inPixHeight);

    % Check whether the mouse is within the startButton
    awayFromCentre_angle = sqrt(X_angle^2+Y_angle^2);                                       %Pythagoras, distance from the centre in visual angle (degrees)        
    within_startButton_bool = awayFromCentre_angle <= D.startButton_Radius;  

    % Draw text, mouse and startButton
    Screen('DrawText',P.win, myTextAbove, round(D.win_center_x-boundsTextAbove(3)/2), round(D.aboveStartButton-boundsTextAbove(4)/2), P.draw_color);   %draw text above startButton
    Screen('DrawText',P.win, myTextBelow, round(D.win_center_x-boundsTextBelow(3)/2), round(D.belowStartButton-boundsTextBelow(4)/2), P.draw_color);   %draw text below startButton
    Screen('DrawText',P.win, myTextCentre, round(D.win_center_x-boundsTextCentre(3)/2), round(D.win_center_y-boundsTextCentre(4)/2), P.draw_color);     %draw text in startButton
    
    if ~KbResponseFlag
        %Screen('DrawLines', P.win, D.miniCursor_Coords, D.miniCursor_LineWidth, P.draw_color, [mX,mY]);                                                       %draw mouse cursor (same way as the fixation cross)
        Screen('DrawDots', P.win, [mX,mY], 10, P.draw_color, [], 1);
    end
    
    if within_startButton_bool
        Screen('FillOval', P.win, P.draw_color, D.startButton_Coords);                                                                                    %draw filled startButton
        Screen('DrawText',P.win, myTextCentre, round(D.win_center_x-boundsTextCentre(3)/2), round(D.win_center_y-boundsTextCentre(4)/2), 0);%draw black text in startButton
    else
        Screen('FrameOval', P.win, P.draw_color, D.startButton_Coords, 3);                         %draw open startButton
    end
    Screen('DrawingFinished', P.win);                                                       %tell PsychToolBox that there are no further drawing commands (this speeds up the processing)
    Screen('Flip', P.win);                                                      %flip the screen - make the drawings visible on the screen
    
    %Quickly check for any key on Keyboard 
    if KbResponseFlag
        [~, keyCode] = KbWait([], 2);
        break; %break from while loop
    end
    
    % Mouse button pressed?
    if false %IsOSX                                                             %I used this once during debugging for an Apple macbook (OSX). But then didn't need it after all.
        [pressed, ~, keyCodeKb] = KbCheck([]);                                  %Maybe still useful for another time, hence still here, but "false", so unreachable.
        keyID_raw = find(keyCodeKb,1,'first');     
        if keyID_raw == P.leftArrowKey
            keyID = 1;
        elseif keyID_raw == P.rightArrowKey
            keyID = 2;
        else 
            keyID = NaN;
        end
    else
        if IsLinux 
            [pressed, ~, keyCodeMouse] = KbCheck(GetMouseIndices('slavePointer'));
        else
            [pressed, ~, keyCodeMouse] = KbCheck(GetMouseIndices);
        end
        keyID = find(keyCodeMouse,1,'first');
    end
        
    if pressed && keyID == 1 && within_startButton_bool
        previous_pressed = 1;
    end
    % Mouse button released again?                                                           %clicks here only count if it is still within the startButton after release.
    if ~pressed && previous_pressed
        % And still within startButton?
        if within_startButton_bool
            continueBool = 1;                                               %Break from while loop
        else
            previous_pressed = 0;                                           %Reset the previous mouse button press
        end
    end

    % Escape pressed?
    [pressed, ~, keyCode, ~] = KbCheck;
    if pressed && keyCode(P.quitKey)
        continueBool = 1;                                                   %Break from while loop
    end 

end %end of while loop

end %[EOF]