function [R,keyCode] = AskQuestions(S,P,D,R)

%Show feedback?
if strcmp(S.task_name,'MAA')
    confidenceBool = false;
    feedbackBool = true;
else
    confidenceBool = true;
    feedbackBool = false;
end

%Set the maximum response time (in seconds)
max_responseTime = inf;               

%Initialize the response
R.LocResponse = [];
R.LocRespCorrect = [];
R.LocResponseTime = [];
R.ConfidenceLevel = [];

%Wait for button response
LocQuestionAnsweredBool = 0;
TimeLimitExcededBool = 0;
previous_pressed = 0;
FirstPresentation = 1;

%Recentre the mouse to avoid undesired biases
SetMouse(D.win_center_x, D.win_center_y, P.win);

while ~LocQuestionAnsweredBool && ~TimeLimitExcededBool
    
    rightSelectedBool = 0;
    leftSelectedBool = 0;
    confSelected = 0;

    % Draw answerFrame
    Screen('FrameArc',P.win,P.draw_color,D.aBcoords,D.aB_full_angles_R(2),D.aB_full_angleSize,D.answerButton_LineWidth);
    Screen('FrameArc',P.win,P.draw_color,D.aBcoords,D.aB_full_angles_L(1),D.aB_full_angleSize,D.answerButton_LineWidth);
    if confidenceBool
        
        Screen('DrawLines',P.win,D.aB_line_coords_R_parts,D.answerButton_LineWidth,P.draw_color);
        Screen('DrawLines',P.win,D.aB_line_coords_L_parts,D.answerButton_LineWidth,P.draw_color);
        
        Screen('DrawLines',P.win,D.aB_scale_lines_coords_R,D.answerButton_LineWidth,P.draw_color);
        Screen('DrawLines',P.win,D.aB_scale_lines_coords_L,D.answerButton_LineWidth,P.draw_color);
        
        % Draw text
        myText = 'certain';
        boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
        DrawFormattedText(P.win, myText, D.aB_scale_text_Xright+10, D.aB_scale_text_Ytop-round(boundsText(4)/2), P.draw_color);
        DrawFormattedText(P.win, myText, D.aB_scale_text_Xleft-10-boundsText(3), D.aB_scale_text_Ytop-round(boundsText(4)/2), P.draw_color);

        myText = 'guess';
        boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
        DrawFormattedText(P.win, myText, D.aB_scale_text_Xright+10, D.aB_scale_text_Ybottom-round(boundsText(4)/2), P.draw_color);
        DrawFormattedText(P.win, myText, D.aB_scale_text_Xleft-10-boundsText(3), D.aB_scale_text_Ybottom-round(boundsText(4)/2), P.draw_color);
    else
        Screen('DrawLines',P.win,D.aB_line_coords_R_full,D.answerButton_LineWidth,P.draw_color);
        Screen('DrawLines',P.win,D.aB_line_coords_L_full,D.answerButton_LineWidth,P.draw_color);
    end
    
    % Get the current position of the mouse
    [mX, mY, ~] = GetMouse(P.win);
    %Find position in visual angles            
    xRel2Center = mX-D.win_center_x;
    yRel2Center = mY-D.win_center_y;
    X_angle = atand(xRel2Center / D.dist2Screen_inPixWidth);
    Y_angle = atand(yRel2Center / D.dist2Screen_inPixHeight);
    %within startButton
    awayFromCentre_angle = sqrt(X_angle^2+Y_angle^2);            
    within_startButton_bool = awayFromCentre_angle <= D.startButton_Radius;
    within_answerButton_bool = awayFromCentre_angle <= D.aB_radius;
    if ~within_startButton_bool && within_answerButton_bool
        %find angle relative to vertical axis
        angle_rel2_xAxis = cart2pol(X_angle,-Y_angle);          %in rad (-pi,pi] - anticlockwise
        angle_rel2_xAxis = (angle_rel2_xAxis/pi)*180;           %in degree
        angle_rel2_yAxis = -1*(angle_rel2_xAxis-45)+45;         %relative to the vertical axis - clockwise (as PTB likes it)
        if angle_rel2_yAxis < 0
            angle_rel2_yAxis = 360 + angle_rel2_yAxis;
        end
        %Right selected
        if angle_rel2_yAxis > D.aB_full_angles_R(2) && angle_rel2_yAxis <= D.aB_full_angles_R(1)            %notice the order [2 1] instead of [1 2]
            rightSelectedBool = 1;
            if angle_rel2_yAxis > D.aB_part_angles_R(2) && angle_rel2_yAxis <= D.aB_part_angles_R(1)        %notice the order [2 1] instead of [1 2]
                confSelected = 1;
            elseif angle_rel2_yAxis > D.aB_part_angles_R(3) && angle_rel2_yAxis <= D.aB_part_angles_R(2)    %notice the order [3 2] instead of [2 3]
                confSelected = 2;
            elseif angle_rel2_yAxis > D.aB_part_angles_R(4) && angle_rel2_yAxis <= D.aB_part_angles_R(3)    %notice the order [4 3] instead of [3 4]
                confSelected = 3;
            elseif angle_rel2_yAxis > D.aB_part_angles_R(5) && angle_rel2_yAxis <= D.aB_part_angles_R(4)    %notice the order [5 4] instead of [4 5]
                confSelected = 4;
            end
            if confidenceBool && confSelected
                Screen('FillArc',P.win,P.draw_color,D.aBcoords,D.aB_part_angles_R(confSelected+1),D.aB_part_angleSize);
            elseif ~confidenceBool && rightSelectedBool
                Screen('FillArc',P.win,P.draw_color,D.aBcoords,D.aB_full_angles_R(2),D.aB_full_angleSize);
            end
        %Left selected   
        elseif angle_rel2_yAxis >= D.aB_full_angles_L(1) && angle_rel2_yAxis < D.aB_full_angles_L(2)
            leftSelectedBool = 1;                                                                
            if angle_rel2_yAxis >= D.aB_part_angles_L(1) && angle_rel2_yAxis < D.aB_part_angles_L(2)
                confSelected = 1;
            elseif angle_rel2_yAxis >= D.aB_part_angles_L(2) && angle_rel2_yAxis < D.aB_part_angles_L(3)
                confSelected = 2;
            elseif angle_rel2_yAxis >= D.aB_part_angles_L(3) && angle_rel2_yAxis < D.aB_part_angles_L(4)
                confSelected = 3;
            elseif angle_rel2_yAxis >= D.aB_part_angles_L(4) && angle_rel2_yAxis < D.aB_part_angles_L(5)
                confSelected = 4;
            end
            if confidenceBool && confSelected
                Screen('FillArc',P.win,P.draw_color,D.aBcoords,D.aB_part_angles_L(confSelected),D.aB_part_angleSize);
            elseif ~confidenceBool && leftSelectedBool
                Screen('FillArc',P.win,P.draw_color,D.aBcoords,D.aB_full_angles_L(1),D.aB_full_angleSize);
            end
        end
        Screen('FillOval', P.win, P.background, D.startButton_Coords);      %to possibly overlay one of the filled arcs                            
    end
    %Draw startButton
    Screen('FrameOval', P.win, P.draw_color, D.startButton_Coords, D.startButton_LineWidth); 
    %Draw mouse pointer
    %Screen('DrawLines', P.win, D.miniCursor_Coords, D.miniCursor_LineWidth, P.draw_color, [mX,mY]);
    Screen('DrawDots', P.win, [mX,mY], 10, P.draw_color, [], 1);
    %Flip the Screen
    Screen('DrawingFinished', P.win);
    Screen('Flip', P.win);
    
    %First time that this is presented?
    if FirstPresentation
        %Set start time
        startTime = GetSecs;
        % Send triggers to eyetracker and EEG for prompt onset
        if P.eyeTrackerActive || S.eeg_recording
            triggerNr = S.triggersInfo{cellfun(@(x) strcmp(x,'Response Prompt'),S.triggersInfo(:,3)),1};
            if P.eyeTrackerActive
                Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
            end
            if S.eeg_recording
                IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
            end
            %pause(0.01);
        end
        FirstPresentation = 0;
    end
    
    % Mouse button pressed?
    if IsLinux 
        [pressed, KbTimeTemp, keyCodeMouse] = KbCheck(GetMouseIndices('slavePointer'));
    else
        [pressed, KbTimeTemp, keyCodeMouse] = KbCheck(GetMouseIndices);
    end
    keyID = find(keyCodeMouse,1,'first');
    if pressed && ~previous_pressed && keyID == 1 && (leftSelectedBool || rightSelectedBool)
        previous_pressed = 1;
        KbTime = KbTimeTemp;
        selected_side_first = [leftSelectedBool, rightSelectedBool];
        conf_selected_first = confSelected;
    end
    % Mouse button released again?
    if ~pressed && previous_pressed
        % And still the same selection?
        selected_side_new = [leftSelectedBool, rightSelectedBool];
        conf_selected_new = confSelected;
        if sum(selected_side_first == selected_side_new) == numel(selected_side_first) && (~confidenceBool || (conf_selected_first == conf_selected_new))     %if selected is still the same..
            
            % An answer was given...
            R.LocResponseTime = (KbTime-startTime)*1000;                            %Response time in ms
            R.LocResponse = find([rightSelectedBool 0 leftSelectedBool])-2;         %Record answer: right = -1, left = 1
            R.LocRespCorrect = sign(R.v(end)) == R.LocResponse;
            if confidenceBool
                R.ConfidenceLevel = confSelected;
            end
            LocQuestionAnsweredBool = 1;                                            %Break from question's while loop
            
            % Send triggers to eyetracker and EEG for response
            if P.eyeTrackerActive || S.eeg_recording
                triggerNr = S.triggersInfo{cellfun(@(x) strcmp(x,'Response Given'),S.triggersInfo(:,3)),1};
                if P.eyeTrackerActive
                    Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
                end
                if S.eeg_recording
                    IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
                end
                %pause(0.01);
            end
        else                                                
            previous_pressed = 0;                                           %Reset the previous mouse button press if the selection is not the same anymore as when the mouse button was pressed
        end
    end %end of mouse-button release if-statement
    
    % Escape pressed?
    [pressed, ~, keyCode, ~] = KbCheck;
    if pressed && keyCode(P.quitKey)
        LocQuestionAnsweredBool = 1;                                        %Break from question's while loop
    end
    
    %Check response time
    currentTime = GetSecs;
    if (currentTime - startTime) > max_responseTime
        TimeLimitExcededBool = 1;
    end
    
