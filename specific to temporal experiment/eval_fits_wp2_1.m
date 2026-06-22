clearvars;
clc;

addpath('fitting_functions_wp2');
fitted_data_folder = 'fitted_data_wp2';

data_file = 'behav_data_WP2.mat';
load(data_file,'subj_IDs','num_subj');

%% Collect fitted parameters (sd_sens) and mu_exp

fitted_params = nan(num_subj,1);
mu_exps = nan(num_subj,1);

for j=1:num_subj 
    
    disp(['Loading fitResults of subj ' num2str(j) ' out of ' num2str(num_subj)]);
    subj_str = subj_IDs{j};
    
    save_path = fullfile('fitted_data_wp2',subj_str);
    load(fullfile(save_path,[subj_str '_BdCPfitResults_1.mat']),'BdCPfitResults');
    
    %Get mu_exp
    mu_exps(j) = BdCPfitResults.settings.param_settings.mu_exp;
    
    %Get fitted param (sd_sens)
    fitted_params(j) = BdCPfitResults.fit.fittedParams;
end

% Plot an overview of the fitted parameter values per subject
figure; hold on; box on;
plot(mu_exps,fitted_params,'bo');
xlim([1.05 1.35]);

%Subject 13 (S016) is a complete outlier! - remove this one.
good_idx = [1:12 14:num_subj];

b = regress(fitted_params(good_idx),[mu_exps(good_idx) ones(numel(good_idx),1)]);
x = unique(mu_exps);
y = b(1)*x + b(2);
plot(x,y,'r-');

xlabel('mu exp');
ylabel('Fitted sd sens');

%% Collect the latent variables and save in one overview file

num_trials = 200;

latent_var_names = BdCPfitResults.settings.fit_settings.latent_vars;

%Initialize latent cell arrays
latents = [];
for f=1:numel(latent_var_names)
    latents.(latent_var_names{f}).med = cell(num_trials,num_subj);
    latents.(latent_var_names{f}).iqr = cell(num_trials,num_subj);
end

%Collect the latents for all subjects
for j=1:num_subj 
    
    disp(['Collecting latent variables for subj ' num2str(j) ' out of ' num2str(num_subj)]);
    subj_str = subj_IDs{j};
    
    save_path = fullfile('fitted_data_wp2',subj_str);
    load(fullfile(save_path,[subj_str '_BdCPfitResults_1.mat']),'BdCPfitResults');
    
    for f=1:numel(latent_var_names)
        for t=1:num_trials
            
            latents.(latent_var_names{f}).med{t,j} = BdCPfitResults.predictions{t,1}.latent_vars.(latent_var_names{f}).med;
            latents.(latent_var_names{f}).iqr{t,j} = BdCPfitResults.predictions{t,1}.latent_vars.(latent_var_names{f}).iqr;
        end
    end
end

%Check the latents for NaNs or Inf, and then create variable for each latent
for f=1:numel(latent_var_names)
    assert(~any(cellfun(@(x) any(isnan(x) | isinf(x)), latents.(latent_var_names{f}).med),'all'),['NaNs or Inf found in ' latent_var_names{f} '.med']);
    assert(~any(cellfun(@(x) any(isnan(x) | isinf(x)), latents.(latent_var_names{f}).iqr),'all'),['NaNs or Inf found in ' latent_var_names{f} '.iqr']);
    eval([latent_var_names{f} ' = latents.' latent_var_names{f} ';']);
end

%Save all latents for this model
save(fullfile(fitted_data_folder,'BdCPfitResults_1_latent_vars.mat'),'subj_IDs','num_subj','num_trials','latent_var_names',latent_var_names{:}); 

%% Gather the SAC levels of all stimuli and rectify some latents

SAC_levels = cell(num_trials,num_subj);

correct_dir = cell(num_trials,num_subj);
lambda_rect.med = cell(num_trials,num_subj);
prior_d_rect.med = cell(num_trials,num_subj);
post_d_rect.med = cell(num_trials,num_subj);
for j=1:num_subj
    
    disp(['Collecting SAC levels for subj ' num2str(j) ' out of ' num2str(num_subj)]);
    subj_str = subj_IDs{j};
    
    load(data_file,['trials_cell_' subj_str]);
    eval(['trials_cell = trials_cell_' subj_str ';']);
    eval(['clear(["trials_cell_' subj_str '"])']);

    %Create one column vector
    trials_cell = trials_cell(:);
    
    for t=1:num_trials
        cp = trials_cell{t,1}.cp(2:end);                        
        idx_cp = find(cp);
        SAC_levels{t,j} = (1:numel(cp))-(idx_cp(cumsum(cp))-1);
        
        correct_dir{t,j} = trials_cell{t,1}.d(2:end);
        lambda_rect.med{t,j} = correct_dir{t,j} .* lambda.med{t,j};
        prior_d_rect.med{t,j} = correct_dir{t,j} .* prior_d.med{t,j};
        post_d_rect.med{t,j} = correct_dir{t,j} .* post_d.med{t,j};
    end
end

