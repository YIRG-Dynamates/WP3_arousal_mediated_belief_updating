function [S,num_trials_completed] = PresentStim(S,F,trials_cell,eye_data) 
% Main function for stimulus presentation
P.eyeTrackerActive = 0; %temporary debugging
% Set some timing specifics (in seconds) --> but do ensure that these are multiples of the ifi (screen update time: e.g. with a 60Hz monitor the ifi is 1/60.
S.timing.stim_duration = 0.05; 
S.timing.ISI = 0.45; 

if strcmp(S.task_name,'MAA')
    S.timing.lead_out = 0;                                  %Fast
elseif strcmp(S.task_name, 'Continuous_detection')
    S.timing.lead_out = 1;                                  %Allow for some time to change responded direction at the end of each sequence
elseif strcmp(S.task_name, 'Last_direction_discrimination')
    S.timing.lead_out = 1;                                  %Long pause before response prompt appears, such that this time can be used to analyse pupillometry signals
end
   
% After how many trials does the participant get a break?  
S.miniBreakRate = 25;

% How early should the command to flip at a certain time be given (time in flips: e.g. 0.2*ifi before the next flip)   
S.flipFractionEarlyCommand = 0.2;
S.last_part_LeadIn_duration = 0.2;  %in seconds

%Initialize output of this function (in case of early return)
num_trials_completed = sum(cellfun(@(x) isfield(x,'LocResponse'),trials_cell),'all');

% It's a good habit to run PTB within a try-catch loop
try
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Preparation phase %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Prepare the screen and response buttons
    P = SetupScreen(S);
    
    % Prepare Audio Device
    [P,HRTF] = SetupAudio(S,P,F);
    
    % Prepare to draw shapes on the screen
    D = PrepareDrawing(S,P);                                                %Design fixation cross, response mechanism, etc
    
    % Ensure head on chin-rest and face pointing in correct direction
    quit_flag = false;
    keyCode = SoundFromMiddleCheck(S,P,D,HRTF,1);                           %Has to be done before eye-tracker calibration
    if keyCode(P.quitKey)
        quit_flag = true;      
    end
    
    %Initialize and calibrate the eyetracker
    if S.eye_tracking && ~quit_flag
        P = PrepareEyeTracker(F,P,D);
        eyeTrackerDataAvailableBool = 0;   
        P.eyeTrackerActive = 1; 
    else
        P.eyeTrackerActive = 0;
    end
    
    % Initialize virtual serial port for EEG triggers
    if S.eeg_recording && ~quit_flag
        P.TriggerBox = IOPort('OpenSerialPort', 'COM3'); 
        Available = IOPort('BytesAvailable', P.TriggerBox);                 %Read data from the TriggerBox
        if(Available > 0)
            disp(IOPort('Read', P.TriggerBox, 0, Available));
        end
        IOPort('Write', P.TriggerBox, uint8(0), 0);                         %Set the port to zero state 0
        pause(0.01);
    end
    
    % Restrict button presses to selected few 
    if ~IsLinux && ~S.PTBcode_debuging && ~quit_flag                            %Commented out because it led to the mouse not working on an Apple macBook.
%        RestrictKeysForKbCheck(P.responseKeys);                                %This speeds up reading out key-responses
    end                                                                         %Should be done only after eye-tracker calibration in order to allow 
                                                                                            
    % Initialize trial counting system
    P.trial_counter = num_trials_completed+1;
    P.firstTrialBool = 1;
    P.allTrialsDoneBool = 0;
    
    % Save screen center and distance to screen for reference to eye-tracker data (has to be done after counting system has been initialized)    
    eye_data{P.trial_counter,3} = [D.win_center_x, D.win_center_y; D.dist2Screen_inPixWidth, D.dist2Screen_inPixHeight];                                                      
    save(F.save_file,'eye_data','-append','-v6');
    % This can be used as (in the analysis) - optionally, the center position can be replaced by the mean of the 5 second fixation period at the block start:
    % xRel2Center = GazeX-eye_data{P.trial_counter,3}(1,1);
    % yRel2Center = GazeY-eye_data{P.trial_counter,3}(1,2);
    % X_angle = atand(xRel2Center ./ eye_data{P.trial_counter,3}(2,1));
    % Y_angle = atand(yRel2Center ./ eye_data{P.trial_counter,3}(2,2));
    
    % Dummy calls to GetSecs (because the first call may take some additional time)
    GetSecs; GetSecs;
    
    % Send triggers for start of block
    if (P.eyeTrackerActive || S.eeg_recording) && ~quit_flag
        triggerNr = S.triggersInfo{cellfun(@(x) strcmp(x,'Start of Block'),S.triggersInfo(:,3)),1};
        if P.eyeTrackerActive
            Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
        end
        if S.eeg_recording
            IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
        end
        pause(0.01);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Start the trials while loop %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    while ~P.allTrialsDoneBool && ~quit_flag
        
        % Display the trial nr at the bottom of the eyetracker display
        if P.eyeTrackerActive
            Eyelink('command', 'record_status_message "TRIAL %d"', P.trial_counter);                  
        end
        
        % Update the staircase settings for the coming trial
        if strcmp(S.task_name,'MAA') && ismember(S.block_nr, [2 3 4])
            [S,trials_cell,stopTaskBool] = StaircaseControl(S,P,trials_cell);
            if stopTaskBool
                P.trial_counter = P.trial_counter-1;
                break;                                  %If staircases have all converged, then break from the trial's while loop 
            end                                         %Note: ESCAPE was not pressed, so the program finishes in the normal way
        end                                             %The trial counter is subtracted by one, because this trial was never executed
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Time for a minibreak? %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if (P.trial_counter > S.miniBreakRate) && (mod(P.trial_counter,S.miniBreakRate) == 1) && ~S.AVsynchrony_test 
            miniBreakBool = 1;
        else 
            miniBreakBool = 0;
        end
           
        if miniBreakBool
            keyCode = TakeMiniBreak(S,P,D);                
            % Terminate the program? if escape was pressed..     
            if keyCode(P.quitKey)
                break;                                                      %Break from the Trial's While-loop (results of the previous trial are not saved: aborted before the answers were saved)
            end   
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Press circle in middle %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if (P.firstTrialBool && ~S.AVsynchrony_test) || miniBreakBool
            if strcmp(S.task_name,'MAA') 
                if ismember(S.block_nr,[3 4])
                    if trials_cell{P.trial_counter}.azimuth_offset < 0
                        myTextAbove = 'Both sounds will be presented on the RIGHT side of space';
                    elseif trials_cell{P.trial_counter}.azimuth_offset > 0
                        myTextAbove = 'Both sounds will be presented on the LEFT side of space';
                    end
                elseif P.firstTrialBool
                    myTextAbove = 'TASK: Indicate movement direction when prompted';
                else
                    myTextAbove = ' ';
                end
            elseif strcmp(S.task_name, 'Continuous_detection') 
                if P.firstTrialBool
                    myTextAbove = 'TASK: Continuously indicate movement direction';
                else
                    myTextAbove = ['Trial ' num2str(P.trial_counter) ' out of ' num2str(S.nTrials)];
                end
            elseif strcmp(S.task_name, 'Last_direction_discrimination') && P.firstTrialBool
                myTextAbove = 'TASK: Indicate LAST movement direction and confidence rating when prompted';
            else
                myTextAbove = ' ';
            end
            if miniBreakBool
                myTextBelow = 'Press any key to continue';  %'Click on circle to continue';
            else
                myTextBelow = 'Press any key to start';     %'Click on circle to start';
            end
            myTextCentre = ' '; 
            SetMouse(D.win_center_x, D.belowStartButton, P.win);            %Set the mouse to some random low point
            keyCode = CircleInMiddleClick(S,P,D,myTextAbove,myTextBelow,myTextCentre,1);
            % Terminate the program? if escape was pressed..     
            if keyCode(P.quitKey)
                break;                                                      %Break from the Trial's While-loop (results of the previous trial are not saved: aborted before the answers were saved)
            end 
        
        %The following is necessary because we don't ask questions at the end of the change-point detection task    
        elseif strcmp(S.task_name, 'Continuous_detection')
            
            myText = ['Trial ' num2str(P.trial_counter) ' out of ' num2str(S.nTrials)];
            boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
            DrawFormattedText(P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
            Screen('Flip', P.win);
            WaitSecs(1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Fixation Calibration of EyeTracker %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Fixation necessary?
        if P.firstTrialBool && P.eyeTrackerActive
            
            % Ask participant to fixate
            %myText = 'Please closely fixate your eyes on the cross for a few seconds';
            myText = 'Please closely fixate your eyes on the dot for a few seconds';
            boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
            DrawFormattedText(P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
            Screen('Flip', P.win);
            WaitSecs(4);
            
            % Draw the fixation cross 
            %Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);               % Draw the fixation cross.
            Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
            Screen('DrawingFinished', P.win);                                                                                                  % No further drawing commands before Screen('Flip')
            Screen('Flip', P.win); 
            
            % Ignore the first second
            WaitSecs(1);
            
            % Get eye-data
            [~, ~, ~] = GetDataEyelink(P,0);                                    %Flush Queue
            WaitSecs(0.1); Eyelink('Message', ['MYKEYWORD '  num2str(S.triggersInfo{cellfun(@(x) strcmp(x,'5sec Fix Start'),S.triggersInfo(:,3)),1})]); WaitSecs(0.1);
            [SampleData1, EventData1, keyCode1] = GetDataEyelink(P,4.8);        %Collect EyeData for a duration of 5 seconds
            WaitSecs(0.1); Eyelink('Message', ['MYKEYWORD '  num2str(S.triggersInfo{cellfun(@(x) strcmp(x,'5sec Fix End'),S.triggersInfo(:,3)),1})]); WaitSecs(0.1);          
            [SampleData2, EventData2, keyCode2] = GetDataEyelink(P,0);          %Get last eyetracker data

            % Terminate the program? if escape was pressed..     
            if keyCode1(P.quitKey)
                keyCode = keyCode1;
                break;                                                          %Break from the Trial's While-loop (results of the previous trial are not saved: aborted before the answers were saved)
            elseif keyCode2(P.quitKey)
                keyCode = keyCode2;
                break;
            end

            %Save relevant data
            SampleData = [SampleData1 SampleData2];
            EventData = [EventData1 EventData2];
            save([P.eye_save_dir filesep 'Eyelink_Fixation_Trial_' num2str(P.trial_counter) '.mat'], 'SampleData', 'EventData', '-v6');
            eyeTrackerDataAvailableBool = 0;

%             %Find the sample times of the triggers and save them
%             if ~isempty(EventData)
%                 idx_msgs = find(EventData(1,:) == 24);
%                 if ~isempty(idx_msgs)
%                     FixationStartTime = EventData(2,idx_msgs(end-1));
%                     FixationEndTime = EventData(2,idx_msgs(end));
%                     eye_data{P.trial_counter,2} = [FixationStartTime FixationEndTime];  %Calibration timestamps are saved in the second column of the eye_data cell-array
%                     save(F.save_file,'eye_data','-append','-v6');                       %Save to Harddisk/USB (this may take quite some time, hundreds of milliseconds)   
%                 end
%             end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Instructions on Screen (block anouncement) %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Instruction necessary?
        if P.firstTrialBool && ~S.AVsynchrony_test
            instructBool = 1;
            P.firstTrialBool = 0;                  
        elseif miniBreakBool 
            instructBool = 1;
            %Screen('Flip', P.win);                  %This 1 second interval ensures that some extra attention is focused on the instruction (after the minibreak)
            %WaitSecs(1);                            %Commented out, because we already ask the participant to click the circle to continue   
        else
            instructBool = 0;
        end
        
        % Present instructions
        if instructBool
            
           if strcmp(S.task_name,'MAA')
                myText = 'Indicate movement direction when prompted';
            elseif strcmp(S.task_name, 'Continuous_detection')
                myText = 'Continuously indicate movement direction';
            elseif strcmp(S.task_name, 'Last_direction_discrimination')
                myText = 'Indicate LAST movement direction when prompted';
            end
            boundsText = Screen(P.win,'TextBounds',myText);   
            DrawFormattedText(P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);       %draw text
            Screen('DrawingFinished', P.win);                                                                                   %No more drawing commands
            Screen('Flip', P.win);                                                                                              %Flip the Screen
            
            %Wait X seconds
            xSeconds = 3;
            InstructionStartTime = GetSecs;
            continueBool = 0;
            while ~continueBool
                %Check Time
                CurrentTime = GetSecs;
                if (CurrentTime-InstructionStartTime) > xSeconds
                    continueBool = 1;                                       %Break from instruction while loop (time passed)
                end
                % Escape pressed?
                [pressed, ~, keyCode, ~] = KbCheck;
                if pressed && keyCode(P.quitKey)
                    continueBool = 1;                                       %Break from instruction while loop (Escape pressed)
                end
            end

            % Terminate the program? if escape was pressed..     
            if keyCode(P.quitKey)
                break;                                                      %Break from the Trial's While-loop (results of the previous trial are not saved: aborted before the answers were saved)
            end    
        end %end of if-statement (instructions?)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Start the lead-in time, perform some saving and preparation actions %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Flush eyetracker queue - eyetracker data hereafter will be saved
        if P.eyeTrackerActive
            [~, ~, ~] = GetDataEyelink(P,0);
        end
        
        %Get a timestamp to record the trial's duration (including the response time, feedback time, etc)       
        tic;
        
        % We split the leadIn duration because we want to save the data from the previous trial during the first part of the leadIn,       
        % but we still want to use a fixed and accurate duration for the second part in order for the AV synchrony to work out as expected.         
        Minimal_leadIn_duration_first_part_in_flips = round((trials_cell{P.trial_counter,1}.timing_lead_in/1000 - S.last_part_LeadIn_duration)/P.ifi);     
        LeadIn_duration_last_part_in_flips = round(S.last_part_LeadIn_duration/P.ifi);                            
          
        if ~S.AVsynchrony_test
            % Draw the fixation cross
            %Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);               % Draw the fixation cross.  
            Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
        end
        
        % No further drawing commands before Screen('Flip')
        Screen('DrawingFinished', P.win);
        % Flip the screen (offline drawing board becomes online screen)                                                                                 
        tvbl_begin_first_part_LeadIn = Screen('Flip', P.win);                             
        % Video cards mark the end of each video frame by briefly reducing the voltage to the Vertical Blanking Level (VBL), which "blanks" the screen to black. 
        % Psychtoolbox does all video timing relative to the beginning of blanking (tvbl: system time in seconds). This is the onset of the exchange of front- 
        % and back drawing surfaces and it is the crucial reference value for computing the 't_deadline' presentation deadline for the next 'Flip' command.
        
        % Define the minimum deadline (we wait at least this long, perhaps longer if saving the last trial took longer).    
        minimum_vis_deadline = tvbl_begin_first_part_LeadIn + (Minimal_leadIn_duration_first_part_in_flips - S.flipFractionEarlyCommand)*P.ifi;
        
        % The trial has now really started. Send the trial number to eyetracker and EEG as a trigger to signal the start of the trial.   
        if P.eyeTrackerActive
            Eyelink('Message', ['MYKEYWORD '  num2str(P.trial_counter)]);                 
        end
        if S.eeg_recording
            IOPort('Write', P.TriggerBox, uint8(P.trial_counter), 0);
            %pause(0.01);
        end
        
        % Save Eyelink data of previous trial (this may take quite some time)
        if P.eyeTrackerActive 
            if eyeTrackerDataAvailableBool
                save([P.eye_save_dir filesep 'Eyelink_Trial_' num2str(P.trial_counter-1) '.mat'], 'SampleData', 'EventData', '-v6');
                eyeTrackerDataAvailableBool = 0;
            end
        end
        
        % Save the data of the previous trial (this may take quite some time) - Note: this includes the updated staircase settings of the current trial      
        if P.trial_counter ~= 1
            time1 = GetSecs;      
            settings = S;
            if P.eyeTrackerActive
                save(F.save_file,'settings','trials_cell','eye_data','-append','-v6');
            else
                save(F.save_file,'settings','trials_cell','-append','-v6');
            end
            time2 = GetSecs;
            trialSaveTime = (time2-time1)*1000;
        else
            trialSaveTime = NaN;
        end
        
        % Generate stimuli
        [Stimuli,total_sound_duration] = GenerateStimuli(S,P,trials_cell,HRTF);
        
        % Buffer the sound 
        PsychPortAudio('FillBuffer',P.AudioHandle,Stimuli);

        % Start the last part of the leadIn time
        if ~S.AVsynchrony_test
            %Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);          % Draw the fixation cross.
            Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
        end
        Screen('DrawingFinished', P.win);                                                                                       % No further drawing commands before Screen('Flip')
        tvbl_begin_last_part_LeadIn = Screen('Flip',P.win,minimum_vis_deadline);  
        % Flip will wait until (at least) the deadline and then flips the buffers at the next possible VBL
        % This flip may be missed if saving the data took longer than the leadIn_first_part, but that is not problematic because the accurate timing starts from now on (lead-in time may unintentionally be longer)          

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Start stimuli presentation %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % We schedule the sound to begin playback after the duration of the lead_in, starting from the initial timestamp. 
        % The visual stimuli will be presented at around half the height of the monitor, so we delay sound onsets relative to the visual stimuli with half an ifi.
        aud_stim_start_time = tvbl_begin_last_part_LeadIn + (LeadIn_duration_last_part_in_flips + 0.5)*P.ifi;
        PsychPortAudio('Start', P.AudioHandle, [], aud_stim_start_time);
        aud_stim_end_time = aud_stim_start_time+total_sound_duration;
        
        % Similarly we schedule the visual stimulus to begin after the duration of the lead_in   
        % We substract S.flipFractionEarlyCommand*P.ifi so the screen gets the flip command a bit earlier and flips on the next possibility.
        vis_stim_onset_deadline = tvbl_begin_last_part_LeadIn + (LeadIn_duration_last_part_in_flips - S.flipFractionEarlyCommand)*P.ifi;
        vis_stim_offset_deadline = vis_stim_onset_deadline + S.timing.stim_duration;
        
        % Draw the fixation cross
        %Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);          
        Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
        
        % Testing AV synchrony?
        if S.AVsynchrony_test 
            Screen('FillRect',P.win,P.white,D.AVsynchrony_rect);            % Overwrite everything that was previously drawn (but still draw it to let it be part of the timing test)
        end
        
        % Tell the system drawing has finished and present it at the deadline
        Screen('DrawingFinished', P.win);                                                                                       % No further drawing commands before Screen('Flip')
        tvbl_stimOnset = Screen('Flip',P.win,vis_stim_onset_deadline);                     % Flip will wait until the deadline and then flips the buffers at the next possible VBL.
        
        % Send triggers to eyetracker and EEG for stimulus onset
        if P.eyeTrackerActive || S.eeg_recording
            triggerNr = S.triggersInfo{cellfun(@(x) strcmp(x,'A stimulus'),S.triggersInfo(:,3)),1};
            if P.eyeTrackerActive
                Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
            end
            if S.eeg_recording
                IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
            end
        end
        
        % Present stimulus offset
        %Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);          
        Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
        
        % Testing AV synchrony?
        if S.AVsynchrony_test 
            Screen('FillRect',P.win,0,D.AVsynchrony_rect);                                  % Overwrite everything that was previously drawn (but still draw it to let it be part of the timing test)
        end

        % Tell the system drawing has finished and present stim_offset at the deadline
        Screen('DrawingFinished', P.win);                                                                                       % No further drawing commands before Screen('Flip')
        tvbl_stimOffset = Screen('Flip',P.win,vis_stim_offset_deadline);                    % Flip will wait until the deadline and then flips the buffers at the next possible VBL.

        % Send triggers to EEG for stimulus offset (trigger reset to zero is necessary in case consecutive triggers have the same number)
        if S.eeg_recording
            IOPort('Write', P.TriggerBox, uint8(0), 0);
        end
        
        %Start recording button clicks (we do this even if the task does not require it, to notice if participants do it anyways) 
        cp_response = [];
        cp_response_time_secs = [];  
        counter = 1;
        while GetSecs < (aud_stim_end_time+1)                               %After the sound ends we still record responses for 1 additional second
            
            if IsWin %Use left/right mouse buttons on Windows OS
                [KbTime, keyCodeMouse] = KbPressWait(GetMouseIndices,aud_stim_end_time+1);
                keyID = find(keyCodeMouse,1,'first');       

            elseif ismac %Mac works with the windows solutions, surprisingly // Roman
                [KbTime, keyCodeMouse] = KbPressWait(GetMouseIndices,aud_stim_end_time+1);
                keyID = find(keyCodeMouse,1,'first');    
                
            else %Use left/right arrow keys on any other operating system

                [KbTime, keyCodeKb] = KbPressWait([],aud_stim_end_time+1);
                keyID_raw = find(keyCodeKb,1,'first');     
                if keyID_raw == P.leftArrowKey
                    keyID = 1;
                elseif keyID_raw == P.rightArrowKey
                    keyID = 2;
                else 
                    keyID = NaN;
                end
            end

            %Save response
            if ~isempty(keyID) && ((keyID == 1) || (keyID == 2))            %For some reason, when two keys are pressed at the same time, keyID becomes empty
                if keyID == 1 %Left
                    cp_response(counter) = 1;
                elseif keyID == 2 %Right
                    cp_response(counter) = -1;
                end
                cp_response_time_secs(counter) = KbTime-aud_stim_start_time;
                if strcmp(S.task_name, 'Continuous_detection')
                    %If this is the changepoint detection task, then display the response on screen   
                    %Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);          
                    Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1); 
                    %Screen('DrawLines', P.win, cp_response(counter)*D.dirI_Coords, D.dirI_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 1);   
                    Screen('FillPoly', P.win, P.draw_color, [D.win_center_x,D.win_center_y]+cp_response(counter)*D.dirI_pointList, 1);
                    Screen('DrawingFinished', P.win);                          
                    Screen('Flip',P.win);  
                end
                counter = counter+1;

                %Also send triggers to eyetracker and EEG
                if P.eyeTrackerActive || S.eeg_recording
                    triggerNr = S.triggersInfo{cellfun(@(x) strcmp(x,'Response Given'),S.triggersInfo(:,3)),1};
                    if P.eyeTrackerActive
                        Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
                    end
                    if S.eeg_recording
                        IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
                        WaitSecs(0.1);
                        IOPort('Write', P.TriggerBox, uint8(0), 0);
                    end
                end
            end
            
            % Escape pressed? (To use: press ESC and hold down while you click with the mouse)
            [pressed, ~, keyCode, ~] = KbCheck;
            if pressed && keyCode(P.quitKey)
                PsychPortAudio('Stop', P.AudioHandle, 0);                   % waitForEndOfPlayback = 0      
                break;                                                      % Break from response-recording-while-loop
            end
        end %end of while loop to record responses during playtime
            
        % Terminate the program? if escape was pressed..     
        if keyCode(P.quitKey)
            break;                                                          %Break from the Trial's While-loop (results of this trial are not saved: aborted before all answers were given)
        end
        
        % Stop sound playback (although it should have already ended by now)
        PsychPortAudio('Stop', P.AudioHandle, 1);                                                                                % waitForEndOfPlayback = 1  
        control_returned_time = GetSecs;
        
        % Send the trial number to eyetracker and EEG as a trigger to signal the end of the trial.   
        if P.eyeTrackerActive
            Eyelink('Message', ['MYKEYWORD '  num2str(P.trial_counter)]);                 
        end
        if S.eeg_recording
            IOPort('Write', P.TriggerBox, uint8(P.trial_counter), 0);
        end
        
        % Get Eyelink Data from this trial
        if P.eyeTrackerActive
            pause(0.01); %Allow some time for the last trigger to arrive
            [SampleData, EventData] = GetDataEyelink(P,0);   
            eyeTrackerDataAvailableBool = 1;  
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Ask the questions and save the results %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Save timestamps to link the eyetracker-data to
%         if P.eyeTrackerActive && ~isempty(EventData)    
%             eye_data{P.trial_counter,1} = EventData(2,EventData(1,:) == 24); %Sample times of all the triggers              
%         end

        % Initialize the results structure for this trial (use a temporary structure R for concise code)   
        R = trials_cell{P.trial_counter,1};
        R.trialnr                                 = P.trial_counter;

        % Save timing results in ms
        R.timing.inter_flip_interval              = P.ifi*1000;
        R.timing.trialSaveTime                    = trialSaveTime;                 %Timing of saving the previous trial to disk (if it's long then that explains why the lead-in period might be longer)
        R.timing.leadIn_first_part                = (tvbl_begin_last_part_LeadIn-tvbl_begin_first_part_LeadIn)*1000;
        R.timing.leadIn_last_part                 = (tvbl_stimOnset(1)-tvbl_begin_last_part_LeadIn)*1000;
        R.timing.full_aud_presentation_time       = total_sound_duration*1000;
        
        R.timing.stim_durations                   = round((tvbl_stimOffset-tvbl_stimOnset)*1000*100)/100;
        
        R.timing.raw.tvbl_begin_first_part_LeadIn = tvbl_begin_first_part_LeadIn;
        R.timing.raw.tvbl_begin_last_part_LeadIn  = tvbl_begin_last_part_LeadIn;
        R.timing.raw.aud_stim_start_time          = aud_stim_start_time;
        R.timing.raw.tvbl_stimOnset               = tvbl_stimOnset;
        R.timing.raw.tvbl_stimOffset              = tvbl_stimOffset;
        R.timing.raw.control_returned_time        = control_returned_time;
        
%         if P.eyeTrackerActive && ~isempty(eye_data{P.trial_counter,1})
%             R.timing.eye.start_trial = eye_data{P.trial_counter,1}(1);      %Raw trigger times to coregister the Eyelink eyetracker data
%             R.timing.eye.end_trial = eye_data{P.trial_counter,1}(end);
%         end
        
        R.cp_response = cp_response;
        R.cp_response_time_secs = cp_response_time_secs;
        R.cp_response_time_stim = cp_response_time_secs/(S.timing.stim_duration+S.timing.ISI)+1;
        
        % Ask the final question(s) for this trial
        if strcmp(S.task_name,'Continuous_detection')
            R.LocResponse = NaN;                                            %Dummy so that the trial_counting_system keeps working
        elseif S.AVsynchrony_test 
            [~, ~, keyCode] = KbCheck;
            KbWait;
        else
            [R,keyCode] = AskQuestions(S,P,D,R);
        end
        
        % Terminate the program? if escape was pressed during one of the questions..
        if keyCode(P.quitKey)
            break;                                                          %Break from the Trial's While-loop (results of this trial are not saved: aborted before all answers were given)
        end
        
        % Save results of this trial (if no escape button was pressed)
        R.totalTrialDuration = round(toc*10)/10;
        trials_cell{P.trial_counter,1} = R; 
        
        % Check whether all trials are done
        if P.trial_counter == S.nTrials
            P.allTrialsDoneBool = 1;                                        %Break from the Trial's While-loop
        else
            P.trial_counter = P.trial_counter+1;                            %This needs to be done AFTER saving R in 'results'
        end 
        
        % Clear the java heap memory to avoid java OutOfMemory exception
        jheapcl;
        
    end %end Main Trial While Loop
    
    %%%%%%%%%%%%%%%
    %%% Goodbye %%%
    %%%%%%%%%%%%%%%
    
    % Update the output argument of this function
    num_trials_completed = sum(cellfun(@(x) isfield(x,'LocResponse'),trials_cell),'all');
    
    % Send triggers for end of block
    if (P.eyeTrackerActive || S.eeg_recording) && ~quit_flag
        triggerNr = S.triggersInfo{cellfun(@(x) strcmp(x,'End of Block'),S.triggersInfo(:,3)),1};
        if P.eyeTrackerActive
            Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
        end
        if S.eeg_recording
            IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
        end
        pause(0.01);
    end
    
    % Deal with eye-tracker data
    if P.eyeTrackerActive
        
        %Display the file-move on-screen
        myText = 'Saving Eyetracker Data';
        boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        DrawFormattedText(P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
        Screen('Flip',P.win);          

        %Save Eyelink data of last trial (this may take quite some time, hundreds of milliseconds)
        if eyeTrackerDataAvailableBool
            save([P.eye_save_dir filesep 'Eyelink_Trial_' num2str(P.trial_counter) '.mat'], 'SampleData', 'EventData', '-v6');
            eyeTrackerDataAvailableBool = 0;
        end
        save(F.save_file,'eye_data','-append','-v6');                       %Save the eye_data of the last trial before processing the data

        %Save and close
        [edf_path,edf_filename,edf_ext] = fileparts(P.el_edf_filename);
        P.el_edf_filename = fullfile(edf_path,[edf_filename '_Trials_' num2str(num_trials_completed) edf_ext]); %Append the number of trials to the fileName
        P.el_edf_filename = GiveCopyNumber(P.el_edf_filename);              %Check if it already exists. If so, give it a copy number
        RunEyelink('close',P);                                              %This command includes saving of the data in edf format
        P.eyeTrackerActive = 0;
%         ProcessEyeData(F,num_trials_completed);                             %Process the raw eye data   
    end 
    
    %Display Goodbye Text
    if keyCode(P.quitKey)
        myText = 'The program will now terminate';
        boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        DrawFormattedText(P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
        Screen('Flip', P.win);
        WaitSecs(1);
    
    else %If no ESCAPE was pressed (normal end of block)
        
        if strcmp(S.task_name,'Last_direction_discrimination') 
            num_correct = sum(cellfun(@(x) x.LocRespCorrect, trials_cell(1:num_trials_completed)),'all');
            myText = ['Thanks for your hard effort! You answered ' num2str(num_correct) ' out of ' num2str(num_trials_completed) ' trials correctly.']; %Feedback at end of block
        else
            myText = 'That''s it for this task. Thanks for your hard effort!';
        end
        boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        DrawFormattedText(P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.aboveStartButton-boundsText(4)/2), P.draw_color);
        myText = 'Please call the experimenter';
        boundsText = Screen(P.win, 'TextBounds', myText); %[L,T,R,B] from [0,0]
        DrawFormattedText(P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.belowStartButton-boundsText(4)/2), P.draw_color);
        Screen('Flip', P.win);

        %Wait until experimenter presses ESCAPE
        if ~IsLinux && ~S.PTBcode_debuging
            RestrictKeysForKbCheck(KbName('q'));                            %Restrict operation of KbCheck (et al.) to escape only.
        end
        KbWait([],3);                                                                               
        
        %Check if the participant is all done
        OverviewFile = fullfile(F.run_path,'OverviewFile.mat');
        load(OverviewFile,'completed_tasks');
        if S.task_nr == size(completed_tasks,2)
            myText = 'That''s it! All done! Thank you very much for everything!';
            boundsTextAbove = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
            DrawFormattedText(P.win, myText, round(D.win_center_x-boundsTextAbove(3)/2), round(D.aboveStartButton-boundsTextAbove(4)/2), P.draw_color);
            minimumReadTime = 5;
        else
            minimumReadTime = 1;
        end
        myText = 'The program will now terminate';
        boundsTextBelow = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        DrawFormattedText(P.win, myText, round(D.win_center_x-boundsTextBelow(3)/2), round(D.belowStartButton-boundsTextBelow(4)/2), P.draw_color);
        Screen('Flip', P.win);
        startTime = GetSecs; %Get the time
        
        %Save the data of the last trial and include settings ('S') that may have been updated along the way                          
        %Do this after the analysis such that if something went wrong there, only the last trial has to be repeated.
        settings = S;
        save(F.save_file,'settings','trials_cell','-append','-v6');         %'eye_data' has already been saved above
        
        %Wait the remaining time that was necessary for reading the final message    
        newTime = GetSecs; %Get the time
        if newTime < (startTime+minimumReadTime)
            WaitSecs(minimumReadTime-(newTime-startTime));
        end
        
    end %end of normal goodbye regime (no ESCAPE was pressed)
    
    % Clean up
    Priority(0);                        % Shutdown realtime scheduling:
    ListenChar(0);                      % Reenable all keys output to Matlab
    RestrictKeysForKbCheck([]);         % Reenable all keys for KbCheck
    ShowCursor;                         % Show Cursor
    Screen('CloseAll');                 % Close display(s)
    if isfield(P,'AudioHandle')
        PsychPortAudio('Close');        % Shutdown sound driver
    end
    if S.eeg_recording && ~quit_flag
        IOPort('Close', P.TriggerBox);  % Close connection to the EEG triggerbox
    end
    if S.PTBcode_debuging
        clear Screen                    % Disable PsychDebugWindowConfiguration
    end
    
catch % This "catch" section executes in case of an error in the "try" section above. 
    
    %Update the output argument of this function
    num_trials_completed = sum(cellfun(@(x) isfield(x,'LocResponse'),trials_cell),'all');
    
    %Deal with the eye tracker
    if  P.eyeTrackerActive 
        
        %Display the file-move on-screen
        myText = 'Saving Eyetracker Data';
        boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        DrawFormattedText(P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
        Screen('Flip', P.win);          
        
        %Save Eyelink data of last trial (this may take quite some time, hundreds of milliseconds)
        if eyeTrackerDataAvailableBool
            save([P.eye_save_dir filesep 'Eyelink_Trial_' num2str(P.trial_counter) '.mat'], 'SampleData', 'EventData', '-v6');
        end
        save(F.save_file,'eye_data','-append','-v6');                       %Save the eye_data of the last trial before processing the data
        
        %Save and close
        [edf_path,edf_filename,edf_ext] = fileparts(P.el_edf_filename);
        P.el_edf_filename = fullfile(edf_path,[edf_filename '_Trials_' num2str(num_trials_completed) edf_ext]); %Append the number of trials to the fileName
        P.el_edf_filename = GiveCopyNumber(P.el_edf_filename);              %Check if it already exists. If so, give it a copy number
        RunEyelink('close',P);                                              %This command includes saving of the data in edf format
%         ProcessEyeData(F, num_trials_completed);                            %Process the raw eye data        
    end
    
    % Clean up
    Priority(0);                        % Shutdown realtime scheduling:
    ListenChar(0);                      % Reenable all keys output to Matlab
    RestrictKeysForKbCheck([]);         % Reenable all keys for KbCheck
    ShowCursor;                         % Show Cursor
    Screen('CloseAll');                 % Close display(s)
    if isfield(P,'AudioHandle')
        PsychPortAudio('Close');        % Shutdown sound driver
    end
    if S.eeg_recording && ~quit_flag
        IOPort('Close', P.TriggerBox);  % Close connection to the EEG triggerbox
    end
    if S.PTBcode_debuging
        clear Screen                    % Disable PsychDebugWindowConfiguration
    end
    
    %Show any available figures in the right order
    fig_handles = findall(0,'type','figure');
    if ~isempty(fig_handles)
        for i=numel(fig_handles):-1:1
            set(0, 'currentfigure', fig_handles(i)); 
            set(gcf,'visible','on');
        end
    end
    
    psychrethrow(psychlasterror);       % Show the error message
    
end % try..catch..

end %[EoF]
