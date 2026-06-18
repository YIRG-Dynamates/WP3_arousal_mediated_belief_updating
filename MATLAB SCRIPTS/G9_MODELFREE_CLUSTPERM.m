%%G8 MODELFREE CLUSTPERM
clear all

%% load basics

% loading preprocessed eye data
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024/preprocessed_eye_data_motion_version_12_07_2024.mat')
% loading trials cell
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat')
% loading included sounds
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\included_sounds_motion.mat')
% load latents
data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data';


%% make the incl_sounds accessible
incl_sounds_cell = cellfun(@(x) x.incl_sounds, included_sounds, 'UniformOutput', false);

SAC_level_cell = cellfun(@(x) x.SAC_level, included_sounds, 'UniformOutput', false);

%% check if they are the same length!!
A = SAC_level_cell;
B = incl_sounds_cell;
% Assume cell arrays A and B
if isequal(size(A), size(B)) % Check if cell arrays have the same dimensions
    same_length = true;
    for i = 1:numel(A)
        if ~isequal(size(A{i}), size(B{i})) % Check if each corresponding array has the same size
            same_length = false;
            break;
        end
    end
    if same_length
        disp('Both cell arrays have the same dimensions and same lengths of arrays.');
    else
        disp('Cell arrays have the same dimensions, but different lengths of arrays inside.');
    end
else
    disp('Cell arrays have different dimensions.');
end
clearvars A B


%% create matrix with only healthy pupil trace sounds and split by SAC level = 1

% set NaN where pupil trace is corrupted or smth
SAC_levels_healthy = SAC_level_cell;

SAC_levels_healthy = cellfun(@(SAC_levels_healthy, incl_sounds_cell) set_NaN_where_false(SAC_levels_healthy, incl_sounds_cell), ...
    SAC_levels_healthy, incl_sounds_cell, 'UniformOutput', false);

% set all SAC > 1 to 0
SAC_levels_healthy = cellfun(@(x) ...
    (x .* ~(x > 1)), ...
    SAC_levels_healthy, ...
    'UniformOutput', false);

%% matches 0010
SAC_matches0010 = {};
cnt = 1;

% Loop through each cell in SAC_levels_healthy
for col = 1:size(SAC_levels_healthy, 2)
    for row = 1:size(SAC_levels_healthy, 1)
        arr = SAC_levels_healthy{row, col}; % Get the current array
        if length(arr) < 4  % Skip if array is too short for pattern
            continue;
        end
        % Find indices where arr contains the pattern [0,0,1,0]
        for idx = 1:length(arr)-2 % so the index doesnt go out of range
            if arr(idx) == 0 && arr(idx+1) == 0 && arr(idx+2) == 1 %&& arr(idx+3) == 0
                % Store row, column, and index of "1" in matches cell
                SAC_matches0010{cnt, 1} = row;   % Row index
                SAC_matches0010{cnt, 2} = col;   % Column index
                SAC_matches0010{cnt, 3} = idx;   % Index of "1" in the array
                cnt = cnt + 1; % Increment count
            end
        end
    end
end

subjects = [SAC_matches0010{:,2}]';

% Find unique elements and their counts
[uniqueElements, ~, idx] = unique(subjects);
counts0010 = accumarray(idx, 1);

disp('Unique elements in column 2 and their counts:');
for i = 1:length(uniqueElements);
    fprintf('%d: %d\n', uniqueElements(i), counts0010(i));
end

pupilstrace0010 = [];

tic
for j = 1:length(SAC_matches0010)
    subj = SAC_matches0010{j,2};
    trial = SAC_matches0010{j,1};
    index = SAC_matches0010{j,3};
    time_stim_sequence =  preprocessed_eye_data{trial, subj}.A_stim_times(index) ;
    pupilstrace0010(j,:) = preprocessed_eye_data{trial, subj}.pupilSize(time_stim_sequence-500:time_stim_sequence+3500);
    % baselining
    pupilstrace0010(j,:) = pupilstrace0010(j,:) - mean(pupilstrace0010(j,1:1500)); %baselining period
