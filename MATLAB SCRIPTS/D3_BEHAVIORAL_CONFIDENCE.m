
clear all
clearvars -except avg_acc_tempo avg_acc_motion

motion_TCA = load("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat");
tempo_TCA = load("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_tempo.mat");

%from drive
%motion_TCA = load('/Volumes/BALENCIJUGO/DESKTOP WORK PC/DATA/RAW THINGS/motion (WP1) local/final_behav_eye_data/preprocessing_version_12_07_2024/trials_cell_all_motion.mat')
%tempo_TCA = load('/Volumes/BALENCIJUGO/DESKTOP WORK PC/DATA/RAW THINGS/temporal (WP2) local/final_behav_eye_data/preprocessing_version_12_07_2024/trials_cell_all_tempo.mat')

motion_TCA = motion_TCA.trials_cell_all;
tempo_TCA = tempo_TCA.trials_cell_all;


%% tempo confidence responses

% get rid of baseline trials
% this is only necessary if we want further accuracies without baseline

for sbjtrial = 1:numel(tempo_TCA);
    if length(tempo_TCA{sbjtrial}.x ) == 3;
        tempo_TCA{sbjtrial}.ConfidenceLevel = NaN;
        disp(sbjtrial);
    end
end

cnt = 1
for trial = 1:length(tempo_TCA)
    for subj = 1:width(tempo_TCA)
        conflevel_t(cnt,2) = tempo_TCA{trial, subj}.SAC;
        conflevel_t(cnt,3) = subj;
        conflevel_t(cnt,1) = tempo_TCA{trial, subj}.ConfidenceLevel  ;
        cnt = cnt + 1;
    end
end   

conflevel_t(any(isnan(conflevel_t), 2), :) = [];


for subj = 1:width(tempo_TCA)
    for SAC = 1:5
        logi = (conflevel_t(:,2) == SAC) & (conflevel_t(:,3) == subj);
        mean_conf = mean(conflevel_t(logi,1));
        confidences_tempo(subj, SAC) = mean_conf;
    end 
end

%% motion confidence responses

% get rid of baseline trials
% this is only necessary if we want further accuracies without baseline

for sbjtrial = 1:numel(motion_TCA);
    if length(motion_TCA{sbjtrial}.x ) == 2;
        motion_TCA{sbjtrial}.ConfidenceLevel = NaN;
        disp(sbjtrial);
    end
end

cnt = 1
for trial = 1:length(motion_TCA)
    for subj = 1:width(motion_TCA)
        conflevel_m(cnt,2) = motion_TCA{trial, subj}.SAC;
        conflevel_m(cnt,3) = subj;
        conflevel_m(cnt,1) = motion_TCA{trial, subj}.ConfidenceLevel  ;
        cnt = cnt + 1;
    end
end   

conflevel_m(any(isnan(conflevel_m), 2), :) = [];

for subj = 1:width(motion_TCA)
    for SAC = 1:5
        logi = (conflevel_m(:,2) == SAC) & (conflevel_m(:,3) == subj);
        mean_conf = mean(conflevel_m(logi,1));
        confidences_motion(subj, SAC) = mean_conf;
    end 
end

%% ANOVAS

% Convert to table format, as required by fitrm
ConditionNames = {'SAC1', 'SAC2', 'SAC3', 'SAC4', 'SAC5'};
T_motion = array2table(confidences_motion, 'VariableNames', ConditionNames);
% Add a subject ID column
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\subj_nrs.mat')
T_motion.Subject = subj_nrs ;
T_motion.Group = repmat({'spatial'}, 22, 1);

T_tempo = array2table(confidences_tempo, 'VariableNames', ConditionNames);
% Add a subject ID column
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data\subj_nrs.mat')
T_tempo.Subject = subj_nrs ;
%mark them as different so its not the same subject again, change S to T
T_tempo.Subject = regexprep(T_tempo.Subject, '^S', 'T');
T_tempo.Group = repmat({'tempo'}, 27, 1);

T_all = [T_motion; T_tempo];
T_all = movevars(T_all, {'Subject', 'Group'}, 'Before', 1);

