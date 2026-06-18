function plotallTrials(trials_cell,trl_cond_nrs,predictions,responses,param_settings_cond,model_settings,fit_settings)
%Plot model predictions summarized across all trials

num_trials = numel(responses);
for j=1:num_trials
    if isempty(responses{j})
        responses{j}.pupil_resp = nan(trials_cell{j}.trial_length,1);
    end
end

resp_min = nanmin(cellfun(@(x) min(x.pupil_resp),responses),[],'all');
pred_min = nanmin(cellfun(@(x) min(x.pupil_pred),predictions),[],'all');
resp_max = nanmax(cellfun(@(x) max(x.pupil_resp),responses),[],'all');
pred_max = nanmax(cellfun(@(x) max(x.pupil_pred),predictions),[],'all');

yLim = [nanmin(resp_min,pred_min),nanmax(resp_max,pred_max)];
if isnan(yLim(1)); yLim(1) = 0; end
if isnan(yLim(2)); yLim(2) = 1; end

%Plot predictions per trial
num_trials_per_block = 25;
num_blocks = num_trials/num_trials_per_block;

cond_colours = {[0.9290 0.6940 0.1250],[0.4940 0.1840 0.5560]};  %Cond 1 = orange, Cond 2 = purple

for j=1:num_trials
    
    c = trl_cond_nrs(j);
    
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
    pupil_pred = predictions{j}.pupil_pred;
    pupil_resp = responses{j}.pupil_resp;
    R2 = compR2(pupil_resp,pupil_pred);
    
    %Extract useful info 
    trial_length = trials_cell{j}.trial_length;  
    t = 1:trial_length;
    
    PRFinfo = predictions{j}.PRFinfo;
    event_times = PRFinfo.event_times;
    delta_amp = PRFinfo.delta_amp;
    delta_lat = PRFinfo.delta_lat;
    boxcar_amp = PRFinfo.boxcar_amp;
    boxcar_lat = PRFinfo.boxcar_lat;
    boxcar_dur = PRFinfo.boxcar_dur;
    
    %Do the plotting
    plot(t,pupil_resp,'b-');
    plot(t,pupil_pred,'r--');
    for i=1:length(event_times)
        plot(delta_lat(i)+[event_times(i) event_times(i)],[0 delta_amp(i)],'-','Color',cond_colours{c});
        plot(boxcar_lat(i)+[event_times(i) event_times(i)+boxcar_dur(i)],[boxcar_amp(i) boxcar_amp(i)],'-','Color',cond_colours{c});
    end
    
    %Finish plot
    xlim([1 trial_length]); xticks(event_times);
    xticklabels(cellfun(@(x) num2str(x),num2cell(1:length(event_times)),'UniformOutput',false));
    title(['R2=' num2str(round(R2*100)/100)]); ylim(yLim); 
end

end %[EoF]