end
toc

disp('0010 done');

%% SAME THING FOR 0000

SAC_matches0000 = {};
cnt = 1;

% Loop through each cell in SAC_levels_healthy
for col = 1:size(SAC_levels_healthy, 2)
    for row = 1:size(SAC_levels_healthy, 1)
        arr = SAC_levels_healthy{row, col}; % Get the current array
        if length(arr) < 4  % Skip if array is too short for pattern
            continue;
        end
        % Find indices where arr contains the pattern [0,0,0,0]
        for idx = 1:length(arr)-2 % so the index doesnt go out of range
            if arr(idx) == 0 && arr(idx+1) == 0 && arr(idx+2) == 0 %&& arr(idx+3) == 0
                % Store row, column, and index of "1" in matches cell
                SAC_matches0000{cnt, 1} = row;   % Row index
                SAC_matches0000{cnt, 2} = col;   % Column index
                SAC_matches0000{cnt, 3} = idx;   % Index of "1" in the array
                cnt = cnt + 1; % Increment count
            end
        end
    end
end

subjects = [SAC_matches0000{:,2}]';

% Find unique elements and their counts
[uniqueElements, ~, idx] = unique(subjects);
counts0000 = accumarray(idx, 1);

disp('Unique elements in column 2 and their counts:');
for i = 1:length(uniqueElements);
    fprintf('%d: %d\n', uniqueElements(i), counts0000(i));
end

pupilstrace0000 = [];

tic
for j = 1:length(SAC_matches0000)
    subj = SAC_matches0000{j,2};
    trial = SAC_matches0000{j,1};
    index = SAC_matches0000{j,3};
    time_stim_sequence =  preprocessed_eye_data{trial, subj}.A_stim_times(index) ;
    pupilstrace0000(j,:) = preprocessed_eye_data{trial, subj}.pupilSize(time_stim_sequence-500:time_stim_sequence+3500);
    % baselining
    pupilstrace0000(j,:) = pupilstrace0000(j,:) - mean(pupilstrace0000(j,1:1500)); %baselining period
end
toc

disp('0000 done');

%% all counts
counts_all = horzcat(counts0000, counts0010);


%% filtering before differential
% (WAY WAY faster now with filtfilt() than it was with lowpass() )

% Sampling frequency (choose appropriately)
fs_samplingrate = 1000;  % Hz, adjust based on your actual signal

% Cutoff frequency
f_cutoff = 4;  % Hz

% Normalized cutoff frequency (Nyquist = fs/2)
Wn = f_cutoff / (fs_samplingrate/2);

% Filter order (higher = steeper cutoff, more delay)
N = 100;  % Adjust this to make the cutoff steeper

% Design FIR lowpass filter using the window method
b = fir1(N, Wn, 'low');

% Zero-phase filtering using filtfilt
% filtered_signal = filtfilt(b, 1, signal);

% Plot frequency response to verify steep cutoff
fvtool(b, 1);

tic
for cnt = 1:height(pupilstrace0000)
    pupilstrace0000(cnt,:) = filtfilt(b, 1, pupilstrace0000(cnt,:));
    disp(cnt);
end
toc
tic
for cnt = 1:height(pupilstrace0010)
    pupilstrace0010(cnt,:) = filtfilt(b, 1, pupilstrace0010(cnt,:));
    disp(cnt);
end
toc

% A zero-phase, low-pass finite impulse response (FIR) filter was 
% applied to the signal to attenuate frequencies above 4 Hz. 
% The filter was designed using the window method with a Hamming window 
% (filter order = 100) and a normalized cutoff frequency of 0.008 
% (corresponding to 4 Hz for a sampling rate of 1000 Hz). 
% To eliminate phase distortion, the filter was applied in both forward 
% and reverse directions using MATLAB%s filtfilt function, 
% resulting in zero-phase delay.

%% make the differential

difftrace_SAC0010 = diff(pupilstrace0010, 1, 2);
difftrace_SAC0000 = diff(pupilstrace0000, 1, 2);

