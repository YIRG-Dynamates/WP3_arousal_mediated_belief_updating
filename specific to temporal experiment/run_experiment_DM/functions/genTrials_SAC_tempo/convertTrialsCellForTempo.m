function trials_cell = convertTrialsCellForTempo(trials_cell,MAI,a,b,transform_flag)

if nargin < 5
    transform_flag = true;
end

num_trials = numel(trials_cell);

for j=1:num_trials
    
    trials_cell{j}.MAI = MAI;
    trials_cell{j}.a = a;
    trials_cell{j}.b = b;
    
    num_stim = numel(trials_cell{j}.x) + 1;
    
    %Fields specific to temporal task
    if transform_flag
        SOAs = transform2perJND(trials_cell{j}.x,a,b,'trans2real');
    else
        SOAs = trials_cell{j}.x;
    end
    
    trials_cell{j}.SOA = [SOAs NaN];                                        %The SOA is added after every stimulus, also the last one (but not before the first one)                                                            
    trials_cell{j}.SOA_change = [NaN diff(SOAs) NaN];
    
    %Add a dummy NaN to 'directions' (slow-down / speed-up) and 'change-point' logicals   
    trials_cell{j}.d = [NaN trials_cell{j}.d];
    trials_cell{j}.cp = [NaN trials_cell{j}.cp];
       
    %Set locations and velocities to zero (but ensure existence for future use in WP3[?])
    trials_cell{j}.x = zeros(1,num_stim);
    trials_cell{j}.v = zeros(1,num_stim);
    
end

end %[EoF]
