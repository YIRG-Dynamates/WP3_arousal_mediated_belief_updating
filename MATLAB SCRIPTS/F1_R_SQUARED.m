clear all

% motion old procedure
load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\fittingPRF_vers2023_01082024\fit_results_PRF_2023.mat')
%load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\trials_cell_all_motion.mat')

load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\preprocessing_version_12_07_2024\preprocessed_eye_data_motion_version_12_07_2024.mat')

sbj = 16
trial = 25

%% set filtering
% (WAY WAY faster now with filtfilt() than it was with lowpass() )

% Sampling frequency (choose appropriately)
fs_samplingrate = 1000;  % Hz, adjust based on your actual signal

% Cutoff frequency
f_cutoff = 1;  % Hz

% Normalized cutoff frequency (Nyquist = fs/2)
Wn = f_cutoff / (fs_samplingrate/2);

% Filter order (higher = steeper cutoff, more delay)
N = 100;  % Adjust this to make the cutoff steeper

% Design FIR lowpass filter using the window method
b = fir1(N, Wn, 'low');

% Zero-phase filtering using filtfilt
% filtered_signal = filtfilt(b, 1, signal);

%%

for sbj = 1:22;
    for trial = 1:200;

        % Given data for trial
        y_true = preprocessed_eye_data{trial, sbj}.pupilSize ; 

        %filtering
        % y_true = filtfilt(b, 1, y_true);

        %baselining
        y_true = y_true - mean(y_true);  %
        y_pred = PRFfitResults_motion{1, sbj}.predictions{trial, 1}.y_pred  ;
        
        % i have to do this in two steps so it works because im stupid 
        % if i delete right away the length of the array is wrong in the next
        % iteration
        
        for i = 1:height(preprocessed_eye_data{trial, sbj}.missing_periods  );
            miss_per = preprocessed_eye_data{trial, sbj}.missing_periods ;
            y_true(miss_per(i,1):miss_per(i,2)) = NaN;
            y_pred(miss_per(i,1):miss_per(i,2)) = NaN;
        end

        % excluding those areas
        y_true(1:1500) = NaN;
        y_true(end-1500:end) = NaN;

        y_pred(1:1500) = NaN;
        y_pred(end-1500:end) = NaN;

        
        y_true = y_true(~isnan(y_true));
        y_pred = y_pred(~isnan(y_pred));
        
        
        % Calculate R-squared
        SS_res = sum((y_true - y_pred).^2);              % Residual sum of squares
        SS_tot = sum((y_true - mean(y_true)).^2);        % Total sum of squares
        R_squared = 1 - (SS_res / SS_tot);               % R-squared calculation
        
        % Display result
        %disp(['R-squared: ', num2str(R_squared)]);
        
        preprocessed_eye_data{trial,sbj}.r_squ_clean = R_squared;
        
        r_squared_all(trial,sbj) = R_squared;

    end
end

% remove all NaNs
for k = 1:22
    temp = r_squared_all(:,k) ;
    temp = temp(~isnan(temp));
    r_sq_sbj(k) = median(temp);
end

%rsq_nofilt = mean(r_sq_sbj)
% rsq_filt2hz = mean(r_sq_sbj)
% rsq_filt4hz = mean(r_sq_sbj2)

mean(r_sq_sbj)
std(r_sq_sbj)


clearvars -except r_sq_sbj r_squared_all preprocessed_eye_data

%% motion autoregression

load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\fittingPRF_vers2024_01082024\fit_results_PRF_2024_autoregression.mat')

