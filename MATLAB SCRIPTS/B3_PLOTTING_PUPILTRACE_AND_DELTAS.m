%B2 PLOTTING THE FITS AND THE PUPIL TRACE

clear all

load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\fittingPRF_vers2023_01082024\delta_amplitudes_PRF_2023.mat')
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\fittingPRF_vers2023_01082024\fit_results_PRF_2023.mat')
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\preprocessed_eye_data_motion_version_12_07_2024.mat')
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat');

data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data';
load(fullfile(data_folder, "LATENT VARS/", "BdCPfitResults_4_latent_vars_2.mat")); %nr 4 is the same one but with medians

%excl the people from the latents
surprisal = surprisal.med(:,6:end);
infogain = info_gain.med(:,6:end);


save_folder = "C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\TRIAL_PLOTS";
%% 
experiment = 'motion'

tic
for subject = 1:22
    trial = 1
    for p = 1:50


            % stimulus times and deltas
            s_times = preprocessed_eye_data{trial, subject}.A_stim_times
            s_deltas = delta_amps_all_motion{trial, subject}


            figure(p)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            subplot(2,1,1)
            hold on
            
            %basically a baseline
            add_mean = mean(mean(preprocessed_eye_data{trial, subject}.pupilSize) ); % just to plot them all on the same height -50/100 for visibility

            %plot prediction and response and raw
            plot(PRFfitResults_motion{1, subject}.predictions{trial, 1}.y_pred + add_mean, 'color','r' );
            plot(PRFfitResults_motion{1, subject}.data.responses{trial, 1} + add_mean - 50 , 'color','b');
            plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','c');

            
            % stimulus times 
            plot(s_times, zeros(1, length(s_times))+3500, 'color','k', 'LineStyle', '-', 'Marker', 'o'  );

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

       
            % again better visible after the missing periods are filled in
            plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','c');

            % cutoff, under and on the right of here data is excluded
            yline(3200, 'color','k');
            xline(1500, 'color','k')

            % shade pink areas that are out nevertheless
            area([0 1500], [yLimits(2) yLimits(2)], FaceColor="m", FaceAlpha=.2, EdgeColor='none');
            xLimits = get(gca,'XLim');
            area([1500 xLimits(2)], [3200 3200], FaceColor="m", FaceAlpha=.2, EdgeColor='none');

            

            % limits 
            xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);

            if max(preprocessed_eye_data{trial, subject}.pupilSize)+300 < 3000
                ylim([10 20])
            else
                ylim([3000 max(preprocessed_eye_data{trial, subject}.pupilSize)+300])
            end

            % axis
            xlabel("time (ms)")
            ylabel("pupil dilation (AU)")

            title(['trial ', num2str(trial)]);
            legend('predicted', 'preprocessed', 'raw', 'stimulus times', Location='southeast')
            hold off


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            subplot(2,1,2)

            hold on

            % plot times
            plot(s_times, zeros(1, length(s_times)), 'color','k', 'LineStyle', '-', 'Marker', 'o'  );

            % plot delta values
            scatter(s_times, ...
                s_deltas , 'color','k', 'Marker', 'o' );

            % plot lines
            for num_stim = 1:length(s_times)
                line([s_times(num_stim) s_times(num_stim)], [0 s_deltas(num_stim)], 'Color', 'r', 'LineWidth', 2);
            end
            
            % this is just so th eöengths of the plots align
            xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
            ylim([min(s_deltas)-50 max(s_deltas)+50])

            % axises
            xlabel("time (ms)")
            ylabel("pupil gain")
            
            % area before we trust
            xline(1500, 'color','k')

            % shade pink areas that are out nevertheless
            yLimits = get(gca,'YLim');
            area([0 1500], [yLimits(2) yLimits(2)], FaceColor="m", FaceAlpha=.2, EdgeColor='none');
            area([0 1500], [yLimits(1) yLimits(1)], FaceColor="m", FaceAlpha=.2, EdgeColor='none');

            hold off

            trial = trial + 1;
        

            sgtitle([experiment ' subject ' subj_nrs{subject}])
            %fig = figure;

            width_i = 800;   % pixels
            height_i = 600;  % pixels
            left_i = 100;    % pixels from left
            bottom_i = 100;  % pixels from bottom
            set(gcf, 'Position', [left_i bottom_i width_i height_i]);
            %set(gcf, 'Position', get(0, 'Screensize'));

            saveas(gcf, [fullfile(save_folder, [subj_nrs{subject},'_' ,'trial', num2str(trial), '.png'])]);
            close all

    end
