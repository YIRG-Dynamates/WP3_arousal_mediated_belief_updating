clear all


%%%% MOTION %%%%
% Base directory
baseDir = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\modelling_by_david\fitted_data_dir_exp';

% Get list of all folders in the base directory matching the 'S###' pattern
folderPattern = fullfile(baseDir, 'S*');
folders = dir(folderPattern);

% Loop over each folder
for i = 1:length(folders)
    % Ensure the directory is indeed a folder
    if folders(i).isdir
        folderName = folders(i).name;
        folderPath = fullfile(baseDir, folderName);
        
        % Define the specific file name we're looking for in this folder
        targetFileName = strcat(folderName, '_BdCPfitResults_4.mat');
        targetFilePath = fullfile(folderPath, targetFileName);
        
        % Check if the target file exists
        if isfile(targetFilePath)
            % Load the .mat file
            load(targetFilePath);
            
            % (Optional) Display which file is being loaded
            fprintf('Loaded file: %s\n', targetFilePath);
            
            % (Optional) Process the loaded data here
            minus_one(:,i) = BdCPfitResults.predictions.responses.prob(1,1:200);
            
            % Example: Access a variable from the .mat file
            % myData = data.variableName;
        else
            fprintf('File not found: %s\n', targetFilePath);
        end
    end
end

% copying
minus_one_red = minus_one
% predicted answers
minus_one_red(minus_one > 0.5) = -1;
minus_one_red(minus_one <= 0.5) = 1;

minus_one_reduced_motion = minus_one_red;

% load motion trial cell
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat')

%actual answers
LocResponse_matrix = cellfun(@(x) x.LocResponse, trials_cell_all);

% how many were correct? % how well does the prediction fit the given
% answer by the participant?
prediction_correct_motion = (minus_one_red == LocResponse_matrix);
percentage_pred_correct = mean(prediction_correct_motion, 1);
percentage_pred_correct_motion = percentage_pred_correct;


%% cohens h

% Compute proportion correct per participant
accuracy = mean(prediction_correct_motion, 1);  % 1 x nParticipants

% Compare to chance (e.g., 0.5)
p_chance = 0.5;

% Cohen's h function
cohens_h = 2 * (asin(sqrt(accuracy)) - asin(sqrt(p_chance)));

% cohens_h is now a 1 x nParticipants vector of effect sizes
mean(accuracy)
mean(cohens_h)
std(cohens_h)

% CI for cohens h
% Cohen's h for each subject
cohens_h = 2 * (asin(sqrt(accuracy)) - asin(sqrt(p_chance)));

% Bootstrap CI of the mean effect size
nboot = 10000;

boot_means = bootstrp(nboot, @mean, cohens_h);

mean_acc_motion = mean(accuracy)
CI_motion = prctile(boot_means,[2.5 97.5]);
mean_h_motion = mean(cohens_h);
std_h_motion  = std(cohens_h);

%%%% END MOTION


%% % TEMPO

% Base directory
baseDir = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\modelling_by_david\fitted_data_wp2';

% Get list of all folders in the base directory matching the 'S###' pattern
folderPattern = fullfile(baseDir, 'S*');
folders = dir(folderPattern);

% we have not properly excluded people yet! %%%%%%%%%%%%%%%%%%

% Loop over each folder
for i = 1:length(folders)
    % Ensure the directory is indeed a folder
    if folders(i).isdir
        folderName = folders(i).name;
        folderPath = fullfile(baseDir, folderName);
        
        % Define the specific file name we're looking for in this folder
        targetFileName = strcat(folderName, '_BdCPfitResults_1.mat');
        targetFilePath = fullfile(folderPath, targetFileName);
        
        % Check if the target file exists
        if isfile(targetFilePath)
            % Load the .mat file
            load(targetFilePath);
            
            % (Optional) Display which file is being loaded
            fprintf('Loaded file: %s\n', targetFilePath);
            
            % (Optional) Process the loaded data here
            for k = 1:200;
                LikeFun(1:2,k) = BdCPfitResults.predictions{k, 1}.LikeFun  ;
            end

            minus_one(:,i) =  LikeFun(1,:);

            %minus_one(:,i) = BdCPfitResults.predictions.responses.prob(1,1:200);
            % myData = data.variableName;
        else
            fprintf('File not found: %s\n', targetFilePath);
        end
    end
