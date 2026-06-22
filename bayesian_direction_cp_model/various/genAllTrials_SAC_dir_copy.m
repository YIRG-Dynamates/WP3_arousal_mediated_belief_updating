function trials_cell = genAllTrials_SAC_dir_copy(num_blocks,MAA)
%This is a pseudo-copy of the genTrials.m function that was used in the directions experiment. 

mu_exp = 3*MAA;
sd_exp = 1*MAA;

true_hazard_rate = 1/5;
hazard_rate_threshold = true_hazard_rate*[0.95 1.05];   %5 percent margin

max_attempts = 25;

trials_cell_all = cell(1,num_blocks);

for j_block=1:num_blocks

    attempt = 1;
    while attempt <= max_attempts

        %Always save the first attempt
        if attempt == 1
            trials_cell = genOneBlock_SAC_dir(mu_exp,sd_exp,true);        
            T_all = getTrialConditions_All_SAC_dir(trials_cell,mu_exp,sd_exp);
            actual_hazard_rate_chosen = sum(T_all.num_cp-1)/sum(T_all.num_stim-2);

        %Overwrite the previous attempt if new attempt is better (in terms of hazard rate)   
        else
            trials_cell_temp = genOneBlock_SAC_dir(mu_exp,sd_exp,true);        
            T_all = getTrialConditions_All_SAC_dir(trials_cell_temp,mu_exp,sd_exp);
            actual_hazard_rate_tmp = sum(T_all.num_cp-1)/sum(T_all.num_stim-2);
            if abs(actual_hazard_rate_tmp-true_hazard_rate) < abs(actual_hazard_rate_chosen-true_hazard_rate)
                trials_cell = trials_cell_temp;
                actual_hazard_rate_chosen = actual_hazard_rate_tmp;
            end
        end

        %Break from while loop if the actual hazard rate falls within the bounds 
        if (actual_hazard_rate_chosen > hazard_rate_threshold(1)) && (actual_hazard_rate_chosen < hazard_rate_threshold(2))
            disp(['Trial generation successful, the actual hazard rate is ' num2str(actual_hazard_rate_chosen)]);
            break
        end

        attempt = attempt+1;
    end

    %Warning message if chosen hazard rate does not fall within the bounds
    if attempt > max_attempts
        warning(['Trial generation unsuccessful, the actual hazard rate is ' num2str(actual_hazard_rate_chosen)])
    end

    %Transpose the trials_cell to be a cell-array of one column
    trials_cell_all{1,j_block} = trials_cell(:);

end

%Unpack cell array per block
num_trials_per_block = numel(trials_cell);
trials_cell = cell(num_trials_per_block,num_blocks);
for j_block=1:num_blocks
    trials_cell(:,j_block) = trials_cell_all{1,j_block};
end

end %[EoF]