end
toc


%% plotting a specific one


subject = 21 % subject number 40
trial = 42


p = 1;
experiment = 'motion';

% stimulus times and deltas
s_times = preprocessed_eye_data{trial, subject}.A_stim_times;
s_deltas = delta_amps_all_motion{trial, subject};

%figure(p);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SUBPLOT 1
subplot(5,1,1);
figure(1)
hold on;

% plot the main data first for the legend
add_mean = mean(mean(preprocessed_eye_data{trial, subject}.pupilSize));
plot(PRFfitResults_motion{1, subject}.predictions{trial, 1}.y_pred + add_mean, 'color','r');
plot(PRFfitResults_motion{1, subject}.data.responses{trial, 1} + add_mean - 50, 'color','b');
plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','m');
% plot(s_times, zeros(1, length(s_times))+5000, 'color','k', 'LineStyle', '-', 'Marker', 'o');


% First plot the pink background areas
yLimits = [3000 max(preprocessed_eye_data{trial, subject}.pupilSize)+300]; % Initialize

% Plot excluded areas first (so they stay behind)
if ~isempty(preprocessed_eye_data{trial, subject}.missing_periods)
    for p = 1:height(preprocessed_eye_data{trial, subject}.missing_periods)
        area(preprocessed_eye_data{trial, subject}.missing_periods(p,:), ...
            [yLimits(2) yLimits(2)], ...
            'FaceColor', '#FFCCE6', 'EdgeColor', 'none', 'FaceAlpha', 1);
    end
end

% Plot other pink exclusion areas
area([0 1500], [yLimits(2) yLimits(2)], 'FaceColor', '#FFCCE6', 'EdgeColor', 'none');
xLimits = get(gca,'XLim');
area([1500 xLimits(2)], [3200 3200], 'FaceColor', '#FFCCE6', 'EdgeColor', 'none');
end_i = length(preprocessed_eye_data{trial, subject}.pupilSize);
area([end_i-1500 end_i], [yLimits(2) yLimits(2)], 'FaceColor', '#FFCCE6', 'EdgeColor', 'none');

% Now plot the main data (on top of pink areas)
add_mean = mean(mean(preprocessed_eye_data{trial, subject}.pupilSize));
plot(PRFfitResults_motion{1, subject}.predictions{trial, 1}.y_pred + add_mean, 'color','r');
plot(PRFfitResults_motion{1, subject}.data.responses{trial, 1} + add_mean - 50, 'color','b');
plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','m');
% plot(s_times, zeros(1, length(s_times))+5000, 'color','k', 'LineStyle', '-', 'Marker', 'o');

% Plot interp periods on top
if ~isempty(preprocessed_eye_data{trial, subject}.interp_periods)
    xline(preprocessed_eye_data{trial, subject}.interp_periods(:,1), 'color','#A9A9A9', 'LineStyle', '-');
    xline(preprocessed_eye_data{trial, subject}.interp_periods(:,2), 'color','#A9A9A9', 'LineStyle', '--');
end

% Set limits
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
ylim([5000 max(preprocessed_eye_data{trial, subject}.pupilSize)+50])

% Labels and legend
xlabel("time (ms)");
ylabel("pupil dilation (AU)");
%title(['trial ', num2str(trial)]);
legend('predicted', 'preprocessed', 'raw', Location='southeast');

% Critical fix: Bring axes to top
set(gca, 'Layer', 'top');
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(5,1,2);
%figure(2)
hold on;

% First get proper y-limits
yl = [min(s_deltas)-50 max(s_deltas)+50];

% Plot pink background areas first (so they stay behind everything)
fill_color = [1 0.8 0.9]; % Light pink RGB

