function plotOneTrial(trial_data,trial_responses,pred_trial_struct,cond_nr,param_settings,model_settings,fit_settings)
%Plot predictions for one trial
    
%Retrieve stimulus locations from trial_data
x_true = trial_data.x;

%Retrieve latent_vars from predictions struct
latent_vars = pred_trial_struct.latent_vars;

%Retrieve responses for this trial (may contain NaNs)
if ~isempty(trial_responses)
    d_resp = trial_responses.d_resp;
else
    d_resp = [];
end

%Start original code...
plot_order = {'lambda','prior_d','post_d', ...
              'var_lik','prior_entropy','post_entropy', ...
              'surprisal','post_prob_CP','info_gain'};
         
num_stim = length(x_true);
num_diffs = num_stim-1;
t = 1:num_diffs;

fh = figure();
% fh.WindowState = 'maximized';

for i=1:length(fit_settings.latent_vars)
    
    var_name = fit_settings.latent_vars{i};
    i_plotOrder = find(strcmp(var_name,plot_order),1);
    assert(~isempty(i_plotOrder),'Latent variable name is unknown in plot_order cell-array');
    
    %special fix for first stimulus (otherwise the plots get obscured by the large probabilities at stimulus 1)   
    if any(strcmp(var_name,{'prior_d','post_prob_CP','prior_entropy'}))
        if size(latent_vars.(var_name).med,2) > 1
            latent_vars.(var_name).med(1,1) = nan;
            latent_vars.(var_name).iqr(1,1) = nan;
        end
    end
    
    subplot(3,3,i_plotOrder); hold on; box on;
    
    y = latent_vars.(var_name).med(1,:) + [-1; 0; 1].*latent_vars.(var_name).iqr(1,:);
    [hl,hp] = boundedLine_DM(t,y,'b');
    
    title(regexprep(var_name,'_',' '));
    if i_plotOrder==1 
        true_nu = diff(x_true);
        plot(t,true_nu,'ok','MarkerFaceColor','k','MarkerSize',5); 
        plot(num_diffs*ones(numel(d_resp),1),d_resp(:),'*r','MarkerSize',5)
    end
    if i_plotOrder<=3
        plot([1 num_diffs],[0 0],'m--','LineWidth',.5); 
    end
    if i_plotOrder>6; xlabel('Stim interval number'); end
    
end

end %[EoF]
