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
if  strcmp(S.task_name, 'Last_direction_discrimination') && ismember(S.block_nr, [1,2])
    feedbackBool = true;
else
    feedbackBool = false;
    %feedbackBool = true;        %%%% TEMPORARY %%%% !!!!!
end

%Initialize the response
R.TempoDirResponse = [];
R.TempoDirRespCorrect = [];
R.TempoDirResponseTime = [];
R.ConfidenceLevel = [];
R.ConfResponseTime = [];

%Draw a question mark in the centre of the screen
myText = '?';
boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
Screen('DrawText',P.win, myText, D.win_center_x-round(boundsText(3)/2), D.win_center_y-round(boundsText(4)/2), P.draw_color);

%Draw response buttons
for j=1:2
    Screen('FrameRect', P.win,  P.draw_color,  D.respButton_Coords{j} , D.respButton_lineWidth);
    myText = D.respText{j};
    boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
    Screen('DrawText',P.win, myText, D.respButton_CentreLocs{j}(1)-round(boundsText(3)/2), D.respButton_CentreLocs{j}(2)-round(boundsText(4)/2), P.draw_color);
end

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

%Wait for a direction response (ignore any other response)
while true

    %Check for a key press
    [~,keyCode,~,~,~] = KbQueueCheck([]);

    %Check what the key press was
    if keyCode(P.quitKey) || keyCode(P.upKey) || keyCode(P.downKey)
        break;
    end

    % Wait for 5 msec to prevent system overload
    WaitSecs(0.005);
end

%Register the response
if keyCode(P.quitKey)
    return;
elseif keyCode(P.upKey)
    resp_selected = 1;
    KbTimeTempoDir = keyCode(P.upKey);
elseif  keyCode(P.downKey)
    resp_selected = 2;
    KbTimeTempoDir = keyCode(P.downKey);
end

resp_options = [1 2];
%Wait until a confidence response has been given, but allow for the direction response to change too
while true


    %Show the selected response on screen
    Screen('FillRect', P.win,  P.draw_color,  D.respButton_Coords{resp_selected});
    myText = D.respText{resp_selected};
    boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
    Screen('DrawText',P.win, myText, D.respButton_CentreLocs{resp_selected}(1)-round(boundsText(3)/2), D.respButton_CentreLocs{resp_selected}(2)-round(boundsText(4)/2), P.background);
    %Also show the unselected response button
    resp_unselected = setdiff(resp_options,resp_selected);
    Screen('FrameRect', P.win,  P.draw_color,  D.respButton_Coords{resp_unselected} , D.respButton_lineWidth);
    myText = D.respText{resp_unselected};
    boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
    Screen('DrawText',P.win, myText, D.respButton_CentreLocs{resp_unselected}(1)-round(boundsText(3)/2), D.respButton_CentreLocs{resp_unselected}(2)-round(boundsText(4)/2), P.draw_color);

    %Flip the Screen and wait to make sure that the participants check their response
    Screen('DrawingFinished', P.win);
    Screen('Flip', P.win);
    WaitSecs(0.5);

    %Show the selected response on screen
    Screen('FillRect', P.win,  P.draw_color,  D.respButton_Coords{resp_selected});
    myText = D.respText{resp_selected};
    boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
    Screen('DrawText',P.win, myText, D.respButton_CentreLocs{resp_selected}(1)-round(boundsText(3)/2), D.respButton_CentreLocs{resp_selected}(2)-round(boundsText(4)/2), P.background);
    %Also show the unselected response button
    resp_unselected = setdiff(resp_options,resp_selected);
    Screen('FrameRect', P.win,  P.draw_color,  D.respButton_Coords{resp_unselected} , D.respButton_lineWidth);
    myText = D.respText{resp_unselected};
    boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
    Screen('DrawText',P.win, myText, D.respButton_CentreLocs{resp_unselected}(1)-round(boundsText(3)/2), D.respButton_CentreLocs{resp_unselected}(2)-round(boundsText(4)/2), P.draw_color);


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
        if keyCode(P.quitKey) || keyCode(P.upKey) || keyCode(P.downKey) || keyCode(P.Conf1key) || keyCode(P.Conf1key_alt) || keyCode(P.Conf2key) || keyCode(P.Conf3key) || keyCode(P.Conf4key)
            break;
        end

        % Wait for 5 msec to prevent system overload
        WaitSecs(0.005);
    end

    %Check what the key press was
    if keyCode(P.quitKey) || keyCode(P.Conf1key) || keyCode(P.Conf1key_alt) || keyCode(P.Conf2key) || keyCode(P.Conf3key) || keyCode(P.Conf4key)
        break;
    elseif keyCode(P.upKey)

        KbTimeTempoDir = keyCode(P.upKey);

        resp_selected = 1;
    elseif keyCode(P.downKey)

        KbTimeTempoDir = keyCode(P.downKey);

        resp_selected = 2;
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


%Save the response and response time
if ~ismember(resp_selected,resp_options)
    error('Invalid response');
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

R.TempoDirResponse = 2*(resp_selected-1.5);     %convert [1,2] to [-1,+1]
R.TempoDirRespCorrect = R.d(end) == R.TempoDirResponse;
R.TempoDirResponseTime = (KbTimeTempoDir-startTime)*1000;                   %TempoDir response time in ms
R.ConfResponseTime = (KbTimeTemp-KbTimeTempoDir)*1000;                           %Confidence response time in ms, since the final direction response

%Show the selected response on screen
Screen('FillRect', P.win,  P.draw_color,  D.respButton_Coords{resp_selected});
myText = D.respText{resp_selected};
boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
Screen('DrawText',P.win, myText, D.respButton_CentreLocs{resp_selected}(1)-round(boundsText(3)/2), D.respButton_CentreLocs{resp_selected}(2)-round(boundsText(4)/2), P.background);

%Also show the unselected response button
resp_unselected = setdiff(resp_options,resp_selected);
Screen('FrameRect', P.win,  P.draw_color,  D.respButton_Coords{resp_unselected} , D.respButton_lineWidth);
myText = D.respText{resp_unselected};
boundsText = Screen(P.win, 'TextBounds', myText);   %[L,T,R,B] from [0,0]
Screen('DrawText',P.win, myText, D.respButton_CentreLocs{resp_unselected}(1)-round(boundsText(3)/2), D.respButton_CentreLocs{resp_unselected}(2)-round(boundsText(4)/2), P.draw_color);

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
    if isempty(R.TempoDirRespCorrect)
        correctBool = 0;
    else
        correctBool = R.TempoDirRespCorrect;
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