% List of subjects to exclude
excluded_subjects = {'T016', 'T004', 'T012'};

% Keep only rows where Subject is NOT in the exclusion list
T_all = T_all(~ismember(T_all.Subject, excluded_subjects), :);

% Define within-subjects table
within = table(ConditionNames', 'VariableNames', {'Condition'});

% Fit repeated-measures model
rm = fitrm(T_all, 'SAC1-SAC5 ~ Group', 'WithinDesign', within);

% Run mixed ANOVA
ranovatbl = ranova(rm, 'WithinModel', 'Condition');

%% assumption: Sphericity

% Compute the correct degrees of freedom to report! For Greenhous geisser
mauchly_results = mauchly(rm);
disp(mauchly_results);

epsTable = epsilon(rm); 
disp(epsTable);

epsGG = epsTable.GreenhouseGeisser(1);
originalDF_num = ranovatbl{5,2}; %4
originalDF_den = ranovatbl{6,2}; %176

DF_num_GG = originalDF_num * epsGG;
DF_den_GG = originalDF_den * epsGG;
disp(['GG-corrected F(', num2str(DF_num_GG), ', ', num2str(DF_den_GG), ')']);

%% Test assumptions: Normality 

% --- Normality ---
% Predict the fitted values for each subject
fitted_vals = predict(rm);

% Compute residuals: actual - predicted
residuals_matrix = T_all{:, ConditionNames} - fitted_vals;

% You can now test normality on these residuals
disp('Shapiro-Wilk tests on residuals for each condition:')
for i = 1:numel(ConditionNames)
    residuals_col = residuals_matrix(:, i);
    % Use swtest or replace with lillietest if needed
    [h, p] = swtest(residuals_col);
    fprintf('%s: p = %.4f\n', ConditionNames{i}, p);
end

disp('Shapiro-Wilk normality tests:')
for i = 1:numel(ConditionNames)
    cond_data = T_all{:, ConditionNames{i}};
    [h, p] = swtest(cond_data);  % swtest requires Statistics Toolbox or File Exchange version
    fprintf('%s: p = %.4f\n', ConditionNames{i}, p);
end


%%

%% effect sizes %% effect sizes %% effect sizes %% effect sizes %% effect sizes
% this took so long to get right wtf

% Extract Condition effect values from ranovatbl
condition_row = strcmp(ranovatbl.Properties.RowNames, '(Intercept):Condition');
SS_condition = ranovatbl.SumSq(condition_row);
df_condition = ranovatbl.DF(condition_row);
F_condition = ranovatbl.F(condition_row);

% Extract corresponding error term values
error_row = strcmp(ranovatbl.Properties.RowNames, 'Error(Condition)');
SS_error = ranovatbl.SumSq(error_row);
df_error = ranovatbl.DF(error_row);

% Calculate partial eta squared
eta_sq = SS_condition / (SS_condition + SS_error);

% Calculate Cohen's f
cohens_f = sqrt(eta_sq / (1 - eta_sq));

% Calculate confidence intervals
alpha = 0.05;
F_lower = finv(alpha/2, df_condition, df_error);
F_upper = finv(1-alpha/2, df_condition, df_error);

% Eta squared CI
eta_ci_lower = (df_condition .* (F_condition./F_upper)) ./ (df_condition .* (F_condition./F_upper) + df_error);
eta_ci_upper = (df_condition .* (F_condition./F_lower)) ./ (df_condition .* (F_condition./F_lower) + df_error);

% Cohen's f CI
f_ci_lower = sqrt(eta_ci_lower ./ (1 - eta_ci_lower));
f_ci_upper = sqrt(eta_ci_upper ./ (1 - eta_ci_upper));

% Display results
fprintf('Effect Size Analysis for Condition:\n');
fprintf('Partial η² = %.3f, 95%% CI [%.3f, %.3f]\n', eta_sq, eta_ci_lower, eta_ci_upper);
fprintf('Cohen''s f = %.3f, 95%% CI [%.3f, %.3f]\n\n', cohens_f, f_ci_lower, f_ci_upper);
