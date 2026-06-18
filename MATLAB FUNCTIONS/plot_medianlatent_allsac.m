
function plot_medianlatent_allsac = plot_medianlatent_allsac(fignum, latent, correct, SAC, latenttext, exptext, col_var, abscissa)
%%% FUNCTION STARTS FROM HERE

% ========= set tresholds per person! ===============
% tresholds only within SAC = sac_var at the end
latent_tresh = [];
latent_end = cellfun(@(s) s(end), latent);

for sac_var = 1:5

    latent_end_SAC = latent_end;
    % latent_end_SAC(SAC > sac_var) = NaN;
    latent_end_SAC(SAC ~= sac_var) = NaN;
    latent_tresh(sac_var, :) = median(latent_end_SAC, 1, 'omitnan');
end
% per row (SAC level) and colulmn (subject) a treshold for the median
% clustering



% ========= make logicals ===============

means_over_tresh = [];
means_under_tresh = [];


for sac_var = 1:5;
    %sac_var = 1;
    
    SAC_logical = SAC == sac_var; % value  means this trial ends on respective SAC
    
    matrix_tresh_placeholder = NaN(size(latent));
    for sbj = 1:width(latent)

        trials = latent_end(:,sbj) >= latent_tresh(sac_var, sbj); %chose the right treshold per sac and sbj
        matrix_tresh_placeholder(trials,sbj) = 1;

        trials = latent_end(:,sbj) < latent_tresh(sac_var, sbj); %overwrite the other way around
        matrix_tresh_placeholder(trials,sbj) = 0;
    
    
    end
    
    latent_larger_than_tresh = logical(matrix_tresh_placeholder);
    
    % ================= combine logicals ===================
    
    logical_SAC_over_tresh = latent_larger_than_tresh & SAC_logical;
    
    logical_SAC_under_tresh = ~latent_larger_than_tresh & SAC_logical;
    
    % ================= apply logicals + calc meaans ===================
    
    %means_over_tresh = [];
    %means_under_tresh = [];
    
    for sbj = 1:width(latent)
    
        rows = []; array_temp = [];
        rows = logical_SAC_over_tresh(:,sbj);
        array_temp = correct(rows,sbj);
        array_temp = array_temp(~isnan(array_temp));
        means_over_tresh(sbj, sac_var) = sum(array_temp) / length(array_temp);
    
        rows = []; array_temp = [];
        rows = logical_SAC_under_tresh(:,sbj);
        array_temp = correct(rows,sbj);
        array_temp = array_temp(~isnan(array_temp));
        means_under_tresh(sbj, sac_var) = sum(array_temp) / length(array_temp);
    
    end
end


% ========================== calc SEM and mean(mean) ==============

% Mean across subjects (per sac level)
t_over_mean  = mean(means_over_tresh, 1, 'omitnan');
t_under_mean = mean(means_under_tresh, 1, 'omitnan');

% SEM across subjects (per sac level)
t_over_sem  = std(means_over_tresh, 0, 1, 'omitnan')  ./ sqrt(sum(~isnan(means_over_tresh),1));
t_under_sem = std(means_under_tresh, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(means_under_tresh),1));



x = 1:5; % sac levels

% figure(fignum); hold on;
% 
% % Latent < median
% errorbar(x, t_under_mean, t_under_sem, ...
%     '-o', 'LineWidth', 2, 'MarkerSize', 8);
% 
% % Latent > median
% errorbar(x, t_over_mean, t_over_sem, ...
%     '-o', 'LineWidth', 2, 'MarkerSize', 8);
% 
% xlabel('Sac level');
% ylabel('Accuracy');
% 
% set(gca,'XTick',x)
% 
% legend({'Latent < median','Latent > median'}, 'Location','best');
% 
% ylim([0 1]);
% title([latenttext exptext])
% 
% grid on;
% box on;


alpha_val = 0.5;      % 0 = very light, 1 = full color
%x_vals = x + abscissa;           % abscissa

if col_var == 1
    col_code = [1 0 0];
    col_code_light = alpha_val*[1 0 0] + (1-alpha_val)*[1 1 1];
elseif col_var == 2
    col_code = [0 0 1];
    col_code_light = alpha_val*[0 0 1] + (1-alpha_val)*[1 1 1];
end


%figure(fignum); 
hold on;

% Latent < median
errorbar(x - 0.05 - abscissa, t_under_mean, t_under_sem, ...
    '-o', 'LineWidth', 1, 'MarkerSize', 3, 'Color', col_code_light);

% Latent > median
errorbar(x + 0.05 + abscissa, t_over_mean, t_over_sem, ...
    '-o', 'LineWidth', 1, 'MarkerSize', 3, 'Color', col_code);
yline(0.5, '--');


xlabel('SAC');
ylabel('Accuracy');

set(gca,'XTick',x)

legend({'Latent < median','Latent > median'}, 'Location','best');

ylim([0 1]);
xlim([0.8 5.2]);
title([latenttext exptext])
set(gca,'XTick',1:5)

grid on;

hold off;
end %eof