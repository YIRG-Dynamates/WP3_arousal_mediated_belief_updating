function [trials_cell_all_blocks,block_settings] = LoadDataOneSubj(save_path,subj_str)

subj_path = fullfile(save_path,subj_str);

taskname = 'LD';
block_nrs = 2:5;

num_blocks = length(block_nrs);
num_trials_per_block = 50;

%Collect the trials_cell info of each block
block_settings = cell(1,num_blocks);
trials_cell_all_blocks = cell(num_trials_per_block,num_blocks);
fields = {'x','v','cp','d','mu_exp','sd_exp'};

for j=1:num_blocks
    
    %Load block data
    filename = fullfile(subj_path,[subj_str '_' taskname num2str(block_nrs(j)) '_Trials_50.mat']);
    load(filename,'trials_cell','settings');
    
    %Add conditions per trial
    for k=1:num_trials_per_block
        trials_cell{k}.block_type = taskname;   %Add 'LD' block type
        
        %Get all trial conditions
        for f=1:length(fields)
            eval([fields{f} ' = trials_cell{k}.' fields{f} ';']);
        end
        T = getTrialConditions_SAC_dir(x,v,cp,d,mu_exp,sd_exp);
        
        %Check that the SAC level is the same
        assert(T.SAC == trials_cell{k}.SAC,'SAC level is not the same');
        
        %Copy all conditions into the trials_cell
        fldnames = fieldnames(T);
        for f=1:length(fldnames)
            trials_cell{k}.(fldnames{f}) = T.(fldnames{f});
        end
        
    end
    trials_cell_all_blocks(:,j) = trials_cell;
    block_settings{1,j} = settings;
end

end %[EoF]
