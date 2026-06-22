function [R,keyCode] = AskQuestions(S,P,D,R)

%Set up a KbQueue
keysOfInterest=zeros(1,256);
keysOfInterest(P.responseKeys)=1;
KbQueueCreate([], keysOfInterest);
KbQueueStart([]);

%Vertical text alignment inside drawn boxes
if IsWin
    c_text_dir = -[1/3, 1/2, 1/2, 1/3];     %larger negative ==> push text further down
else
    c_text_dir = +[1/3, 1/2, 1/2, 1/3];     %larger positive ==> push text further up
end

%Show feedback?
if strcmp(S.task_name,'MAA')
    feedbackBool = true;
else
    feedbackBool = false;
end

%Initialize the response
R.LocResponse = [];
R.LocRespCorrect = [];
R.LocResponseTime = [];
R.ConfidenceLevel = [];
R.ConfResponseTime = [];

%Draw a question mark in the centre of the screen
myText = '?';
boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
DrawFormattedText(P.win, myText, D.win_center_x-round(boundsText(3)/2), D.win_center_y-round(boundsText(4)/2), P.draw_color);

%Draw two arrows in either direction
Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_L1,D.rotationArrows_angleSize_L1,D.rotationArrows_LineWidth);     %L1
Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_L1, D.rotationArrows_LineWidth, P.draw_color);
Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_R2,D.rotationArrows_angleSize_R2,D.rotationArrows_LineWidth);     %R2
Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_R2, D.rotationArrows_LineWidth, P.draw_color);

%Flip the Screen
Screen('DrawingFinished', P.win);
Screen('Flip', P.win);

%Start a timer
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
    %WaitSecs(0.01);
end

%Wait for an initial direction response (ignore any other response)
while true
    
    %First wait for all keys to be released
    %[KbTimeLoc, keyCode] = KbWait([], 2);
        
    %Check for a key press
    [~,keyCode,~,~,~] = KbQueueCheck([]);
    
    %     %Check what the key press was
    if keyCode(P.quitKey) || keyCode(P.Rkey) || keyCode(P.Lkey)
        break;
    end
    
    % Wait for 5 msec to prevent system overload
    WaitSecs(0.005);
end

%Deal with the initial response
if keyCode(P.quitKey) 
    return; 
elseif keyCode(P.Rkey)
    right_selected = true;
    left_selected = false;
    KbTimeLoc = keyCode(P.Rkey);
elseif  keyCode(P.Lkey)
    right_selected = false;
    left_selected = true;
    KbTimeLoc = keyCode(P.Lkey);
end
    