end

% copying
minus_one_red = minus_one
% predicted answers
minus_one_red(minus_one > 0.5) = -1;
minus_one_red(minus_one <= 0.5) = 1;

minus_one_reduced_tempo = minus_one_red;

% load tempo
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_tempo.mat')

%actual answers
TempoResponse_matrix = cellfun(@(x) x.TempoDirResponse, trials_cell_all);

% how many were correct? % how well does the prediction fit the given
% answer by the participant?
prediction_correct_tempo = (minus_one_red == TempoResponse_matrix);
percentage_pred_correct_tempo = mean(prediction_correct_tempo, 1);

%%% EFFECT SIZE TEMPO

% Compute proportion correct per participant
accuracy = mean(prediction_correct_tempo, 1);  % 1 x nParticipants

% Compare to chance (e.g., 0.5)
p_chance = 0.5;

% Cohen's h function
cohens_h = 2 * (asin(sqrt(accuracy)) - asin(sqrt(p_chance)));

% cohens_h is now a 1 x nParticipants vector of effect sizes
mean(accuracy)
mean(cohens_h)
std(cohens_h)

% CI for cohens h
% Cohen's h for each subject
cohens_h = 2 * (asin(sqrt(accuracy)) - asin(sqrt(p_chance)));

% Bootstrap CI of the mean effect size
nboot = 10000;

boot_means = bootstrp(nboot, @mean, cohens_h);

mean_acc_tempo = mean(accuracy)
CI_tempo = prctile(boot_means,[2.5 97.5]);
mean_h_tempo = mean(cohens_h);
std_h_tempo  = std(cohens_h);

%% LOG FILE

% Open text file for writing
fileID = fopen('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\REGMODELS\F2_EFFECT_SIZES_BEHAVIORAL_MODEL.txt','w');

% ---- Custom header lines ----
fprintf(fileID, 'EFFECT SIZES FOR BEHAVIORAL MODEL\n');
fprintf(fileID, 'Generated on: %s\n', datestr(now));
fprintf(fileID, '---------------------------------\n\n');

% ---- statistics diff trace ----
fprintf(fileID, '--- Temporal task');
fprintf(fileID, '\n');
fprintf(fileID, ['Mean accuracy = ', num2str(mean_acc_tempo), '\n']);
fprintf(fileID, ['Cohens h = ', num2str(mean_h_tempo), '\n']);
fprintf(fileID, ['95 CI Cohens h = ', num2str(CI_tempo), '\n']);
fprintf(fileID, ['STD Cohens h = ', num2str(std_h_tempo), '\n']);
fprintf(fileID, '\n');
fprintf(fileID, '--- Spatial task');
fprintf(fileID, '\n');
fprintf(fileID, ['Mean accuracy = ', num2str(mean_acc_motion), '\n']);
fprintf(fileID, ['Cohens h = ', num2str(mean_h_motion), '\n']);
fprintf(fileID, ['95 CI Cohens h = ', num2str(CI_motion), '\n']);
fprintf(fileID, ['STD Cohens h = ', num2str(std_h_motion), '\n']);
fprintf(fileID, '\n');
fprintf(fileID, 'Cohens h calculated per person, then averaged over participants');
fprintf(fileID, '\n');

% ---- Custom footer ----
fprintf(fileID, '\n---------------------------------\n');
fprintf(fileID, 'i hope this contains everything you need.\n');

% Close file
fclose(fileID);

