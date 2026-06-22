function [S, F] = SetSubjIDandTask(run_path,save_path,PTBcode_debuging,AVsynchrony_test)
%This is an interactive function that will ask for the subject ID and then
%finds the correct subject number and task  

%Initialize output
S.Created = datestr(datetime('now'));
F.run_path = run_path;

%Debugging or AVsynchrony test?
S.PTBcode_debuging = PTBcode_debuging;
S.AVsynchrony_test = AVsynchrony_test;

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load overviewFile %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

%Check that the OverviewFile.mat file exists and load it
OverviewFile = fullfile(F.run_path,'OverviewFile.mat');
if ~(exist(OverviewFile, 'file') == 2)
    %If it doesn't exist, create it!
    experimenter_IDs = {};
    computer_IDs = {};
    sound_cards = {};
    screen_numbers = {};
    subject_IDs = {};
    HRTF_files = {};

task_list = {'MS1','LD1','LD2','RS1','SF1','LD3','LD4','LD5','LD6'};  
    completed_tasks = zeros(0,numel(task_list));
    save(OverviewFile,'experimenter_IDs','computer_IDs','sound_cards','screen_numbers','subject_IDs','HRTF_files','task_list','completed_tasks');          
else
    load(OverviewFile,'experimenter_IDs','computer_IDs','sound_cards','screen_numbers','subject_IDs','HRTF_files','task_list','completed_tasks');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Select Experimenter %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

experimenters = ['New'; experimenter_IDs];
[selected_option,continueBool] = OptionsDialog(experimenters,numel(experimenters),'Experimenter','Select the experimenter');        %See below for the function
if ~continueBool                          
    error('Program is aborted');                        %dialog window was closed
end
if selected_option == 1                                 %default option 'New' was selected
    answers = inputdlg({'Who is the new experimenter?'},'Experimenter',1,{''});
    if sum(size(answers) == [0,0]) == 2       
        error('ERROR: No answer was given');            %cancel was pressed or dialog window was closed
    elseif isempty(answers{1})      
        error('ERROR: No answer was given');            %OK was pressed but no input was given
    end
    experimenter_ID = answers{1};
    
    %If it does indeed not exist yet, then add it to the list of experimenters  
    expID_matches = cellfun(@(x) strcmp(x,experimenter_ID),experimenter_IDs);
    if ~any(expID_matches)
        experimenter_IDs{end+1,1} = experimenter_ID;
    end
else
    experimenter_ID = experimenters{selected_option};
end
S.experimenter_ID = experimenter_ID;

%%%%%%%%%%%%%%%%%%%%%%
%%% Select Subject %%%
%%%%%%%%%%%%%%%%%%%%%%

subjects = ['New'; subject_IDs];
[selected_option,continueBool] = OptionsDialog(subjects,numel(subjects),'Subject','Select the subject ID');        %See below for the function
if ~continueBool                          
    error('Program is aborted');                        %dialog window was closed
end
if selected_option == 1                                 %default option 'New' was selected
    answers = inputdlg({'What is the new subject ID?'},'Subject ID',1,{''});
    if sum(size(answers) == [0,0]) == 2       
        error('ERROR: No answer was given');            %cancel was pressed or dialog window was closed
    elseif isempty(answers{1})      
        error('ERROR: No answer was given');            %OK was pressed but no input was given
    end
    subject_ID = answers{1};
    
    %If it does indeed not exist yet, then add it to the list of experimenters  
    subjID_matches = cellfun(@(x) strcmp(x,subject_ID),subject_IDs);
    if ~any(subjID_matches)
        subject_IDs{end+1,1} = subject_ID;
    else
        error('ERROR: New subject ID already exists! Please choose the existing subject ID from the drop-down list or create a new subject ID');
    end
else
    subject_ID = subjects{selected_option};
end
S.subject_ID = subject_ID;
S.subject_Nr = find(cellfun(@(x) strcmp(x,subject_ID),subject_IDs));

%Check if subject-specific directory already exists, create one otherwise.
if S.subject_Nr < 10
    subject_nr_str = ['S00' num2str(S.subject_Nr)];
elseif S.subject_Nr < 100
    subject_nr_str = ['S0' num2str(S.subject_Nr)];
else
    subject_nr_str = ['S' num2str(S.subject_Nr)];
end
S.subject_nr_str = subject_nr_str;
subject_path = fullfile(save_path,subject_nr_str);
if exist(subject_path,'dir')
    if selected_option == 1 %New subject was selected
        error('New subject selected, but folder with subject number already exists. Please clean up the behavioral data folder first.')
    end
