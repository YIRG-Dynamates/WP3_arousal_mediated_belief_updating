function [S,trials_cell,eye_data] = GenTrials(S,F)
% Prepare the task by generating trial locations

%Shuffle the random number generator
rng('shuffle');

%Do different things for different tasks
if strcmp(S.task_name,'MAA')
    
    %First familiarization block (used in both sessions)
    if (S.block_nr == 1) || (S.block_nr == 5)
        
        %Initialize the number of trials
        S.nTrials = 50;                                        
        trials_cell = cell(S.nTrials,1);
        eye_data = cell(S.nTrials,3);

        %Initialize the stimulus locations
        easy = 20:-1:11;                        %10 trials
        hard = 10:-1:1;                         %10 trials
        mix = [easy hard];
        
        x = [easy mix(randperm(20)) mix(randperm(20))];                     %10 easy trials, followed by two blocks of 20 mixed trials (50 total)
        
        %Randomize left/right locations and standard/probe order
        for i=1:50
            
            if rand() < 0.5; x(i) = -1*x(i); end
            
            %Randomize standard (0) and probe location
            %if x is positive, then sequence is [0 +] or [- 0]
            %if x is negative, then sequence is [0 -] or [+ 0]
            if rand() < 0.5
                azimuth_sequence = [0 x(i)];
            else
                azimuth_sequence = [-x(i) 0];
            end
                
            %Store the info of the coming trial
            trials_cell{i}.sd_exp = 0;
            trials_cell{i}.x = azimuth_sequence;
            trials_cell{i}.cp = [NaN true];
            trials_cell{i}.v_mean = diff(azimuth_sequence);
            trials_cell{i}.v = diff(azimuth_sequence);
            trials_cell{i}.SAC = 1;

            %Add random jitter to lead in timing
            trials_cell{i}.timing_lead_in = 750 + round(rand()*250);
            
        end
        
    %Second staircase block to determine the MAA at 0° 
    elseif ismember(S.block_nr,[2 3 4])
        
        %Initialize the number of trials
        S.nTrials = 101;                                        %Set to one more than desired...
        trials_cell = cell(S.nTrials-1,1);
        eye_data = cell(S.nTrials-1,3);

        % Minimize posterior entropy of sigma only (PSI-marginal method by Luigi Acerbi: https://github.com/lacerbi/psybayes/)
        method = 'ent';       
        vars = [0 1 0];       
        
        % Initialize PSY structure
        psy = [];

        % You can specify one or more user-defined psychometric functions (as a string)
        psy.psychofun = '@(x,mu,sigma,lambda,gamma) psyfun_yesno(x,mu,sigma,lambda,gamma,@psynormcdf);';
        
        % Force symmetry of stimulus locations
        psy.forcesymmetry = true;
        
        % Define range for stimulus and for parameters of the psychometric function
        % (lower bound, upper bound, number of points)
        psy.range.x = [-20,20,41];
        psy.range.mu = [-5,5,21];
        psy.range.sigma = [0.5,20,61];          % The range for sigma is automatically converted to log spacing
        psy.range.lambda = [0,0.1,21];
        
        % Set chance level (leave empty for Yes/No psychometric functions)
        psy.gamma = [];
        
        % Units -- used just for plotting in axis labels and titles
        psy.units.x = 'Spatial difference in degrees';
        psy.units.mu = 'Bias';
        psy.units.sigma = 'MAA';
        psy.units.lambda = 'Lapse Rate';
        
        % Initialize and get first recommended stimulus location
        [x,psy] = psybayes(psy, method, vars, [], []);
        
        %Save staircase stuff in the first cell of trials_cell
        trials_cell{1}.staircase = {psy,method,vars,x};
        
    else
        error('Unknown block number (not 1 or 2)');
    end
    
    %Randomize order of left and right azimuth for MAA task for each set of 25 consecutive trials    
    if ismember(S.block_nr, [1 2 5])
        azimuth_offset = 0;
    elseif S.block_nr == 3
        azimuth_offset = 20;
    elseif S.block_nr == 4
        azimuth_offset = 40;
    end
    azimuth_offset_per_trial = azimuth_offset*ones(length(trials_cell),1);
    if ismember(S.block_nr, [3 4])
        sign_options = [-1 1; 1 -1];
        signs = [sign_options(randi(2,1),:), sign_options(randi(2,1),:)];
        azimuth_offset_per_trial = reshape(signs.*ones(25,4),[100 1]).*azimuth_offset_per_trial;
    end
    for i=1:length(trials_cell)
        trials_cell{i}.azimuth_offset = azimuth_offset_per_trial(i);
    end
    
%Main task blocks    
else
    
    mu_exp = 3*S.MAA;
    sd_exp = 1*S.MAA;
    
    true_hazard_rate = 1/5;
    hazard_rate_threshold = true_hazard_rate*[0.95 1.05];   %5 percent margin
    
    max_attempts = 25;
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
    trials_cell = trials_cell(:);
    
    %Set the number of trials in this block
    S.nTrials = numel(trials_cell);
    
    %Initialize the eye_data variable, even if no eye_data is recorded
    eye_data = cell(S.nTrials,3);                                           %First column for trials_data, second column for calibration_data, third is for the screen resolution  
    
    %Add jitter in the lead_in timing of each stimulus (in ms)
    for i=1:S.nTrials
        trials_cell{i,1}.timing_lead_in = 750 + round(rand()*250);          %750 to 1000 ms lead in times
    end
end

end %[EoF]
