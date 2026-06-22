function T = getTrialConditions_SAC_dir(x,v,cp,d,mu_exp,sd_exp)
%Obtain all relevant trial conditions

nx = numel(x);          

%Sound After Changepoint level (SAC)
idx_last_cp = find(cp,1,'last');
T.SAC = nx-idx_last_cp+1;

%Actual hazard rate
T.num_cp = nansum(cp);
if nx <= 2
    T.actual_cp_hazard_rate = NaN;
else
    T.actual_cp_hazard_rate = (T.num_cp-1)/(nx-2);  %Exclude the first two stimuli
end

%Trial length bin number
T.num_stim = nx;
if nx <= 6      %(1-5 velocities)
    T.num_stim_bin = nx-1;
elseif nx <= 8 %(6-7 velocities)
    T.num_stim_bin = 7;
elseif nx <= 11 %(8-10 velocities)
    T.num_stim_bin = 8;
elseif nx <= 15 %(11-14 velocities)
    T.num_stim_bin = 9;
elseif nx <= 21 %(15-20 velocities)   
    T.num_stim_bin = 10;
elseif nx <= 45 %(21-44 velocities)   
    T.num_stim_bin = 11;
else            %(>44 velocities)
    T.num_stim_bin = 12;
end

%Bin the last velocity into two or three parts
Q2 = mu_exp;
T.target_vel_2_bin = find([Q2 inf] >= abs(v(nx)),1,'first');                    %Note the 'abs' such that this is a measure of 'difficulty'
Q3 = [norminv(1/3,mu_exp,sd_exp),norminv(2/3,mu_exp,sd_exp)];
T.target_vel_3_bin = find([Q3 inf] >= abs(v(nx)),1,'first');                    %Note the 'abs' such that this is a measure of 'difficulty'

%Bin the last stimulus location (not velocity!) into spatial quantiles
Q5 = linspace(-40,40,6);
T.target_loc_5_bin = find([Q5(2:5) inf] >= x(nx),1,'first');

%Bin the velocity direction
dir_options = [-1,1];
T.target_dir_bin = find(dir_options == d(nx),1,'first');

end %[EoF]