else
    mkdir_success = mkdir(save_path,subject_nr_str);
    if ~mkdir_success
        error('An error occured while trying to create the subject-specific folder');
    end
end
F.save_path = fullfile(save_path,subject_nr_str);

%%%%%%%%%%%%%%%%%%%
%%% Select Task %%%
%%%%%%%%%%%%%%%%%%%

%Find next task number
if size(completed_tasks,1) < S.subject_Nr
    completed_tasks(S.subject_Nr,:) = zeros(1,size(completed_tasks,2));     %Initialize
    next_task_nr = 1;
else
    next_task_nr = find(completed_tasks(S.subject_Nr,:) == 0,1,'first');
    if isempty(next_task_nr)
        next_task_nr = numel(task_list);    %If all tasks were already completed, but for some reason the subject wants to repeat a task
    end
    

end

%Let the user select the desired task
[selected_option,continueBool] = OptionsDialog(task_list,next_task_nr,'Task','Select the next task');
if ~continueBool                          
    error('Program is aborted');                        %dialog window was closed
end
short_task_name = task_list{selected_option};

%Create the filename of the savefile for this task
F.save_file = fullfile(F.save_path,[subject_nr_str '_' short_task_name '.mat']);

%Set the task_name and block_nr (in understandable language)
switch short_task_name(1:2)
    case 'LD'
        S.task_name = 'Last_direction_discrimination';
    case 'MS'
        S.task_name = 'MSI';
    case 'RS'
        S.task_name = 'RS';
    case 'SF'
        S.task_name = 'SF';
    otherwise
        error('Unknown task');
end
S.block_nr = str2double(short_task_name(3));  
S.task_nr = selected_option;

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Select HRTF file %%%
%%%%%%%%%%%%%%%%%%%%%%%%

HRTF_path_found = false;
if (size(HRTF_files,1) >= S.subject_Nr) && ~isempty(HRTF_files{S.subject_Nr,1})
    %Check if the HRTF path exists (it may have been used on a different computer before..)  
    for i=numel(HRTF_files(S.subject_Nr,:)):-1:1
        [HRTF_path,HRTF_name,HRTF_ext] = fileparts(HRTF_files{S.subject_Nr,i});
        if exist(HRTF_path,'dir')
            HRTF_path_found = true;
            break; %from for-loop
        end
    end
end
if HRTF_path_found
    [S.HRTF_filename,hrtf_path] = uigetfile(fullfile(HRTF_path,[HRTF_name HRTF_ext]),'Select subject''s HRTF file');
else
    [S.HRTF_filename,hrtf_path] = uigetfile('*.sofa','Select subject''s HRTF file');
end
F.HRTF_file = fullfile(hrtf_path,S.HRTF_filename);

%If this HRTF was not known yet, then add it to the list of HRTFs  
if (size(HRTF_files,1) < S.subject_Nr) || isempty(HRTF_files{S.subject_Nr,1}) || ~strcmp(F.HRTF_file,HRTF_files{S.subject_Nr,1})
    HRTF_files{S.subject_Nr,1} = F.HRTF_file;
elseif ~any(strcmp(F.HRTF_file,HRTF_files(S.subject_Nr,:)))
    HRTF_files{S.subject_Nr,end+1} = F.HRTF_file;
end

%Check that HRTF spatial resolution is compatible with desired minimum step size
HRTF = SOFAload(F.HRTF_file);
HRTF.Data.IR = HRTF.Data.IR ./ (max(max(max(abs(HRTF.Data.IR(SOFAfind(HRTF, 0, 0), :, :))))+eps));
if SOFAfind(HRTF, 0, 0) == SOFAfind(HRTF, 1, 0)
    warning('HRTF spatial resolution is not sufficient (i.e. smallest step size is larger than 1 degree). Interpolation of this HRTF is strongly recommended.')
    choice = questdlg('HRTF spatial resolution is not sufficient. Interpolation recommended. Continue anyway?','HRTF resolution warning!','Yes','No','No');    
    if ~strcmpi(choice,'Yes')
        error('HRTF resolution is not sufficient. User aborted program.')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Select sound card %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

%On what computer are we?
S.computer_ID = getenv('computername');
computer_matches = cellfun(@(x) strcmp(x,S.computer_ID),computer_IDs);
if any(computer_matches)
    computer_nr = find(computer_matches);
else
    computer_nr = numel(computer_IDs)+1;
    computer_IDs{end+1,1} = S.computer_ID;
end

