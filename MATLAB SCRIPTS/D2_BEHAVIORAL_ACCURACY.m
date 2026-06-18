
clear all
clearvars -except avg_acc_tempo avg_acc_motion

motion_TCA = load("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat");
tempo_TCA = load("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_tempo.mat");

%from drive
%motion_TCA = load('/Volumes/BALENCIJUGO/DESKTOP WORK PC/DATA/RAW THINGS/motion (WP1) local/final_behav_eye_data/preprocessing_version_12_07_2024/trials_cell_all_motion.mat')
%tempo_TCA = load('/Volumes/BALENCIJUGO/DESKTOP WORK PC/DATA/RAW THINGS/temporal (WP2) local/final_behav_eye_data/preprocessing_version_12_07_2024/trials_cell_all_tempo.mat')

motion_TCA = motion_TCA.trials_cell_all;
tempo_TCA = tempo_TCA.trials_cell_all;



%% tempo accuracies

% get rid of baseline trials
% this is only necessary if we want further accuracies without baseline

for sbjtrial = 1:numel(tempo_TCA);
    if length(tempo_TCA{sbjtrial}.x ) == 3;
        tempo_TCA{sbjtrial}.TempoDirRespCorrect = NaN;
        disp(sbjtrial);
    end
end


cnt = 1
for trial = 1:length(tempo_TCA)
    for subj = 1:width(tempo_TCA)
        correcto(cnt,2) = tempo_TCA{trial, subj}.SAC;
        correcto(cnt,3) = subj;
        correcto(cnt,1) = tempo_TCA{trial, subj}.TempoDirRespCorrect  ;
        cnt = cnt + 1;
    end
end   

correcto(any(isnan(correcto), 2), :) = [];


for subj = 1:width(tempo_TCA)
    for SAC = 1:5
        logi = (correcto(:,2) == SAC) & (correcto(:,3) == subj);
        acc = sum(correcto(logi,1))/length(correcto(logi,1));
        accuracies_tempo(subj, SAC) = acc;

    end 
end

clearvars correcto

%% motion accuracies

% get rid of baseline trials
% this is only necessary if we want further accuracies without baseline

for sbjtrial = 1:numel(motion_TCA);
    if length(motion_TCA{sbjtrial}.x ) == 2;
        motion_TCA{sbjtrial}.LocRespCorrect = NaN;
        disp(sbjtrial);
    end
end


cnt = 1
for trial = 1:length(motion_TCA)
    for subj = 1:width(motion_TCA)
        correcto(cnt,2) = motion_TCA{trial, subj}.SAC;
        correcto(cnt,3) = subj;
        correcto(cnt,1) = motion_TCA{trial, subj}.LocRespCorrect  ;
        cnt = cnt + 1;
    end
end   

correcto(any(isnan(correcto), 2), :) = [];


for subj = 1:width(motion_TCA)
    for SAC = 1:5
        logi = (correcto(:,2) == SAC) & (correcto(:,3) == subj);
        acc = sum(correcto(logi,1))/length(correcto(logi,1));
        accuracies_motion(subj, SAC) = acc;

    end 
end

clearvars correcto


%% anovas


% Convert to table format, as required by fitrm
ConditionNames = {'SAC1', 'SAC2', 'SAC3', 'SAC4', 'SAC5'};
T_motion = array2table(accuracies_motion, 'VariableNames', ConditionNames);
% Add a subject ID column
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\subj_nrs.mat')
T_motion.Subject = subj_nrs ;
T_motion.Group = repmat({'spatial'}, 22, 1);

T_tempo = array2table(accuracies_tempo, 'VariableNames', ConditionNames);
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

%% Sphericity

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


%% Test assumptions: Normality and Sphericity

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


% Alternative: test normality of residuals (depends on context)
% [h, p] = swtest(residuals.Raw); % Can also be used if appropriate

%% RANOVA for only SAC2-3

T_all2 = T_all;
T_all2(:,"SAC1") = [];
T_all2(:,"SAC5") = [];

ConditionNames2 = { 'SAC2', 'SAC3', 'SAC4'};

