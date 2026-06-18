clear all

data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data';
load(fullfile(data_folder, "LATENT VARS/", "BdCPfitResults_4_latent_vars_2.mat")); %nr 4 is the same one but with medians
load(fullfile(data_folder, "preprocessing_version_12_07_2024/", "included_sounds_motion.mat"));

delta_amps_all_motion_fitwintercept = load(fullfile(data_folder, "fitting_2023version_12_07_2024/", "2024_07_11_delta_amplitudes_PRF_2023version.mat")); % w/ intercept
delta_amps_all_motion_fwi = delta_amps_all_motion_fitwintercept.delta_amps_all_motion;

load(fullfile(data_folder, "fittingPRF_vers2023_01082024/", "delta_amplitudes_PRF_2023.mat")); % w/o interxept
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat');

%% anpassen für weniger subjects und anpassen der sound-zahl
% all in medians, nothin in averages anymore

% surprisal
surp_med_motion = [];
%surp_avg_motion = surprisal.avg
surp_med_motion = surprisal.med;
surp_med_motion(:,1:5) = [];

%prior entropy
pent_med_motion = [];
pent_med_motion = prior_entropy.med;
pent_med_motion(:,1:5) = [];

%ppCP
ppCP_med_motion = [];
ppCP_med_motion = post_prob_CP.med;
ppCP_med_motion(:,1:5) = [];

%infogain
infog_med_motion = [];
infog_med_motion = info_gain.med;
infog_med_motion(:,1:5) = [];

% posterior entropy
postent_med_motion = [];
postent_med_motion = post_entropy.med;
postent_med_motion(:,1:5) = [];

% post_d
post_d_motion = [];
post_d_motion = post_d.med;
post_d_motion(:,1:5) = [];

% prior d
prior_d_motion = [];
prior_d_motion = post_d.med;
prior_d_motion(:,1:5) = [];

% sac levels
SAC_levels(:,1:5) = [];

% make block numbers
block_nrs = surp_med_motion;
for i = 1:size(block_nrs, 1)   % loop over rows
    % Determine which value to assign based on row index
    val = ceil(i / 50);   % 1,2,3,4 for each 50-row block
    
    for j = 1:size(block_nrs, 2)   % loop over columns
        % Replace with same-sized array filled with val
        block_nrs{i, j} = val * ones(size(block_nrs{i, j}));
    end
end

for i= 1:numel(surp_med_motion)
    surp_med_motion{i} = horzcat([NaN], surp_med_motion{i});
    pent_med_motion{i} = horzcat([NaN], pent_med_motion{i});
    ppCP_med_motion{i} = horzcat([NaN], ppCP_med_motion{i});
    infog_med_motion{i} = horzcat([NaN], infog_med_motion{i});
    postent_med_motion{i} = horzcat([NaN], postent_med_motion{i});
    post_d_motion{i} = horzcat([NaN], post_d_motion{i});
    prior_d_motion{i} = horzcat([NaN], prior_d_motion{i});
end

% motion velocities % convert trials cell
motion_velocities = cellfun(@(x) x.v, trials_cell_all, 'UniformOutput', false);

% stimulus in trial from start/end
stim_trial_from_start =  cellfun(@(x) x.x, trials_cell_all, 'UniformOutput', false);
stim_trial_from_end =  cellfun(@(x) x.x, trials_cell_all, 'UniformOutput', false);
for cnt = 1:numel(stim_trial_from_start)
    length_cnt = length(stim_trial_from_start{cnt});
    stim_trial_from_start{cnt} = 1:length_cnt;
    stim_trial_from_end{cnt} = fliplr(stim_trial_from_start{cnt});
end



%% Motion data into good format for regressing

deltas = [];
surp = [];
ppCP = [];
priorent = [];
infog = [];
postent = [];
prior_d = [];
post_d = [];
sbj = [];
blocknr = [];
sac = [];
stim_start= [];
stim_end = [];
evidence = [];
deltas_fitwintercept = [];

