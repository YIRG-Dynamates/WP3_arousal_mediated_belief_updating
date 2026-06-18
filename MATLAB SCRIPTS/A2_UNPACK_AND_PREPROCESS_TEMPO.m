%%% UNPACKING AND PREPROCESSING OF DATA - TEMPORAL EXPERIMENT %%%
% SKRIPT LAST CHANGED AND DATA SAVED: 12-07-2024 - RF


%% %%% STEP 1: UNPACK! (done 12.07.2024) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% commented out because it takes a while to run
% personalized skripts extract_pupil_data_all_tempo_RF and
% extract_pupil_data_all_tempo_RF differ from the previous unpacking
% skripts in terms of keywords and which info gets included in the unpacked
% data

clear all
addpath('C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\extract_data') 

% check which data folder is defined inside
extract_pupil_data_all_tempo_RF

%% %%%%%%%%% STEP 2: TEMPO PREPROCESS (done 12.07.2024) %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear all

%initialize folders
data_folder = 'C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\temporal (WP2) local\final_behav_eye_data';
mkdir(data_folder, 'preprocessing_version_12_07_2024');
save_folder = fullfile(data_folder, "preprocessing_version_12_07_2024/");

load(fullfile(data_folder,'subj_nrs.mat'),'num_subj','subj_nrs');

num_trials = 200;

%% RESTRUCTURING
% transform everything into one big matrix trials_cell_all (for all
% subjects) and eye_data_all (for all subjects)

for j_subj = 1:num_subj
    
    subj_nr_str = subj_nrs{j_subj};
    
    %Load the data file for this subject (takes up to 10 seconds)
    data_file = fullfile(data_folder,subj_nr_str,[subj_nr_str '_behav_eye_data.mat']);
    load(data_file,'eye_data_all_blocks');                                  %Other variables: 'eye_settings_all_blocks','trials_cell_all_blocks','settings_all_blocks'
    
    for i = 1:num_trials
        eye_data_all(i,j_subj) = eye_data_all_blocks(i);
    end
   
    load(data_file,'trials_cell_all_blocks');   

    for i = 1:num_trials
        trials_cell_all(i,j_subj) = trials_cell_all_blocks(i);
    end
end

%% ADD DUMMY DATA
% if pupilSize data is missing in a block or participant it is susbtituted substituted by dummy data that will be flagged as
% NaN later, but it cant be empty, so we need this

for j = 1:numel(eye_data_all)
    if isempty(eye_data_all{j}.pupilSize)
        disp(numel)
        eye_data_all{j}.fix1_sacc2_blink3  = ones(1000,1)*3;
        eye_data_all{j}.pupilSize  = zeros(1000,1);
        eye_data_all{j}.posX  = zeros(1000,1);
        eye_data_all{j}.posY  = zeros(1000,1);

        eye_data_all{j}.PUPblinks  = ones(1000,1);
    end
end

% Nothing is empty in the temporal data set!! --> Yay!

%% CLEAN UP DIGITAL BULLSHIT

% this function searches every period less than 'cutoff' ms with 0 values and
% interpolates them linearly between the values before and after the period
% of zeroes --> this cleans up nasty digital artifacts
% make sure cutoff is the same over motion and temporal preprocessing
% skript

% the function remove_digital_artifact_bullshit_RF also annnotates the
% interpolated periods into fix1_sacc2_blink3, but i ended up not using
% that thoughout the rest of the preprocessing


addpath('C:\Users\rfleischmann\Documents\GitHub\dynamates\modelling\krishnamurthy_based\replication\pupillometry\functions')

cutoff = 55;

for i = 1:numel(eye_data_all)
    %disp(i);
    if ~isempty(eye_data_all{i}.pupilSize == 0);
        disp(i)
        [eye_data_all{i}.pupilSize, eye_data_all{i}.fix1_sacc2_blink3]  = remove_digital_artifact_bullshit_RF(eye_data_all{i}.pupilSize, eye_data_all{i}.fix1_sacc2_blink3, cutoff);
        eye_data_all{i}.digitallyclean = 1;

    end
