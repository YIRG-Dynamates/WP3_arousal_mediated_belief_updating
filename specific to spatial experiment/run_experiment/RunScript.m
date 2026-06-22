%%%%%%%%%%%%%%%%%%
%%% Initialize %%% 
%%%%%%%%%%%%%%%%%%

close all;                                                                  %close all open figures
clearvars;                                                                  %clear all variables in the workspace
clc;                                                                        %clear the text in the command window                                     

%Debugging or AV synchrony test?
PTBcode_debuging = false;                                                   %Set to true if you want some control over the mouse and keyboard while you run the PTB code (for debugging)
AVsynchrony_test = false;                                                   %Set to true if you want a large flickering rectangle together with the sounds for audiovisual synchrony tests

%Make sure Psychtoolbox is properly installed and set it up 
PsychDefaultSetup(2);                                                       %Feature level 2: Normalized 0-1 color range and unified key mapping
PsychImaging('PrepareConfiguration');                                       %Prepare setup of imaging pipeline for onscreen window. This is the first step in the sequence of configuration steps.
Screen('Preference','SkipSyncTests', 1);                                    %Skip sync tests because it often leads to errors on Windows systems (http://psychtoolbox.org/docs/SyncTrouble)
Screen('Preference','VisualDebugLevel', 0);                                 %Disable all visual alerts (this avoids the large on-screen error message for the skipping of sync tests).
InitializePsychSound(1);                                                    %Load the PsychPortAudio sound driver for high-precision timing ("1")
clear ans;                                                                  %Not sure why 'ans' gets created by PTB, but I'll just delete it to clean up the workspace.

%Load dynamates paths structure (or just find the repository) 
dynamates_repository_path = LoadDynamates('wp1_spatial_predictions');       %This assumes that the 'LoadDynamates' function is on the path or in the current folder (same as this RunScript)

%Set some relevant paths
exp_path = fullfile(dynamates_repository_path,'Experiment','spatial_directions');
run_path = fullfile(exp_path,'run_experiment');
save_path = fullfile(exp_path,'behavioral_data');
generate_stimulus_path = fullfile(dynamates_repository_path,'src','generate_stimulus');

%Add some relevant paths
addpath(generate_stimulus_path);                                            %add the stimulus generation code to the path

addpath(genpath(fullfile(run_path,'functions')));                           %add the functions-folder and all subfolders to the matlab path
if ~any(cellfun(@(x) strcmp(x,fullfile(PsychtoolboxRoot,'PsychJava')),javaclasspath('-static')))
    javaaddpath(fullfile(PsychtoolboxRoot,'PsychJava'));                    %add PsychJava folder to dynamic Java path if not already on the static Java path 
end
javaaddpath(fullfile(run_path,'functions','general_presentation_functions','MatlabGarbageCollector.jar'));   %add Garbage Collecter to dynamic Java path

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Set Subj_nr, task and main conditions %%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[S, F] = SetSubjIDandTask(run_path,save_path,PTBcode_debuging,AVsynchrony_test);  %This function asks all the required input from the user

%Check for an old file of the same task, if present load it. Otherwise initialize a new data set     
[S, F, executePresentStimBool, generateNewStimuliBool] = ContinueOrCleanUp(S, F);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Call Psychtoolbox script %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if executePresentStimBool
    
    if generateNewStimuliBool 
        [S,trials_cell,eye_data] = GenTrials(S,F);                          %Generate a new block of trials
        settings = S;                                                       %Change name of S to settings for saving
        save(F.save_file,'settings','trials_cell','eye_data','-v6');        %Save the file using the -v6 method (fastest)  
        clear settings                                                      %Clean workspace
        
    else %Continue old unfinished file
        load(F.save_file,'trials_cell','eye_data');
    end 
    
    %PRESENT STIMULI IN PSYCHTOOLBOX!
    startTime = GetSecs;
    [S, nr_of_trials_completed] = PresentStim(S,F,trials_cell,eye_data); 
    duration = GetSecs - startTime;
    disp(' '); disp(['Total block presentation duration was: ' datestr(duration/(24*60*60),'HH:MM:SS') ' (HH:MM:SS).']);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Save and Process the data %%% 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Check if all trials were finished - and if not, ask what to do
    if nr_of_trials_completed > 0
        
        saveNowBool = true;
        if nr_of_trials_completed < S.nTrials
            choice = questdlg(['Not all trials were completed (' num2str(nr_of_trials_completed) '/' num2str(S.nTrials) '). Finish block later or consider the block finished now (save and analyse)?'], ...
                                                'Finish later?', 'Finish later','Finalise block now','Finish later');
            if strcmp(choice,'Finish later')
                saveNowBool = false;
            end
        end

        if saveNowBool
            %Save the data (update the filename such that it includes the nr of trials that were finished)
            [save_file,alldoneBool] = UpdateTrialCountSystem(S, F, nr_of_trials_completed);
            msgbox(['Subject ' num2str(S.subject_Nr) ' data for ' S.task_name ' block ' num2str(S.block_nr) ' saved successfully']);
            disp(['Subject ' num2str(S.subject_Nr) ' data for ' S.task_name ' block ' num2str(S.block_nr) ' saved successfully']);
            disp(['Data was saved in: ' F.save_file]);
            
            %Show a warning if this participant is all done
            if alldoneBool
                warndlg(['Participant with subject nr ' num2str(S.subject_Nr) ' is all done!','!! Yeey !!']);
            end
        else
            save_file = F.save_file;
        end
        [save_path,filename,ext] = fileparts(save_file);
        save_file = [filename ext];
        clearvars -except 'run_path' 'save_path' 'save_file';                       %Clean up workspace
    else 
        delete(F.save_file);                                                        %Delete the file that was created if no trials were completed
        clearvars -except 'run_path';                                               %Clean up workspace 
    end
else 
    clearvars -except 'run_path';                                                   %Clean up workspace (in case PresentStim.m was not executed)
end %end if statement 'Execute PresentStim.m?'

%Remove Psychtoolbox and MatlabGarbageCollector from the dynamic java path
if any(cellfun(@(x) strcmp(x,fullfile(PsychtoolboxRoot,'PsychJava')),javaclasspath))
    javarmpath(fullfile(PsychtoolboxRoot,'PsychJava'));                             %remove PsychJava folder from dynamic Java path if it's on there                
end
javarmpath(fullfile(run_path,'functions','general_presentation_functions','MatlabGarbageCollector.jar')); %remove GarbageCollector from dynamic Java path       

%[EOF]