for sbj = 1:21;
    for trial = 1:200;

        % Given data for trial
        y_true = preprocessed_eye_data{trial, sbj}.pupilSize ; 
        y_true = y_true - mean(y_true);  %
        y_pred = PRFfitResults_motion{1, sbj}.predictions{trial, 1}.pupil_pred  ;
        
        % i have to do this in two steps so it works because im stupid 
        % if i delete right away the length of the array is wrong in the next
        % iteration
        
        for i = 1:height(preprocessed_eye_data{trial, sbj}.missing_periods  );
            miss_per = preprocessed_eye_data{trial, sbj}.missing_periods ;
            y_true(miss_per(i,1):miss_per(i,2)) = NaN;
            y_pred(miss_per(i,1):miss_per(i,2)) = NaN;
        end
        
        y_true = y_true(~isnan(y_true));
        y_pred = y_pred(~isnan(y_pred));
        
        
        % Calculate R-squared
        SS_res = sum((y_true - y_pred).^2);              % Residual sum of squares
        SS_tot = sum((y_true - mean(y_true)).^2);        % Total sum of squares
        R_squared = 1 - (SS_res / SS_tot);               % R-squared calculation
        
        % Display result
        %disp(['R-squared: ', num2str(R_squared)]);
        
        preprocessed_eye_data{trial,sbj}.r_squ_clean = R_squared;
        
        r_squared_all_autoreg(trial,sbj) = R_squared;

    end
end

sbj = 14
trial = 38

plot(y_true)
hold on
plot(y_pred)
hold off

for k = 1:21
    temp = r_squared_all_autoreg(:,k) ;
    temp = temp(~isnan(temp));
    r_sq_sbj_autoreg(k) = median(temp);
end

r_sq_sbj_autoreg(22) = NaN

old_v_autoreg = [r_sq_sbj; r_sq_sbj_autoreg]


old_r = mean(r_sq_sbj)
std(r_sq_sbj)
autoreg_r = mean(r_sq_sbj_autoreg(1:21))
std(r_sq_sbj_autoreg(1:21))


%% motion old procedure with free intercept

load('C:\Users\rfleischmann\Desktop\DATA\RAW THINGS\motion (WP1) local\final_behav_eye_data\fitting_2023version_12_07_2024\2024_07_11_fit_results_PRF_2023version.mat')


for sbj = 1:22;
    for trial = 1:200;

        % Given data for trial
        y_true = preprocessed_eye_data{trial, sbj}.pupilSize ; 

        %filtering
        %y_true = filtfilt(b, 1, y_true);

        %baselining
        y_true = y_true - mean(y_true);  %
        y_pred = PRFfitResults_motion{1, sbj}.predictions{trial, 1}.y_pred  ;
        
        % i have to do this in two steps so it works because im stupid 
        % if i delete right away the length of the array is wrong in the next
        % iteration
        
        for i = 1:height(preprocessed_eye_data{trial, sbj}.missing_periods  );
            miss_per = preprocessed_eye_data{trial, sbj}.missing_periods ;
            y_true(miss_per(i,1):miss_per(i,2)) = NaN;
            y_pred(miss_per(i,1):miss_per(i,2)) = NaN;
        end
        
        y_true = y_true(~isnan(y_true));
        y_pred = y_pred(~isnan(y_pred));
        
        
        % Calculate R-squared
        SS_res = sum((y_true - y_pred).^2);              % Residual sum of squares
        SS_tot = sum((y_true - mean(y_true)).^2);        % Total sum of squares
        R_squared = 1 - (SS_res / SS_tot);               % R-squared calculation
        
        % Display result
        %disp(['R-squared: ', num2str(R_squared)]);
        
        preprocessed_eye_data{trial,sbj}.r_squ_clean = R_squared;
        
        r_squared_all(trial,sbj) = R_squared;

    end
end

% remove all NaNs
for k = 1:22
    temp = r_squared_all(:,k) ;
    temp = temp(~isnan(temp));
    r_sq_sbj(k) = median(temp);
end

%rsq_nofilt = mean(r_sq_sbj)
% rsq_filt2hz = mean(r_sq_sbj)
% rsq_filt4hz = mean(r_sq_sbj2)

mean(r_sq_sbj)
std(r_sq_sbj)


clearvars -except r_sq_sbj r_squared_all preprocessed_eye_data

