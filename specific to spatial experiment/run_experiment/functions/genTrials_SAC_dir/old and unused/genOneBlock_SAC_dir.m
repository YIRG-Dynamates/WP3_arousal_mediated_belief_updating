function trials_cell = genOneBlock_SAC_dir(mu_exp,sd_exp,test_flag)
% Generate all trials for one block with a specified experimental noise level.
% Input
%    mu_exp    [Required]: offset of bimodal generative distribution: +/- mu_exp 
%    sd_exp    [Required]: standard deviation of generative distributions: i.e. experimental noise level.
%    test_flag [Optional]: logical that indicates whether to perform some additional checks (default: false).   
% Output
%   trials_cell: 1xN cell array, where N is the number of trials in the block 
%                Each cell contains a structure with five fields: sd_exp, x, mu, cp, and SAC
%                   mu_exp: scalar, the +/- means of the bimodal generative distributions, that was the input to this function   
%                   sd_exp: scalar, the experimental noise level that was the input to this function   
%                   x :     1xL double, of stimulus locations (L = trial length), locations in degrees.
%                   v:      1xL double, of actual velocity for this stimulus relative to the previous stimulus (degrees / stimulus).
%                   cp:     1xL logical, indicating where the change-points are.
%                   d:      1xL double, 1 or -1 indicating the direction of the distribution from which we sample the velocities.   
%                   SAC:    scalar, the Sound After Changepoint level of the trial (as in Krishnamurthy et al., 2017)   

%% Set default input arguments

if nargin < 2
    MAA = 3;
    mu_exp = sqrt(2)*MAA;       %Previously: sqrt(.5)*MAA;
    sd_exp = 1*MAA;             %Previously: 0.5*MAA;
end

if nargin < 3
    test_flag = false;          %Should we run some tests and display these?
end

%% DEFINITIONS:
% * stimulus:   A burst of auditory noise 
% * trial:      One trial consists of a sequence of stimuli
% * block:      One block consists of N trials
% * session:    One session may consist of multiple blocks that are separated by breaks for resting
% * experiment: One experiment may consist of multiple sessions, with each session taking place on a different day. 

%% TRIAL GENERATION PROCESS:
  
% (1) Each trial starts with a clean sheet: i.e. a 'starter' stimulus location is sampled at random from a normal distribution centred at zero: x(0) ~ N(0,first_simulus_sd^2). 
% (2) After the starter stimulus, with location x(0), every stimulus is sampled by adding a certain velocity to the previous location: x(t) = x(t-1)+v(t). 
%     A. The mean velocities are determined via a change-point procedure. 
%        - In case of a change-point (CP=1) the velocity is sampled at random from a mixture of two normal distributions centred on +/-mu_exp: v(t) ~ .5*[N(0,sd_exp^2)+N(0,sd_exp^2)]   
%        - In case of a no change-point (CP=0) the velocity is exactly the same as the previous velocity: v(t) = v(t-1)
%     C. At t=1 there always is a change-point: p(CP_1 = 1) = 1. At t>1 the chance of a change-point is constant for all stimuli: p(CP_t = 1) = cp_hazard_rate (e.g. 1/6 = 16.67%).  
% (3) Each stimulus, after the starter stimulus x(0), has an equal chance of being the last stimulus in the trial. The end-point (EP) hazard rate is ep_hazard_rate (e.g. 1/12 = 8.33%)   
%     This means that:
%       - Trial length (T) is unpredictable and equal attention should be paid to all stimuli because each stimulus has an equal chance of being the relevant last/target stimulus. 
%       - Trial lengths are distributed according to a geometric distribution with mean(T) = 12 stimuli. For more info on the trial lengths see the 'trial selection process' below.  

%% TRIAL SELECTION PROCESS:

