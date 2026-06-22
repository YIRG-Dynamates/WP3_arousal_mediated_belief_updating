function MSI(S,F)


P = SetupScreen(S);

% Start
DrawFormattedText(P.win, ['Musical Experience Questionnaire \n There will be 12 questions' ...
    '\n Press return key to continue'], 'center', P.win_rect(4)*0.3 - 100, 0, [], [], [], 1.5);
Screen('Flip', P.win);
KbWait();
Screen('Flip', P.win);
WaitSecs(2);

% Define the questions and response options
questions = {
    ['I am able to hit the right notes when I sing along with a recording.']
    ['I find it difficult to spot mistakes \n' ...
    ' in a performance of a song even if I know the tune.']
    ['I can compare and discuss differences between two performances \n' ...
    ' or versions of the same piece of music.']
    'I am not able to sing in harmony when somebody is singing a familiar tune.'
    'I can tell when people sing or play out of time with the beat.'
    ['I engaged in regular, daily practice of a \n' ...
    'musical instrument (including voice) for ___ years.']
    ['At the peak of my interest, I practiced ___ hours \n' ...
    'per day on my primary instrument.']
    ['I have attended ___ live music events as an \n' ...
    'audience member in the past twelve months.']
    'I have had formal training in music theory for ___ years.'
    ['I have had ___ years of formal training on a \n' ...
    'musical instrument (including voice) during my lifetime.']
    'I can play ___ musical instruments.'
    'I listen attentively to music for ___ per day.'
    };

responseOptions = {
    {'Completely Disagree', 'Strongly Disagree', 'Disagree', 'Neither Agree Nor Disagree', 'Agree', 'Strongly Agree', 'Completely Agree'}
    {'Completely Disagree', 'Strongly Disagree', 'Disagree', 'Neither Agree Nor Disagree', 'Agree', 'Strongly Agree', 'Completely Agree'}
    {'Completely Disagree', 'Strongly Disagree', 'Disagree', 'Neither Agree Nor Disagree', 'Agree', 'Strongly Agree', 'Completely Agree'}
    {'Completely Disagree', 'Strongly Disagree', 'Disagree', 'Neither Agree Nor Disagree', 'Agree', 'Strongly Agree', 'Completely Agree'}
    {'Completely Disagree', 'Strongly Disagree', 'Disagree', 'Neither Agree Nor Disagree', 'Agree', 'Strongly Agree', 'Completely Agree'}
    {'0', '1', '2', '3', '4-5', '6-9', '10 or more'}
    {'0', '0.5', '1', '1.5', '2', '3-4', '5 or more'}
    {'0', '1', '2', '3', '4-6', '7-10', '11 or more'}
    {'0', '0.5', '1', '2', '3', '4-6', '7 or more'}
    {'0', '0.5', '1', '2', '3-5', '6-9', '10 or more'}
    {'0', '1', '2', '3', '4', '5', '6 or more'}
    {'0-15 mins', '15-30 mins', '30-60 mins', '60-90 mins', '2hrs', '2-3hrs', '4hrs or more'}
    };

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
    
    % Wait for a brief interval before presenting the next question
    WaitSecs(0.5);
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

%Check if it already exists, if so, give it a copy number
save_file = GiveCopyNumber(save_file);
save(save_file,'responses','responseOptions','questions')

% End
WaitSecs(2);
DrawFormattedText(P.win, ['Thanks, that was it!' ...
    '\n Press return key to close'], 'center', P.win_rect(4)*0.3 - 100, 0, [], [], [], 1.5);
Screen('Flip', P.win);
KbWait();
Screen('Flip', P.win);
WaitSecs(1);
PsychPortAudio('Close');        % Shutdown sound driver
ListenChar(0);
% Close the window
sca

end