for subject = 1:num_subj
    for trial = 1:200

        %logical included sounds
        logic_index = included_sounds{trial, subject}.incl_sounds  ;

        % pupil gain
        deltas = vertcat(deltas, delta_amps_all_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  ) );

         % pupil gain fit with intercept
        deltas_fitwintercept = vertcat(deltas_fitwintercept, delta_amps_all_motion_fwi{trial, subject}(included_sounds{trial, subject}.incl_sounds  ) );
        
        % surprisal
        surp = vertcat(surp,surp_med_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );
        
        %ppCP
        ppCP = vertcat(ppCP,ppCP_med_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );
        
        % prior entropy
        priorent = vertcat(priorent,pent_med_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );

        %infogain
        infog = vertcat(infog,infog_med_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );

        % postertior entropy
        postent = vertcat(postent,postent_med_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );

        % post d
        post_d = vertcat(post_d, post_d_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );

        % prior d
        prior_d = vertcat(prior_d, prior_d_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );

        % subject number
        len = length(surp_med_motion{trial, subject}(included_sounds{trial, subject}.incl_sounds  ));
        sbj = vertcat(sbj,  (ones(len, 1)*subject)+100); %transforming the subject ID into a three digit system, first digit is experiment, then actual ID
        
        % block nr
        blocknr = vertcat(blocknr, block_nrs{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );

        % sac level
        sac = vertcat(sac, included_sounds{trial, subject}.SAC_level(included_sounds{trial, subject}.incl_sounds  )'  );
        
        % stim from start
        stim_start = vertcat(stim_start, stim_trial_from_start{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );
        
        %stim from end
        stim_end = vertcat(stim_end, stim_trial_from_end{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );
        
        % evidence
        evidence = vertcat(evidence, motion_velocities{trial, subject}(logic_index)'  );
    end
end

% this part is important for the aceleration versus deceleration analysis
%exp = repmat({'motion'}, 1, length(surp))';
exp = ones(length(surp),1) % motion = 1
accdel = zeros(length(surp),1) % no accceleration or deceleration = 1


tbl_motion = table(surp, ppCP, priorent, infog, postent, post_d, prior_d, deltas, sbj, blocknr, exp, sac, stim_start, stim_end, accdel, evidence, deltas_fitwintercept)
clearvars -except tbl_motion



%% Tempo
data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data';
load(fullfile(data_folder, "LATENT VARS/", "BdCPfitResults_1_latent_vars.mat")); 
load(fullfile(data_folder, "preprocessing_version_12_07_2024/", "included_sounds_tempo.mat"));

delta_amps_all_tempo_fitwintercept = load(fullfile(data_folder, "fitting_2023version_12_07_2024/", "2024_07_11_delta_amplitudes_PRF_2023version.mat")); % w/ intercept
delta_amps_all_tempo_fwi = delta_amps_all_tempo_fitwintercept.delta_amps_all_tempo;

load(fullfile(data_folder, "fittingPRF_vers2023_02082024/", "delta_amplitudes_PRF_2023.mat")); % w/o interxept
load(fullfile(data_folder, "preprocessing_version_12_07_2024/", "trials_cell_all_tempo.mat"));
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_tempo.mat');


% add first two dummy sounds back to the surprisal matrix to make them all fit each other
surp_med_tempo = cell(size(surprisal.med  ));
priorent_med_tempo = cell(size(surprisal.med  ));
ppCP_med_tempo = cell(size(surprisal.med  ));
infog_med_tempo = cell(size(surprisal.med  ));
postent_med_tempo = cell(size(surprisal.med  ));
post_d_tempo = cell(size(surprisal.med  ));
prior_d_tempo = cell(size(surprisal.med  ));

% sac levels
SAC_levels(:,1:5) = [];

for i= 1:numel(surp_med_tempo)
    surp_med_tempo{i} = horzcat([NaN, NaN], surprisal.med{i});
    priorent_med_tempo{i} = horzcat([NaN, NaN], prior_entropy.med{i});
    ppCP_med_tempo{i} = horzcat([NaN, NaN], post_prob_CP.med{i});
    infog_med_tempo{i} = horzcat([NaN, NaN], info_gain.med{i});
    postent_med_tempo{i} = horzcat([NaN, NaN], post_entropy.med{i});
    post_d_tempo{i} = horzcat([NaN, NaN], post_d.med{i});
    prior_d_tempo{i} = horzcat([NaN, NaN], prior_d.med{i});
end

% convert trials cell
tempo_SOA = cellfun(@(x) x.SOA, trials_cell_all, 'UniformOutput', false);
% make block numbers

block_nrs = surp_med_tempo;
for i = 1:size(block_nrs, 1)   % loop over rows
    % Determine which value to assign based on row index
    val = ceil(i / 50);   % 1,2,3,4 for each 50-row block
    
    for j = 1:size(block_nrs, 2)   % loop over columns
        % Replace with same-sized array filled with val
        block_nrs{i, j} = val * ones(size(block_nrs{i, j}));
    end
end

% SOA change is weirdle coded as a variable, the change always affects the
% NEXT sound and therefore is not really in line with CP. Were therefore
% adding a NaN at the start and moving everything one place back.

% were also undoing the complicated weird process to compute SOA values
% from evidence levels, bc we need evidence levels
% Formula Point of evidence = log(SOAt+1) - log(SOAt)

for i = 1:numel(tempo_SOA)
    tempo_SOA{i} = [NaN, tempo_SOA{i}(1:end-1)];
end

tempo_evidence = tempo_SOA;
for i = 1:numel(tempo_evidence)
    tempo_evidence{i} = [NaN, diff(log(tempo_evidence{i}))];
end

% stimulus in trial from start/end
stim_trial_from_start =  cellfun(@(x) x.x, trials_cell_all, 'UniformOutput', false);
stim_trial_from_end =  cellfun(@(x) x.x, trials_cell_all, 'UniformOutput', false);
for cnt = 1:numel(stim_trial_from_start)
    length_cnt = length(stim_trial_from_start{cnt});
    stim_trial_from_start{cnt} = 1:length_cnt;
    stim_trial_from_end{cnt} = fliplr(stim_trial_from_start{cnt});
end

% initialize
deltas = [];
surp = [];
ppCP = [];
priorent = [];
infog = [];
postent = [];
prior_d = [];
post_d = [];
sbj = [];
blocknr = [];
sac = [];
stim_start= [];
stim_end = [];
evidence = [];
accdel = [];
deltas_fitwintercept = [];

for subject = 1:num_subj
    for trial = 1:200
        %logical
        logic_index = included_sounds{trial, subject}.incl_sounds  ;
        
        % pupil gain
        deltas = vertcat(deltas, delta_amps_all_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  ) );

        % pupil gain fit with intercept
        deltas_fitwintercept = vertcat(deltas_fitwintercept, delta_amps_all_tempo_fwi{trial, subject}(included_sounds{trial, subject}.incl_sounds  ) );
        
        %surprisal
        surp = vertcat(surp,surp_med_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );

        %ppCp
        ppCP = vertcat(ppCP,ppCP_med_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );

        %priorentropy
        priorent = vertcat(priorent,priorent_med_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );

        % infogain
        infog = vertcat(infog,infog_med_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );
        
        % posteriro entropy
        postent = vertcat(postent,postent_med_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );

        % subject number
        len = length(surp_med_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  ));
        sbj = vertcat(sbj,  (ones(len, 1)*subject)+200); %transforming the subject ID into a three digit system, first digit is experiment, then actual ID
        
        % block nr
        blocknr = vertcat(blocknr,block_nrs{trial, subject}(included_sounds{trial, subject}.incl_sounds  )'   );

        % sac level
        sac = vertcat(sac, included_sounds{trial, subject}.SAC_level(included_sounds{trial, subject}.incl_sounds  )'  );
        
        % acceleration
        accdel = vertcat(accdel, trials_cell_all{trial, subject}.d(included_sounds{trial, subject}.incl_sounds  )'); 
        
        % evidence
        evidence = vertcat(evidence, tempo_evidence{trial, subject}(logic_index)'  );

        % stim from start
        stim_start = vertcat(stim_start, stim_trial_from_start{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );
        
        %stim from end
        stim_end = vertcat(stim_end, stim_trial_from_end{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );

        % post d
        post_d = vertcat(post_d, post_d_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );

        % prior d
        prior_d = vertcat(prior_d, prior_d_tempo{trial, subject}(included_sounds{trial, subject}.incl_sounds  )' );
    end
end

%exp = repmat({'tempo'}, 1, length(surp))';
exp = ones(length(surp),1)*2; %tempo = 2

%tbl_tempo = table(surp,deltas,sbj,exp,sac,accdel, evidence)
tbl_tempo = table(surp, ppCP, priorent, infog, postent, post_d, prior_d, deltas, sbj, blocknr, exp, sac, stim_start, stim_end, accdel, evidence, deltas_fitwintercept)
%accdel   %1 is faster, -1 is slower
clearvars -except tbl_motion tbl_tempo




%% exclusions all done here!!

% exclude up to third (or fourth) stimulus
tbl_tempo(tbl_tempo.stim_start < 4,:) = [];

% exclude one less in the motion data
tbl_motion(tbl_motion.stim_start < 3,:) = [];

% exclude participants 204, 211, 213
tbl_tempo(tbl_tempo.sbj == 204,:) = [];
tbl_tempo(tbl_tempo.sbj == 211,:) = [];
tbl_tempo(tbl_tempo.sbj == 213,:) = [];






%% saving / exporting
% combine
tbl_all = vertcat(tbl_motion, tbl_tempo)


save_folder = "C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion+localization (WP3)\PROC DATA"
writetable(tbl_tempo, fullfile(save_folder, 'tbl_tempo.txt'), 'Delimiter', '\t')
writetable(tbl_motion, fullfile(save_folder, 'tbl_motion.txt'), 'Delimiter', '\t')
writetable(tbl_all, fullfile(save_folder, 'tbl_all.txt'), 'Delimiter', '\t')



%% this script means we dont need the other E numbers anymore and they could be deleted
% here tryout a little plotting to see how the variables look like

scatter(tbl_all.ppCP, tbl_all.deltas)
scatter(tbl_all.surp, tbl_all.deltas)

latent = tbl_all.surp
figure(1)
subplot(1,2,1)
scatter(latent, tbl_all.deltas)
xlabel("surprisal")
subplot(1,2,2)
hist(latent)

latent = tbl_all.surp
figure(1)
subplot(1,2,1)
scatter(latent, tbl_all.deltas)
xlabel("surprisal")
subplot(1,2,2)
hist(latent)


hist(tbl_all.ppCP)

hist(tbl_tempo.priorent(tbl_tempo.stim_start < 5,:), 100)
hist(tbl_tempo.priorent(tbl_tempo.stim_start < 4,:), 100)
hist(tbl_tempo.priorent, 100)

any(tbl_tempo.stim_start == 2)
sum(tbl_motion.stim_start == 2)