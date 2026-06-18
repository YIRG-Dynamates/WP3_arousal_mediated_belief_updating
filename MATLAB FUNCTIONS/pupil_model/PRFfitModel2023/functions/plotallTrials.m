function plotallTrials(trials_cell,trl_cond_nrs,predictions,responses)
%Plot predictions summarized across all trials

num_trials = numel(responses);
for j=1:num_trials
    if isempty(responses{j})
        responses{j} = nan(trials_cell{j}.trial_length,1);
    end
end

data_min = nanmin(cellfun(@(x) min(x),responses),[],'all');
predictions_min = nanmin(cellfun(@(x) min(x.y_pred),predictions),[],'all');
data_max = nanmax(cellfun(@(x) max(x),responses),[],'all');
predictions_max = nanmax(cellfun(@(x) max(x.y_pred),predictions),[],'all');

yLim = [nanmin(data_min,predictions_min),nanmax(data_max,predictions_max)];
if isnan(yLim(1)); yLim(1) = 0; end
if isnan(yLim(2)); yLim(2) = 1; end

%Plot predictions per trial
num_trials_per_block = 25;
num_blocks = num_trials/num_trials_per_block;

colours = {[0.9290 0.6940 0.1250],[0.4940 0.1840 0.5560]};  %AV=orange, A=purple

for j=1:num_trials
    
    %Get block number and trial number within block
    block_nr = ceil(j/num_trials_per_block);
    trial_nr = mod(j,num_trials_per_block);
    if trial_nr==0
        trial_nr = num_trials_per_block;
    end
    
    %Open new figure? and select subplot
    if trial_nr==1
        figure('Name',['Block Nr ' num2str(block_nr)],'NumberTitle','off');
    end
    subplot(5,5,trial_nr); hold on; box on;
    
    %Compute R-squared
    y_pred = predictions{j}.y_pred;
    y = responses{j};
    R2 = compR2(y,y_pred);
    
    %Extract useful info 
    trial_length = trials_cell{j}.trial_length;  
    t = 1:trial_length;
    
    PRFinfo = predictions{j}.PRFinfo;
    stim_times = PRFinfo.stim_times;
    stim_types = PRFinfo.stim_types;
    delta_amp = PRFinfo.delta_amp;
    delta_lat = PRFinfo.delta_lat;
    
    %Do the plotting
    plot(t,y,'b-');
    plot(t,y_pred,'r--');
    for i=1:length(stim_types)
        plot([stim_times(i) stim_times(i)]+delta_lat(i),[0 delta_amp(i)],'-','Color',colours{stim_types(i)});
    end
    
    %Finish plot
    xlim([1 trial_length]); xticks(stim_times);
    xticklabels(cellfun(@(x) num2str(x),num2cell(1:length(stim_times)),'UniformOutput',false));
    title(['R2=' num2str(round(R2*100)/100)]); ylim(yLim); 
end

end %[EoF]