%Retrieve all available sound devices
sound_devices = PsychPortAudio('GetDevices');
for i=1:numel(sound_devices)
    full_name_audioDevices{i} = [num2str(sound_devices(i).DeviceIndex), '. ', sound_devices(i).HostAudioAPIName, ' - ', ...
                                 sound_devices(i).DeviceName, ' - NrOfOutputChan = ', num2str(sound_devices(i).NrOutputChannels)]; 
    full_name_audioDevices{i} = regexprep(full_name_audioDevices{i},'[\n\r]+','');  %Erase newlines and carriage returns
end

%Check if the saved audiocard for this computer still exists, if so set as default 
sound_card_default = 0;
if (size(sound_cards,1) >= computer_nr) && ~isempty(sound_cards{computer_nr,1})
    if any(cellfun(@(x) strcmp(x,sound_cards{computer_nr,1}),full_name_audioDevices))
        sound_card_default = find(cellfun(@(x) strcmp(x,sound_cards{computer_nr,1}),full_name_audioDevices));
    end
end

%If no known sound card was found, default to a Windows WASAPI sound card if available   
if ~sound_card_default
    WASAPI_devices = strfind(full_name_audioDevices, 'WASAPI');             %cell-array with indices of characters of where 'WASAPI' was found in full_name_audioDevices
    first_WASAPI_device = find(cellfun(@(x) ~isempty(x),WASAPI_devices),1); %first device with WASAPI in the name
    if ~isempty(first_WASAPI_device)
        sound_card_default = first_WASAPI_device;
    else
        sound_card_default = 1;                                             %Default to first sound card if WASAPI was not found
    end
end
    
%Let the user select the appropriate sound card
[selected_option,continueBool] = OptionsDialog(full_name_audioDevices,sound_card_default,'Sound Card','Select the sound card');
if ~continueBool                          
    error('Program is aborted');                        %dialog window was closed
end
S.sound_card = full_name_audioDevices{selected_option};
S.sound_device_idx = sound_devices(selected_option).DeviceIndex;

if strcmp(getenv('computername'),'EXPGRUEN')  % Manually overwrite the default sampling rate on the lab computer (default is 44100, but that leads to auditory delays relative to visual)
    S.sound_sample_rate = 48000;
else
    S.sound_sample_rate = sound_devices(selected_option).DefaultSampleRate;
end

%If this sound_card was not known yet, then remember it for this computer
if (size(sound_cards,1) < computer_nr) || isempty(sound_cards{computer_nr,1}) || ~strcmp(S.sound_card,sound_cards{computer_nr,1})
    sound_cards{computer_nr,1} = S.sound_card;
end

%%%%%%%%%%%%%%%%%%%%%
%%% Select screen %%%
%%%%%%%%%%%%%%%%%%%%%

available_screens = Screen('Screens');

%Check if the saved screen_number is available to set as default choice
screen_number_default = NaN;
if (size(screen_numbers,1) >= computer_nr) && ~isempty(screen_numbers{computer_nr,1})
    if ismember(screen_numbers{computer_nr,1},available_screens)
    	screen_number_default = find(screen_numbers{computer_nr,1} == available_screens);
    end
end
if isnan(screen_number_default)
    screen_number_default = numel(available_screens);
end

%Let the user select the appropriate screen number
[selected_option,continueBool] = OptionsDialog(num2cell(available_screens),screen_number_default,'Screen Number','Select the screen number');
if ~continueBool                          
    error('Program is aborted');                        %dialog window was closed
end
S.screen_number = available_screens(selected_option);

%If this screen_number was not known yet, then remember it for this computer
if (size(screen_numbers,1) < computer_nr) || isempty(screen_numbers{computer_nr,1}) || ~strcmp(S.screen_number,screen_numbers{computer_nr,1})
    screen_numbers{computer_nr,1} = S.screen_number;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Eye-tracker and/or EEG present? %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Ask the user whether the eye-tracker is connected
choice = questdlg('Is the eye-tracker connected?','EyeTracker?','Yes','No','No');    
if strcmpi(choice,'Yes')
    S.eye_tracking = true;   
else
    S.eye_tracking = false;
end

% Ask the user whether the eye-tracker is connected
choice = questdlg('Will you record EEG?','EEG?','Yes','No','No');    
if strcmpi(choice,'Yes')
    S.eeg_recording = true;
else
    S.eeg_recording = false;
end

% Set the triggers
if S.eye_tracking || S.eeg_recording
    S.triggersInfo = GetAllTriggers([]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Update the OverviewFile with the new input information %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save(OverviewFile,'experimenter_IDs','computer_IDs','sound_cards','screen_numbers','subject_IDs','HRTF_files','task_list','completed_tasks');

end %[EOF]
