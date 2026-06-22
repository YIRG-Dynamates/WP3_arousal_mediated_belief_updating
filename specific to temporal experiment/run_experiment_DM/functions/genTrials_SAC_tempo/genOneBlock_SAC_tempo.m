function trials_cell = genOneBlock_SAC_tempo(mu_exp,sd_exp,space_limits,test_flag)
%Generate one block of 50 trials for the tempo-change discrimination task. 
%Loads of hard coded stuff, but efficient and well-balanced.

%The general approach is to divide the trial conditions based on the last
%stimuli [SAC level (prior strength), last direction (speed-up/slow-down), 
%last absolute velocity (ISI change, i.e. evidence strength), last ISI=x]. 
%We then randomly sample the sequences backwards (towards first stimulus).

%Should we create an overview of the trial conditions in the command window?
if nargin < 3
    test_flag = false;
end

%Shuffle the random number generator so as to ensure that all generated blocks are truly different   
rng('shuffle');

%Basic settings
cp_hazard_rate = 1/5;       %Change point hazard rate
SAC_levels = 1:5;           %Stimulus after change point levels    

%We approximately follow a geometric distribution with p = 0.1
%Trials lengths 1-5 each appear exactly 4 times. For these trials, their length and SAC are equal (i.e. no in-between CPs)   
%Furthermore, each of the following trial length bins appear exactly 6 times. Each bin contains at least 1, and at most 2 trials of each SAC level.   
length_bins = {6:7; 8:10; 11:14; 15:20; 21:44};
length_bin_idx = [repmat(1:5,[5 1]) randperm(5)'];
for i_SAC=1:5
    length_bin_idx(i_SAC,:) = length_bin_idx(i_SAC,randperm(6));            %Ensure a balanced distribution of the random 'extra' SAC level per bin
end

%Directions: Slow down (-1) and Speed Up (+1)
d_options = [-1, +1];

%Absolute velocities of the last stimulus are divided into 2 (for short <=5 trials) or 3 (for long >5 trials) bins: small-large evidence for the last ISI change   
%SAC levels (prior strengths) are completely balanced, with an equal amount of high and low evidence trials per direction (slow-down and speed-up).   
v3_edges = [norminv(1/3,mu_exp,sd_exp),norminv(2/3,mu_exp,sd_exp)];
v3_bins = {[0 v3_edges(1)]; [v3_edges(1) v3_edges(2)]; [v3_edges(2) 2*mu_exp]};
v2_bins = {[0 mu_exp]; [mu_exp 2*mu_exp]};

%Space is divided into 5 equally sized parts. Across all SAC levels the number of left/right directions and evidence strength (velocity bin) are balanced for each of the spatial regions. 
%This could not be done within each SAC level because we move through space too fast: e.g. SAC level 5 cannot end in the middle of space..
space_edges = linspace(space_limits(1),space_limits(2),6);
space_bins = [space_edges(1:5)' space_edges(2:6)'];

%Initialize trials_cell
trials_cell = cell(50,1);           %50 trials total
counter = 1;

%20 short trials (<= 5 velocities, <= 6 stimuli)
for i_d = 1:2
    
    d_tmp = d_options(i_d);         %direction of these trials
    
    for i_v = 1:2
        
        filled_space_bins = zeros(1,5);
        
        for i_SAC=5:-1:1            %Note that we start sampling the SAC 5 trials, because these are hardest to fill in combination with the balanced spatial location criterion
            
            SAC = SAC_levels(i_SAC);
            
            available_space_bins = find(~filled_space_bins);
            
            %Sample one trial until we meet all desired criteria
            max_attempts = 5e6;
            attempts_counter = 0;
            valid_trial = false;
            while ~valid_trial
                
                %Sample the last velocity from the desired bin
                v_tmp = NaN;
                while ~((v_tmp > v2_bins{i_v}(1)) && (v_tmp < v2_bins{i_v}(2)))
                    v_tmp = sd_exp*randn()+mu_exp;
                end
                v_tmp = d_tmp*v_tmp;    %Take care of direction
                
                %Sample the last spatial location from the desired bin
                space_bin_idx = available_space_bins(randi(numel(available_space_bins),1));
                space_bin_edges = space_bins(space_bin_idx,:);
                x_last = rand()*diff(space_bin_edges)+space_bin_edges(1);
                
                %Sample the locations and velocities of all stimuli in the short trial (length and CPs determined by SAC)   
                [x,v,cp,d] = genTrialLastPart(mu_exp,sd_exp,x_last,v_tmp,d_tmp,SAC);
                
                %Check that all spatial locations fall within the limits
                if ~any((x < space_limits(1)) | (x > space_limits(2)))
                    valid_trial = true;
                else
                    attempts_counter = attempts_counter+1;
                end
                
                %Because of earlier bugs, we set a maximum number of sampling attempts
                if attempts_counter >= max_attempts
                    %keyboard;
                    error('Unable to find solution. Try again or happy debugging :-)');
                end
            end
            
            %Keep track of the spatial bins that have already been used
            filled_space_bins(space_bin_idx) = 1;
            
            %Save trial info
            trials_cell{counter}.mu_exp = mu_exp;
            trials_cell{counter}.sd_exp = sd_exp;
            trials_cell{counter}.x = fliplr(x);             %Note that the order of the stimuli is flipped 
            trials_cell{counter}.v = fliplr(v);
            trials_cell{counter}.cp = fliplr(cp);
            trials_cell{counter}.d = fliplr(d);
            trials_cell{counter}.SAC = SAC;
            
            %Increase the trial counter
            counter = counter+1;
        end
    end
end

%30 long trials (> 5 velocities, > 6 stimuli)
for i_d = 1:2
    
    d_tmp = d_options(i_d);             %direction of these trials
    
    for i_v = 1:3
        
        filled_space_bins = zeros(1,5);
        
        for i_SAC=5:-1:1                %Note that we start sampling the SAC 5 trials, because these are hardest to fill in combination with the balanced spatial location criterion
            
            SAC = SAC_levels(i_SAC);
            
            available_space_bins = find(~filled_space_bins);
            
            %Sample the last part of this trial until we meet all desired criteria
            max_attempts = 1e6;
            attempts_counter = 0;
            valid_last_part = false;
            while ~valid_last_part
                
                %Sample the last velocity from the desired bin
                v_tmp = NaN;
                while ~((v_tmp > v3_bins{i_v}(1)) && (v_tmp < v3_bins{i_v}(2)))
                    v_tmp = sd_exp*randn()+mu_exp;
                end
                v_tmp = d_tmp*v_tmp;    %Take care of direction
                
                %Sample the last spatial location from the desired bin
                space_bin_idx = available_space_bins(randi(numel(available_space_bins),1));
                space_bin_edges = space_bins(space_bin_idx,:);
                x_last = rand()*diff(space_bin_edges)+space_bin_edges(1);
                
                %Sample the locations and velocities of the last few stimuli in the long trial (length and CPs of these last stimuli determined by SAC)  
                %The remaining preceding stimuli will be sampled later (see below)  
                [x1,v1,cp1,d1] = genTrialLastPart(mu_exp,sd_exp,x_last,v_tmp,d_tmp,SAC);
                
                %Check that all spatial locations fall within the limits
                if ~any((x1 < space_limits(1)) | (x1 > space_limits(2)))
                    valid_last_part = true;
                else
                    attempts_counter = attempts_counter+1;
                end
                
                %Because of earlier bugs, we set a maximum number of sampling attempts
                if attempts_counter >= max_attempts
                    %keyboard;
                    error('Unable to find solution. Try again or happy debugging :-)');
                end
            end
            
            %Keep track of the spatial bins that have already been used
            filled_space_bins(space_bin_idx) = 1;
            
            %Now start preparing to sample the remaining preceding stimuli locations, velocities and change-points   
            length_options = length_bins{length_bin_idx(counter-20)};
            n_stim_first_part = length_options(randi(numel(length_options),1))-SAC;     %The trial length bin for this trial number was determined before. Here we randomly select from within the bin.
            
            %Sample the first part of this trial until we meet all desired criteria
            max_attempts = 1e6;
            attempts_counter = 0;
            valid_first_part = false;
            while ~valid_first_part
                
                %Sample the locations, velocities and change-points of the first few stimuli in the long trial  
                [x,v,cp,d] = genTrialFirstPart(mu_exp,sd_exp,SAC,x1,v1,cp1,d1,n_stim_first_part,cp_hazard_rate);
                
                %Check that the actual hazard rate of this trial is not completely different from the target hazard rate (and that all stimuli locs are within limits)  
                actual_cp_hazard_rate = (nansum(cp)-1)/(n_stim_first_part+SAC-2);
                if ~any((x < space_limits(1)) | (x > space_limits(2))) && (abs(actual_cp_hazard_rate-cp_hazard_rate) < .5*cp_hazard_rate)
                    valid_first_part = true;
                else
                    attempts_counter = attempts_counter+1;
                end
                
                %Because of earlier bugs, we set a maximum number of sampling attempts
                if attempts_counter >= max_attempts
                    %keyboard;
                    error('Unable to find solution. Try again or happy debugging :-)');
                end
            end
            
            %Save trial info
            trials_cell{counter}.mu_exp = mu_exp;
            trials_cell{counter}.sd_exp = sd_exp;
            trials_cell{counter}.x = fliplr(x);         %Note that the order of the stimuli is flipped 
            trials_cell{counter}.v = fliplr(v);
            trials_cell{counter}.cp = fliplr(cp);
            trials_cell{counter}.d = fliplr(d);
            trials_cell{counter}.SAC = SAC;
            
            %Increase the trial counter
            counter = counter+1;
        end
    end
end

%Shuffle the order of the trials within this block
trials_cell = trials_cell(randperm(50));

%Create an overview of the full set of trials
if test_flag
    T_all = getTrialConditions_All_SAC_tempo(trials_cell,mu_exp,sd_exp,space_limits);
    createTrialsOverview_SAC_tempo(trials_cell,T_all);
end

end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper functions %%%
%%%%%%%%%%%%%%%%%%%%%%%%

function [x,v,cp,d] = genTrialLastPart(mu_exp,sd_exp,x_last,v_last,d_last,SAC)
    
    %Initialize
    x = nan(1,SAC+1);
    v = nan(1,SAC+1);
    cp = nan(1,SAC+1);
    d = nan(1,SAC+1);
    
    %Set known values
    x(1) = x_last;                                  %Last loc in sequence
    v(1) = v_last;                                  %Last velocity in sequence
    cp(1:SAC) = false;
    cp(SAC) = true;                                 %Start of last part of sequence always starts with a CP
    d(1:SAC) = d_last*ones(1,SAC);
    
    %Randomly sample the other values
    for i=2:SAC
        x(i) = x(i-1)-v(i-1);                       %Note minus instead of plus
        while true
            v(i) = sd_exp*randn()+d(i)*mu_exp;      
            if sign(v(i)) == d(i); break; end       %Avoid acciddental change of sign because of random sampling (0.23% chance)
        end 
    end
    x(SAC+1) = x(SAC)-v(SAC);                       %Note minus instead of plus
    
end %[EoF]

%%%

function [x,v,cp,d] = genTrialFirstPart(mu_exp,sd_exp,SAC,x1,v1,cp1,d1,n_stim,cp_hazard_rate)
    
    %Change-point multiplier
    cp_m = [1 -1];

    %Initialize
    x = [x1 nan(1,n_stim)];
    v = [v1 nan(1,n_stim)];
    cp = [cp1 nan(1,n_stim)];
    d = [d1 nan(1,n_stim)];
    
    for i=(1:n_stim)+SAC
        d(i) = cp_m(double(cp(i-1))+1)*d(i-1);  
        while true
            v(i) = sd_exp*randn()+d(i)*mu_exp;      
            if sign(v(i)) == d(i); break; end       %Avoid acciddental change of sign because of random sampling (0.23% chance)
        end 
        x(i+1) = x(i)-v(i);                         %Note minus instead of plus 
        if i == n_stim+SAC
            cp(i) = true;                           %First motion in sequence is always called a changepoint
        else
            cp(i) = (rand() <= cp_hazard_rate);     %Randomly assign changepoints
        end
    end
    
end %[EoF]
