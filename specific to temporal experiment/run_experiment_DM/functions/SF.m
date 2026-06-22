function SF(S,F)
% This script is to record data to design spatial filter. It is a listening
% task because we would like to extract perceptual component.
%First 60 seconds will be 120 sounds with SOA of 500 ms
%Then we present 10 more stimuli which also includes 1
%Set up a KbQueue

P = SetupScreen(S);
[P,HRTF] = SetupAudio(S,P,F);
D = PrepareDrawing(S,P);
P = SetupKeyboard(P);

keysOfInterest=zeros(1,256);
keysOfInterest(1:end)=1; % P.responseKeys
KbQueueCreate([], keysOfInterest);
KbQueueStart([]);

if S.eeg_recording
    P.TriggerBox = IOPort('OpenSerialPort', 'COM3');
    Available = IOPort('BytesAvailable', P.TriggerBox);                 %Read data from the TriggerBox
    if(Available > 0)
        disp(IOPort('Read', P.TriggerBox, 0, Available));
    end
    IOPort('Write', P.TriggerBox, uint8(0), 0);                         %Set the port to zero state 0
    pause(0.01);
end
% Number of sounds
num_stim = 120;
control_stim = 10;

%Have all the ISIs 500 ms except one. That one is randomly selected to be
%either 400ms or 600ms. This should be presented at the end. 
SOA = 500;
random_SOA = [400,600];
random_SOA =  random_SOA(randperm(length(random_SOA),1));
control_SOAs = [repmat(500,9,1)' random_SOA];
control_SOAs = control_SOAs(randperm(length(control_SOAs)));
num_trials = 1;


% Initialize trials cell
trials_cell = cell(num_trials,1);
trials_cell{1,1}.SOA = [repmat(SOA,num_stim,1)' control_SOAs];
trials_cell{1,1}.x = zeros(length(trials_cell{1,1}.SOA),1); % location of the sounds


P.trial_counter = num_trials;

% Set some timing specifics (in seconds) --> but do ensure that these are multiples of the ifi (screen update time: e.g. with a 60Hz monitor the ifi is 1/60.
S.timing.stim_duration = 0.025;
S.timing.lead_out = 0.475;

% Generate stimuli
[SoundStim,totalduration] = GenerateStimuli(S,P,trials_cell,HRTF);

% Dummy calls to GetSecs (because the first call may take some additional time)
GetSecs; GetSecs;

% Add fixation
% instructions
myText = ['Press any key to start, count the number of different intervals silently, fixate on the dot'];

boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1);
Screen('DrawText',P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
Screen('Flip', P.win);
WaitSecs(1);
KbWait([], 2);
Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1);
Screen('Flip', P.win);
WaitSecs(1);


if P.eyeTrackerActive || S.eeg_recording
    triggerNr = 100; % trial_start
    if P.eyeTrackerActive
        Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
    end
    if S.eeg_recording
        IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
    end
    %pause(0.01);
end


%Start to play sounds
PsychPortAudio('FillBuffer',P.AudioHandle,SoundStim);                       % Buffer the Sound
PsychPortAudio('Start', P.AudioHandle, []);
PsychPortAudio('Stop', P.AudioHandle, 1);
% Define the questions and response options
questions = { ['How many different intervals did you hear?']};
responseOptions = {{'0', '1', '2', '3', '4-5', '6-9', '10 or more'}};

numQuestions = length(questions);

% Initialize an empty array to store the responses
responses = struct('question', cell(1, numQuestions), 'response', cell(1, numQuestions));

% Loop through each question
for i = 1:numQuestions
    question = questions{i};
    options = responseOptions{i};
    numOptions = length(options);
    response = 1;
    keyCode = 0;
    
    % Display the question and response options
    Screen('FillRect', P.win, 1);
    DrawFormattedText(P.win, question, 'center', P.win_rect(4)*0.3 -100, 0, [], [], [], 1.5);
    for j = 1:numOptions
        if j == response
            optionText = ['[   ' num2str(j) ') ' char(options(j)) '   ]'];
            DrawFormattedText(P.win, optionText, 'center', P.win_rect(4)*0.3 + (j * 50), [1.0 0.41 0.71]);
        else
            optionText = [num2str(j) ') ' char(options(j))];
            DrawFormattedText(P.win, optionText, 'center', P.win_rect(4)*0.3 + (j * 50), 0);
        end
        
    end
    Screen('Flip', P.win);
    
    % Wait for key press
    while 1
        [~, keyCode, ~] = KbWait([], 2);
        keyName = KbName(keyCode);
        
        % Check if left or right arrow key was pressed
        if strcmp(keyName, 'UpArrow')
            response = max(response - 1, 1);
        elseif strcmp(keyName, 'DownArrow')
            response = min(response + 1, numOptions);
        elseif strcmp(keyName, 'Return')
            break; % Break the loop if Enter key is pressed
        elseif strcmp(keyName, 'q')
            sca; % Close Psychtoolbox if "q" key is pressed
            return;
            
        end
        
        % Display the updated response options
        Screen('FillRect', P.win, 1);
        DrawFormattedText(P.win, question, 'center', P.win_rect(4)*0.3 - 100, 0, [], [], [], 1.5);
        for j = 1:numOptions
            if j == response
                optionText = ['[   ' num2str(j) ') ' char(options(j)) '   ]'];
                DrawFormattedText(P.win, optionText, 'center', P.win_rect(4)*0.3 + (j * 50), [1.0 0.41 0.71]);
            else
                optionText = [num2str(j) ') ' char(options(j))];
                DrawFormattedText(P.win, optionText, 'center', P.win_rect(4)*0.3 + (j * 50), 0);
            end
            
        end
        Screen('Flip', P.win);
        
        % Wait for key release
        KbReleaseWait;
    end
    
    % Save the response
    responses(i).question = question;
    responses(i).response = response;
    
    % Clear the screen
    Screen('FillRect', P.win, 1);
    Screen('Flip', P.win);





if P.eyeTrackerActive || S.eeg_recording
    triggerNr = 200; % trial end
    if P.eyeTrackerActive
        Eyelink('Message', ['MYKEYWORD '  num2str(triggerNr)]);
    end
    if S.eeg_recording
        IOPort('Write', P.TriggerBox, uint8(triggerNr), 0);
    end
    %pause(0.01);
end
WaitSecs(1)

% Text
myText = ['Thank you! That was it!'];
boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
Screen('DrawText',P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
Screen('Flip', P.win);
WaitSecs(2);

% Update overview file
OverviewFile = fullfile(F.run_path,'OverviewFile.mat');
load(OverviewFile,'completed_tasks');
completed_tasks(S.subject_Nr,S.task_nr) = 1;
save(OverviewFile,'completed_tasks','-append');
%Gather Path, Name and Extension
[savePath,filename,fileExtension] = fileparts(F.save_file);

%Append the number of trials to the fileName
save_file = fullfile(savePath,[filename fileExtension]);

%Check if it already exists, if so, give it a copy number
save_file = GiveCopyNumber(save_file);
save(save_file,'responses','responseOptions','questions')


ListenChar(0);
sca
return

end