end

clear cutoff;

%% Find blinks with PUPILs thing and add to structure
% Blinks are detected based on the velocity in change of the pupil size and
% blinks are recorded inside eye_data_all in 'PUBblinks'
% this part takes a while (the filtering plus blink detection)


addpath("C:\Users\rfleischmann\Documents\TOOLBOXES\PUPILS-preprocessing-pipeline-master") ;

options = struct;
options.fs = 1000;                % sampling frequency (Hz)
options.blink_rule = 'vel';       % Rule for blink detection 'std' / 've

for i = 1:numel(eye_data_all);
%for i = 1:200
    clear data;

    data(:,4) = lowpass(eye_data_all{i}.pupilSize, 2.5, 1000 );   %lowpassfiltering gives better results with the detectBlinks function
    %data(:,4) = filteredpupilSize
    data(:,3) = eye_data_all{i}.posY  ;
    data(:,2) = eye_data_all{i}.posX  ;
    data(:,1) = 1:height(data) ;

    [data_out, info_blinks] = detectBlinks(data, options);
    data_out(data_out(:,5) > 0,5) = 1; % all blinks are now coded with 1

    eye_data_all{i}.PUPblinks = data_out(:,5);

    % fields are not used anymore and memory intensive, therefore out
    %eye_data_all{i} = rmfield(eye_data_all{i},'time');
    eye_data_all{i} = rmfield(eye_data_all{i},'posX');
    eye_data_all{i} = rmfield(eye_data_all{i},'posY');    
    eye_data_all{i} = rmfield(eye_data_all{i},'fix1_sacc2_blink3');  

    disp(i)

end

%% SAVING (last save 14.07.2024)

save(fullfile(save_folder,'trials_cell_all_tempo.mat'),'trials_cell_all','-v7.3');
save(fullfile(save_folder,'eye_data_all_tempo.mat'),'eye_data_all','-v7.3');

%% interpolate 

% blinks are annotated as 1 in PUPblinks, in this section we interpolate
% the pupil trace linearly based on that info:
% additionally everything smaller than 3200 (limit) --> marked as 1
% all periods closer together than cutoff1 are merged into one 
% then some additional time before and after the period is added where data
% is usually unreliable ("coushion")
% all of the resulting periods longer than cutoff2 are marked to be set to NaN because they
% are too long to be used after interpolation.

% result is saved in 'preprocessed_eye_data

cutoff1 = 150 % ms
cutoff2 = 600 % ms
coushion = 75 % ms

load(fullfile(data_folder,'subj_nrs.mat'),'num_subj','subj_nrs');
preprocessed_eye_data = cell(200,num_subj);


