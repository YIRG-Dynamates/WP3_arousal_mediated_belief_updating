function P = PrepareEyeTracker(F,P,D)

[save_path,filename] = fileparts(F.save_file);
P.eye_save_dir = fullfile(save_path,['RawEyeData_' filename]); 
if isempty(dir(P.eye_save_dir))
    mkdir(P.eye_save_dir);
else
    %Clean up from last time should have happened before because we'll be overwriting old data otherwise!!! 
    warning('Previous raw eye-tracking data folder for this subject and task has been detected and will be overwritten');
end

% Set EDF file names
P.el_tmp_filename = [filename '.edf'];                              %temporary EDF file name for Eyelink Data on Host computer. Keep it short (Eyelink host computer accepts max 8 characters)
P.el_edf_filename = fullfile(save_path,[filename '.edf']);          %permanent EDF file name (and path) for data on this computer

% Setup eyetracker display settings 
P.dist_to_screen = D.dist_to_screen*1000;                                                           %in millimeters
P.screen_width = D.screen_width*1000;
P.screen_height = D.screen_height*1000;
% P.el_dispRect = CenterRectOnPoint(D.el_dispRect_raw, D.win_center_x, D.win_center_y);               %Set window in which the eye-tracker works (smaller centred rectangle, size is set in PrepareDrawing.m)   
% screen_parts = D.el_dispRect_raw ./ [P.win_rect(3) P.win_rect(4) P.win_rect(3) P.win_rect(4)];
% P.el_dispRect_mm = round(screen_parts.*[P.screen_width P.screen_height P.screen_width P.screen_height]);

P.el_dispRect = CenterRectOnPoint(P.win_rect+[1 1 -1 -1], D.win_center_x, D.win_center_y);          %Set window in which the eye-tracker works (entire screen +/-1 is to avoid illogical errors) 
P.el_dispRect_mm = round([-P.screen_width/2 -P.screen_height/2 P.screen_width/2 P.screen_height/2]);

% Setup eyetracker connection and perform calibration
E = RunEyelink('setup',P);                                                                          %Output includes S.eyelink.online = 1; if everything went alright, otherwise it is 0;

% Start recording
if E.online
    RunEyelink('record');                                                                           %RECORD!
    P.eyeTrackerActive = 1;
end

% Uncomment below in case calibration & validation was done with a different colour (not recommended!)  
% Screen('FillRect',P.win,P.background);
% Screen('Flip',P.win);

end %[EoF]