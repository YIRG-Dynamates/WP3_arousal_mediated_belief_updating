%%% FITTING OLD PROCEDURE (but its the one were going with)

%% initialize
clear all

data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data';
mkdir(data_folder, 'fitting_2023version_12_07_2024');
save_folder = fullfile(data_folder, "fitting_2023version_12_07_2024/");
prep_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data\preprocessing_version_12_07_2024'

addpath(genpath('C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2023'))
addpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\functions")

experiment = 'tempo'
%% Fit! --> make this prettier

load(fullfile(prep_folder, 'preprocessed_eye_data_tempo_version_12_07_2024.mat'));
load(fullfile(data_folder,'subj_nrs.mat'),'num_subj','subj_nrs');
i_subj_2_exclude = false(1, num_subj) %dummy, because we include all
i_trial_2_exclude = false(200, num_subj) %dummy, ecause we include all

num_trials = 200;

[delta_amps_all_tempo, PRFfitResults_tempo] = fit_models_RF(preprocessed_eye_data,subj_nrs,save_folder,i_subj_2_exclude,i_trial_2_exclude); 

%% SAVING (last saved 14.07.2024)

save(fullfile(save_folder,'2024_07_11_fit_results_PRF_2023version.mat'),'PRFfitResults_tempo','-v7.3');
save(fullfile(save_folder,'2024_07_11_delta_amplitudes_PRF_2023version.mat'),'delta_amps_all_tempo','num_subj','num_trials','i_subj_2_exclude','i_trial_2_exclude','subj_nrs');


%% fit without intercept

load(fullfile(prep_folder, 'preprocessed_eye_data_tempo_version_12_07_2024.mat'));
load(fullfile(data_folder,'subj_nrs.mat'),'num_subj','subj_nrs');
num_trials = 200;

mkdir(data_folder, 'fittingPRF_vers2023_02082024');
save_folder = fullfile(data_folder, "fittingPRF_vers2023_02082024/");

%make sure correct model is on path and other one is removed
rmpath(genpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2024"))
addpath(genpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2023"))

% fit
[delta_amps_all_teempo, PRFfitResults_tempo] = fit_models_2023_RF(preprocessed_eye_data,subj_nrs,save_folder); 

% SAVING
save(fullfile(save_folder,'fit_results_PRF_2023.mat'),'PRFfitResults_tempo','-v7.3');
save(fullfile(save_folder,'delta_amplitudes_PRF_2023.mat'),'delta_amps_all_tempo','num_subj','num_trials','subj_nrs');


%% fit 2024 autoregression

mkdir(data_folder, 'fittingPRF_vers2024_01082024');
save_folder = fullfile(data_folder, "fittingPRF_vers2024_01082024/");

load(fullfile(prep_folder, 'preprocessed_eye_data_tempo_version_12_07_2024.mat'));
load(fullfile(data_folder,'subj_nrs.mat'),'num_subj','subj_nrs');

num_trials = 200;

%make sure correct model is on path and other one is removed
addpath(genpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2024"))
rmpath(genpath("C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\pupil_model\PRFfitModel2023"))

%fitting lets go!
tic
PRFfitResults_tempo = fit_models_2024_RF(preprocessed_eye_data,subj_nrs,save_folder); 
toc

save(fullfile(save_folder,'fit_results_PRF_2024_autoregression.mat'),'PRFfitResults_tempo','num_subj','num_trials', 'subj_nrs');

%% Plot to check (plotted 17.07.24)

tic
for subject = 1:num_subj
    trial = 1
    for p = 1:50

        figure(p)

        for j = 1:4

            subplot(2,2,j)
            hold on

            % plot(PRFfitResults_danger{1, subject}.predictions{trial, 1}.y_pred + mean(preprocessed_eye_data{trial, subject}.pupilSize), 'color', 'b'  )
            % plot(preprocessed_eye_data{trial, subject}.pupilSize -50,'color', 'g');
            add_mean = mean(mean(preprocessed_eye_data{trial, subject}.pupilSize) ); % just to plot them all on the same height -50/100 for visibility
            %plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','c');
            plot(PRFfitResults_tempo{1, subject}.predictions{trial, 1}.y_pred + add_mean, 'color','r' );
            plot(PRFfitResults_tempo{1, subject}.data.responses{trial, 1} + add_mean - 50 , 'color','b');
            plot(preprocessed_eye_data{trial, subject}.A_stim_times, ...
                zeros(1, length(preprocessed_eye_data{trial, subject}.A_stim_times))+3000, 'color','k', 'LineStyle', '-', 'Marker', 'o' );


            if ~isempty(preprocessed_eye_data{trial, subject}.interp_periods);
                xline(preprocessed_eye_data{trial, subject}.interp_periods(:,1), 'color','m',  'LineStyle', '-');
                xline(preprocessed_eye_data{trial, subject}.interp_periods(:,2), 'color','m', 'LineStyle', '--');
            end

            if ~isempty(preprocessed_eye_data{trial, subject}.missing_periods);
                xline(preprocessed_eye_data{trial, subject}.missing_periods(:,1), 'color','m',  'LineStyle', '-');
                xline(preprocessed_eye_data{trial, subject}.missing_periods(:,2),'color', 'm',  'LineStyle', '--');

                %mark trustworthy areas vs non-trustworthy (pink shading for exclude)
                for p = 1:height(preprocessed_eye_data{trial, subject}.missing_periods);
                    yLimits = get(gca,'YLim');
                    area(preprocessed_eye_data{trial, subject}.missing_periods(p,:), [yLimits(2) yLimits(2)], FaceColor="m", FaceAlpha=.2, EdgeColor='none');
                end

            end

           
            % better visible after the missing periods are filled in
            plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','c');

            % cutoff, under and on the right of here data is excluded
            yline(3200, 'color','k');
            xline(1500, 'color','k')

            xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);

            title(['trial ', num2str(trial)]);
            legend('raw', 'pred', 'preproc', Location='southeast')
            hold off


            trial = trial + 1;
        end

        sgtitle([experiment ' subject ' subj_nrs{subject}])
        %fig = figure;

        set(gcf, 'Position', get(0, 'Screensize'));
        saveas(gcf, [fullfile(save_folder, subj_nrs(subject),[subj_nrs{subject},'_' ,'trial', num2str(trial-4), '-', num2str(trial-1), '.png'])]);
        close all

    end
end
toc