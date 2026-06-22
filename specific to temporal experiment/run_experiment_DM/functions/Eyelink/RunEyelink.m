function E = RunEyelink(mode,P)
% Performs various operations with the eyelink system. 
% 
% USAGE: 
%   E = RunEyelink('setup',P);
%       RunEyelink('record');
%       RunEyelink('close',P);

switch mode   
    case 'setup'
        E = setupeyelink(P);
    case 'record'
        recordeyelink();
    case 'close'
        closeeyelink(P);
end

end %[EOF]


function E = setupeyelink(P)
    % Sets up the Eyelink eyetracker. 
    % 
    % DETAILS: 
    %   Tries to connect to an EyeLink eyetracker. Performs the initialization 
    %   of eyelink, connection to the eyelink data file, as well as calibration
    %   and drift correction. If this works out the eye tracker can be used 
    %   during stimulus presentation. 
    % 
    %   Sample data:
    %   Keyword     Data Type
    %   LEFT,       Sets the intended tracking eye (usually include both LEFT and...
    %   RIGHT       RIGHT)
    %   GAZE        includes screen gaze position data
    %   GAZERES     includes units-per-degree screen resolution at point of gaze
    %   HREF        head-referenced eye position data 
    %   HTARGET     target distance and X/Y position (EyeLink Remote only)
    %   PUPIL       raw pupil coordinates 
    %   AREA        pupil size data (diameter or area)
    %   BUTTON      buttons 1-8
    %   STATUS      state and change flags warning and error flags (not yet supported)
    %   INPUT       input port data lines (not yet supported)
    % 
    %   Event data:
    %   Keyword     Effect
    %   GAZE        includes display (gaze) position data.
    %   GAZERES     includes units-per-degree screen resolution (for start, end of event)
    %   HREF        includes head-referenced eye position
    %   AREA        includes pupil area or diameter
    %   VELOCITY    includes velocity of parsed position-type (average, peak, start and end)
    %   STATUS      includes warning and error flags, aggregated across event (not yet supported)
    %   FIXAVG      include ONLY averages in fixation end events, to reduce file size
    %   NOSTART     start events have no data other than timestamp
    % 
    %   GAZE,GAZERES,AREA,HREF,VELOCITY  - default: all useful data
    %   GAZE,GAZERES,AREA,FIXAVG,NOSTART - reduced data for fixations
    %   GAZE,AREA,FIXAVG,NOSTART         - minimal data
    %   

    % Setting up the default parameters for the eyelink
    E = EyelinkInitDefaults(P.win);                                             %SET DEFAULTS (PsychToolBox function)

    % Customizing parameters
    E.backgroundcolour        = P.background;
    E.msgfontcolour           = P.draw_color;
    E.imgtitlecolour          = P.draw_color;
    E.calibrationtargetcolour = P.draw_color;
    E.calibrationtargetsize   = 1;
    E.calibrationtargetwidth  = .5;
    E.targetbeep              = 0;
    E.feedbackbeep            = 0;
    E.displayCalResults       = 1;
    E.eyeimagesize            = 50;                                             %percentage of screen
    E.eye_used                = E.RIGHT_EYE;                                    %this one was set-up in the PTB defaults
    % E.allowlocaltrigger       = 0;                                            %Set to zero to disallow user to trigger him or herself
    % E.allowlocalcontrol       = 0;                                            %Set to zero to disallow control from subject-computer

    EyelinkUpdateDefaults(E);                                                   %UPDATE DEFAULTS (PsychToolBox function)

    % Initialization of the connection with the eyetracker.
    %E.online = EyelinkInit_Mate();                                              %INITIALIZE!
    E.online = EyelinkInit();                                              %INITIALIZE!
    if ~E.online
        cleanup; %shutdown Eyelink
        error('Eyelink initialization aborted!');
    end
    
    % Open file on host computer
    status = Eyelink('Openfile',P.el_tmp_filename);                                    %Eyelink = (PsychToolBox function) --> open file '*.edf' ('name will be changed later when we call 'close')
    if status
        disp(status);
        cleanup; %shutdown Eyelink
        error('Cannot create EDF file');
    end
    Eyelink('Command','add_file_preamble_text = "%s"', P.el_tmp_filename(1:(end-4)));       %Display Subj_nr and task 

    % make sure we're still connected.
    if Eyelink('IsConnected')~=1 
        cleanup; %shutdown Eyelink:
        error('Eyelink is not available anymore!');
    end

%   ## screen_pixel_coords = <left> <top> <right> <bottom>
%   ;; Sets the gaze-position coordinate system, which is used for all
%   ;; calibration target locations and drawing commands.  Usually set
%   ;; to correspond to the pixel mapping of the participant display. 
%   ;; Issue the calibration_type command after changing this to recompute
%   ;; fixation target positions. 
%   ;; You should also write a DISPLAY_COORDS message to the start of
%   ;; the EDF file to record the display resolution.
%   ;;            <left>: X coordinate of left of display area
%   ;;            <top>: Y coordinate of top of display area
%   ;;            <right>: X coordinate of right of display area
%   ;;            <bottom>: Y coordinate of bottom of display area
    Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld',P.el_dispRect(1),P.el_dispRect(2),P.el_dispRect(3),P.el_dispRect(4));
    Eyelink('Message','SCREEN PIXEL COORDS = %ld %ld %ld %ld',P.el_dispRect(1),P.el_dispRect(2),P.el_dispRect(3),P.el_dispRect(4));
    
%   ## screen_phys_coords = <left>, <top>, <right>, <bottom>
%   ;; Measure the distance of the visible part of the display screen edge
%   ;; relative to the center of the screen (measured in in millimeters).
%   ;; <left>, <top>, <right>, <bottom>:
%   ;; position of display area corners relative to display center
    Eyelink('Command','screen_phys_coords = %ld %ld %ld %ld',P.el_dispRect_mm(1),P.el_dispRect_mm(2),P.el_dispRect_mm(3),P.el_dispRect_mm(4));
    Eyelink('Message','SCREEN PHYS COORDS = %ld %ld %ld %ld',P.el_dispRect_mm(1),P.el_dispRect_mm(2),P.el_dispRect_mm(3),P.el_dispRect_mm(4));
    
%   ## screen_distance = <mm to center> | <mm to top> <mm to bottom>
%   ;; Used for visual angle and velocity calculations. 
%   ;; Providing <mm to top> <mm to bottom> parameters will give better 
%   ;; estimates than <mm to center>
%   ;; <mm to center> = distance from display center to participant in millimeters.
%   ;; <mm to top> = distance from display top to participant in millimeters.
%   ;; <mm to bottom> = distance from display bottom to participant in millimeters.
    Eyelink('Command','screen_distance = %ld',P.dist_to_screen);
    Eyelink('Message','SCREEN DISTANCE = %ld',P.dist_to_screen);
    
%   If using the EyeLink 1000 in Remote mode, the camera-to-screen distance will also need to be edited via the remote_camera_position function by adding the following command to the FINAL.INI file. 
%   Adjust the last parameter to accurately reflect the distance from the Display monitor to the base of the camera lens in mm (keep the minus sign).    
%   ## remote_camera_position <rh> <rv> <dx> <dy> <dz>
%   ;; <rh>: 10;    // rotation of camera from screen (clockwise from top)
%   ;;              i.e. how much the right edge of the camera is closer than left edge of camera
%   ;;              i.e. 10 assumes right edge is closer than left edge
%   ;; <rv>: 17;  // tilt of camera from screen (top toward screen)
%   ;; <dx>: -80;  // bottom-center of display in cam coords
%   ;; <dy>:  60;
%   ;; <dz>: -90;
%   remote_camera_position 10 17 -80 60 -90
    
    % Should I also set "screen_write_prescale"?? -- I don't think so. 
    
    % Use conservative online saccade detection (cognitive setting)
    ELtrackerversion = Eyelink('GetTrackerVersion');
    if ELtrackerversion == 2 || ELtrackerversion == 3                       %Eyelink II or 1000, resp.
        Eyelink('Command','select_parser_configuration = 0');
    else
        Eyelink('Command','recording_parse_type = GAZE');
        Eyelink('Command','saccade_velocity_threshold = 30');
        Eyelink('Command','saccade_acceleration_threshold = 9500');
        Eyelink('Command','saccade_motion_threshold = 0.15');
        Eyelink('Command','saccade_pursuit_fixup = 60');
        Eyelink('Command','fixation_update_interval = 0');
    end % both configurations should be equivalent, see Eyelink Programmers Guide, p. 183.

    % Other tracker configurations
    Eyelink('Command','calibration_type = HV9');                            %HV3, HV5, HV9, HV13
    Eyelink('Command','generate_default_targets = YES');
    Eyelink('Command','enable_automatic_calibration = YES');
    Eyelink('Command','automatic_calibration_pacing = 1000');
    Eyelink('Command','binocular_enabled = NO');                            %only do monocular recording
    Eyelink('Command','use_ellipse_fitter = NO');
    Eyelink('Command','sample_rate = 1000');                                %1000 Hz
    Eyelink('Command','elcl_tt_power = %d', 2);                             %illumination, 1 = 100%, 2 = 75%, 3 = 50%
    Eyelink('command','pupil_size_diameter = YES');                         %pupil area or diameter?
    
    % Automatic sequencing during calibration?                   
    [~,reply] = Eyelink('ReadFromTracker','enable_automatic_calibration');
    if reply 
        fprintf('\n\nEyeLink:\nAutomatic sequencing ON\n');
    else
        fprintf('\n\nEyeLink:\nAutomatic sequencing OFF\n');
    end
    
    %For current information on the EyeLink tracker configuration, examine the *.INI files in the EYELINK\EXE\ or ELCL\EXE\ directory of the Host PC. See tracker file "DATA.INI" for types.
    
    % set edf data
    Eyelink('Command','file_sample_data = RIGHT,GAZE,AREA,INPUT');
    Eyelink('Command','file_event_data = RIGHT,GAZE,AREA,INPUT');
    Eyelink('Command','file_event_filter = RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,INPUT');
    
    % set link data (can be used to react to events online)
    Eyelink('Command','link_sample_data = RIGHT,GAZE,AREA,INPUT');
    Eyelink('Command','link_event_data = RIGHT,GAZE,AREA,INPUT');
    Eyelink('Command','link_event_filter = RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,INPUT');
    
    %set eye-tracker to idle mode, i.e. just wait
    %Eyelink('command', 'set_idle_mode');
    
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup_Mate(E);                                          %CALIBRATE!
    KbWait([],1); %Wait until all keys are released
    
%     % Do a final check of calibration using driftcorrection
%     success=EyelinkDoDriftCorrection(E);
%     if success~=1
%         cleanup;
%         return;
%     end  
    
    % Cleanup routine:
    function cleanup
        % Shutdown Eyelink:
        Eyelink('Shutdown');
        E.online = 0;
    end

end %[EOF 'setup']

function recordeyelink()
    %Start recording!
    status = Eyelink('StartRecording');
    if status ~= 0
        error('Eyelink StartRecording error');
    end
end %[EOF 'record']

function closeeyelink(P)
    % Stop recording and close file
    Eyelink('StopRecording');
    Eyelink('CloseFile');

    % Eyelink file
    [~,name,ext] = fileparts(P.el_edf_filename);

    % Receive file from host computer and move to the experimental data folder
    try
        fprintf('Receiving data file ''%s''\n',[name,ext]);
        status = Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n',status);
        end
        if exist(P.el_tmp_filename,'file')
            movefile(P.el_tmp_filename,P.el_edf_filename);                  % rename and move file to destination
            fprintf('Data file moved to subject folder.\n');
        end
    catch
        warning('Problem receiving data file ''%s''',[name,ext]);
    end
    % Shut down the eyetracker
    Eyelink('Shutdown');
end %[EOF 'close']

