%% Collect resting state data
function RS(S,F)

% P and D are necessary to draw things on screen
P = SetupScreen(S);
D = PrepareDrawing(S,P);

if S.eeg_recording
    P.TriggerBox = IOPort('OpenSerialPort', 'COM3');
    Available = IOPort('BytesAvailable', P.TriggerBox);                 %Read data from the TriggerBox
    if(Available > 0)
        disp(IOPort('Read', P.TriggerBox, 0, Available));
    end
    IOPort('Write', P.TriggerBox, uint8(0), 0);                         %Set the port to zero state 0
    pause(0.01);
end

% Ask to press button
DrawFormattedText(P.win, ' Please  press any key on keyboard to start!',...
    'center', 'center', P.draw_color);
Screen('Flip', P.win);

% Wait for participant to press a button
pressed_button = 0;
while ~pressed_button
    [pressed] = KbCheck;
    if pressed
        break
    end
    
end

% Make participants fixate for 5 seconds while there is still text on the
% screen
DrawFormattedText(P.win, ' Please fixate on the fixation dot!',...
    'center', D.win_center_y-200, P.draw_color);
Screen('DrawDots', P.win, [D.win_center_x D.win_center_y], 5, P.draw_color, [], 2);
Screen('Flip', P.win);
WaitSecs(5)

% Present only dot
Screen('DrawDots', P.win, [D.win_center_x D.win_center_y], 5, P.draw_color, [], 2);
Screen('Flip', P.win);

if S.eeg_recording
    % Send trigger to EEG for the start of fixation
    IOPort('Write', P.TriggerBox, uint8(100), 0); % start of fixation
    pause(0.01);
end


% Participant fixates for 65 seconds
WaitSecs(65)
if S.eeg_recording
    % Send trigger to EEG for end of fixation
    IOPort('Write', P.TriggerBox, uint8(200), 0); % end of fixation
    pause(0.01);
end
% Update overview file
OverviewFile = fullfile(F.run_path,'OverviewFile.mat');
load(OverviewFile,'completed_tasks');
completed_tasks(S.subject_Nr,S.task_nr) = 1;
save(OverviewFile,'completed_tasks','-append');
%Gather Path, Name and Extension
[savePath,filename,fileExtension] = fileparts(F.save_file);

%Append the number of trials to the fileName
save_file = fullfile(savePath,[filename fileExtension]);

% Finished
DrawFormattedText(P.win, ' It is all done! Thank you!',...
    'center', 'center', P.draw_color);
Screen('Flip', P.win);
WaitSecs(2)
ListenChar(0);
sca;


end