%%% FITTING OLD PROCEDURE (but its the one were going with)

%% initialize
clear all

data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data';
%mkdir(data_folder, 'fitting_2023version_12_07_2024');
%save_folder = fullfile(data_folder, "fitting_2023version_12_07_2024/");
prep_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024'

%save_folder = "C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\PREP3_folder"
%save_path = "C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\PREP3_folder"

addpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\functions")

experiment = 'motion'

%% Fit! 2023 Version, without intercept
% 
load(fullfile(prep_folder, 'preprocessed_eye_data_motion_version_12_07_2024.mat'));
load(fullfile(data_folder,'subj_nrs.mat'),'num_subj','subj_nrs');

num_trials = 200;

mkdir(data_folder, 'fittingPRF_vers2023_01082024');
save_folder = fullfile(data_folder, "fittingPRF_vers2023_01082024/");

%make sure correct model is on path and other one is removed
rmpath(genpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2024"))
addpath(genpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2023"))

%Fit w/ or wothout intercept (check the function)
[delta_amps_all_motion,PRFfitResults_motion] = fit_models_2023_RF(preprocessed_eye_data,subj_nrs,save_folder); 

% SAVING
save(fullfile(save_folder,'fit_results_PRF_2023.mat'),'PRFfitResults_motion','-v7.3');
save(fullfile(save_folder,'delta_amplitudes_PRF_2023.mat'),'delta_amps_all_motion','num_subj','num_trials','subj_nrs');

%% Fit with intercept (set to zero!)
% this part is already done in "C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\fitting_2023version_12_07_2024"
% but probably has to be cleaned up a little
%
% 
% [delta_amps_all_motion,PRFfitResults_motion] = fit_models_RF_noInt(preprocessed_eye_data,subj_nrs,save_folder_fit2,i_subj_2_exclude,i_trial_2_exclude); 
% 

%% Fit without delta, only boxcar, Autoregression (31.07.24)
% fitted only without subject 22, and without hipasfiltering: has to be
% done again, but for now its good enough

mkdir(data_folder, 'fittingPRF_vers2024_01082024');
save_folder = fullfile(data_folder, "fittingPRF_vers2024_01082024/");

load(fullfile(prep_folder, 'preprocessed_eye_data_motion_version_12_07_2024.mat'));
load(fullfile(data_folder,'subj_nrs.mat'),'num_subj','subj_nrs');

num_trials = 200;

%make sure correct model is on path and other one is removed
addpath(genpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2024"))
rmpath(genpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2023"))

%fitting lets go!
tic
PRFfitResults_motion = fit_models_2024_RF(preprocessed_eye_data,subj_nrs,save_folder); 
toc

save(fullfile(save_folder,'fit_results_PRF_2024_autoregression.mat'),'PRFfitResults_motion','num_subj','num_trials', 'subj_nrs');


%% Plot to check (takes forever, done 16.07.24) --> with intercept
% tic
% for subject = 1:22
%     trial = 1
%     for p = 1:50
% 
%         figure(p)
% 
%         for j = 1:4
% 
%             subplot(2,2,j)
%             hold on
% 
%             % plot(PRFfitResults_danger{1, subject}.predictions{trial, 1}.y_pred + mean(preprocessed_eye_data{trial, subject}.pupilSize), 'color', 'b'  )
%             % plot(preprocessed_eye_data{trial, subject}.pupilSize -50,'color', 'g');
%             add_mean = mean(mean(preprocessed_eye_data{trial, subject}.pupilSize) ); % just to plot them all on the same height -50/100 for visibility
%             %plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','c');
%             plot(PRFfitResults_motion{1, subject}.predictions{trial, 1}.y_pred + add_mean, 'color','r' );
%             plot(PRFfitResults_motion{1, subject}.data.responses{trial, 1} + add_mean - 50 , 'color','b');
%             plot(preprocessed_eye_data{trial, subject}.A_stim_times, ...
%                 zeros(1, length(preprocessed_eye_data{trial, subject}.A_stim_times))+3000, 'color','k', 'LineStyle', '-', 'Marker', 'o' );
% 
% 
%             if ~isempty(preprocessed_eye_data{trial, subject}.interp_periods);
%                 xline(preprocessed_eye_data{trial, subject}.interp_periods(:,1), 'color','m',  'LineStyle', '-');
%                 xline(preprocessed_eye_data{trial, subject}.interp_periods(:,2), 'color','m', 'LineStyle', '--');
%             end
% 
%             if ~isempty(preprocessed_eye_data{trial, subject}.missing_periods);
%                 xline(preprocessed_eye_data{trial, subject}.missing_periods(:,1), 'color','m',  'LineStyle', '-');
%                 xline(preprocessed_eye_data{trial, subject}.missing_periods(:,2),'color', 'm',  'LineStyle', '--');
% 
%                 %mark trustworthy areas vs non-trustworthy (pink shading for exclude)
%                 for p = 1:height(preprocessed_eye_data{trial, subject}.missing_periods);
%                     yLimits = get(gca,'YLim');
%                     area(preprocessed_eye_data{trial, subject}.missing_periods(p,:), [yLimits(2) yLimits(2)], FaceColor="m", FaceAlpha=.2, EdgeColor='none');
%                 end
% 
%             end
% 
% 
%             % better visible after the missing periods are filled in
%             plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','c');
% 
%             % cutoff, under and on the right of here data is excluded
%             yline(3200, 'color','k');
%             xline(1500, 'color','k')
% 
%             xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
% 
%             title(['trial ', num2str(trial)]);
%             legend('raw', 'pred', 'preproc', Location='southeast')
%             hold off
% 
% 
%             trial = trial + 1;
%         end
% 
%         sgtitle([experiment ' subject ' subj_nrs{subject}])
%         %fig = figure;
% 
%         set(gcf, 'Position', get(0, 'Screensize'));
%         saveas(gcf, [fullfile(save_folder, subj_nrs(subject),[subj_nrs{subject},'_' ,'trial', num2str(trial-4), '-', num2str(trial-1), '.png'])]);
%         close all
% 
%     end
% end
% toc