disp('File written successfully.');





%% plot predicted accuracies over SAC level

% load motion trial cell
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat')

lastSAC = zeros(size(minus_one_reduced_motion));

for cnt = 1:numel(minus_one_reduced_motion)
    if length(trials_cell_all{cnt}.x) < 3
        lastSAC(cnt) = 0;
    else
        lastSAC(cnt) = trials_cell_all{cnt}.SAC;
    end
end

last_motion_direction = cellfun(@(x) sign(x.v(end)), trials_cell_all, 'UniformOutput', false);

%how well does the PREDICTED answer fit the actual last motion direction?
predicted_correct_answer = (minus_one_reduced_motion == cell2mat(last_motion_direction));

filePath = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\modelling_by_david\fitted_data_dir_exp\trials_correct_modelled.mat';
save(filePath,'predicted_correct_answer');

for sbj = 1:22
    for SAC = 1:5
        logical_SAC = lastSAC(:,sbj) == SAC;
        logical_SAC_correctanswer = logical_SAC == 1 & predicted_correct_answer(:,sbj) == 1;
        matrix_motion(sbj, SAC) = sum(logical_SAC_correctanswer) / sum(logical_SAC);
    end
end

%% now tempo

% load motion trial cell
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_tempo.mat')

lastSAC_tempo = zeros(size(minus_one_reduced_tempo));

for cnt = 1:numel(minus_one_reduced_tempo)
    if length(trials_cell_all{cnt}.x) < 4
        lastSAC_tempo(cnt) = 0;
    else
        lastSAC_tempo(cnt) = trials_cell_all{cnt}.SAC;
    end
end

last_tempo_direction = cellfun(@(x) sign(x.SOA_change(end-1)), trials_cell_all, 'UniformOutput', false);

%how well does the PREDICTED answer fit the actual last tempo direction?
predicted_correct_answer = (minus_one_reduced_tempo == cell2mat(last_tempo_direction));

filePath = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\modelling_by_david\fitted_data_wp2\trials_correct_modelled.mat';
save(filePath,'predicted_correct_answer');

for sbj = 1:22
    for SAC = 1:5
        logical_SAC = lastSAC_tempo(:,sbj) == SAC;
        logical_SAC_correctanswer = logical_SAC == 1 & predicted_correct_answer(:,sbj) == 1;
        matrix_tempo(sbj, SAC) = sum(logical_SAC_correctanswer) / sum(logical_SAC);
    end
end


%%%%%%%%%% quick plotting but exporting it to R to plot there with the rest

mean_motion = mean(matrix_motion, 1);
sem_motion = std(matrix_motion, 0, 1) ./ sqrt(size(matrix_motion, 1)); % Standard error

mean_tempo = mean(matrix_tempo, 1);
sem_tempo = std(matrix_tempo, 0, 1) ./ sqrt(size(matrix_tempo, 1)); % Standard error

dlmwrite("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\accuracy_pred_sac_means_motion.txt", mean_motion, 'delimiter', ' ')
dlmwrite("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\accuracy_pred_sac_sems_motion.txt", sem_motion, 'delimiter', ' ')

dlmwrite("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\accuracy_pred_sac_means_tempo.txt", mean_tempo, 'delimiter', ' ')
dlmwrite("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\accuracy_pred_sac_sems_tempo.txt", sem_tempo, 'delimiter', ' ')

% X-axis for plotting
x = 1:size(matrix_motion, 2);

% Plot mean as a line and error bars for SAC
figure;
errorbar(x, mean_motion, sem_motion, 'o-', 'LineWidth', 1.5, 'MarkerSize', 8);
hold on
errorbar(x, mean_tempo, sem_tempo, 'o-', 'LineWidth', 1.5, 'MarkerSize', 8);
hold off
xlabel('SAC level');
ylabel('predicted accuracy');
title('predicted accuracy of BCP model');
grid on;