disp("differential done");

plot(mean(difftrace_SAC0010, 1))
hold on
plot(mean(difftrace_SAC0000, 1))
hold off


%% make fieldtrip structure
data_beispeil = load('C:\Users\rfleischmann\Desktop\DATA\PUPIL DATA FIELDTRIP FORMAT\DE_preprocessed_eeg\S041_preprocessed_data.mat')

lengthsequence = 4000;
timeline = -1.499:0.001:2.5;
elec = data_beispeil.data.elec;
fsample = 1000;
label = data_beispeil.data.label ;
cfg = data_beispeil.data.cfg  ;
data = [];

tic
for sbj = 1:22;
    data = [];
    rows0000 = find(cell2mat(SAC_matches0000(:,2)) == sbj);
    rows0010 = find(cell2mat(SAC_matches0010(:,2)) == sbj);
    cnt = 1;
    for row = rows0000(1):rows0000(end);

        data.trial{cnt} = zeros(128,lengthsequence);
        data.trial{cnt}(1,:) = difftrace_SAC0000(row, :);
        data.trial{cnt}(2,:) = pupilstrace0000(row, 1:end-1); %one longer than the difftrace
        data.time{cnt} = timeline;

        cnt = cnt + 1;
    end

    for row = rows0010(1):rows0010(end);

        data.trial{cnt} = zeros(128,lengthsequence);
        data.trial{cnt}(1,:) = difftrace_SAC0010(row, :);
        data.trial{cnt}(2,:) = pupilstrace0010(row, 1:end-1); %one longer than the difftrace
        data.time{cnt} = timeline;

        cnt = cnt + 1;
    end

    data.elec = elec;
    data.fsample = fsample;
    data.label = label;
    data.cgf = cfg;

    data.select_log = horzcat(zeros(1,length(rows0000)), ones(1,length(rows0010)));

    ERP0 = [];
    ERP1 = [];

     % set cfg
     cfg = [];
     cfg.latency = [0 2.5];           
     % temp_trials gives all the correct indices
     cfg.trials = find(data.select_log == 0);
     % cfg.keeptrials = 'yes' or 'no', return individual trials or average (default = 'no')
     ERP0 = ft_timelockanalysis(cfg,data)

     cfg.trials = find(data.select_log == 1);
     ERP1 = ft_timelockanalysis(cfg,data)


    allsbj_data{sbj, 1} = ERP0;
    allsbj_data{sbj, 2} = ERP1;

    disp(sbj)
end
toc

%% now lets go cluster based perm, preparation

ERP000 = {};
ERP001 = {};

for cnt = 1:22;
    ERP000{1,cnt} = allsbj_data{cnt,1} ;
    ERP001{1,cnt} = allsbj_data{cnt,2}  ;
end

cfg         = [];
cfg.channel = 'Fp1';            % relict of the EEG, this is stil just pupil data channel 1, diffchannel
cfg.latency = [0 2.5];           % the data is already shortened to the epoch 0-0.5, so were doing the whole length yeeehaaaaw

cfg_neighb        = [];         
cfg_neighb.method = 'distance';
%cfg.feedback = 'yes';
neighbours        = ft_prepare_neighbours(cfg_neighb, ERP001{1,1});

cfg.neighbours    = neighbours;  % the neighbours specify for each sensor with
                                 % which other sensors it can form clusters

cfg.method           = 'montecarlo';
%cfg.statistic        = 'ft_statfun_depsamplesFunivariate';  %possible statistics, choose your warrior
%cfg.statistic        =  'ft_statfun_indepsamplesF'
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
%cfg.minnbchan        = 1; %minimum cluster requirement
cfg.neighbours       = neighbours;  % same as defined for the between-trials experiment
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.05;
cfg.numrandomization = 1000;

design = []
Nsubj  = 22;
design = zeros(2, Nsubj*2);
design(1,:) = [1:Nsubj 1:Nsubj ];
design(2,:) = [ones(1,Nsubj) ones(1,Nsubj)*2];

