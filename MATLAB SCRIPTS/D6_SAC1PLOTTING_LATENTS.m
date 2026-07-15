clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%% motion %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% load latents
data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data';
file_path = fullfile(data_folder, "LATENT VARS", "BdCPfitResults_4_latent_vars_2.mat");
loaded_data = load(file_path, 'surprisal', 'info_gain');

motion_TCA = load("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat");
motion_TCA = motion_TCA.trials_cell_all;

% get rid of baseline trials
for sbjtrial = 1:numel(motion_TCA);
    if length(motion_TCA{sbjtrial}.x ) == 2;
        motion_TCA{sbjtrial}.LocRespCorrect = NaN;
        motion_TCA{sbjtrial}.SAC = 0;
        disp(sbjtrial);
    end
end

SAC_m = []
% all sac levels
for subject = 1:width(motion_TCA)
    for trial = 1:height(motion_TCA)
        SAC_m(trial, subject) = motion_TCA{trial, subject}.SAC;
    end 
end

% set latent variable
latent_sur_m = loaded_data.surprisal.med;
latent_sur_m(:,1:5) = [];

% set latent variable
latent_info_m = loaded_data.info_gain.med;
latent_info_m(:,1:5) = [];

% boxcox and zscore for latent (within last sound)
latent_info_m_bcoxzscore = cellfun(@(s) s(end), latent_info_m);
latent_sur_m_bcoxzscore = cellfun(@(s) s(end), latent_sur_m);

for sbj = 1:width(latent_info_m_bcoxzscore) % motion loop
    latent_info_m_bcoxzscore(:,sbj) = boxcox_auto_2(latent_info_m_bcoxzscore(:,sbj));
    latent_info_m_bcoxzscore(:,sbj) = zscore(latent_info_m_bcoxzscore(:,sbj));
    latent_sur_m_bcoxzscore(:,sbj) = boxcox_auto_2(latent_sur_m_bcoxzscore(:,sbj));
    latent_sur_m_bcoxzscore(:,sbj) = zscore(latent_sur_m_bcoxzscore(:,sbj));
end

% find correct points of evidence (POE)
POE_real_motion = cell2mat(cellfun(@(s) s.v(end), motion_TCA, 'UniformOutput', false));
latent_POE_m = num2cell(POE_real_motion);

% extracting which trials are correct and which arent
correct_m = cellfun(@(s) s.LocRespCorrect, motion_TCA, 'UniformOutput', false);
correct_m = cell2mat(cellfun(@double, correct_m, 'UniformOutput', false));

% loading in the same format which trials were correct/wrong according
prediction_correct_motion = load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\modelling_by_david\fitted_data_dir_exp\trials_correct_modelled.mat')
prediction_correct_motion = prediction_correct_motion.predicted_correct_answer  ;

motion_sbj_num = width(latent_POE_m);


%% ===================== tempo stuff=================
% EXCLUSIONS NEED TO GO HERE!

tempo_TCA = load("C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_tempo.mat");
tempo_TCA = tempo_TCA.trials_cell_all;

for sbjtrial = 1:numel(tempo_TCA);
    if length(tempo_TCA{sbjtrial}.x ) == 3;
        tempo_TCA{sbjtrial}.TempoDirRespCorrect = NaN; %two ways of excluding short trials, per Answer = NaN 
        tempo_TCA{sbjtrial}.SAC = 0;                    % and per SAC = 0
        disp(sbjtrial);
    end
end

SAC_t = []
% all sac levels
for subject = 1:width(tempo_TCA)
    for trial = 1:height(tempo_TCA)
        SAC_t(trial, subject) = tempo_TCA{trial, subject}.SAC;
    end 
end

data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data';
file_path = fullfile(data_folder, "LATENT VARS/", "BdCPfitResults_1_latent_vars.mat"); 
loaded_data = load(file_path, 'surprisal', 'info_gain');

% point of evidence as latent variable
POE_tempo = nan(size(tempo_TCA));

% this specific conversion is important to interpret the SOA change value!
for i = 1:numel(tempo_TCA)
    SOA = tempo_TCA{i}.SOA;
    POE = diff(log(SOA));
    POE_tempo(i) = POE(end-1);
end

latent_POE_t = num2cell(abs(POE_tempo)); % evidence levels go into negative space which we dont need

% set latent variable
latent_sur_t = loaded_data.surprisal.med;

% set latent variable
latent_info_t = loaded_data.info_gain.med;