%Wait until a confidence response has been given, but allow for the direction response to change too  
while true
    
    %Draw selected rotation
    if left_selected
        Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_L1,D.rotationArrows_angleSize_L1,D.rotationArrows_LineWidth);     %L1
        Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_L1, D.rotationArrows_LineWidth, P.draw_color);
        Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_L2,D.rotationArrows_angleSize_L2,D.rotationArrows_LineWidth);     %L2
        Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_L2, D.rotationArrows_LineWidth, P.draw_color);
    elseif right_selected
        Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_R1,D.rotationArrows_angleSize_R1,D.rotationArrows_LineWidth);     %R1
        Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_R1, D.rotationArrows_LineWidth, P.draw_color);
        Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_R2,D.rotationArrows_angleSize_R2,D.rotationArrows_LineWidth);     %R2
        Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_R2, D.rotationArrows_LineWidth, P.draw_color);
    end
    
    %Flip the Screen and wait to make sure that the participants check their response
    Screen('DrawingFinished', P.win);
    Screen('Flip', P.win);
    WaitSecs(0.5);
    
    %Draw selected rotation again
    if left_selected
        Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_L1,D.rotationArrows_angleSize_L1,D.rotationArrows_LineWidth);     %L1
        Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_L1, D.rotationArrows_LineWidth, P.draw_color);
        Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_L2,D.rotationArrows_angleSize_L2,D.rotationArrows_LineWidth);     %L2
        Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_L2, D.rotationArrows_LineWidth, P.draw_color);
    elseif right_selected
        Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_R1,D.rotationArrows_angleSize_R1,D.rotationArrows_LineWidth);     %R1
        Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_R1, D.rotationArrows_LineWidth, P.draw_color);
        Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_R2,D.rotationArrows_angleSize_R2,D.rotationArrows_LineWidth);     %R2
        Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_R2, D.rotationArrows_LineWidth, P.draw_color);
    end
    
    %But now also draw the confidence boxes
    Screen('FrameRect', P.win,  P.draw_color,  D.confBox_1, D.confBox_lineWidth);
    Screen('FrameRect', P.win,  P.draw_color,  D.confBox_2, D.confBox_lineWidth);
    Screen('FrameRect', P.win,  P.draw_color,  D.confBox_3, D.confBox_lineWidth);
    Screen('FrameRect', P.win,  P.draw_color,  D.confBox_4, D.confBox_lineWidth);
    DrawFormattedText(P.win, D.confText{1}, round(mean(D.confBox_1([1 3])))-round(D.boundsConfText{1}(3)/2), round(mean(D.confBox_1([2 4])))-c_text_dir(1)*round(D.boundsConfText{1}(4)), P.draw_color);
    DrawFormattedText(P.win, D.confText{2}, round(mean(D.confBox_2([1 3])))-round(D.boundsConfText{2}(3)/2), round(mean(D.confBox_2([2 4])))-c_text_dir(2)*round(D.boundsConfText{2}(4)), P.draw_color);
    DrawFormattedText(P.win, D.confText{3}, round(mean(D.confBox_3([1 3])))-round(D.boundsConfText{3}(3)/2), round(mean(D.confBox_3([2 4])))-c_text_dir(3)*round(D.boundsConfText{3}(4)), P.draw_color);
    DrawFormattedText(P.win, D.confText{4}, round(mean(D.confBox_4([1 3])))-round(D.boundsConfText{4}(3)/2), round(mean(D.confBox_4([2 4])))-c_text_dir(4)*round(D.boundsConfText{4}(4)), P.draw_color);
    
    %Flip the screen again and wait for a confidence response
    Screen('DrawingFinished', P.win);
    Screen('Flip', P.win);
    
    %Wait for all keys to be released the record the next key stroke
    %[KbTimeTemp, keyCode] = KbWait([], 2);
    KbQueueWait([], 1);             %1 = return as soon as no keys are down
    
    %Wait for a new response (rotation or confidence)
    while true

        %Check for a key press
        [~,keyCode,~,~,~] = KbQueueCheck([]);

        %Check what the key press was
        if keyCode(P.quitKey) || keyCode(P.Rkey) || keyCode(P.Lkey) || keyCode(P.Conf1key) || keyCode(P.Conf1key_alt) || keyCode(P.Conf2key) || keyCode(P.Conf3key) || keyCode(P.Conf4key)
            break;
        end

        % Wait for 5 msec to prevent system overload
        WaitSecs(0.005);
    end
    
    %Check what the key press was
    if keyCode(P.quitKey) || keyCode(P.Conf1key) || keyCode(P.Conf1key_alt) || keyCode(P.Conf2key) || keyCode(P.Conf3key) || keyCode(P.Conf4key)
        break;
    elseif keyCode(P.Rkey)
        if left_selected            %if direction change
            %KbTimeLoc = KbTimeTemp; %overwrite the direction response time
            KbTimeLoc = keyCode(P.Rkey);
        end        
        right_selected = true;
        left_selected = false;
    elseif keyCode(P.Lkey)
        if right_selected           %if direction change
            %KbTimeLoc = KbTimeTemp; %overwrite the direction response time
            KbTimeLoc = keyCode(P.Lkey);
        end 
        right_selected = false;
        left_selected = true;
    end
end

%Send triggers to eyetracker and EEG for response
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

%Deal with the confidence response
if keyCode(P.quitKey) 
    return; 
elseif keyCode(P.Conf1key) || keyCode(P.Conf1key_alt)
    confKeyDown = 1;
    R.ConfidenceLevel = 4;
    KbTimeTemp = max(keyCode(P.Conf1key),keyCode(P.Conf1key_alt));
elseif keyCode(P.Conf2key)
    confKeyDown = 2;
    R.ConfidenceLevel = 3;
    KbTimeTemp = keyCode(P.Conf2key);
elseif keyCode(P.Conf3key)
    confKeyDown = 3;
    R.ConfidenceLevel = 2;
    KbTimeTemp = keyCode(P.Conf3key);
elseif keyCode(P.Conf4key)
    confKeyDown = 4;
    R.ConfidenceLevel = 1;
    KbTimeTemp = keyCode(P.Conf4key);
end

%Record the final direction response and the response times
if right_selected
    R.LocResponse = -1;
elseif left_selected
    R.LocResponse = 1;
else
    error('Somehow there was no direction response');