%for i = 1:200
for i = 1:numel(eye_data_all);

    % lower limit counting from peak
    %limit = max(eye_data_all{i}.pupilSize) - 3000;

    % exclude with hard limit
    limit = 3200;

    % lower limit by std --> not really good
    % std_abw = std(eye_data_all{i}.pupilSize);
    % limit = mean(eye_data_all{i}.pupilSize - 3*std_abw);

    % set to 1
    eye_data_all{i}.PUPblinks(eye_data_all{i}.pupilSize < limit) = 1;

    % find additional high jumps from sample to sample
    eye_data_all{i}.PUPblinks(diff(eye_data_all{i}.pupilSize) > 100) = 1;

    % core fuction annotating the interpolation periods!
    [ones_periods, make_nan] = find_blocks_of_ones_RF(eye_data_all{i}.PUPblinks, cutoff1, cutoff2, coushion);
    trace = eye_data_all{i}.pupilSize;

    % linear interpolation could be a small function, note to myself, make one in the
    % future roman, this is not elegant at all
    for j = 1:height(ones_periods);
        % %interpolate linearly
        difference = ones_periods(j,2) - ones_periods(j,1);
        trace(ones_periods(j,1):ones_periods(j,2)) = linspace( trace(ones_periods(j,1)), trace(ones_periods(j,2)), difference+1);   
    end

    %interp with the pline thingy (seems worse than the linear option)
    %trace = interp_spline(trace,ones_periods);
    
    %set non-interp periods to nan
    for p = 1:height(make_nan);
        trace(make_nan(p,1):make_nan(p,2))= NaN;
    end

    eye_data_all{i}.interpoltrace = trace;

    preprocessed_eye_data{i}.pupilSize = trace;
    preprocessed_eye_data{i}.pupilSize_raw = eye_data_all{i}.pupilSize;
    preprocessed_eye_data{i}.cp = eye_data_all{i}.cp;
    preprocessed_eye_data{i}.SAC_level = eye_data_all{i}.SAC_level;
    preprocessed_eye_data{i}.A_stim_times = eye_data_all{i}.A_stim_times;
    preprocessed_eye_data{i}.AV_stim_times = eye_data_all{i}.AV_stim_times;
    preprocessed_eye_data{i}.blink_periods = [];
    preprocessed_eye_data{i}.blink_overlap_problem = 0;
    preprocessed_eye_data{i}.interp_periods = ones_periods;
    preprocessed_eye_data{i}.missing_periods = make_nan;
    preprocessed_eye_data{i}.exclude_trial = false;

    % calculating the fractions of interpolated and excluded samples
    if ~isempty(ones_periods)
        preprocessed_eye_data{i}.fraction_interpolated_samples = sum(ones_periods(:,2)-ones_periods(:,1))/length(trace);
    else
        preprocessed_eye_data{i}.fraction_interpolated_samples = 0;
    end
    if ~isempty(make_nan)
        preprocessed_eye_data{i}.fraction_excluded_samples = sum(make_nan(:,2)-make_nan(:,1))/length(trace);
    else
        preprocessed_eye_data{i}.fraction_excluded_samples = 0;
    end

        % mark if there is interpolated areas in the middle 
    preprocessed_eye_data{i}.missing_in_middle_flag = false;
    if ~isempty(make_nan)
        idx1 = find(any(make_nan == 1, 2));
        idx1 = vertcat(idx1, find(any(make_nan == length(trace), 2)) );
        preprocessed_eye_data{i}.missing_in_middle_flag = height(make_nan) > length(idx1); %when there is more lines in make_nan than there are lines containin the first or last sample, we have missing periods that are not in the start or end
    end

end

% add trial and subject number
for subject = 1:num_subj
    for trial = 1:200
        preprocessed_eye_data{trial, subject}.subject = subject;
        preprocessed_eye_data{trial, subject}.trial = trial;
    end
end

%% SAVING (last saved 14.07.2024)

save(fullfile(save_folder,'preprocessed_eye_data_tempo_version_12_07_2024.mat'),'preprocessed_eye_data','-v7.3');

%% interpolate the missing areas linearly, i will then exlude them after the fitting (hopefully)
% change of tactics, instead of setting the areas that are too long to
% interpolate to NaN we are now interpolating them anyways (linearly) and
% then excluding  those times after the PRF fitting procedure
% this couldve been done all in one step but whatever