% boxcox and zscore for latent (within last sound)
latent_info_t_bcoxzscore = cellfun(@(s) s(end), latent_info_t);
latent_sur_t_bcoxzscore = cellfun(@(s) s(end), latent_sur_t);
for sbj = 1:width(latent_info_t_bcoxzscore) % tempo loop
    latent_info_t_bcoxzscore(:,sbj) = boxcox_auto_2(latent_info_t_bcoxzscore(:,sbj));
    latent_info_t_bcoxzscore(:,sbj) = zscore(latent_info_t_bcoxzscore(:,sbj));
    latent_sur_t_bcoxzscore(:,sbj) = boxcox_auto_2(latent_sur_t_bcoxzscore(:,sbj));
    latent_sur_t_bcoxzscore(:,sbj) = zscore(latent_sur_t_bcoxzscore(:,sbj));
end

% were applying our logical to motion_correct later
correct_t = cellfun(@(s) s.TempoDirRespCorrect, tempo_TCA, 'UniformOutput', false);
correct_t = cell2mat(cellfun(@double, correct_t, 'UniformOutput', false));

% loading in the same format which trials were correct/wrong according
prediction_correct_tempo = load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\modelling_by_david\fitted_data_wp2\trials_correct_modelled.mat')
prediction_correct_tempo = prediction_correct_tempo.predicted_correct_answer   ;

tempo_sbj_num = width(latent_POE_t);

figure(1)
%% ===================== without latents stuff =================
subplot(4, 3, 1)
plot_allsac(1, correct_m, SAC_m, 'spatial vs. ', 'temporal', 0, 2)
plot_allsac(1, correct_t, SAC_t, 'spatial vs. ', 'temporal', 0.1, 1)
%legend({'spatial','chance level', 'temporal'}, 'Location','best');
legend(gca, 'off'); box on;
delete(get(gca, 'Title'));
ylabel('Accuracy');

subplot(4, 3, 2)
plot_allsac(1, prediction_correct_motion, SAC_m, 'spatial vs. ', 'temporal', 0, 2)
plot_allsac(1, prediction_correct_tempo, SAC_t, 'spatial vs. ', 'temporal', 0.1, 1)
%legend({'spatial', 'chance level', 'temporal'}, 'Location','best');
legend(gca, 'off'); box on;
delete(get(gca, 'Title'));
ylabel('Predicted Accuracy');

% confidences load
save_folder = "C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA"
load(fullfile(save_folder, 'tempo_conflevel_mean.mat'))
load(fullfile(save_folder, 'tempo_conflevel_sem.mat'))
load(fullfile(save_folder, 'motion_conflevel_mean.mat'))
load(fullfile(save_folder, 'motion_conflevel_sem.mat'))

subplot(4, 3, 3)
hold on
errorbar(1:5, motion_conflevel_mean, motion_conflevel_sem, 'o-', 'LineWidth', 1, 'MarkerSize', 3, 'Color', 'red');
errorbar(1:5, tempo_conflevel_mean, tempo_conflevel_sem, 'o-', 'LineWidth', 1, 'MarkerSize', 3,'Color', 'blue'  );
hold on
xlabel('SAC');
ylabel('Confidence Level');
title('spatial vs. temporal');
set(gca,'XTick',1:5)
ylim([1 4]);
xlim([0.8 5.2]);
%legend({'spatial','temporal'}, 'Location','best');
legend(gca, 'off'); box on;
delete(get(gca, 'Title'));
grid off;
hold off;

%% ===============================  plotting all the latents over experiment
subplot(4, 3, 4)
plot_allsac_latent(1, latent_sur_m_bcoxzscore, SAC_m, 'spatial vs. ', 'temporal', 0, 2)
plot_allsac_latent(1, latent_sur_t_bcoxzscore, SAC_t, 'spatial vs. ', 'temporal', 0, 1)
%legend({'spatial','temporal'}, 'Location','best');
legend(gca, 'off'); box on;
delete(get(gca, 'Title'));
grid off;
ylim([-0.7 1.5])
ylabel('Surprisal (zscored)');

subplot(4, 3, 5)
plot_allsac_latent(1, latent_info_m_bcoxzscore, SAC_m, 'spatial vs. ', 'temporal', 0, 2)
plot_allsac_latent(1, latent_info_t_bcoxzscore, SAC_t, 'spatial vs. ', 'temporal', 0, 1)
%legend({'spatial','temporal'}, 'Location','best');
legend(gca, 'off'); box on;
delete(get(gca, 'Title'));
grid off;
ylim([-0.7 1.5])
ylabel('Infogain (zscored)');


%% ===============================  plotting all them motion plots

% =================== motion, surprisal =====================
subplot(4, 3, 7)
plot_medianlatent_allsac(1, latent_sur_m, correct_m, SAC_m, 'surprisal in ', 'spatial task', 2, 0)
%figure1 = gcf;
legend({'low surprisal','high surprisal'}, 'Location','southeast'); box on;
delete(get(gca, 'Title'));
grid off;
ylabel('Accuracy');

