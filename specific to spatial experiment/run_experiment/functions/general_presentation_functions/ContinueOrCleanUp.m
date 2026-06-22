function [S, F, executePresentStimBool, generateNewStimuliBool] = ContinueOrCleanUp(S, F)

%Initialize to defaults
generateNewStimuliBool = true;
executePresentStimBool = true;
updateTrialsCountBool = false;

%We check whether the subject folder already contains an unfinished .mat file for this block
if exist(F.save_file, 'file') == 2
     
    %Check how many trials were already completed previously
    load(F.save_file,'settings','trials_cell');
    num_trials_completed = sum(cellfun(@(x) isfield(x,'LocResponse'),trials_cell),'all');
     
     %Clean up from previous crash    
    if num_trials_completed == 0
        
        %Delete empty file
        delete(F.save_file);
        fprintf('\nDELETED EMPTY OLD FILE\n');
        
    elseif num_trials_completed == settings.nTrials
        
        %The number of finished trials needs to be added to the filename in order to "finish" the block
        updateTrialsCountBool = true; 
        
        %Throw a warning if somehow all trials were finished already
        choice = questdlg({'This block was completed already.'; 'Do you want to repeat the block with new trials?'},'Repeat Block?','Yes','No','No');    
        if strcmpi(choice,'No')
            generateNewStimuliBool = false;
            executePresentStimBool = false;
        end
        
    else
        
        %Ask user whether to continue with unfinished block
        choice = questdlg({'Unfinished block was found.'; 'Do you want to continue the old block or start a new block?'},'Continue Old Block?','Continue Old Block','Start New Block','Continue Old Block');    
        
        if strcmpi(choice,'Continue Old Block')
            
            generateNewStimuliBool = false;
            
            %Update S.Created to keep track of all separate entries
            if ~iscell(settings.Created)
                %Only one previous entry
                S.Created = {settings.Created, ['Start trial is ' num2str(1)]; S.Created, ['Start trial is ' num2str(num_trials_completed+1)]};
            else
                %Multiple previous entries exist
                S.Created = [settings.Created; {S.Created, ['Start trial is ' num2str(num_trials_completed+1)]}];   
            end
            S.nTrials = settings.nTrials;
            
        elseif strcmpi(choice,'Start New Block')
            
            %The number of finished trials needs to be added to the filename in order to "finish" the 'unfinished' previous block
            updateTrialsCountBool = true; 

        else 
            
            %No response was chosen (e.g. the pop-up question was closed)    
            generateNewStimuliBool = false;
            executePresentStimBool = false;     %Nothing happens
        end
    end
    
    %Clean up EyeDataRaw if it exists    
%     ProcessEyeData(F, num_trials_completed);
    
    %Update Trials Counting System of the Old File
    if updateTrialsCountBool
        UpdateTrialCountSystem(settings, F, num_trials_completed)
        fprintf('\nOLD FILENAME WAS UPDATED WITH NUMBER OF TRIALS THAT WERE COMPLETED\n');
    end
    
end

end %[EOF]