end
R.LocRespCorrect = sign(R.v(end)) == R.LocResponse;
R.LocResponseTime = (KbTimeLoc-startTime)*1000;                             %Location response time in ms, of final direction response since the prompt onset
R.ConfResponseTime = (KbTimeTemp-KbTimeLoc)*1000;                           %Confidence response time in ms, since the final direction response

%Show the confidence response on screen
if left_selected
    Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_L1,D.rotationArrows_angleSize_L1,D.rotationArrows_LineWidth);     %L1
    Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_L1, D.rotationArrows_LineWidth, P.draw_color);
    Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_L2,D.rotationArrows_angleSize_L2,D.rotationArrows_LineWidth);     %L2
    Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_L2, D.rotationArrows_LineWidth, P.draw_color);
elseif right_selected
    Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_R1,D.rotationArrows_angleSize_R1,D.rotationArrows_LineWidth);     %R1
    Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_R1, D.rotationArrows_LineWidth, P.draw_color);
    Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_R2,D.rotationArrows_angleSize_R2,D.rotationArrows_LineWidth);     %R2
    Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_R2, D.rotationArrows_LineWidth, P.draw_color);
end

%Draw the confidence boxes as normal
Screen('FrameRect', P.win,  P.draw_color,  D.confBox_1, D.confBox_lineWidth);
Screen('FrameRect', P.win,  P.draw_color,  D.confBox_2, D.confBox_lineWidth);
Screen('FrameRect', P.win,  P.draw_color,  D.confBox_3, D.confBox_lineWidth);
Screen('FrameRect', P.win,  P.draw_color,  D.confBox_4, D.confBox_lineWidth);
DrawFormattedText(P.win, D.confText{1}, round(mean(D.confBox_1([1 3])))-round(D.boundsConfText{1}(3)/2), round(mean(D.confBox_1([2 4])))-c_text_dir(1)*round(D.boundsConfText{1}(4)), P.draw_color);
DrawFormattedText(P.win, D.confText{2}, round(mean(D.confBox_2([1 3])))-round(D.boundsConfText{2}(3)/2), round(mean(D.confBox_2([2 4])))-c_text_dir(2)*round(D.boundsConfText{2}(4)), P.draw_color);
DrawFormattedText(P.win, D.confText{3}, round(mean(D.confBox_3([1 3])))-round(D.boundsConfText{3}(3)/2), round(mean(D.confBox_3([2 4])))-c_text_dir(3)*round(D.boundsConfText{3}(4)), P.draw_color);
DrawFormattedText(P.win, D.confText{4}, round(mean(D.confBox_4([1 3])))-round(D.boundsConfText{4}(3)/2), round(mean(D.confBox_4([2 4])))-c_text_dir(4)*round(D.boundsConfText{4}(4)), P.draw_color);

%Overlay the selected confidence box
box_coords = {D.confBox_1,D.confBox_2,D.confBox_3,D.confBox_4};
Screen('FillRect', P.win,  P.draw_color,  box_coords{confKeyDown});
DrawFormattedText(P.win, D.confText{confKeyDown}, round(mean(box_coords{confKeyDown}([1 3])))-round(D.boundsConfText{confKeyDown}(3)/2), ...
                                                        round(mean(box_coords{confKeyDown}([2 4])))-c_text_dir(confKeyDown)*round(D.boundsConfText{confKeyDown}(4)), P.background);

%Show the feedback too?                                                     
if feedbackBool
    %Correct response?
    if isempty(R.LocRespCorrect)
        correctBool = 0;
    else
        correctBool = R.LocRespCorrect;                     
    end
    %Feedback Colour?
    if correctBool
        Screen('FillOval', P.win, P.green, D.feedbackButton_Coords);
        triggerString = 'Feedback Positive';
    else
        Screen('FillOval', P.win, P.red, D.feedbackButton_Coords);
        triggerString = 'Feedback Negative';
    end
    %Flip screen
    Screen('FrameOval', P.win, P.draw_color, D.feedbackButton_Coords, 2);
    Screen('DrawingFinished', P.win);
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
        %WaitSecs(0.01);
    end   
else
    %Just flip the screen without sending a trigger
    Screen('DrawingFinished', P.win);
    Screen('Flip', P.win);
end                                                     

%Show the feedback for a bit of time
WaitSecs(0.5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Start the next trial %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Draw Fixation cross
%Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);         % Draw the fixation cross.
Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
Screen('Flip', P.win);

end %[EOF]
