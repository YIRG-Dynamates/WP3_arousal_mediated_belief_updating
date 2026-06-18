


%B2 PLOTTING THE FITS AND THE PUPIL TRACE

clear all

load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\fittingPRF_vers2023_01082024\delta_amplitudes_PRF_2023.mat')
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\fittingPRF_vers2023_01082024\fit_results_PRF_2023.mat')
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\preprocessed_eye_data_motion_version_12_07_2024.mat')
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat');

data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data';
load(fullfile(data_folder, "LATENT VARS/", "BdCPfitResults_4_latent_vars_2.mat")); %nr 4 is the same one but with medians

load(fullfile(data_folder, "preprocessing_version_12_07_2024/", "included_sounds_motion.mat"));



%excl the people from the latents
surprisal = surprisal.med(:,6:end);
infogain = info_gain.med(:,6:end);
post_d = post_d.med(:,6:end);
prior_d = prior_d.med(:,6:end);

save_folder = "C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\TRIAL_PLOTS_2026"

%% 
experiment = 'motion'

tic
for subject = 1:22
    trial = 1
    for fignum = 1:50


            % plotting function main
            plot_pupiltrace_latents_location_motion(subject, trial, fignum, preprocessed_eye_data, surprisal, infogain, trials_cell_all, delta_amps_all_motion, PRFfitResults_motion, included_sounds, prior_d, post_d)


            trial = trial + 1;
        
            sgtitle([experiment ' subject ' subj_nrs{subject}])
            %fig = figure;

            width_i = 800;   % pixels
            height_i = 1600;  % pixels
            left_i = 100;    % pixels from left
            bottom_i = 100;  % pixels from bottom
            set(gcf, 'Position', [left_i bottom_i width_i height_i]);
            %set(gcf, 'Position', get(0, 'Screensize'));

            saveas(gcf, [fullfile(save_folder, [subj_nrs{subject},'_' ,'trial', num2str(trial), '.png'])]);
            close all

    end
end
toc


%% plot specific one

subject = 21;
trial = 42;

fignum = 1;

plot_pupiltrace_latents_location_motion(subject, trial, fignum, preprocessed_eye_data, surprisal, infogain, trials_cell_all, delta_amps_all_motion, PRFfitResults_motion, included_sounds, prior_d, post_d)
 
width_i = 800;   % pixels
height_i = 2000;  % pixels
left_i = 30;    % pixels from left
bottom_i = 30;  % pixels from bottom
set(gcf, 'Position', [left_i bottom_i width_i height_i]);
%set(gcf, 'Position', get(0, 'Screensize'));

 saveas(gcf, [fullfile(save_folder, [subj_nrs{subject},'_' ,'trial', num2str(trial), '.png'])]);
