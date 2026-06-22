function [S,trials_cell] = GenTrials(S,F,generateNewStimuliBool)
% Prepare the task by generating trial settings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% General timing settings %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% What are the "standard" SOA (Stimulus Onset Asynchrony) durations for the MAI tasks?
S.SOA_settings.MAI_task_standards = [1000,650,300];

S.SOA_settings.MAI_maxima = (1/4)*[1000,650,300];

%Set the SOA limits for the main task
S.SOA_settings.MAI_StimLevelRange_multiplier = (1/3);


S.SOA_settings.main_task_sd_exp = (1/3)*S.SOA_settings.main_task_mu_exp;

%Return early if we were only interested in the SOA settings (used in SetSubjIDandTask.m)
if isnan(generateNewStimuliBool)
    trials_cell = NaN;
    return
end

% Set some timing specifics (in seconds) --> but do ensure that these are multiples of the ifi (screen update time: e.g. with a 60Hz monitor the ifi is 1/60.
S.timing.stim_duration = 0.025;
S.timing.lead_out = 0.975;                                   %Lead-out time starts directly after the last stimulus offset

% After how many trials does the participant get a break?
S.miniBreakRate = 25;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Generate a new trials_cell %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Load old trials_cell for this block?
if ~generateNewStimuliBool
    
    %Continue old unfinished file
    load(F.save_file,'trials_cell');
    
    %Create a new trials_cell (default)
else
    %     if strcmp(S.task_name, 'Last_direction_discrimination') && ismember(S.block_nr, [2,3,4,5,6])
    %         S.SOA_settings.main_task_limits = [(2/3)*300, (4/3)*1000];
    %         if S.SOA_settings.main_task_mu_exp > 1.3
    %             S.SOA_settings.main_task_mu_exp = 1.3;
    %         end
    %     end
    %Shuffle the random number generator
    rng('shuffle');
    
    
    
    %Main task blocks
    S.MAI = S.SOA_settings.MAI_maxima;
    %Find "a" and "b" for JND = a+b.*x (where x is the SOA)
    y = S.MAI';
    X2 = S.SOA_settings.MAI_task_standards';
    X = [ones(3,1), X2];
    betas = (X'*X)\X'*y;        %Ordinary least squares
    a = betas(1);
    b = betas(2);
    if a < 1
        a = 1;                  %Set a minimum of 1 ms for the intersect "a", i.e. the JND at 0 ms ISI (a>0 is required for transformation to 1/JND units)
        b = (X2'*X2)\X2'*(y-1); %Redo ordinary least squares to find best fitting slope parameter with a fixed intercept of 1 ms
    end
    if b <= 0.01
        b = 0.01;               %Set a minimum of 0.01 for the slope "b", i.e. the JND increase is minimally 10 ms with a 1 second increase in SOA. This is necessary for a stable tranformation.
        a = mean(y)-mean(b*X2);
    end
    
    %Find the "space_limits" in units of 1/JND
    space_limits = transform2perJND(S.SOA_settings.main_task_limits,a,b,'real2trans');
    
    %Set difficulty in units of JND (larger is easier)
    mu_exp = S.SOA_settings.main_task_mu_exp;
    sd_exp = S.SOA_settings.main_task_sd_exp;
    
    true_hazard_rate = 1/5;
    hazard_rate_threshold = true_hazard_rate*[0.95 1.05];   %5 percent margin
    
    max_attempts = 100;
    attempt = 1;
    while attempt <= max_attempts
        
        %Always save the first attempt
        if attempt == 1
            trials_cell = genOneBlock_SAC_tempo(mu_exp,sd_exp,space_limits,true);
            T_all = getTrialConditions_All_SAC_tempo(trials_cell,mu_exp,sd_exp,space_limits);
            actual_hazard_rate_chosen = sum(T_all.num_cp-1)/sum(T_all.num_stim-2);
            
            %Overwrite the previous attempt if new attempt is better (in terms of hazard rate)
        else
            trials_cell_temp = genOneBlock_SAC_tempo(mu_exp,sd_exp,space_limits,true);
            T_all = getTrialConditions_All_SAC_tempo(trials_cell_temp,mu_exp,sd_exp,space_limits);
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
    
    %Convert the trials_cell to use for in the WP2 temporal experiment (TEMPO study)
    trials_cell = convertTrialsCellForTempo(trials_cell,S.MAI,a,b);
    
    %Transpose the trials_cell to be a cell-array of one column
    trials_cell = trials_cell(:);
    
    %Set the number of trials in this block
    S.nTrials = numel(trials_cell);
    
    %Add jitter in the lead_in timing of each stimulus (in ms)
    for i=1:S.nTrials
        trials_cell{i,1}.timing_lead_in = 750 + round(rand()*250);      %750 to 1000 ms lead in times
    end
    
    
    settings = S;                                                           %Change name of S to settings for saving
    save(F.save_file,'settings','trials_cell','-v6');                       %Save the file using the -v6 method (fastest)
    
end %end of "generateNewStimuliBool" if-statement

end %[EoF]