%Also add the IQR (doesn't change when flipping the sign)
lambda_rect.iqr = lambda.iqr;
prior_d_rect.iqr = prior_d.iqr;
post_d_rect.iqr = post_d.iqr;

%Add the new latents to the list of latent names
num_latents = numel(latent_var_names);
latent_var_names{1,num_latents+1} = 'lambda_rect';
latent_var_names{1,num_latents+2} = 'prior_d_rect';
latent_var_names{1,num_latents+3} = 'post_d_rect';
num_latents = num_latents+3;

%Save these in the latents file
save(fullfile(fitted_data_folder,'BdCPfitResults_1_latent_vars.mat'),'latent_var_names','SAC_levels','correct_dir','lambda_rect','prior_d_rect','post_d_rect','-append'); 

%% Create an overview figure with the latent variables as a function of SAC

%Gather the latents in one structure and ignore the IQRs
latents = [];
for i=1:numel(latent_var_names)
    eval(['latents.(latent_var_names{i}) = ' latent_var_names{i} '.med;']);
end

%Remove the first stimulus of each trial (for SAC and latents)
%This is actually the first acceleration/deceleration (i.e. it refers to the first two SOAs, the first three stimuli!)
for k=1:numel(SAC_levels)
    SAC_levels{k}(1) = [];
    if isempty(SAC_levels{k})
        SAC_levels{k} = zeros(1,0);
    end
    for i=1:numel(latent_var_names)
        latents.(latent_var_names{i}){k}(1) = [];
        if isempty(latents.(latent_var_names{i}){k})
            latents.(latent_var_names{i}){k} = zeros(1,0);
        end
    end
end

%Set a maximum SAC level of 5
SAC_levels = cellfun(@(x) min(5,x), SAC_levels, 'UniformOutput', false);

%Concatenate all stimuli for each subject
SAC_levels = cellfun(@(x) x', SAC_levels, 'UniformOutput', false);
SAC_levels_cat = cell(1,num_subj);
for j=1:num_subj   
    SAC_levels_cat{1,j} = cat(1,SAC_levels{:,j});
end
latents_cat = [];
for i=1:numel(latent_var_names)
    latents.(latent_var_names{i}) = cellfun(@(x) x', latents.(latent_var_names{i}), 'UniformOutput', false);
    latents_cat.(latent_var_names{i}) = cell(1,num_subj);
    for j=1:num_subj
        latents_cat.(latent_var_names{i}){1,j} = cat(1,latents.(latent_var_names{i}){:,j});
    end
end

%Gather the mean latent per SAC level (1-5) per subject
latents_MeanPerSAC = [];
for i=1:numel(latent_var_names)
    latents_MeanPerSAC.(latent_var_names{i}) = nan(num_subj,5);
    for j=1:num_subj
        latents_MeanPerSAC.(latent_var_names{i})(j,:) = accumarray(SAC_levels_cat{1,j},latents_cat.(latent_var_names{i}){1,j},[5 1],@(x) mean(x));
    end
end

%Create the plot
xgrid = 1:5;
xgrid2 = [xgrid fliplr(xgrid)];

plot_order = {'lambda','prior_d','post_d', ...
              'lambda_rect','prior_d_rect','post_d_rect', ...  
              'var_lik','prior_entropy','post_entropy', ...
              'surprisal','post_prob_CP','info_gain'};

figure;
for i=1:numel(latent_var_names)
    
    %Open subplot
    var_name = latent_var_names{i};
    i_plotOrder = find(strcmp(var_name,plot_order),1);
    assert(~isempty(i_plotOrder),'Latent variable name is unknown in plot_order cell-array');
    subplot(4,3,i_plotOrder); cla; hold on; box on;
            
    %Plot data
    data_tmp = latents_MeanPerSAC.(latent_var_names{i});
    Qs = quantile(data_tmp,[.25,.5,.75],1);
    med_tmp = Qs(2,:);
    iqr_tmp = Qs(3,:)-Qs(1,:);
    y = [med_tmp+iqr_tmp, fliplr(med_tmp-iqr_tmp)];

    patch(xgrid2,y,[0 0 1],'facealpha', 0.2, 'edgecolor', 'none');
    plot(xgrid,med_tmp,'b-');

    %Finish the figure
    y_range = [min(y), max(y)];
    yLim = [y_range(1)-.1*diff(y_range)-.1*mean(med_tmp)-1e-3, y_range(2)+.1*diff(y_range)+.1*mean(med_tmp)+1e-3];
    ylim(yLim); xlim([.5 5.5]); xticks(1:5);
    if f > 6; xlabel('SAC level'); end
    title(regexprep(latent_var_names{i},'_',' ')); 
end

%% Also quickly do an average accuracy plot for all subjects (is S016 an outlier?)

Accuracy_trials = nan(num_trials,num_subj);
SAC_trials = nan(num_trials,num_subj);
for j=1:num_subj
    
    disp(['Collecting accuracies for subj ' num2str(j) ' out of ' num2str(num_subj)]);
    subj_str = subj_IDs{j};
    
    load(data_file,['trials_cell_' subj_str]);
    eval(['trials_cell = trials_cell_' subj_str ';']);
    eval(['clear(["trials_cell_' subj_str '"])']);

    %Create one column vector
    trials_cell = trials_cell(:);
    
    %Collect accuracy and SAC
    Accuracy_trials(:,j) = cellfun(@(x) x.TempoDirRespCorrect,trials_cell);
    SAC_trials(:,j) = cellfun(@(x) x.SAC,trials_cell);
end

%Gather the accuracy per SAC level (1-5) per subject
AccuracyPerSAC = nan(num_subj,5);
for j=1:num_subj
    AccuracyPerSAC(j,:) = accumarray(SAC_trials(:,j),Accuracy_trials(:,j),[5 1],@(x) mean(x));
end

%Plot the results separately for each subject and SAC level
figure;
for j_SAC = 1:5
    subplot(5,1,j_SAC); 
    x = 1:num_subj;
    y = AccuracyPerSAC(:,j_SAC)';
    plot(x,y);
    ylabel(['SAC ' num2str(j_SAC)]);
    if j_SAC==1; title('Accuracy per subject and SAC level'); end
    if j_SAC==5; xlabel('subject number'); end
    xlim([0 num_subj+1]);
    ylim([0 1]);
    hold on; plot([0 num_subj+1],[.5 .5],'k--');
end


