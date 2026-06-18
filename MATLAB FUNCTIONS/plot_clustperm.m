function plot_clustperm = plot_clustperm(fignum, mean_trace0, mean_trace1, sem_trace0, sem_trace1, logical_pos, high_color, low_color, sign_color)


%% this is all needed to plot the shaded area of the significant clusters
% becvause im bad at coding
logical_mask = zeros(1,4000)
logical_mask(end-2500:end) = logical_pos;

shade = double(logical_mask);         % Convert logical to double
shade(shade == 0) = NaN;              % Set 0s to NaN so they're not plotted

x = (length(mean_trace0)-2501)*(-1):2500;  % Time vector to end at 2500 exactly
%yLimits = [-0.14 0.16];  % Y-axis limits
yLimits = [-500 500];  % Y-axis limits

% Find contiguous regions where shade is not NaN (i.e., mask is active)
in_region = false;
start_idx = 0;

%%

figure(fignum); clf;
hold on;

% Loop over and shade all contiguous regions
for i = 1:length(shade)
    if ~isnan(shade(i)) && ~in_region
        in_region = true;
        start_idx = i;
    elseif isnan(shade(i)) && in_region
        in_region = false;
        stop_idx = i - 1;
        x_fill = [x(start_idx) x(stop_idx) x(stop_idx) x(start_idx)];
        y_fill = [yLimits(1) yLimits(1) yLimits(2) yLimits(2)];
        fill(x_fill, y_fill, sign_color, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    end
end

% Catch case where region extends to end
if in_region
    x_fill = [x(start_idx) x(end) x(end) x(start_idx)];
    y_fill = [yLimits(1) yLimits(1) yLimits(2) yLimits(2)];
    fill(x_fill, y_fill, sign_color, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
end

% Plot shaded SEMs
fill([x fliplr(x)], [mean_trace0 - sem_trace0, fliplr(mean_trace0 + sem_trace0)], ...
    low_color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

fill([x fliplr(x)], [mean_trace1 - sem_trace1, fliplr(mean_trace1 + sem_trace1)], ...
    high_color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% Plot means
plot(x, mean_trace0, 'Color', low_color, 'LineWidth', 2);
plot(x, mean_trace1, 'Color',  high_color, 'LineWidth', 2);

hold off;

end %eof
