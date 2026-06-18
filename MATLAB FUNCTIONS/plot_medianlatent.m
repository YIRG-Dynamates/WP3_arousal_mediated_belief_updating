function plot_medianlatent = plot_medianlatent(latent, correct, SAC, latenttext, exptext)
%%% FUNCTION STARTS FROM HERE


% ========= set tresholds per person! ===============

% tresholds for all latent values
latent_tresh_1 = [];
for sbj = 1:width(latent)
    allvals = [];
    for trial = 1:height(latent)
        allvals = horzcat(allvals, latent{trial, sbj});
    end
    latent_tresh_1(sbj) = median(allvals)
end

% tresholds only within SAC = 1 at the end
latent_tresh_2 = [];
latent_end = cellfun(@(s) s(end), latent);

latent_end_SAC1 = latent_end;
latent_end_SAC1(SAC > 1) = NaN;
latent_tresh_2 = median(latent_end_SAC1, 1, 'omitnan');

% ========= make logicals ===============

SAC_logical = SAC == 1; % value 1 means this trial ends on SAC 1

matrix_tresh_2_placeholder = NaN(size(latent));
matrix_tresh_1_placeholder = NaN(size(latent));
for sbj = 1:width(latent)
    trials = latent_end(:,sbj) >= latent_tresh_2(sbj);
    matrix_tresh_2_placeholder(trials,sbj) = 1;
    trials = latent_end(:,sbj) < latent_tresh_2(sbj); %overwrite the other way around
    matrix_tresh_2_placeholder(trials,sbj) = 0;

    trials = latent_end(:,sbj) >= latent_tresh_1(sbj);
    matrix_tresh_1_placeholder(trials,sbj) = 1;
    trials = latent_end(:,sbj) < latent_tresh_1(sbj); %overwrite the other way around
    matrix_tresh_1_placeholder(trials,sbj) = 0;

end

latent_larger_than_tresh_2 = logical(matrix_tresh_2_placeholder);
latent_larger_than_tresh_1 = logical(matrix_tresh_1_placeholder);

% ================= combine logicals ===================

logical_SAC1_over_tresh1 = latent_larger_than_tresh_1 & SAC_logical;
logical_SAC1_over_tresh2 = latent_larger_than_tresh_2 & SAC_logical;

logical_SAC1_under_tresh1 = ~latent_larger_than_tresh_1 & SAC_logical;
logical_SAC1_under_tresh2 = ~latent_larger_than_tresh_2 & SAC_logical;

% ================= apply logicals + calc meaans ===================

means_over_tresh1 = [];
means_over_tresh2 = [];
means_under_tresh1 = [];
means_under_tresh2 = [];

for sbj = 1:width(latent)

    rows = []; array_temp = [];
    rows = logical_SAC1_over_tresh1(:,sbj);
    array_temp = correct(rows,sbj);
    array_temp = array_temp(~isnan(array_temp));
    means_over_tresh1(sbj) = sum(array_temp) / length(array_temp);
 
    rows = []; array_temp = [];
    rows = logical_SAC1_over_tresh2(:,sbj);
    array_temp = correct(rows,sbj);
    array_temp = array_temp(~isnan(array_temp));
    means_over_tresh2(sbj) = sum(array_temp) / length(array_temp);

    rows = []; array_temp = [];
    rows = logical_SAC1_under_tresh1(:,sbj);
    array_temp = correct(rows,sbj);
    array_temp = array_temp(~isnan(array_temp));
    means_under_tresh1(sbj) = sum(array_temp) / length(array_temp);

    rows = []; array_temp = [];
    rows = logical_SAC1_under_tresh2(:,sbj);
    array_temp = correct(rows,sbj);
    array_temp = array_temp(~isnan(array_temp));
    means_under_tresh2(sbj) = sum(array_temp) / length(array_temp);

end

% ========================== calc SEM and mean(mean) ==============

t1_over_mean = mean(means_over_tresh1, 'omitnan');
t2_over_mean = mean(means_over_tresh2, 'omitnan');
t1_under_mean = mean(means_under_tresh1, 'omitnan');
t2_under_mean = mean(means_under_tresh2, 'omitnan');

t1_over_sem  = std(means_over_tresh1, 'omitnan')  / sqrt(sum(~isnan(means_over_tresh1)));
t2_over_sem  = std(means_over_tresh2, 'omitnan')  / sqrt(sum(~isnan(means_over_tresh2)));
t1_under_sem = std(means_under_tresh1, 'omitnan') / sqrt(sum(~isnan(means_under_tresh1)));
t2_under_sem = std(means_under_tresh2, 'omitnan') / sqrt(sum(~isnan(means_under_tresh2)));

x = [1 2]; % 1 = under median, 2 = over median

figure; hold on;

% Threshold 1
errorbar(x, [t1_under_mean t1_over_mean], [t1_under_sem t1_over_sem], ...
    '-o', 'LineWidth', 2, 'MarkerSize', 8);

% Threshold 2
errorbar(x, [t2_under_mean t2_over_mean], [t2_under_sem t2_over_sem], ...
    '-o', 'LineWidth', 2, 'MarkerSize', 8);

set(gca,'XTick',x,'XTickLabel',{'Latent < median','Latent > median'});
ylabel('Accuracy');
legend({'Threshold 1','Threshold 2'}, 'Location','best');
ylim([0 1]);
title([latenttext exptext])
grid on;
box on;

end %eof