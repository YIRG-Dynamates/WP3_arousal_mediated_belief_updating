function out = median_split_accuracy_ttest(latent, correct, SAC)
% ========= set thresholds per person ===============
latent_tresh = [];
latent_end = cellfun(@(s) s(end), latent);
for sac_var = 1:5
    latent_end_SAC = latent_end;
    latent_end_SAC(SAC ~= sac_var) = NaN;
    latent_tresh(sac_var, :) = median(latent_end_SAC, 1, 'omitnan');
end
% ========= make logicals + calc means ===============
means_over_tresh  = NaN(width(latent), 5);
means_under_tresh = NaN(width(latent), 5);
for sac_var = 1:5
    SAC_logical = SAC == sac_var;
    matrix_tresh_placeholder = NaN(size(latent));
    for sbj = 1:width(latent)
        trials = latent_end(:,sbj) >= latent_tresh(sac_var, sbj);
        matrix_tresh_placeholder(trials, sbj) = 1;
        trials = latent_end(:,sbj) < latent_tresh(sac_var, sbj);
        matrix_tresh_placeholder(trials, sbj) = 0;
    end
    latent_larger_than_tresh = logical(matrix_tresh_placeholder);
    logical_SAC_over_tresh   = latent_larger_than_tresh & SAC_logical;
    logical_SAC_under_tresh  = ~latent_larger_than_tresh & SAC_logical;
    for sbj = 1:width(latent)
        array_temp = correct(logical_SAC_over_tresh(:,sbj), sbj);
        array_temp = array_temp(~isnan(array_temp));
        means_over_tresh(sbj, sac_var) = sum(array_temp) / length(array_temp);
        array_temp = correct(logical_SAC_under_tresh(:,sbj), sbj);
        array_temp = array_temp(~isnan(array_temp));
        means_under_tresh(sbj, sac_var) = sum(array_temp) / length(array_temp);
    end
end
% ========= five paired t-tests, one per SAC level ===============
fprintf('\n Median Split Accuracy T-Tests (paired, one per SAC level)\n');
fprintf('%s\n', repmat('=', 1, 100));
fprintf(' %-5s  %-8s  %-9s  %-8s  %-10s  %-12s  %-9s  %-20s  %-5s\n', ...
    'SAC', 'Low Mean', 'High Mean', 'Diff', 'p-value', 't(df)', 'Cohen''s d', '95% CI [low, high]', 'n');
fprintf('%s\n', repmat('-', 1, 100));
h_all     = nan(1,5);
p_all     = nan(1,5);
ci_all    = nan(2,5);
stats_all = cell(1,5);
d_all     = nan(1,5);
d_ci_all  = nan(2,5);
for sac_var = 1:5
    low  = means_under_tresh(:, sac_var);
    high = means_over_tresh(:, sac_var);
    valid   = ~isnan(low) & ~isnan(high);
    n_valid = sum(valid);
    [h, p, ci, stats] = ttest(low(valid), high(valid));
    % Cohen's d (paired) — diff = low - high, consistent with ttest(low, high)
    diff_scores = low(valid) - high(valid);
    cohen_d     = mean(diff_scores) / std(diff_scores);  % negative when low < high
    % 95% CI on Cohen's d via noncentral t distribution
    t_val  = stats.tstat;   % negative when low < high
    df     = stats.df;
    ncp_lo = fzero(@(ncp) nctcdf(t_val, df, ncp) - 0.975, t_val);
    ncp_hi = fzero(@(ncp) nctcdf(t_val, df, ncp) - 0.025, t_val);
    % ncp_hi is more negative → lower CI bound; ncp_lo is less negative → upper CI bound
    d_ci_lo = min(ncp_lo, ncp_hi) / sqrt(n_valid);
    d_ci_hi = max(ncp_lo, ncp_hi) / sqrt(n_valid);
    h_all(sac_var)       = h;
    p_all(sac_var)       = p;
    ci_all(:, sac_var)   = ci;
    stats_all{sac_var}   = stats;
    d_all(sac_var)       = cohen_d;
    d_ci_all(:, sac_var) = [d_ci_lo; d_ci_hi];
    % format p-value
    if p < 0.001
        p_str = '<.001';
    else
        p_str = sprintf('%.3f', p);
    end
    fprintf(' SAC %d  %-8.4f  %-9.4f  %-8.4f  %-10s  %-12s  %-9.3f  [%-7.3f, %-7.3f]   %d\n', ...
        sac_var, nanmean(low), nanmean(high), nanmean(low)-nanmean(high), ...
        p_str, sprintf('%.3f(%d)', t_val, df), ...
        cohen_d, d_ci_lo, d_ci_hi, n_valid);
end
fprintf('%s\n', repmat('=', 1, 100));
% ========= store output ===============
out.means_over_tresh  = means_over_tresh;
out.means_under_tresh = means_under_tresh;
out.h                 = h_all;
out.p                 = p_all;
out.ci                = ci_all;
out.stats             = stats_all;
out.cohen_d           = d_all;
out.cohen_d_ci        = d_ci_all;

% for documentation

% For each SAC level (1–5), a paired-samples t-test was conducted to assess 
% whether trial-level accuracy differed as a function of latent variable magnitude. 
% For each participant, a median threshold was computed from the latent variable 
% values at the end of each trial, restricted strictly to trials ending at that
% SAC level. Trials were then classified as above or below this participant- 
% and SAC-level-specific threshold, and accuracy was averaged within each half. 
% This yielded one pair of accuracy values per participant per SAC level. 
% Paired-samples t-tests were performed on these 27 pairs, with participants 
% excluded listwise per SAC level in case of missing data in either half.
% Effect sizes are reported as Cohen's d for paired samples, computed as the
% mean of the difference scores divided by their standard deviation, with 
% 95% confidence intervals derived from the noncentral t-distribution.