for i = 1:numel(preprocessed_eye_data)

    missp = preprocessed_eye_data{i}.missing_periods;

    missing_periods_empty = true;
    if ~isempty(missp)
        missing_periods_empty = false;
    end
    
    for j = 1:height(missp);

        % if entire period is missing were making up dummy data
        if missp(j,1) == 1 && missp(j,2) == length(preprocessed_eye_data{i}.pupilSize) && missing_periods_empty == false;
            preprocessed_eye_data{i}.pupilSize(1:length(preprocessed_eye_data{i}.pupilSize)) = 1000;
            
        % if period contains 1 entire period is set to the first real value
        % after the period   
        elseif missp(j,1) == 1 && missing_periods_empty == false;
            preprocessed_eye_data{i}.pupilSize(1:missp(j,2)) = preprocessed_eye_data{i}.pupilSize(missp(j,2)+1);
            disp('first')
        
        % if the period contains the last value of the pupil trace,
        % everything is set to the last real value in the pupil trace
        elseif missp(j,2) == length(preprocessed_eye_data{i}.pupilSize) && missing_periods_empty == false;
            preprocessed_eye_data{i}.pupilSize(missp(j,1):missp(j,2)) = preprocessed_eye_data{i}.pupilSize(missp(j,1)-1);
            disp('second')

        % if its just a regular period in the middle somewhere we interpolate linearly    
        else
            preprocessed_eye_data{i}.pupilSize = interp_linear_RF(preprocessed_eye_data{i}.pupilSize, missp(j,1), missp(j,2) );
            disp('third')
        end
    end
    disp(i)
end

%% check if there is still some nan values somewhere
% for safety

for i = 1:numel(preprocessed_eye_data)
    if anynan(preprocessed_eye_data{i}.pupilSize);
        disp(['Danger! Danger! Theres NaN in ' num2str(i)])
    end;
end

%% SAVING AGAIN (last saved 14.07.2024)

save(fullfile(save_folder,'preprocessed_eye_data_tempo_version_12_07_2024.mat'),'preprocessed_eye_data','-v7.3');

%% %% PREPROCESSING DONE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% the following code is just to review and check things via plotting


%% PLOT TO CHECK
subj = 1
trial = 175
for trial = 1:150
    figure(trial)
    hold on
    plot(eye_data_all{trial, subj}.pupilSize  )
    plot(eye_data_all{trial, subj}.interpoltrace + 200)
    plot(eye_data_all{trial, subj}.PUPblinks * 2000)

    title(['subject: ', num2str(subj), '/ trial: ', num2str(trial)])
    hold off
end
% 
% for i = 150:200
% %i = 70
%     figure(i)
%     hold on
%     plot(diff(eye_data_all{i}.pupilSize))
%     plot(eye_data_all{i}.pupilSize)
%     hold off
% end



%% plot and check things

trial = 150
subject = 3

for trial = 1:200

    figure(trial)

    %mark trustworthy areas vs non-trustworthy (pink shading for non-trust)
    hold on


    %plot(PRFfitResults_danger{1, subject}.predictions{trial, 1}.y_pred + mean(preprocessed_eye_data{trial, subject}.pupilSize), 'color', 'b'  )
    plot(preprocessed_eye_data{trial, subject}.pupilSize -50,'color', 'g');
    plot(preprocessed_eye_data{trial, subject}.pupilSize_raw -100, 'color','r');
    yline(3200, 'color', 'm',  'LineStyle', '--')

    if ~isempty(preprocessed_eye_data{trial, subject}.interp_periods);
        xline(preprocessed_eye_data{trial, subject}.interp_periods(:,1), 'color','k',  'LineStyle', '-');
        xline(preprocessed_eye_data{trial, subject}.interp_periods(:,2), 'color','k', 'LineStyle', '--');
    end

    if ~isempty(preprocessed_eye_data{trial, subject}.missing_periods);
        xline(preprocessed_eye_data{trial, subject}.missing_periods(:,1), 'color','m',  'LineStyle', '-');
        xline(preprocessed_eye_data{trial, subject}.missing_periods(:,2),'color', 'm',  'LineStyle', '--');

        for p = 1:height(preprocessed_eye_data{trial, subject}.missing_periods);
            yLimits = get(gca,'YLim');
            area(preprocessed_eye_data{trial, subject}.missing_periods(p,:), [yLimits(2) yLimits(2)], FaceColor="m", FaceAlpha=.2, EdgeColor='none');
        end

    end
    

    title(['trial ', num2str(trial)]);
    % legend('pred', 'interp', 'raw')
    xlim([-100 length(preprocessed_eye_data{trial, subject}.pupilSize)+100]);
    hold off

end