% =================== modelled motion accuracy, surprisal =====================
% plot_medianlatent_allsac(2, latent_sur_m, prediction_correct_motion, SAC_m, 'surprisal', ' motion', 1,0)
% figure2 = gcf;
% legend({'low surprisal','high surprisal'}, 'Location','best');
% ylabel('Predicted Accuracy');

% ===================== motion, infogain =================
subplot(4, 3, 8)
plot_medianlatent_allsac(3, latent_info_m, correct_m, SAC_m, 'infogain in ', 'spatial task', 2, 0)
%figure3 = gcf;
legend({'low infogain','high infogain'}, 'Location','southeast'); box on;
delete(get(gca, 'Title'));
grid off;
ylabel('Accuracy');

% ===================== modelled motion accuracy, infogain =================
% plot_medianlatent_allsac(4, latent_info_m, prediction_correct_motion, SAC_m, 'infogain', ' motion', 1, 0)
% figure4 = gcf;
% legend({'low infogain','high infogain'}, 'Location','best');
% ylabel('Predicted Accuracy');

% ===================== motion, POE =================
subplot(4, 3, 9)
plot_medianlatent_allsac(5, latent_POE_m, correct_m, SAC_m, 'evidence in ', 'spatial task', 2, 0)
%figure5 = gcf;
legend({'low evidence','high evidence'}, 'Location','southeast'); box on;
delete(get(gca, 'Title'));
grid off;
ylabel('Accuracy');

% ===================== motion predicted, POE =================
% plot_medianlatent_allsac(6, latent_POE_m, prediction_correct_motion, SAC_m, 'evidence', '  motion', 2, 0)
% figure6 = gcf;
% legend({'low evidence','high evidence'}, 'Location','best');
% ylabel('Predicted Accuracy');

%% ===============================  plotting all them tempo plots

% ===================== tempo, surprisal =================
subplot(4, 3, 10)
plot_medianlatent_allsac(7, latent_sur_t, correct_t, SAC_t, 'surprisal in ', 'temporal task', 1, 0)
%figure7 = gcf;
legend({'low surprisal','high surprisal'}, 'Location','southeast'); box on;
delete(get(gca, 'Title'));
grid off;
ylabel(' Accuracy');

% ===================== tempo predicted, surprisal =================
% plot_medianlatent_allsac(8, latent_sur_t, prediction_correct_tempo, SAC_t, 'surprisal', '  tempo', 1, 0)
% %figure8 = gcf;
% legend({'low surprisal','high surprisal'}, 'Location','best');
% ylabel('Predicted Accuracy');

% ===================== tempo, infogain =================
subplot(4, 3, 11)
plot_medianlatent_allsac(9, latent_info_t, correct_t, SAC_t, 'infogain in ','temporal task', 1, 0)
figure9 = gcf;
legend({'low infogain','high infogain'}, 'Location','southeast'); box on;
delete(get(gca, 'Title'));
grid off;
ylabel('Accuracy');

% ===================== tempo predicted, infogain =================
% plot_medianlatent_allsac(10, latent_info_t, prediction_correct_tempo, SAC_t, 'infogain', '  tempo', 1, 0)
% figure10 = gcf;
% legend({'low infogain','high infogain'}, 'Location','best');
% ylabel('Predicted Accuracy');

% ===================== tempo, POE =================
subplot(4, 3, 12)
plot_medianlatent_allsac(11, latent_POE_t, correct_t, SAC_t, 'evidence in ', 'temporal task', 1, 0)
figure11 = gcf;
legend({'low evidence','high evidence'}, 'Location','southeast'); box on;
delete(get(gca, 'Title'));
grid off;
ylabel('Accuracy');

% ===================== tempo predicted, POE =================
% plot_medianlatent_allsac(12, latent_POE_t, prediction_correct_tempo, SAC_t, 'evidence', '  tempo', 1, 0)
% figure12 = gcf;
% legend({'low evidence','high evidence'}, 'Location','best');
% ylabel('Predicted Accuracy');


%% t-Tests to accomodate the reviewers (only for the temporal part)

% % latent=latent_sur_t
% latent = num2cell(latent_info_t_bcoxzscore)
% latent = cell2mat(latent_POE_t)
% correct=correct_t
% SAC=SAC_t

% ---- median split t-tests ----
latent_labels = {'latent_info_t_bcoxzscore', 'latent_sur_t_bcoxzscore', 'latent_POE_t', ...
                 'latent_info_m_bcoxzscore', 'latent_sur_m_bcoxzscore', 'latent_POE_m'};
latent_inputs = {num2cell(latent_info_t_bcoxzscore), num2cell(latent_sur_t_bcoxzscore), latent_POE_t, ...
                 num2cell(latent_info_m_bcoxzscore), num2cell(latent_sur_m_bcoxzscore), latent_POE_m};