cfg.design = design;
cfg.uvar   = 1;   %index in the design, set above
cfg.ivar   = 2;

%% cluster based perms
cfg.channel = 'Fp1'; 
[stat_diff] = ft_timelockstatistics(cfg, ERP000{:}, ERP001{:});

logic_diff = stat_diff.negclusterslabelmat  == 1;
length_diff = sum(logic_diff);
length_diff_start = find(logic_diff, 1, 'first');
length_diff_end = find(logic_diff, 1, 'last');

cfg.channel = 'Fz';  
[stat_pupil] = ft_timelockstatistics(cfg, ERP000{:}, ERP001{:});

logic_pup = stat_pupil.negclusterslabelmat  == 1;
length_pup = sum(logic_pup);
length_pup_start = find(logic_pup, 1, 'first');
length_pup_end = find(logic_pup, 1, 'last');

%% effect sizes for diff
% Cohen's d cluster statistics

% cfg.channel = 'all';  
% cfg.statistic        = 'cohensd';      % <<< KEY CHANGE
% cfg.correctm         = 'no';
% 
% % run statistics
% [stat_diff_cohen] = ft_timelockstatistics(cfg, ERP000{:}, ERP001{:});

% effect sizes different solution which gives the exact same values, but WITH confidence intervals

Nsubj = 22;
channel_idx = 1;   % e.g., Fp1
latency_idx = 1:length(stat_diff.time);

diff_matrix = zeros(Nsubj, length(latency_idx));

for subj = 1:Nsubj
    diff_matrix(subj,:) = ERP001{1,subj}.avg(channel_idx,:) - ERP000{1,subj}.avg(channel_idx,:);
end

% compute mean and SD of differences
mean_diff = mean(diff_matrix,1);
sd_diff   = std(diff_matrix,0,1);

% Cohen's dz
cohens_d_diff = mean_diff ./ sd_diff;

% t critical value
alpha = 0.05;
tcrit = tinv(1-alpha/2, Nsubj-1);

% 95% CI
ci_lower_diff = cohens_d_diff - tcrit .* sqrt(1/Nsubj .* (1 + (cohens_d_diff.^2)/2));
ci_upper_diff = cohens_d_diff + tcrit .* sqrt(1/Nsubj .* (1 + (cohens_d_diff.^2)/2));
ci_SEM_diff = tcrit .* sqrt(1/Nsubj .* (1 + (cohens_d_diff.^2)/2));

cohens_d_diff = vertcat(cohens_d_diff, ci_lower_diff, ci_upper_diff, ci_SEM_diff);

%% effect sizes for puptrace

Nsubj = 22;
channel_idx = 2;   % important change here
latency_idx = 1:length(stat_pupil.time);

pup_matrix = zeros(Nsubj, length(latency_idx));

for subj = 1:Nsubj
    pup_matrix(subj,:) = ERP001{1,subj}.avg(channel_idx,:) - ERP000{1,subj}.avg(channel_idx,:);
end

% compute mean and SD of differences
mean_pup = mean(pup_matrix,1);
sd_pup   = std(pup_matrix,0,1);

% Cohen's dz
cohens_d_pup = mean_pup ./ sd_pup;

% t critical value
alpha = 0.05;
tcrit = tinv(1-alpha/2, Nsubj-1);

% 95% CI
ci_lower_pup = cohens_d_pup - tcrit .* sqrt(1/Nsubj .* (1 + (cohens_d_pup.^2)/2));
ci_upper_pup = cohens_d_pup + tcrit .* sqrt(1/Nsubj .* (1 + (cohens_d_pup.^2)/2));
ci_SEM_pup = tcrit .* sqrt(1/Nsubj .* (1 + (cohens_d_pup.^2)/2));

cohens_d_pup = vertcat(cohens_d_pup, ci_lower_pup, ci_upper_pup, ci_SEM_pup);

%% SAVING

output_path = 'C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/REGMODELS/';
     
