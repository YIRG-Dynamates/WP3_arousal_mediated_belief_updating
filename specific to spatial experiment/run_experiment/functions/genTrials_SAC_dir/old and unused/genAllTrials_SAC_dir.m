function [trials_cell,randomized_default_order] = genAllTrials_SAC_dir(use_default_flag,mu_exp,sd_exp,num_blocks,disp_info_flag)
% Generate all trials in an experiment. The 2nd output parameter 
% should be saved if a randomized default set of trials is used.   

rng('shuffle');

%Set defaults for this function
if nargin < 1
    use_default_flag = true;
end
if nargin < 2
    mu_exp = 2*sqrt(2)*5;           %MAA = 5
end
if nargin < 3
    sd_exp = 1*5;                   %MAA = 5
end
if nargin < 4
    num_blocks = 9;
end
if nargin < 5
    disp_info_flag = true;
end

%Generate a new set of trials   
if ~use_default_flag
    
    exp_params = setExperimentParams_SAC_dir();
    trials_cell = cell(exp_params.num_trials_per_block,num_blocks);         %Note: block numbers are columns, such that trial indices correspond to the correct order
    for i=1:num_blocks
        trials_cell(:,i) = genOneBlock_SAC_dir(mu_exp,sd_exp,disp_info_flag);
    end
    
    if nargout > 1
        warning('The second output parameter (randomized_default_order) is meaningless when generating a non-default set of trials');
        randomized_default_order = 'dummy';
    end
    
%Use default set of trials but randomize the trials order within each block
%If there are multiple noise levels, you may want to improve this by also pseudo-randomizing across noise level blocks..   
else
    
    load('default_trials_cell_SAC_dir.mat','default_trials_cell_SAC_dir');
    
    [num_trials_per_block,num_blocks] = size(default_trials_cell_SAC_dir);
    trials_cell = cell(size(default_trials_cell_SAC_dir));
    trials_order = nan(num_trials_per_block,num_blocks);
    reverse_trials_order = nan(num_trials_per_block,num_blocks);
    for i=1:num_blocks
        trials_order(:,i) = randperm(num_trials_per_block);
        trials_cell(:,i) = default_trials_cell_SAC_dir(trials_order(:,i),i);
        [~,reverse_trials_order(:,i)] = sort(trials_order(:,i));
    end
    trials_order = trials_order + num_trials_per_block.*(0:(num_blocks-1)).*ones(num_trials_per_block,num_blocks);
    reverse_trials_order = reverse_trials_order + num_trials_per_block.*(0:(num_blocks-1)).*ones(num_trials_per_block,num_blocks);
    % - isequal(default_trials_cell_SAC_dir(trials_order),trials_cell) returns true
    % - isequal(trials_cell(reverse_trials_order),default_trials_cell_SAC_dir) returns true
    
    if nargout < 2
        error('The second output parameter (randomized_default_order) should be saved if you wish to use the default set of trials');
    else
        randomized_default_order.trials_order = trials_order;
        randomized_default_order.reverse_trials_order = reverse_trials_order;
    end
    
end %[EoF]

%% The following code was used to generate the default set of trials

clc;
clearvars; 

rng('shuffle');

MAA = 5;
mu_exp = 2*sqrt(2)*MAA;
sd_exp = 1*MAA;

num_blocks = 9;

default_trials_cell_SAC_dir = cell(48,num_blocks);

hazard_rate_threshold = [0.16 0.175];

block_nr = 1;
while block_nr <= num_blocks
    trials_cell_tmp = genOneBlock_SAC_dir(mu_exp,sd_exp,true);
    T_all = getTrialConditions_All_SAC_dir(trials_cell_tmp,mu_exp,sd_exp);
    
    actual_hazard_rate = sum(T_all.num_cp-1)/sum(T_all.num_stim-2);
    if (actual_hazard_rate > hazard_rate_threshold(1)) && (actual_hazard_rate < hazard_rate_threshold(2))
        default_trials_cell_SAC_dir(:,block_nr) = trials_cell_tmp;
        block_nr = block_nr+1;
    end
end

T_all = getTrialConditions_All_SAC_dir(default_trials_cell_SAC_dir,mu_exp,sd_exp);
actual_hazard_rate = sum(T_all.num_cp-1,'all')/sum(T_all.num_stim-2,'all')  %The actual hazard rate across all trials and blocks is 0.1638 (1/6 = 0.1667)

save('default_trials_cell_SAC_dir.mat','default_trials_cell_SAC_dir');