end %End of question's while-loop 

%%%%%%%%%%%%%%%%
%%% Feedback %%%
%%%%%%%%%%%%%%%%

if feedbackBool && ~keyCode(P.quitKey)
    %Correct response?
    if isempty(R.LocRespCorrect)
        correctBool = 0;
    else
        correctBool = R.LocRespCorrect;                     
    end
    %Feedback Colour?
    if correctBool
        Screen('FillOval', P.win, P.green, D.startButton_Coords);
        triggerString = 'Feedback Positive';
    else
        Screen('FillOval', P.win, P.red, D.startButton_Coords);
        triggerString = 'Feedback Negative';
    end
    %Flip screen
    Screen('FrameOval', P.win, P.draw_color, D.startButton_Coords, 3);
    Screen('Flip', P.win);
    
    % Send triggers to eyetracker and EEG for response
    if P.eyeTrackerActive || S.eeg_recording
        triggerNr = S.triggersInfo{cellfun(@(x) strcmp(x,triggerString),S.triggersInfo(:,3)),1};
        if P.eyeTrackerActive
            Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
        end
        if S.eeg_recording
            IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
        end
        %pause(0.01);
    end
    
    %Show the feedback for a bit of time
    WaitSecs(0.2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Move mouse back to middle to start next trial %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mouseInMiddleBool = 0;
while ~mouseInMiddleBool && ~TimeLimitExcededBool
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

    % Draw mouse and startButton
    %Screen('DrawLines', P.win, D.miniCursor_Coords, D.miniCursor_LineWidth, P.draw_color, [mX,mY]);       %draw mouse cursor (same way as the fixation cross)
    Screen('DrawDots', P.win, [mX,mY], 10, P.draw_color, [], 1);
    % Draw filled/open startButton 
    if within_startButton_bool
        Screen('FillOval', P.win, P.draw_color, D.startButton_Coords);                             %filled startButton
    else
        Screen('FrameOval', P.win, P.draw_color, D.startButton_Coords, D.startButton_LineWidth);   %open startButton
    end
    Screen('DrawingFinished', P.win);                                       %tell PsychToolBox that there are no further drawing commands (this speeds up the processing)
    Screen('Flip', P.win);                                                  %Flip the screen - make the drawings visible on the screen

    % Is the mouse on start button? (Press is unnecessary)
    if within_startButton_bool
        mouseInMiddleBool = 1;                                              %Break from start_trial while loop
    end

    % Escape pressed?
    [pressed, ~, keyCode, ~] = KbCheck;
    if pressed && keyCode(P.quitKey)
        mouseInMiddleBool = 1;                                              %Break from question's while loop
    end
    
    %Check response time
    currentTime = GetSecs;
    if (currentTime - startTime) > max_responseTime
        TimeLimitExcededBool = 1;
    end
    
end %end of while loop (start next trial?)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Start the next trial %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Draw Fixation cross
%Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);         % Draw the fixation cross.
Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
Screen('Flip', P.win);

end %[EOF]