% Combine and savee
filename = 'G9_clustperm_stats_modelfree_puptrace.mat';  
fullfile_path = fullfile(output_path, filename);
save(fullfile_path, 'stat_pupil');

% Combine and savee
filename = 'G9_clustperm_stats_modelfree_difftrace.mat';  
fullfile_path = fullfile(output_path, filename);
save(fullfile_path, 'stat_diff');

% Combine and savee
filename = 'G9_clustperm_stats_modelfree_cohensdmap_difftrace.mat';  
fullfile_path = fullfile(output_path, filename);
save(fullfile_path, 'cohens_d_diff');

% Combine and savee
filename = 'G9_clustperm_stats_modelfree_cohensdmap_puptrace.mat';  
fullfile_path = fullfile(output_path, filename);
save(fullfile_path, 'cohens_d_pup');


%% opening
load('C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/REGMODELS/G9_clustperm_stats_modelfree_cohensdmap_puptrace.mat')
[max_val_pup, idx] = max(cohens_d_pup(1,:));
CI_max_val_pup = cohens_d_pup(2:3,idx);
time_effect_peak_pup = idx;

load('C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/REGMODELS/G9_clustperm_stats_modelfree_cohensdmap_difftrace.mat')
[max_val_diff, idx] = max(cohens_d_diff(1,:));
CI_max_val_diff = cohens_d_pup(2:3,idx);
time_effect_peak_diff = idx;


%% output file 

% Open text file for writing
fileID = fopen('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\REGMODELS\G9_MODELFREE_CLUSTPERM_ANALYSIS.txt','w');

% ---- Custom header lines ----
fprintf(fileID, 'CLUSTER_BASED PERMUTATION ANALYSIS, MODELFREE\n');
fprintf(fileID, 'Generated on: %s\n', datestr(now));
fprintf(fileID, '---------------------------------\n\n');

% ---- Write  data ----
fprintf(fileID, '---settings of clustperm: \n');
fprintf(fileID, 'statistic: \tdepsamlesT \n');
fprintf(fileID, 'method: \tmontecarlo \n');
fprintf(fileID, 'clusterstat: \tmaxsum \n');
fprintf(fileID, '(meaning: summed cluster t) \n');
fprintf(fileID, 'alpha: \t\t0.5 \n');
fprintf(fileID, 'clusteralpha: \t0.5 \n');
fprintf(fileID, 'numrandom: \t1000 \n');
fprintf(fileID, 'epoch: \t\t0:2.5s \n');
fprintf(fileID, '\n');
fprintf(fileID, 'number of subjects: 22\n');
fprintf(fileID, '\n');
fprintf(fileID, '\n');

% ---- statistics diff trace ----
fprintf(fileID, '---statistics of the difference trace');
fprintf(fileID, '\n');
fprintf(fileID, ['negative cluster, p-value:', num2str(stat_diff.negclusters.prob), '\n']);
fprintf(fileID, ['negative cluster, clusterstat:', num2str(stat_diff.negclusters.clusterstat), '\n']);
fprintf(fileID, ['negative cluster, stddev:', num2str(stat_diff.negclusters.stddev), '\n']);
fprintf(fileID, ['negative cluster, cirange:', num2str(stat_diff.negclusters.cirange), '\n']);
fprintf(fileID, ['negative cluster, CI upper:', num2str(stat_diff.negclusters.clusterstat + stat_diff.negclusters.cirange), '\n']);
fprintf(fileID, ['negative cluster, CI lower:', num2str(stat_diff.negclusters.clusterstat - stat_diff.negclusters.cirange), '\n']);
fprintf(fileID, '\n');

% ---- properties diff trace ----
fprintf(fileID, '---properties of the difference cluster');
fprintf(fileID, '\n');
fprintf(fileID, ['length in ms:', num2str(length_diff), '\n']);
fprintf(fileID, ['start in ms after stimulus onset:', num2str(length_diff_start), '\n']);
fprintf(fileID, ['start in ms after stimulus onset:', num2str(length_diff_end), '\n']);
fprintf(fileID, '\n');