% (1). Respect the approximate shape of the geometric distribution while selecting the 50 trials for one block.   
%       - Trial length = 1-2:       Select exactly 4 trials for each trial length; i.e. 2 x 4 = 8 trials in this 'trial-length group'.
%       - Trial length = 3-6:       Select exactly 3 trials for each trial length; i.e. 4 x 3 = 12 trials in this 'trial-length group'. 
%       - Trial length = 7-9:       Select 6 trials (the exact trial lengths are randomly decided)   
%       - Trial length = 10-13:     Select 6 trials (the exact trial lengths are randomly decided)   
%       - Trial length = 14-18:     Select 6 trials (the exact trial lengths are randomly decided)   
%       - Trial length = 19-28:     Select 6 trials (the exact trial lengths are randomly decided)   
%       - Trial length = 29-45:     Select 6 trials (the exact trial lengths are randomly decided)   
% (2). Approximately adhere to the change-point hazard rate.
%       - Trial length = 1-2:       No additional changepoints are allowed after t=1.
%       - Trial length = 3-4:       Out of the three trials for each trial length, exactly one trial contains exactly one additional changepoint (randomly positioned at t=2, t=3 or t=4)
%       - Trial length = 5-6:       Out of the three trials for each trial length, exactly two trials contain exactly one additional changepoint (randomly positioned at t=2, t=3, t=4, t=5, or t=6)
%       - Trial length >= 7:        The trial's actual hazard rate (excl. t=1) should not exceed the hazard rate tolerance limits: e.g. 1/6 ± 1/12 (i.e. between 1/12 and 1/4).  
% (3). Select an approximately equal number of trials for each SAC level.
%       - Trial length = 1-2:       Four trials of SAC1 with length 1, and four trials of SAC2 with length 2. 
%       - Trial length = 3-4:       Two trials of SAC3, and two trials of SAC4, and two trials with random SAC level (1-2 and 1-3)  
%       - Trial length = 5-6:       One trial of SAC5, and one trial of SAC6, and four trials with random SAC level (1-4 and 1-5)  
%       - Trial length >= 7:        In each of the five trial length groups (7-9, 10-13, 14-18, 19-28, 29-45) we select exactly 1 trial of each of the six SAC levels (1-6).  
% (4). Ensure a fair distribution of last change-point sizes. We split the absolute (directionless) change-point sizes (in velocity) into two parts of equal probability mass.   
%       - Trial length = 1-2:       There are no additional changepoints after the first sound.
%       - Trial length = 3-4:       One additional changepoint is small, the other is large. Both CPs appear in trials with different trial length.
%       - Trial length = 5-6:       For each trial length, one additional changepoint is small, the other is large.  
%       - Trial length >= 7:        For each of the six SAC levels, the first+second space quantile contain one large and one small last changepoint. 
%                                   Likewise, the fourth and fifth space quantile contain one large and one small last changepoint. The last changepoint size of the third space quantile (middle) is random.
% (5). Ensure a fair distribution of last/target velocities.
%       - Trial length = 1-2:       Each of the four trials (with identical trial length) will be located in a different quartile of velocity space. 
%       - Trial length = 3-6:       Each of the three trials (with identical trial length) will be located in a different tertile of velocity space.
%       - Trial length >= 7:        The five trials with identical SAC levels (1-6; spread over the five trial length groups) will each be located in a different quantile of velocity space. 
% (6). Ensure a fair distribution of last/target stimulus locations across the actual space (i.e. azimuth, not velocity). 
%       - Trial length = 1-2:       Each of the four trials (with identical trial length) will be located in a different quartile of space. 
%       - Trial length = 3-6:       Each of the three trials (with identical trial length) will be located in a different tertile of space.
%       - Trial length >= 7:        The five trials with identical SAC levels (1-6; spread over the five trial length groups) will each be located in a different quantile of space. 

%% PREPARE SOME THINGS BEFORE SAMPLING

%Shuffle the random number generator so as to ensure that all generated blocks are truly different   
rng('shuffle');

%Obtain parameter settings for the experiment
P = setExperimentParams_SAC_dir();

%% Generate trials until we have one valid trial for each combination of conditions   

%This work-around (hack), wherein we attempt multiple times to successfully generate a block of trials, was introduced because
%IN A PREVIOUS VERSION OF THIS FUNCTION (NOT RELEVANT ANYMORE) the conditions balancing method very occasionally got 'stuck' in an unsolvable loop.  
num_attempts = 1;
max_attempts = 10;
attempt_successful = false;
previous_warning = false;
while ~attempt_successful && (num_attempts <= max_attempts)
    
    %On a new attempt, there is a complete reset
    trials_cell = cell(1,P.num_trials_per_block);  
    num_selected_trials = 0;
    max_counter = 1e6; 
    counter = 1;
    T_all = [];
    while (num_selected_trials < P.num_trials_per_block) && (counter <= max_counter)

        %Generate a trial
        [x,v,cp,d] = genOneTrial_SAC_dir(mu_exp,sd_exp,P.cp_hazard_rate,P.ep_hazard_rate,P.first_stimulus_sd);
        
        %Obtain trial conditions
        T = getTrialConditions_SAC_dir(x,v,cp,d,mu_exp,sd_exp);

        %Check trial validity
        [valid_flag,T_all] = checkTrialValidity_SAC_dir(x,v,d,T,T_all);

        %Save the trial?
        if valid_flag
            num_selected_trials = num_selected_trials+1;
            tmp_s = []; tmp_s.mu_exp = mu_exp; tmp_s.sd_exp = sd_exp; tmp_s.x = x; tmp_s.v = v; tmp_s.cp = cp; tmp_s.d = d; tmp_s.SAC = T_all.SAC(num_selected_trials);
            trials_cell{1,num_selected_trials} = tmp_s;
        end

        %Count the number of generated trials on this attempt 
        counter = counter+1;
    end
    
    %Check if the attempt was successful
    if (num_selected_trials < P.num_trials_per_block)
        if (num_attempts < max_attempts)
            warning(['Unable to fulfill all conditions for trial selection on attempt ' num2str(num_attempts) '. Counter exceeded maximum (' num2str(max_counter) '). We will attempt again!']);
            num_attempts = num_attempts+1;
            previous_warning = true;
        else
            warning(['Unable to fulfill all conditions for trial selection on attempt ' num2str(num_attempts) '. Counter exceeded maximum (' num2str(max_counter) ').']);
            error('Something is likely wrong!');
        end
    else
        attempt_successful = true;
        if previous_warning
            disp(['Successful block generation on attempt: ' num2str(num_attempts) '. Number of generated trials: ' num2str(counter-1) '. Number of selected trials: ' num2str(num_selected_trials)]);
        end
    end
end
    
%% Shuffle the trial order (in case some trials are somehow always selected quicker than others)

shuffle_order = randperm(P.num_trials_per_block);
trials_cell = trials_cell(1,shuffle_order);

Names = fieldnames(T_all);
for i=1:numel(Names)
    T_all.(Names{i}) = T_all.(Names{i})(:,shuffle_order);
end

%% Run test --> Output in command window

%Create an overview of the trial's conditions
if test_flag
    if ~previous_warning
        disp(['Successful block generation on attempt: ' num2str(num_attempts) '. Number of generated trials: ' num2str(counter-1) '. Number of selected trials: ' num2str(num_selected_trials)]);
    end
    createTrialsOverview_SAC_dir(trials_cell,T_all);
end 

end %[EoF]
