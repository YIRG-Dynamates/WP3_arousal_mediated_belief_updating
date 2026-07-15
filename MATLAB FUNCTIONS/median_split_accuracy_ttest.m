function out = median_split_accuracy_ttest(latent, correct, SAC)
% MEDIAN_SPLIT_ACCURACY_TTEST
% For each SAC level, splits trials into "low" and "high" groups based on
% a per-subject median split of the latent variable (computed strictly
% within that SAC level), then compares mean accuracy between the two
% groups using a paired one-sided t-test (H1: low < high).
%
% INPUTS:
%   latent  - cell array, one cell per subject, each containing a
%             per-trial vector of latent variable values (time series;
%             only the last value per trial, s(end), is used as the
%             "threshold-relevant" value)
%   correct - trials x subjects matrix of accuracy (0/1), NaN for missing
%   SAC     - trials x subjects matrix indicating SAC level (1-5) per trial
%
% OUTPUT:
%   out - struct containing means, t-test results, effect sizes, and CIs

    % ========= set thresholds per person ===============
    % For each SAC level separately, take the median of the latent
    % variable's final value across trials (per subject). This gives a
    % subject- and SAC-level-specific split point, avoiding leakage
    % across SAC levels.
    latent_tresh = [];
    latent_end = cellfun(@(s) s(end), latent);  % last value per trial, per subject

    for sac_var = 1:5
        latent_end_SAC = latent_end;
        latent_end_SAC(SAC ~= sac_var) = NaN;  % mask out trials from other SAC levels
        latent_tresh(sac_var, :) = median(latent_end_SAC, 1, 'omitnan');
    end

    % ========= make logicals + calc means ===============
    % For each SAC level, label trials as "over" or "under" the
    % subject-specific threshold, then compute mean accuracy per subject
    % within each group.
    means_over_tresh  = NaN(width(latent), 5);
    means_under_tresh = NaN(width(latent), 5);

    for sac_var = 1:5
        SAC_logical = SAC == sac_var;
        matrix_tresh_placeholder = NaN(size(latent));

        for sbj = 1:width(latent)
            % trials at/above threshold -> 1, below -> 0
            trials = latent_end(:,sbj) >= latent_tresh(sac_var, sbj);
            matrix_tresh_placeholder(trials, sbj) = 1;

            trials = latent_end(:,sbj) < latent_tresh(sac_var, sbj);
            matrix_tresh_placeholder(trials, sbj) = 0;
        end

        latent_larger_than_tresh = logical(matrix_tresh_placeholder);
        logical_SAC_over_tresh   = latent_larger_than_tresh & SAC_logical;
        logical_SAC_under_tresh  = ~latent_larger_than_tresh & SAC_logical;

        % compute per-subject accuracy (proportion correct) in each group
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
    % One-sided (left-tailed) paired t-test per SAC level.
    % H1: mean(low) < mean(high), i.e. accuracy below threshold is lower
    % than accuracy above threshold.
    fprintf('\n Median Split Accuracy T-Tests (paired, one-sided, one per SAC level)\n');
    fprintf('%s\n', repmat('=', 1, 100));
    fprintf(' %-5s  %-8s  %-9s  %-8s  %-10s  %-12s  %-9s  %-20s  %-5s\n', ...
        'SAC', 'Low Mean', 'High Mean', 'Diff', 'p-value', 't(df)', 'Cohen''s d', '95% CI [low, high]', 'n');
    fprintf('%s\n', repmat('-', 1, 100));

    h_all     = nan(1,5);   % test decision (1 = reject H0) per SAC level
    p_all     = nan(1,5);   % exact (non-rounded) p-values per SAC level
    ci_all    = nan(2,5);   % CI on the mean difference, as returned by ttest
    stats_all = cell(1,5);  % full stats struct from ttest (tstat, df, sd)
    d_all     = nan(1,5);   % Cohen's d (paired) per SAC level
    d_ci_all  = nan(2,5);   % 95% CI on Cohen's d per SAC level

    for sac_var = 1:5

        low  = means_under_tresh(:, sac_var);
        high = means_over_tresh(:, sac_var);

        % keep only subjects with valid (non-NaN) data in both groups
        valid   = ~isnan(low) & ~isnan(high);
        n_valid = sum(valid);

        % one-sided paired t-test: testing low < high
        [h, p, ci, stats] = ttest(low(valid), high(valid), 'Tail', 'left');

        % ---- Cohen's d (paired) ----
        % diff = low - high, so d is negative when low < high (as expected
        % under H1). Kept consistent with the direction used in ttest().
        diff_scores = low(valid) - high(valid);
        cohen_d     = mean(diff_scores) / std(diff_scores);

        % ---- 95% CI on Cohen's d via noncentral t-distribution ----
        % Note: this CI is kept two-sided by convention, even though the
        % t-test itself is one-sided. This is a common and defensible
        % reporting choice (test direction != CI direction).
        t_val  = stats.tstat;   % negative when low < high
        df     = stats.df;
        ncp_lo = fzero(@(ncp) nctcdf(t_val, df, ncp) - 0.975, t_val);
        ncp_hi = fzero(@(ncp) nctcdf(t_val, df, ncp) - 0.025, t_val);

        % ncp_hi is more negative -> lower CI bound; ncp_lo is less negative -> upper CI bound
        d_ci_lo = min(ncp_lo, ncp_hi) / sqrt(n_valid);
        d_ci_hi = max(ncp_lo, ncp_hi) / sqrt(n_valid);

        % ---- store results for this SAC level ----
        h_all(sac_var)       = h;
        p_all(sac_var)       = p;          % exact, non-rounded p-value
        ci_all(:, sac_var)   = ci;
        stats_all{sac_var}   = stats;
        d_all(sac_var)       = cohen_d;
        d_ci_all(:, sac_var) = [d_ci_lo; d_ci_hi];

        % ---- format p-value for console display only (rounded) ----
        % the underlying stored p-value (p_all) remains full precision
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
    out.p                 = p_all;         % exact p-values, use these for reporting
    out.ci                = ci_all;
    out.stats             = stats_all;
    out.cohen_d           = d_all;
    out.cohen_d_ci        = d_ci_all;

end

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