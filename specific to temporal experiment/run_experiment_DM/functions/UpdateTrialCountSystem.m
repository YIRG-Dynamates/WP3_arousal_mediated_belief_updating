function [save_file,alldoneBool] = UpdateTrialCountSystem(S, F, nr_of_trials_completed)
%Update save_file name and OverviewFile with the number of completed trials

%Initialize
alldoneBool = false;

%Gather Path, Name and Extension
[savePath,filename,fileExtension] = fileparts(F.save_file);

%Append the number of trials to the fileName
save_file = fullfile(savePath,[filename '_Trials_' num2str(nr_of_trials_completed) fileExtension]);

%Check if it already exists, if so, give it a copy number
save_file = GiveCopyNumber(save_file);

%Rename the file
movefile(F.save_file, save_file);
fprintf('\nDATA SAVED\n');

%Update the OverviewFile if task was finished
if S.nTrials == nr_of_trials_completed
    
    OverviewFile = fullfile(F.run_path,'OverviewFile.mat');
    load(OverviewFile,'completed_tasks');
    completed_tasks(S.subject_Nr,S.task_nr) = 1;
    save(OverviewFile,'completed_tasks','-append');
    
    alldoneBool = S.task_nr == size(completed_tasks,2);
    
    load(save_file,'trials_cell');

        %Plot accuracy per trial for main task (LD)
        plotLDTask(trials_cell);    

end

end %[EOF]
