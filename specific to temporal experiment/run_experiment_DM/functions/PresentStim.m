function [S,num_trials_completed] = PresentStim(S,F,trials_cell)
% Main function for stimulus presentation

%Initialize output of this function (in case of early return)
num_trials_completed = sum(cellfun(@(x) isfield(x,'totalTrialDuration'),trials_cell),'all');

% It's a good habit to run PTB within a try-catch loop
try

    %%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Preparation phase %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%

    % Prepare Screen
    P = SetupScreen(S);

    % Prepare Audio Device
    [P,HRTF] = SetupAudio(S,P,F);

    % Prepare Keyboard
    P = SetupKeyboard(P);

    % Prepare to draw shapes on the screen
    D = PrepareDrawing(S,P);                                                %Design fixation cross, response mechanism, etc

    % Ensure head on chin-rest and face pointing in correct direction
    quit_before_begin_flag = false;
    keyCode = SoundFromMiddleCheck(S,P,D,HRTF,1);                           %Should be done before eye-tracker calibration
    if keyCode(P.quitKey)
        quit_before_begin_flag = true;
    end

    % Initialize and calibrate the eyetracker
    if S.eye_tracking && ~quit_before_begin_flag
        P = PrepareEyeTracker(F,P,D);
        P.eyeTrackerActive = 1;
    end

    % Initialize virtual serial port for EEG triggers
    if S.eeg_recording && ~quit_before_begin_flag
        P.TriggerBox = IOPort('OpenSerialPort', 'COM3');
        Available = IOPort('BytesAvailable', P.TriggerBox);                 %Read data from the TriggerBox
        if(Available > 0)
            disp(IOPort('Read', P.TriggerBox, 0, Available));
        end
        IOPort('Write', P.TriggerBox, uint8(0), 0);                         %Set the port to zero state 0
        pause(0.01);
    end

    % Restrict button presses to selected few
    if IsWin && ~S.PTBcode_debuging && ~quit_before_begin_flag              %Added "IsWin" because it led to the mouse not working on Apple macBooks and Linux devices.
        RestrictKeysForKbCheck(P.responseKeys);                             %This speeds up reading out key-responses
    end                                                                     %Should be done only after eye-tracker calibration in order to allow

    % Initialize trial counting system
    P.trial_counter = num_trials_completed+1;
    P.firstTrialBool = 1;
    P.allTrialsDoneBool = 0;

    % Dummy calls to GetSecs (because the first call may take some additional time)
    GetSecs; GetSecs;

    % Send triggers for start of block
    if (P.eyeTrackerActive || S.eeg_recording) && ~quit_before_begin_flag
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

    while ~P.allTrialsDoneBool && ~quit_before_begin_flag


        % Display the trial nr at the bottom of the eyetracker display
        if P.eyeTrackerActive
            Eyelink('command', 'record_status_message "TRIAL %d"', P.trial_counter);
        end
        %Check if subject-specific directory already exists, create one otherwise.
        if S.subject_Nr < 10
            subject_nr_str = ['S00' num2str(S.subject_Nr)];
        elseif S.subject_Nr < 100
            subject_nr_str = ['S0' num2str(S.subject_Nr)];
        else
            subject_nr_str = ['S' num2str(S.subject_Nr)];
        end


        % Update the staircase settings after every 10 trials percent correct to update the mu level
        if strcmp(S.task_name,'Last_direction_discrimination') && ismember(S.block_nr, [1 2]) %&&  mod(P.trial_counter,10)==1 && P.trial_counter~=1

            [S,trials_cell] = StaircaseControl(S,F,P,D,trials_cell);

        end


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

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Present task instructions if necessary %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if (P.firstTrialBool && ~S.AVsynchrony_test) || miniBreakBool
            if strcmp(S.task_name,'MAI')
                if P.firstTrialBool
                    myTextAbove = 'TASK: Respond "speed-up" or "slow-down" when prompted';
                else
                    myTextAbove = ' ';
                end
            elseif strcmp(S.task_name, 'Last_direction_discrimination') && P.firstTrialBool
                myTextAbove = 'TASK: Indicate "speed-up" or "slow-down" for LAST interval';
            else
                myTextAbove = ' ';
            end
            if miniBreakBool
                myTextBelow = 'Press any response key to continue';  %'Click on circle to continue';
            else
                myTextBelow = 'Press any response key to start';     %'Click on circle to start';
            end
            myTextCentre = ' ';
            SetMouse(D.win_center_x, D.belowStartButton, P.win);            %Set the mouse to some random low point
            keyCode = CircleInMiddleClick(S,P,D,myTextAbove,myTextBelow,myTextCentre,1);
            % Terminate the program? if escape was pressed..
            if keyCode(P.quitKey)
                break;                                                      %Break from the Trial's While-loop (results of the previous trial are not saved: aborted before the answers were saved)
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Start the lead-in time, perform some saving and preparation actions %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %Get a timestamp to record the trial's duration (including the response time, feedback time, etc)
        tic;

        % We split the leadIn duration because we want to save the data from the previous trial during the first part of the leadIn,
        % but we still want to use a fixed and accurate duration for the second part in order for the AV synchrony to work out as expected.
        Minimal_leadIn_duration_first_part_in_flips = round((trials_cell{P.trial_counter,1}.timing_lead_in/1000 - P.last_part_LeadIn_duration)/P.ifi);
        LeadIn_duration_last_part_in_flips = round(P.last_part_LeadIn_duration/P.ifi);

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
        minimum_vis_deadline = tvbl_begin_first_part_LeadIn + (Minimal_leadIn_duration_first_part_in_flips - P.flip_fraction_early_command)*P.ifi;

        % The trial has now really started. Send the trial number to eyetracker and EEG as a trigger to signal the start of the trial.
        if P.eyeTrackerActive
            Eyelink('Message', ['MYKEYWORD '  num2str(P.trial_counter)]);
        end
        if S.eeg_recording
            IOPort('Write', P.TriggerBox, uint8(P.trial_counter), 0);
            %pause(0.01);
        end

        % Save the data of the previous trial (this may take quite some time) - Note: this includes the updated staircase settings of the current trial
        if P.trial_counter ~= 1
            time1 = GetSecs;
            settings = S;
            save(F.save_file,'settings','trials_cell','-append','-v6');
            time2 = GetSecs;
            trial_save_time = (time2-time1)*1000;
        else
            trial_save_time = NaN;
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
        % We substract P.flip_fraction_early_command*P.ifi so the screen gets the flip command a bit earlier and flips on the next possibility.
        vis_stim_onset_deadline = tvbl_begin_last_part_LeadIn + (LeadIn_duration_last_part_in_flips - P.flip_fraction_early_command)*P.ifi;
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
        %N.B. To really collect responses during stimulus presentation (if using visual stimuli) it would be best to use the KbQueue commands. See AskQuestions.m for example code.
        ongoing_responses_key_IDs = [];
        ongoing_responses_times = [];
        counter = 1;
        while GetSecs < (aud_stim_end_time)

            %Wait for a response until the "auditory end time"
            [KbTime, keyCode] = KbWait([], 2, aud_stim_end_time);
            keyID = find(keyCode,1,'first');

            %Escape pressed?
            if keyID == P.quitKey
                PsychPortAudio('Stop', P.AudioHandle, 0);                   % waitForEndOfPlayback = 0
                break;                                                      % Break from response-recording-while-loop

                %Save response?
            elseif ~isempty(keyID)
                ongoing_responses_key_IDs(counter) = keyID;
                ongoing_responses_times(counter) = KbTime-aud_stim_start_time;
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

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Ask the questions and save the results %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Initialize the results structure for this trial (use a temporary structure R for concise code)
        R = trials_cell{P.trial_counter,1};
        R.trialnr                                 = P.trial_counter;

        % Save timing results in ms
        R.timing.inter_flip_interval              = P.ifi*1000;
        R.timing.trial_save_time                  = trial_save_time;                 %Timing of saving the previous trial to disk (if it's long then that explains why the lead-in period might be longer)
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

        R.ongoing_responses.key_IDs = ongoing_responses_key_IDs;
        R.ongoing_responses.times = ongoing_responses_times;

        % Ask the final question(s) for this trial
        if S.AVsynchrony_test
            [~, keyCode] = KbWait;
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
            P.firstTrialBool = 0;
        end

        % Clear the java heap memory to avoid java OutOfMemory exception
        jheapcl;

    end %end Main Trial While Loop

    %%%%%%%%%%%%%%%
    %%% Goodbye %%%
    %%%%%%%%%%%%%%%

    % Update the output argument of this function
    num_trials_completed = sum(cellfun(@(x) isfield(x,'totalTrialDuration'),trials_cell),'all');

    % Send triggers for end of block
    if (P.eyeTrackerActive || S.eeg_recording) && ~quit_before_begin_flag
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
        Screen('DrawText',P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
        Screen('Flip',P.win);

        %Save and close
        [edf_path,edf_filename,edf_ext] = fileparts(P.el_edf_filename);
        P.el_edf_filename = fullfile(edf_path,[edf_filename '_Trials_' num2str(num_trials_completed) edf_ext]); %Append the number of trials to the fileName
        P.el_edf_filename = GiveCopyNumber(P.el_edf_filename);              %Check if it already exists. If so, give it a copy number
        RunEyelink('close',P);                                              %This command includes saving of the data in edf format
        P.eyeTrackerActive = 0;
    end

    %Display Goodbye Text
    if keyCode(P.quitKey)
        myText = 'The program will now terminate';
        boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        Screen('DrawText',P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
        Screen('Flip', P.win);
        WaitSecs(1);

    else %If no ESCAPE was pressed (normal end of block)

        if strcmp(S.task_name,'Last_direction_discrimination')
            num_correct = sum(cellfun(@(x) x.TempoDirRespCorrect, trials_cell(1:num_trials_completed)),'all');
            myText = ['Thanks for your hard effort! You answered ' num2str(num_correct) ' out of ' num2str(num_trials_completed) ' trials correctly.']; %Feedback at end of block
        else
            myText = 'That''s it for this task. Thanks for your hard effort!';
        end
        boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        Screen('DrawText',P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.aboveStartButton-boundsText(4)/2), P.draw_color);
        myText = 'Please call the experimenter';
        boundsText = Screen(P.win, 'TextBounds', myText); %[L,T,R,B] from [0,0]
        Screen('DrawText',P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.belowStartButton-boundsText(4)/2), P.draw_color);
        Screen('Flip', P.win);

        %Wait until experimenter presses ESCAPE
        if IsWin && ~S.PTBcode_debuging
            RestrictKeysForKbCheck(KbName('q'));                            %Restrict operation of KbCheck (et al.) to escape only.
        end
        KbWait([],3);

        %Check if the participant is all done
        OverviewFile = fullfile(F.run_path,'OverviewFile.mat');
        load(OverviewFile,'completed_tasks');
        if S.task_nr == size(completed_tasks,2)
            myText = 'That''s it! All done! Thank you very much for everything!';
            boundsTextAbove = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
            Screen('DrawText',P.win, myText, round(D.win_center_x-boundsTextAbove(3)/2), round(D.aboveStartButton-boundsTextAbove(4)/2), P.draw_color);
            minimumReadTime = 5;
        else
            minimumReadTime = 1;
        end
        myText = 'The program will now terminate';
        boundsTextBelow = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        Screen('DrawText',P.win, myText, round(D.win_center_x-boundsTextBelow(3)/2), round(D.belowStartButton-boundsTextBelow(4)/2), P.draw_color);
        Screen('Flip', P.win);
        startTime = GetSecs; %Get the time

        %Save the data of the last trial and include settings ('S') that may have been updated along the way
        %Do this after the analysis such that if something went wrong there, only the last trial has to be repeated.
        settings = S;
        save(F.save_file,'settings','trials_cell','-append','-v6');

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
    if S.eeg_recording && ~quit_before_begin_flag
        IOPort('Close', P.TriggerBox);  % Close connection to the EEG triggerbox
    end
    if S.PTBcode_debuging
        clear Screen                    % Disable PsychDebugWindowConfiguration
    end

catch % This "catch" section executes in case of an error in the "try" section above.

    %Update the output argument of this function
    num_trials_completed = sum(cellfun(@(x) isfield(x,'totalTrialDuration'),trials_cell),'all');

    %Deal with the eye tracker
    if  P.eyeTrackerActive

        %Display the file-move on-screen
        myText = 'Saving Eyetracker Data';
        boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
        Screen('DrawText',P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
        Screen('Flip', P.win);

        %Save and close
        [edf_path,edf_filename,edf_ext] = fileparts(P.el_edf_filename);
        P.el_edf_filename = fullfile(edf_path,[edf_filename '_Trials_' num2str(num_trials_completed) edf_ext]); %Append the number of trials to the fileName
        P.el_edf_filename = GiveCopyNumber(P.el_edf_filename);              %Check if it already exists. If so, give it a copy number
        RunEyelink('close',P);                                              %This command includes saving of the data in edf format
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
    if S.eeg_recording && ~quit_before_begin_flag
        IOPort('Close', P.TriggerBox);  % Close connection to the EEG triggerbox
    end
    if S.PTBcode_debuging
        clear Screen                    % Disable PsychDebugWindowConfiguration
    end

    psychrethrow(psychlasterror);       % Show the error message

end % try..catch..

end %[EoF]
