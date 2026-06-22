function trials_cell = convertTempoTrialsCellForModel(trials_cell)

num_trials = numel(trials_cell);

SOA_space_limits = [2/3*300 4/3*1000];

for j=1:num_trials
    
    a = trials_cell{j}.a;
    b = trials_cell{j}.b;
    
    trials_cell{j}.space_limits = transform2perJND(SOA_space_limits,a,b,'real2trans');
    
    SOAs = trials_cell{j}.SOA;
    SOAs(end) = [];                                                         %Remove last SOA (NaN was added and replaced by lead-out interval
    
    trials_cell{j}.x = transform2perJND(SOAs,a,b,'real2trans');
    trials_cell{j}.v = [NaN diff(trials_cell{j}.x)];
    
    trials_cell{j}.d(1) = [];                                               %Remove dummy NaN from directions and changepoints
    trials_cell{j}.cp(1) = []; 
end

end %[EoF]
