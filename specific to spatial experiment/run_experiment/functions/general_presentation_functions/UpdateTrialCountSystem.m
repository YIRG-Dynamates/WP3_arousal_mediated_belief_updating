function [save_file,alldoneBool] = UpdateTrialCountSystem(S, F, nr_of_trials_completed)
% Update save_file name and OverviewFile with the number of completed trials

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
    if strcmp(S.task_name,'MAA')
        if ismember(S.block_nr,[2 3 4])
            psy = trials_cell{S.nTrials}.staircase{1};
            S.MAA = psybayes_plot_DM(psy);                                  %Plot staircase results - also use output of this function to overwrite any existing S.MAA
            if S.block_nr == 2
                load(OverviewFile,'MAA_results');
                MAA_results{S.subject_Nr,1} = S.MAA;
                save(OverviewFile,'MAA_results','-append');
                if (round(S.MAA*10)/10) <= 4.5
                    MAA_msg = ['MAA at 0° was measured to be ' num2str(round(S.MAA*10)/10) ' degrees. Subject may continue to next task.'];
                    msgbox(MAA_msg);
                    disp(MAA_msg);
                else
                    MAA_msg = ['WARNING! MAA at 0° was measured to be ' num2str(round(S.MAA*10)/10) ' degrees (i.e. > 4.5° !!). Subject may NOT continue to next task. You could re-try the MA2 task.'];
                    warndlg(MAA_msg);
                    warning(MAA_msg);
                end
            elseif S.block_nr == 3 
                if (round(S.MAA*10)/10) <= 9.0
                    MAA_msg = ['MAA at ±20° was measured to be ' num2str(round(S.MAA*10)/10) ' degrees. Subject may continue to next task.'];
                    msgbox(MAA_msg);
                    disp(MAA_msg);
                else
                    MAA_msg = ['WARNING! MAA at ±20° was measured to be ' num2str(round(S.MAA*10)/10) ' degrees (i.e. > 9.0° !!). Subject may NOT continue to next task. You could re-try the MA3 task.'];
                    warndlg(MAA_msg);
                    warning(MAA_msg);
                end
            elseif S.block_nr == 4
                if (round(S.MAA*10)/10) <= 13.5
                    MAA_msg = ['MAA at ±40° was measured to be ' num2str(round(S.MAA*10)/10) ' degrees. Subject may continue to next task.'];
                    msgbox(MAA_msg);
                    disp(MAA_msg);
                else
                    MAA_msg = ['WARNING! MAA at ±40° was measured to be ' num2str(round(S.MAA*10)/10) ' degrees (i.e. > 13.5° !!). Subject may NOT continue to next task. You could re-try the MA4 task.'];
                    warndlg(MAA_msg);
                    warning(MAA_msg);
                end
            end
        end
        plotFirstTask(trials_cell);                                         %Plot accuracy and confidence level per trial
    elseif strcmp(S.task_name,'Last_direction_discrimination') 
        %Show accuracy in command window
        num_correct = sum(cellfun(@(x) x.LocRespCorrect, trials_cell(1:nr_of_trials_completed)),'all');
        disp(['Subject answered ' num2str(num_correct) ' out of ' num2str(nr_of_trials_completed) ' trials correctly.']); 
        plotLDTask(trials_cell);
    end
end

end %[EOF]