% Plot exclusion zones
fill([0 1500 1500 0], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');
end_i = length(preprocessed_eye_data{trial, subject}.pupilSize);
fill([end_i-1500 end_i end_i end_i-1500], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');

if ~isempty(preprocessed_eye_data{trial, subject}.missing_periods)
    for p = 1:height(preprocessed_eye_data{trial, subject}.missing_periods)
        x1 = preprocessed_eye_data{trial, subject}.missing_periods(p,1);
        x2 = preprocessed_eye_data{trial, subject}.missing_periods(p,2);
        fill([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');
    end
end

% Now plot data on top
scatter(s_times, s_deltas, 'color','k', 'Marker', 'o');
plot(s_times, zeros(1, length(s_times)), 'color','k', 'LineStyle', '-');

% vertical lines to data
for num_stim = 1:length(s_times)
    if s_times(num_stim) ~= 0
        line([s_times(num_stim) s_times(num_stim)], [0 s_deltas(num_stim)], 'Color', 'k', 'LineWidth', 2);
    end
end

% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
ylim(yl);
xlabel("time (ms)");
ylabel("pupil gain");

ax = gca;

% Method 1: Try modern MATLAB approach first
try
    ax.YAxis.Axle.Visible = 'off';  % Hide y=0 line
catch
    % Method 2: Fallback for older versions
    ax.YColor = 'none';  % Hide entire y-axis
    ax.XColor = 'k';     % Keep x-axis visible
    ax.Color = 'none';   % Transparent background
    
    % Add back y-axis ticks and labels
    ax.YTickLabelMode = 'auto';
    ax.YColor = 'k';     % Make y-axis elements visible again
end

% Ensure axes stay on top
set(gca, 'Layer', 'top');

hold off;

% =================================== LOCATIONS OF STIMULI
subplot(5,1,3);

%figure(3)

hold on
locations_trial = trials_cell_all{trial, subject}.x  ;

% First get proper y-limits
yl = [-40 40];

% Plot pink background areas first (so they stay behind everything)
fill_color = [1 0.8 0.9]; % Light pink RGB

% Plot exclusion zones
fill([0 1500 1500 0], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');
end_i = length(preprocessed_eye_data{trial, subject}.pupilSize);
fill([end_i-1500 end_i end_i end_i-1500], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');

if ~isempty(preprocessed_eye_data{trial, subject}.missing_periods)
    for p = 1:height(preprocessed_eye_data{trial, subject}.missing_periods)
        x1 = preprocessed_eye_data{trial, subject}.missing_periods(p,1);
        x2 = preprocessed_eye_data{trial, subject}.missing_periods(p,2);
        fill([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');
    end
end

scatter(s_times, locations_trial, 'color','k', 'Marker', 'o');
plot(s_times, locations_trial);
yline(0);

% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
ylim(yl);
xlabel("time (ms)");
ylabel("location (degree azimuth)");

ax = gca;
% Method 1: Try modern MATLAB approach first
try
    ax.YAxis.Axle.Visible = 'off';  % Hide y=0 line
catch
    % Method 2: Fallback for older versions
    ax.YColor = 'none';  % Hide entire y-axis
    ax.XColor = 'k';     % Keep x-axis visible
    ax.Color = 'none';   % Transparent background
    
    % Add back y-axis ticks and labels
    ax.YTickLabelMode = 'auto';
    ax.YColor = 'k';     % Make y-axis elements visible again
end

% Ensure axes stay on top
set(gca, 'Layer', 'top');
hold off;


% =================================== SURPRISAL OF STIMULI
subplot(5,1,4);

%figure(4)

hold on
surprisal_trial = surprisal{trial, subject};

% First get proper y-limits
yl = [min(surprisal_trial) max(surprisal_trial)];
yl = [0 yl(2)*1.05]

% Plot pink background areas first (so they stay behind everything)
fill_color = [1 0.8 0.9]; % Light pink RGB

% Plot exclusion zones
fill([0 1500 1500 0], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');
end_i = length(preprocessed_eye_data{trial, subject}.pupilSize);
fill([end_i-1500 end_i end_i end_i-1500], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');

if ~isempty(preprocessed_eye_data{trial, subject}.missing_periods)
    for p = 1:height(preprocessed_eye_data{trial, subject}.missing_periods)
        x1 = preprocessed_eye_data{trial, subject}.missing_periods(p,1);
        x2 = preprocessed_eye_data{trial, subject}.missing_periods(p,2);
        fill([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');
    end
end

s_times_2forward = s_times(2:end);
stairs((s_times_2forward), surprisal_trial, 'color','k', 'Marker', 'o');

% vertical lines to data
% for num_stim = 1:length(s_times_2forward)
%     if s_times_2forward(num_stim) ~= 0
%         line([s_times_2forward(num_stim) s_times_2forward(num_stim)], [0 surprisal_trial(num_stim)], 'Color', 'k', 'LineWidth', 2);
%     end
% end



% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
ylim(yl);
xlabel("time (ms)");
ylabel("surprisal (AU)");

ax = gca;
% Method 1: Try modern MATLAB approach first
try
    ax.YAxis.Axle.Visible = 'off';  % Hide y=0 line
catch
    % Method 2: Fallback for older versions
    ax.YColor = 'none';  % Hide entire y-axis
    ax.XColor = 'k';     % Keep x-axis visible
    ax.Color = 'none';   % Transparent background
    
    % Add back y-axis ticks and labels
    ax.YTickLabelMode = 'auto';
    ax.YColor = 'k';     % Make y-axis elements visible again
end

% Ensure axes stay on top
set(gca, 'Layer', 'top');
hold off;


% =================================== INFOGAIN OF STIMULI
subplot(5,1,5);

%figure(5)

hold on
infogain_trial = infogain{trial, subject};

% First get proper y-limits
yl = [min(infogain_trial) max(infogain_trial)];
yl = [0 yl(2)*1.05]

% Plot pink background areas first (so they stay behind everything)
fill_color = [1 0.8 0.9]; % Light pink RGB

% Plot exclusion zones
fill([0 1500 1500 0], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');
end_i = length(preprocessed_eye_data{trial, subject}.pupilSize);
fill([end_i-1500 end_i end_i end_i-1500], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');

if ~isempty(preprocessed_eye_data{trial, subject}.missing_periods)
    for p = 1:height(preprocessed_eye_data{trial, subject}.missing_periods)
        x1 = preprocessed_eye_data{trial, subject}.missing_periods(p,1);
        x2 = preprocessed_eye_data{trial, subject}.missing_periods(p,2);
        fill([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], fill_color, 'EdgeColor', 'none');
    end
end

s_times_2forward = s_times(2:end);

% vertical lines to data
% for num_stim = 1:length(s_times_2forward)
%     if s_times_2forward(num_stim) ~= 0
%         line([s_times_2forward(num_stim) s_times_2forward(num_stim)], [0 surprisal_trial(num_stim)], 'Color', 'k', 'LineWidth', 2);
%     end
% end
stairs((s_times_2forward), infogain_trial, 'color','k', 'Marker', 'o');



% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
ylim(yl);
xlabel("time (ms)");
ylabel("infogain (AU)");

ax = gca;
% Method 1: Try modern MATLAB approach first
try
    ax.YAxis.Axle.Visible = 'off';  % Hide y=0 line
catch
    % Method 2: Fallback for older versions
    ax.YColor = 'none';  % Hide entire y-axis
    ax.XColor = 'k';     % Keep x-axis visible
    ax.Color = 'none';   % Transparent background
    
    % Add back y-axis ticks and labels
    ax.YTickLabelMode = 'auto';
    ax.YColor = 'k';     % Make y-axis elements visible again
end

% Ensure axes stay on top
set(gca, 'Layer', 'top');
hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVING

width_i = 800;   % pixels
height_i = 1200;  % pixels
left_i = 100;    % pixels from left
bottom_i = 100;  % pixels from bottom
set(gcf, 'Position', [left_i bottom_i width_i height_i]);
%set(gcf, 'Position', get(0, 'Screensize'));

saveas(gcf, "G:\My Drive\WORK\PUBLICATIONS\WP3 MANUSCRIPT\PLOTS\EXEMPL_TRACES.svg");
saveas(gcf, "G:\My Drive\WORK\PUBLICATIONS\WP3 MANUSCRIPT\PLOTS\EXEMPL_TRACES.png");
