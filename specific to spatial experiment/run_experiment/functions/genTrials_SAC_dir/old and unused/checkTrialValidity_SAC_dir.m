function [valid_flag,T_all] = checkTrialValidity_SAC_dir(x,v,d,T,T_all)
%Check whether we need this trial

P = setExperimentParams_SAC_dir();
valid_flag = true;

%Check that the last velocity direction matches the intended 'direction'
if sign(v(end)) ~= sign(d(end))
    valid_flag = false;
end

%Check that none of the stimuli locations exceeds the boundaries
if ~all((x >= P.all_stimulus_range(1)) & (x <= P.all_stimulus_range(2)))
    valid_flag = false;
end
    
%Check that the Sound After Changepoint (SAC) level is <= 6
if T.SAC > 6
    valid_flag = false;
end

%Check that there are not too many or too few change-points per trial
if (T.num_stim_bin <= 6) && (T.num_cp > 1)                                      %No other changepoints except at t=1
    valid_flag = false;
elseif (T.num_stim_bin >= 7) && abs(T.actual_cp_hazard_rate-P.cp_hazard_rate) > .5*P.cp_hazard_rate  %For longer trials (t >= 7) the actual hazard rate should not deviate more than some tolerance
    valid_flag = false;                                                                            
end

%Check that the number of stimuli in the trial does not exceed 45
if T.num_stim_bin >= 12
    valid_flag = false;
end

%Okay, this trial passed the basic checks. Now check whether we don't already have a trial with the same required conditions   
if valid_flag && ~isempty(T_all)
    
    %Short trials (num_stim <= 6)
    if ismember(T.num_stim_bin,1:6) 
        if sum(T.num_stim_bin == T_all.num_stim_bin) >= 3                                                               %We require exactly three trials in each trial length bin
            valid_flag = false;
        end
        
    %Long trials (num_stim >= 7)    
    else 
        if any((T.num_stim_bin == T_all.num_stim_bin) & (T.SAC == T_all.SAC))                                           %We require exactly one SAC level in each trial_length bin (i.e. 6 trials per bin)
            valid_flag = false;
        end
    end
    
    %Checks per SAC level (includes short and long trials)                                                              %We require exactly four left and four right directions per SAC level   
    if sum((T.SAC == T_all.SAC) & (T.target_dir_bin == T_all.target_dir_bin)) >= 4
        valid_flag = false; 
    end
    
    %Across all trials (balancing this cannot be done per SAC level because of space limits: motion is too fast) 
    if sum((T.target_dir_bin == T_all.target_dir_bin) & (T.target_loc_4_bin == T_all.target_loc_4_bin)) >= 6            %Exactly six leftward and rightward motion trials in each spatial quadrant
        valid_flag = false;  
    elseif sum((T.target_dir_bin == T_all.target_dir_bin) & (T.target_vel_4_bin == T_all.target_vel_4_bin)) >= 6        %Exactly six leftward and rightward motion trials in each absolute velocity quadrant
        valid_flag = false; 
    end                         
    
    %The above constraints on spatial location and absolute velocity balancing can sometimes lead to impossible condition filling...
    %To circumvent problems with unsolvable condition combinations we first accept the hardest ones: SAC6, then SAC5, etc.. 
    filled_SAC = zeros(6,1);
    for i=1:6
        filled_SAC(i) = sum(T_all.SAC == i);
    end
    SAC2fill = find(filled_SAC < 8,1,'last');
    if T.SAC ~= SAC2fill
        valid_flag = false; 
    end
    
end 

%Add the current trial to all selected trials (i.e. update T_all)
if valid_flag
    if isempty(T_all)
        T_all = T;
    else
        Names = fieldnames(T);
        num_trials = length(T_all.(Names{1}));
        for i=1:numel(Names)
            T_all.(Names{i})(:,num_trials+1) = T.(Names{i});
        end
    end
end

end %[EoF]
