

function plot_pupiltrace_latents_location_motion = plot_pupiltrace_latents_location_motion(subject, trial, fignum, preprocessed_eye_data, surprisal, infogain, trials_cell_all, delta_amps_all_motion, PRFfitResults_motion, included_sounds, prior_d, post_d )


% stimulus times and deltas
s_times = preprocessed_eye_data{trial, subject}.A_stim_times;
s_deltas = delta_amps_all_motion{trial, subject};


sac1_idx = included_sounds{trial, subject}.SAC_level  == 1;
sac1_idx(1:2) = 0;


%figure(p);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SUBPLOT 1
subplot(7,1,1);
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

if max(preprocessed_eye_data{trial, subject}.pupilSize)+50 < 5000;
    ylim([5000 8000])
else
    ylim([5000 max(preprocessed_eye_data{trial, subject}.pupilSize)+50])
end

% Labels and legend
xlabel("time (ms)");
ylabel("pupil dilation (AU)");
%title(['trial ', num2str(trial)]);
legend('predicted', 'preprocessed', 'raw', Location='southeast');

% Critical fix: Bring axes to top
set(gca, 'Layer', 'top');
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(7,1,2);
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
subplot(7,1,3);

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

% this little batch adds vertical lines for SAC1
for timepoint = 1:length(s_times)
    disp(timepoint)

    if sac1_idx(timepoint) == 1
        disp(sac1_idx(timepoint) == 1)
        disp('true')
        xline(s_times(timepoint))
    end

end


% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
ylim(yl);
xlabel("time (ms)");
ylabel("location (deg. azimuth)");

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
subplot(7,1,4);

%figure(4)

hold on
surprisal_trial = surprisal{trial, subject};
surprisal_trial = surprisal_trial - min(surprisal_trial) ; %baselining for easier plotting

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

% this little batch adds vertical lines for SAC1
for timepoint = 1:length(s_times)
    disp(timepoint)

    if sac1_idx(timepoint) == 1
        disp(sac1_idx(timepoint) == 1)
        disp('true')
        xline(s_times(timepoint))
    end

end

% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
if yl(1) < yl(2)
    ylim(yl);
else
end

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
subplot(7,1,5);

%figure(5)

hold on
infogain_trial = infogain{trial, subject};
infogain_trial = infogain_trial - min(infogain_trial);

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

% this little batch adds vertical lines for SAC1
for timepoint = 1:length(s_times)
    disp(timepoint)

    if sac1_idx(timepoint) == 1
        disp(sac1_idx(timepoint) == 1)
        disp('true')
        xline(s_times(timepoint))
    end

end

% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);

if yl(1) < yl(2)
    ylim(yl);
else
end

% this little batch adds vertical lines for SAC1
for timepoint = 1:length(s_times)
    disp(timepoint)

    if sac1_idx(timepoint) == 1
        disp(sac1_idx(timepoint) == 1)
        disp('true')
        xline(s_times(timepoint))
    end
end

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


% =================================== PRIOR D OF STIMULI


subplot(7,1,6);

%figure(5)

hold on
prior_d_trial = prior_d{trial, subject};

% First get proper y-limits
yl = [min(prior_d_trial) max(prior_d_trial)];


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
stairs((s_times_2forward), prior_d_trial, 'color','k', 'Marker', 'o');
yline(0);

% this little batch adds vertical lines for SAC1
for timepoint = 1:length(s_times)
    disp(timepoint)

    if sac1_idx(timepoint) == 1
        disp(sac1_idx(timepoint) == 1)
        disp('true')
        xline(s_times(timepoint))
    end
end

% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);

if yl(1) < yl(2)
    ylim(yl);
else
end


xlabel("time (ms)");
ylabel("prior d");

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


% =================================== POST D OF STIMULI


subplot(7,1,7);

%figure(5)

hold on
priorpost_d_d_trial = post_d{trial, subject};

% First get proper y-limits
yl = [min(priorpost_d_d_trial) max(priorpost_d_d_trial)];


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
stairs((s_times_2forward), priorpost_d_d_trial, 'color','k', 'Marker', 'o');

yline(0);

% this little batch adds vertical lines for SAC1
for timepoint = 1:length(s_times)
    disp(timepoint)

    if sac1_idx(timepoint) == 1
        disp(sac1_idx(timepoint) == 1)
        disp('true')
        xline(s_times(timepoint))
    end
end

% Set limits and labels
xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);

if yl(1) < yl(2)
    ylim(yl);
else
end


xlabel("time (ms)");
ylabel("post d");

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

end %eof