% Define within-subjects table
within2 = table(ConditionNames2', 'VariableNames', {'Condition'});

% Fit repeated-measures model
rm2 = fitrm(T_all, 'SAC2-SAC4 ~ Group', 'WithinDesign', within2);

% Run mixed ANOVA
ranovatbl2 = ranova(rm2, 'WithinModel', 'Condition');

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



% The analysis showed Condition had a statistically significant and substantial 
% effect on the outcome variable. The repeated measures ANOVA yielded F(4, 176) = 126.81, p < .001, 
% with effect sizes confirming the practical significance of this finding: partial η² = 0.742 (95% CI [0.502, 0.960]), 
% Cohen's f = 1.698 (95% CI [1.004, 4.889]). According to conventional benchmarks (Cohen, 1988),
% these values far exceed the threshold for a large effect (f > 0.40), suggesting 
% Condition explains the majority of variance in the dependent measure.


%% effect size for insignificant interaction effect of domain

% Extract Condition effect values from ranovatbl
groupcondition_row = strcmp(ranovatbl.Properties.RowNames, 'Group:Condition');
SS_condition = ranovatbl.SumSq(groupcondition_row);
df_condition = ranovatbl.DF(groupcondition_row);
F_condition = ranovatbl.F(groupcondition_row);

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
fprintf('Effect Size Analysis for INTERACTION! :\n');
fprintf('Partial η² = %.3f, 95%% CI [%.3f, %.3f]\n', eta_sq, eta_ci_lower, eta_ci_upper);
fprintf('Cohen''s f = %.3f, 95%% CI [%.3f, %.3f]\n\n', cohens_f, f_ci_lower, f_ci_upper);




%% actually plotting something


% load the baselines (drive)
load('/Users/romanfleischmann/Library/CloudStorage/GoogleDrive-fleischmann.roman@gmail.com/Other computers/My Computer/motion+localization (WP3)/PROC DATA/baseline_accuracies.mat')


% Compute means and SEMs
mean_tempo = mean(accuracies_tempo, 1); % Mean per SAC level for tempo
sem_tempo = std(accuracies_tempo, 0, 1) ./ sqrt(size(accuracies_tempo, 1)); % SEM for tempo

dlmwrite("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\accuracy_sac_means_tempo.txt", mean_tempo, 'delimiter', ' ')
dlmwrite("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\accuracy_sac_sems_tempo.txt", sem_tempo, 'delimiter', ' ')

mean_motion = mean(accuracies_motion, 1); % Mean per SAC level for motion
sem_motion = std(accuracies_motion, 0, 1) ./ sqrt(size(accuracies_motion, 1)); % SEM for motion

dlmwrite("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\accuracy_sac_means_motion.txt", mean_motion, 'delimiter', ' ')
dlmwrite("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\accuracy_sac_sems_motion.txt", sem_motion, 'delimiter', ' ')


mean(mean_motion)
mean(mean_tempo)


% Plot
figure;
hold on;

% Plot tempo
errorbar(1:5, mean_tempo, sem_tempo, '-o', 'Color', 'b', 'DisplayName', 'Tempo');
% Plot motion
errorbar(1:5, mean_motion, sem_motion, '-o', 'Color', 'r', 'DisplayName', 'Motion');

% Add horizontal lines
yline(avg_acc_tempo*0.01 , '--b', 'DisplayName', 'Tempo Baseline)'); % these values come from the scribt D3
yline(avg_acc_motion*0.01 , '--r', 'DisplayName', 'Motion Baseline');

% Add horizontal lines
yline(mean(mean_tempo) , 'b', 'DisplayName', 'Tempo Avg Acc'); 
yline(mean(mean_motion) , 'r', 'DisplayName', 'Motion Avg Acc');

%chance level
yline(0.5 , 'black', 'DisplayName', 'chance level');

% Labels and legend
xlabel('SAC Level');
ylabel('Accuracy');

xlim([0.5 5.5])
title('Average Accuracy with SEM per SAC Level');
legend('Location', 'best');

hold off;

%% zooming in on SAC level 1
% setting a treshold per person first


POE_tempo = nan(size(tempo_TCA));

% this specific conversion is important to interpret the SOA change value!
for i = 1:numel(tempo_TCA)
    SOA = tempo_TCA{i}.SOA;
    POE_tempo(i) = log(SOA(end-2)) - log(SOA(end-1));
end

% gather all evidences in high (pos and neg combined) and low (pos and neg combined)
evidence_tempo = cell(size(POE_tempo));

% convert to real, ignore tiny imaginary parts
POE_real_tempo = real(POE_tempo);
evidence_tempo = cell(size(POE_real_tempo));


tempo_evidence_high = false(size(POE_real_tempo));
tempo_evidence_low  = false(size(POE_real_tempo));

for c = 1:size(POE_real_tempo,2)
    col = POE_real_tempo(:,c);
    valid = isfinite(col);                  % numeric & not NaN
    q = quantile(col(valid), [0.25 0.75]);

    for r = 1:size(POE_real_tempo,1)
        if ~isfinite(col(r))
            continue                        % NaN stays 0
        elseif col(r) <= q(1) || col(r) >= q(2)
            tempo_evidence_high(r,c) = true;
        elseif col(r) > q(1) && col(r) < q(2)
            tempo_evidence_low(r,c) = true;
        end
    end
end

POE_real_motion = cell2mat(cellfun(@(s) s.v(end), motion_TCA, 'UniformOutput', false));

motion_evidence_high = false(size(POE_real_motion));
motion_evidence_low  = false(size(POE_real_motion));

for c = 1:size(POE_real_motion,2)
    col = POE_real_motion(:,c);
    valid = isfinite(col);                  % numeric & not NaN
    q = quantile(col(valid), [0.25 0.75]);

    for r = 1:size(POE_real_motion,1)
        if ~isfinite(col(r))
            continue                        % NaN stays 0
        elseif col(r) <= q(1) || col(r) >= q(2)
            motion_evidence_high(r,c) = true;
        elseif col(r) > q(1) && col(r) < q(2)
            motion_evidence_low(r,c) = true;
        end
    end
end

tempo_correct = cellfun(@(s) s.TempoDirRespCorrect, tempo_TCA, 'UniformOutput', false);
motion_correct = cellfun(@(s) s.LocRespCorrect, motion_TCA, 'UniformOutput', false);

tempo_SAC = cellfun(@(s) s.SAC, tempo_TCA, 'UniformOutput', false);
motion_SAC = cellfun(@(s) s.SAC, motion_TCA, 'UniformOutput', false);

tempo_SAC1 = cellfun(@(s) s == 1, tempo_SAC);
motion_SAC1 = cellfun(@(s) s == 1, motion_SAC);

% now we filter "correct" by SAC1 first to get all the SAC1 endings. 


%% plot 