% ---- statistics pup trace ----
fprintf(fileID, '---statistics of the pupil trace');
fprintf(fileID, '\n');
fprintf(fileID, ['negative cluster, p-value:', num2str(stat_pupil.negclusters.prob), '\n']);
fprintf(fileID, ['negative cluster, clusterstat:', num2str(stat_pupil.negclusters.clusterstat), '\n']);
fprintf(fileID, ['negative cluster, stddev:', num2str(stat_pupil.negclusters.stddev), '\n']);
fprintf(fileID, ['negative cluster, cirange:', num2str(stat_pupil.negclusters.cirange), '\n']);
fprintf(fileID, ['negative cluster, CI upper:', num2str(stat_pupil.negclusters.clusterstat + stat_pupil.negclusters.cirange), '\n']);
fprintf(fileID, ['negative cluster, CI lower:', num2str(stat_pupil.negclusters.clusterstat - stat_pupil.negclusters.cirange), '\n']);
fprintf(fileID, '\n');

% ---- properties pup trace ----
fprintf(fileID, '---properties of the pupil trace cluster');
fprintf(fileID, '\n');
fprintf(fileID, ['length in ms:', num2str(length_pup), '\n']);
fprintf(fileID, ['start in ms after stimulus onset:', num2str(length_pup_start), '\n']);
fprintf(fileID, ['start in ms after stimulus onset:', num2str(length_pup_end), '\n']);
fprintf(fileID, '\n');

% ------ effect sizes ------------
fprintf(fileID, '---Effect Size Peaks (Cohens d) - Pupil Size');
fprintf(fileID, '\n');
fprintf(fileID, ['Pupil Effect Peak (ms):', num2str(time_effect_peak_pup), '\n']);
fprintf(fileID, ['Pupil Effect Peak (Cohens d):', num2str(max_val_pup), '\n']);
fprintf(fileID, ['Pupil Effect Peak CI:', num2str(CI_max_val_pup(1)), ' ', num2str(CI_max_val_pup(2)) '\n']);
fprintf(fileID, '\n');
fprintf(fileID, '---Effect Size Peaks (Cohens d) - Pupil Dilation Rate');
fprintf(fileID, '\n');
fprintf(fileID, ['Pupil Effect Peak (ms):', num2str(time_effect_peak_diff), '\n']);
fprintf(fileID, ['Pupil Effect Peak (Cohens d):', num2str(max_val_diff), '\n']);
fprintf(fileID, ['Pupil Effect Peak CI:', num2str(CI_max_val_diff(1)), ' ', num2str(CI_max_val_diff(2)), '\n']);
fprintf(fileID, '\n');
fprintf(fileID, 'for effect sizes see the cohens d map, saved as clustperm_stats_modelfree_cohensdmap_diff.mat (or _pup.mat)');
fprintf(fileID, '\n');

% ---- Custom footer ----
fprintf(fileID, '\n---------------------------------\n');
fprintf(fileID, 'this txt was created by script G9.\n');
fprintf(fileID, 'i hope this contains everything you need.\n');

% Close file
fclose(fileID);

disp('File written successfully.');



%% prepare pupil dilation rate plot (diff)
% calculating entire traces per subject, longer period than the one saved
% in ERP, thats why this is done again!

% make one average trace per subject
for sbj = 1:22
    logical_sbj_000 = cell2mat(SAC_matches0000(:,2)) == sbj;
    meandifftraces000(sbj,:) = mean(difftrace_SAC0000(logical_sbj_000, :), 1);

    logical_sbj_001 = cell2mat(SAC_matches0010(:,2)) == sbj;
    meandifftraces001(sbj,:) = mean(difftrace_SAC0010(logical_sbj_001, :), 1);
end

% make SEM
difftrace_000_SEM = std(meandifftraces000, 0, 1) ./ sqrt(size(meandifftraces000, 1));
difftrace_001_SEM = std(meandifftraces001, 0, 1) ./ sqrt(size(meandifftraces001, 1));
% make mean
difftrace_000_mean = mean(meandifftraces000,1);
difftrace_001_mean = mean(meandifftraces001,1);

