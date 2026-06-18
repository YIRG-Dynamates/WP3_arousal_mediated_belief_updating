function [means_mat, percentage_excluded] = mean_SEM_per_SAC_subject(delta_amps_all_motion, included_sounds, preprocessed_eye_data)
% outputs average Deltas and SEMs per column (therefore per subject)

deltas = [];
SACs = [];
stim_times_all = [];

% make two vectors for the deltas and SACs
for trial = 1:200;
    if ~isempty(delta_amps_all_motion{trial, 1});

        logical = included_sounds{trial, 1}.incl_sounds ;

        deltas = vertcat(deltas, delta_amps_all_motion{trial, 1}(logical));
        SACs = vertcat(SACs, included_sounds{trial, 1}.SAC_level(logical)');

        stim_times_all = vertcat(stim_times_all, preprocessed_eye_data{trial, 1}.A_stim_times');
    end 
end

for levels = 1:5
    means_mat(levels, 1) = mean(deltas(SACs == levels));
    means_mat(levels + 5, 1) = calculate_standard_error_RF(deltas(SACs == levels));
    means_mat(levels + 10, 1) = median(deltas(SACs == levels));
end

percentage_excluded = 1-(numel(deltas)/numel(stim_times_all));

end %eof
