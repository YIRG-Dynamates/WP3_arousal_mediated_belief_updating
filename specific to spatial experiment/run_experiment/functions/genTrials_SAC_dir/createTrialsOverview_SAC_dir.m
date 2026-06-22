function createTrialsOverview_SAC_dir(trials_cell,T_all)

%Perform some quick sanity checks
num_trials = sum(~cellfun(@isempty,trials_cell));
if num_trials < 50
    warning(['The number of selected trials is smaller than anticipated! (' num2str(num_trials) ' instead of 50)']);
end

%Check that SAC levels match, that the direction change after each cp, and that the location changes follow the given velocities    
for i=1:50
    assert(trials_cell{i}.SAC == T_all.SAC(i),['SAC levels do not match for trial ' num2str(i)]);
    assert(all(trials_cell{i}.d(2:end) == sign(trials_cell{i}.v(2:end))),['Directions do not match velocity signs for trial ' num2str(i)]);
    assert(all((diff(trials_cell{i}.x) - trials_cell{i}.v(2:end)) < 1e6),['Velocities do not match location changes for trial ' num2str(i)]);
    if numel(trials_cell{i}.x) > 2
        assert(all(logical(diff(trials_cell{i}.d(2:end))) == trials_cell{i}.cp(3:end)),['Direction changes and change-points do not match for trial ' num2str(i)]);
    end
end

%Count the number of trials per trial-length-bin
num_stim_bins = unique(T_all.num_stim_bin)';
bin_counts = nan(size(num_stim_bins));
SAC_levels = unique(T_all.SAC);
SAC_counts = nan(numel(SAC_levels),numel(num_stim_bins));
for i=1:numel(num_stim_bins)
    i_rel = T_all.num_stim_bin == num_stim_bins(i);
    bin_counts(i) = sum(i_rel);
    for j=1:numel(SAC_levels)
        SAC_counts(j,i) = sum(T_all.SAC(i_rel) == SAC_levels(j));
    end
end
disp(' '); disp('Trial length bins and trial counts per SAC level (1-5):');
disp(num_stim_bins); disp(SAC_counts); 

%Check the velocity per SAC level, separately for the short and long trials
vels_short = nan(5,4);
vels_long = nan(5,6);
for i=1:5
    i_SAC = (T_all.SAC == i);
    
    idx_short = find(i_SAC & (T_all.num_stim_bin <= 5));
    for j=1:numel(idx_short)
        vels_short(i,j) = trials_cell{idx_short(j)}.v(end);
    end
    vels_short(i,:) = sort(vels_short(i,:));
    
    idx_long = find(i_SAC & (T_all.num_stim_bin >= 6));
    for j=1:numel(idx_long)
        vels_long(i,j) = trials_cell{idx_long(j)}.v(end);
    end
    vels_long(i,:) = sort(vels_long(i,:));
end
disp('Last velocities for short trials per SAC level (rows)'); disp(vels_short);
disp('Last velocities for long trials per SAC level (rows)'); disp(vels_long); 

%Check the velocity per spatial location, separately for the short and long trials
vels_short = nan(5,4);
vels_long = nan(5,6);
locs_short = nan(5,4);
locs_long = nan(5,6);
for i=1:5
    i_loc = (T_all.target_loc_5_bin == i);
    
    idx_short = find(i_loc & (T_all.num_stim_bin <= 5));
    for j=1:numel(idx_short)
        vels_short(i,j) = trials_cell{idx_short(j)}.v(end);
        locs_short(i,j) = trials_cell{idx_short(j)}.x(end);
    end
    [vels_short(i,:),sort_idx] = sort(vels_short(i,:));
    locs_short(i,:) = locs_short(i,sort_idx);
    
    idx_long = find(i_loc & (T_all.num_stim_bin >= 6));
    for j=1:numel(idx_long)
        vels_long(i,j) = trials_cell{idx_long(j)}.v(end);
        locs_long(i,j) = trials_cell{idx_long(j)}.x(end);
    end
    [vels_long(i,:),sort_idx] = sort(vels_long(i,:));
    locs_long(i,:) = locs_long(i,sort_idx);
end
disp(' '); 
disp('Last velocities for short trials per spatial location bin (rows)'); disp(vels_short);
disp('Accompanying last spatial locations for the above velocities for short trials'); disp(locs_short);
disp(' ');
disp('Last velocities for long trials per spatial location bin (rows)'); disp(vels_long);
disp('Accompanying last spatial locations for the above velocities for long trials'); disp(locs_long);

%Mean trial length and actual hazard rates
disp('Mean trial length across all trials:');
disp(mean(T_all.num_stim-1));
disp('Actual hazard rate across all trials:');
disp(sum(T_all.num_cp-1)/sum(T_all.num_stim-2));                            %Exclude the first two stimuli of each trial

%Find the maximum prior strength within each trial   
max_prior_length = nan(1,num_trials);
for j=1:num_trials
    max_prior_length(j) = max(diff(find([trials_cell{j}.cp(2:end) 1])));    %Note that the extra '1' is there to deal with trials without a cp at the end
end
gaps = 1:10;
num_trials_with_gap = nan(size(gaps));
for i=1:numel(gaps)
    num_trials_with_gap(i) = sum(max_prior_length >= gaps(i));
end
disp('Number of trials with a maximum prior strength (anywhere in trial) of at least this long:');
disp(gaps); disp(num_trials_with_gap); 

end %[EoF]