for l = 1:3
    median_split_results{l} = median_split_accuracy_ttest(latent_inputs{l}, correct_t, SAC_t);
end
for l = 4:6
    median_split_results{l} = median_split_accuracy_ttest(latent_inputs{l}, correct_m, SAC_m);
end

%% saving

% Get figure 
currentFig = figure(1);  % 

% Set size (width, height) 
desiredWidth  = 900;  % Pixels 
desiredHeight = 900;  
set(currentFig, 'Position', [100, 100, desiredWidth, desiredHeight]);  % [left, bottom, width, height]

%Save the figure 
savePath = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\D6_LATENT_MEDIAN_SPLIT_OVER_SAC.png';  % Replace with your desired path/format
exportgraphics(currentFig, savePath, 'Resolution', 300);  % High-resolution PNG
saveas(currentFig, 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\D6_LATENT_MEDIAN_SPLIT_OVER_SAC.svg');  % SVG 
saveas(currentFig, 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\D6_LATENT_MEDIAN_SPLIT_OVER_SAC.fig');  % fig
saveas(currentFig, 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\D6_LATENT_MEDIAN_SPLIT_OVER_SAC.pdf');   % pdf
% output file 


%% OUTPUT TXT FILE
% Open text file for writing
fileID = fopen('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\D6_LATENT_MEDIAN_SPLIT_OVER_SAC.txt','w');

% ---- Custom header lines ----
fprintf(fileID, 'PLOTTING; LATENT VARIABLE (MEDIAN SPLIT) OVER SAC LEVEL\n');
fprintf(fileID, 'Generated on: %s\n', datestr(now));
fprintf(fileID, '---------------------------------\n\n');

% ---- info for plots ----
fprintf(fileID, '---subject numbers\n');
fprintf(fileID, ['N (temporal) = ', num2str(tempo_sbj_num), '\n']);
fprintf(fileID, ['N (motion) = ', num2str(motion_sbj_num), '\n\n']);
fprintf(fileID, 'accuracies calculated as means per person per SAC, then SEM and average over participants\n');
fprintf(fileID, 'these plots were made by script number D6\n');

% ----- t-tests ----
% one-sided paired t-tests (H1: low < high); p (exact) is non-rounded, use for reporting
for l = 1:6

    fprintf(fileID, '==========================================================\n');
    fprintf(fileID, 'LATENT VARIABLE: %s\n', latent_labels{l});
    fprintf(fileID, '==========================================================\n');
    fprintf(fileID, 'Median split strictly within SAC level, paired one-sided t-test per SAC (H1: low < high)\n');
    fprintf(fileID, 'Effect size: Cohen''s d (paired), 95%% CI via noncentral t-distribution\n\n');

    out = median_split_results{l};

    fprintf(fileID, ' %-5s  %-8s  %-9s  %-8s  %-10s  %-14s  %-12s  %-8s  %-20s  %-5s\n', ...
        'SAC', 'Low Mean', 'High Mean', 'Diff', 'p (rounded)', 'p (exact)', 't(df)', 'Cohen''s d', '95% CI [low, high]', 'n');
    fprintf(fileID, '%s\n', repmat('-', 1, 100));

    for sac_var = 1:5
        low     = out.means_under_tresh(:, sac_var);
        high    = out.means_over_tresh(:, sac_var);
        valid   = ~isnan(low) & ~isnan(high);
        n_valid = sum(valid);
        t_val   = out.stats{sac_var}.tstat;
        df      = out.stats{sac_var}.df;

        % rounded p for readability
        if out.p(sac_var) < 0.001
            p_str = '<.001';
        else
            p_str = sprintf('%.3f', out.p(sac_var));
        end

        % exact p, no rounding
        p_exact_str = sprintf('%.6g', out.p(sac_var));

        fprintf(fileID, ' SAC %d  %-8.4f  %-9.4f  %-8.4f  %-10s  %-14s  %-12s  %-8.3f  [%-7.3f, %-7.3f]   %d\n', ...
            sac_var, nanmean(low), nanmean(high), nanmean(low)-nanmean(high), ...
            p_str, p_exact_str, sprintf('%.3f(%d)', t_val, df), ...
            out.cohen_d(sac_var), out.cohen_d_ci(1,sac_var), out.cohen_d_ci(2,sac_var), n_valid);
    end

    fprintf(fileID, '%s\n\n', repmat('=', 1, 100));
end

% ---- Custom footer ----
fprintf(fileID, '\n---------------------------------\n');
fprintf(fileID, 'i hope this contains everything you need.\n');

% Close file
fclose(fileID);
disp('File written successfully.');

