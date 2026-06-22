function T_all = getTrialConditions_All_SAC_tempo(trials_cell,mu_exp,sd_exp,space_limits)
%A simple loop around "getTrialConditions.m" to obtain them for all trials

[num_blocks, num_trials_per_block] = size(trials_cell);

T_all = [];
for i=1:num_blocks
    for j=1:num_trials_per_block
    
        T = getTrialConditions_SAC_tempo(trials_cell{i,j}.x,trials_cell{i,j}.v,trials_cell{i,j}.cp,trials_cell{i,j}.d,mu_exp,sd_exp,space_limits);
        
        if isempty(T_all)
            T_all = T;
        else
            Names = fieldnames(T);
            for k=1:numel(Names)
                T_all.(Names{k})(i,j) = T.(Names{k});
            end
        end
    end
end

end %[EoF]