%% plot pupil dilation rate plot (diff)

logical_pos = stat_diff.negclusterslabelmat ==  1;

mean_trace0 = difftrace_000_mean;
mean_trace1 = difftrace_001_mean;
sem_trace0 = difftrace_000_SEM;
sem_trace1 = difftrace_001_SEM;

high_color = [0, 0.3, 0.6];    % Dark but brighter and more saturated blue
low_color  = [0.25, 0.65, 0.9]; % Dark sky blue, brighter and more saturated
sign_color = [0.95, 0.6, 0.8];  % Light purple for shaded regions

plot_clustperm(1, mean_trace0, mean_trace1, sem_trace0, sem_trace1, logical_pos, high_color, low_color, sign_color)

xline(-1000, '--', 'no CP/           ', 'Color', high_color,'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top'); 
xline(-1000, '--', '           no CP', 'Color', low_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top'); 
xline(-1000, 'k--'); 

xline(-500, '--',  'no CP/           ', 'Color', high_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top'); 
xline(-500, '--',  '           no CP', 'Color', low_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top'); 
xline(-500, 'k--'); 

xline(0, '--', 'CP/           ', 'Color', high_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top'); 
xline(0, '--', '       no CP', 'Color', low_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top'); 
xline(0, 'k-', 'LineWidth', 2); 

xline(500, 'k--'); 
xline(1000, 'k--'); 

diff_plot = gcf;  % store the figure handle

%% prepare pupil size plot (pupils)
% calculating entire traces per subject, longer period than the one saved
% in ERP, thats why this is done again!

% make one average trace per subject
for sbj = 1:22
    logical_sbj_000 = cell2mat(SAC_matches0000(:,2)) == sbj;
    meanpupilstrace000(sbj,:) = mean(pupilstrace0000(logical_sbj_000, :), 1);

    logical_sbj_001 = cell2mat(SAC_matches0010(:,2)) == sbj;
    meanpupilstrace001(sbj,:) = mean(pupilstrace0010(logical_sbj_001, :), 1);
end

% make SEM
puptrace_000_SEM = std(meanpupilstrace000, 0, 1) ./ sqrt(size(meanpupilstrace000, 1));
puptrace_001_SEM = std(meanpupilstrace001, 0, 1) ./ sqrt(size(meanpupilstrace001, 1));
% make mean
puptrace_000_mean = mean(meanpupilstrace000,1);
puptrace_001_mean = mean(meanpupilstrace001,1);


%% plot pupil size plot (pupils)

logical_pos = stat_pupil.negclusterslabelmat ==  1;

mean_trace0 = puptrace_000_mean;
mean_trace1 = puptrace_001_mean;
sem_trace0 = puptrace_000_SEM;
sem_trace1 = puptrace_001_SEM;

high_color = [0, 0.3, 0.6];    % Dark but brighter and more saturated blue
low_color  = [0.25, 0.65, 0.9]; % Dark sky blue, brighter and more saturated
sign_color = [0.95, 0.6, 0.8];  % Light purple for shaded regions

plot_clustperm(2, mean_trace0, mean_trace1, sem_trace0, sem_trace1, logical_pos, high_color, low_color, sign_color)

xline(-1000, '--', 'no CP/', 'Color', high_color,'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom'); 
xline(-1000, '--', '           no CP', 'Color', low_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom'); 
xline(-1000, 'k--'); 

xline(-500, '--',  'no CP/', 'Color', high_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom'); 
xline(-500, '--',  '           no CP', 'Color', low_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom'); 
xline(-500, 'k--'); 

xline(0, '--', 'CP/', 'Color', high_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom'); 
xline(0, '--', '       no CP', 'Color', low_color, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom'); 
xline(0, 'k-', 'LineWidth', 2); 

xline(500, 'k--'); 
xline(1000, 'k--'); 

grid off;

title('Pupiltraces: High vs. Low Surprisal');
pupil_plot = gcf;  % store the figure handle

%% plot cohens d (both)

mean_trace0 =  cohens_d_diff(1,:)
mean_trace1 =  cohens_d_pup(1,:);
sem_trace0 =  cohens_d_diff(4,:)
sem_trace1 =  cohens_d_pup(4,:);

high_color = [0, 0.3, 0.6];    % Dark but brighter and more saturated blue
low_color  = [0.6, 0.1, 0.1];; % red
fignum = 3; 

figure(fignum); clf;
hold on;

x = 0:2500;  % Time vector to end at 2500 exactly
%yLimits = [-0.14 0.16];  % Y-axis limits

% Plot shaded SEMs
fill([x fliplr(x)], [mean_trace0 - sem_trace0, fliplr(mean_trace0 + sem_trace0)], ...
    low_color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

fill([x fliplr(x)], [mean_trace1 - sem_trace1, fliplr(mean_trace1 + sem_trace1)], ...
    high_color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% Plot means
plot(x, mean_trace0, 'Color', low_color, 'LineWidth', 2);
plot(x, mean_trace1, 'Color',  high_color, 'LineWidth', 2);
hold off;

xline(-1000, 'k--'); 
xline(-500, 'k--'); 
xline(0, 'k-', 'LineWidth', 2); 
xline(500, 'k--'); 
xline(1000, 'k--'); 

yline(0,'k-')

cohens_plot = gcf;  % store the figure handle

%% combine
% Create a new figure (Figure 3)
figure(4); clf;

%title('Pupil Derivatives with Significant Difference');

subplot(3,1,1);  % bottom subplot
ax2 = gca;
fig2_axes = findall(pupil_plot, 'Type', 'axes');
copyobj(allchild(fig2_axes), ax2);
ylim([-100 30])
xlim([-1500 2500])
xlabel('Time (ms)');
ylabel('Pupil Size (AU)');
legend({'Significant Difference'} , 'Location', 'northeast');
box on;  % Adds a frame around the axes% Create subplots in the new figure

subplot(3,1,2);  % top subplot
ax1 = gca;
fig1_axes = findall(diff_plot, 'Type', 'axes');
copyobj(allchild(fig1_axes), ax1);
ylim([-0.14 0.16])
xlim([-1500 2500])
xlabel('Time (ms)');
ylabel(['Pupil Dilation Rate'])
legend({'Significant Difference'} , 'Location', 'northeast');
box on;  % Adds a frame around the axes

subplot(3,1,3);  % top subplot
ax1 = gca;
fig1_axes = findall(cohens_plot, 'Type', 'axes');
copyobj(allchild(fig1_axes), ax1);
ylim([-1 2])
xlim([-1500 2500])
xlabel('Time (ms)');
ylabel(['Cohens d(z)'])
legend({'Dilation Rate', 'Pupil Size'} , 'Location', 'northwest');
box on;  % Adds a frame around the axes

%% SAVING
% Get figure 
currentFig = gcf;  % 

% Set size (width, height) 
desiredWidth  = 600;  % Pixels 
desiredHeight = 600;  
set(currentFig, 'Position', [100, 100, desiredWidth, desiredHeight]);  % [left, bottom, width, height]

%Save the figure 
savePath = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\G9_PUPTRACE_AND_DERIVATIVE_CLUSTERB_MODFREE.png';  % Replace with your desired path/format
exportgraphics(currentFig, savePath, 'Resolution', 300);  % High-resolution PNG
saveas(currentFig, 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\G9_PUPTRACE_AND_DERIVATIVE_CLUSTERB_MODFREE.svg');  % SVG 
saveas(currentFig, 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\G9_PUPTRACE_AND_DERIVATIVE_CLUSTERB_MODFREE.fig');  % fig
saveas(currentFig, 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA\PLOTS\G9_PUPTRACE_AND_DERIVATIVE_CLUSTERB_MODFREE.pdf');  

