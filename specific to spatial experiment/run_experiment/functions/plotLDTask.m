function plotLDTask(trials_cell)

%Select only trials that were completed
num_trials = sum(cellfun(@(x) isfield(x,'LocResponse'),trials_cell),'all');
trials_cell = trials_cell(1:num_trials);

%Get all trial conditions
fields = {'x','v','cp','d','mu_exp','sd_exp'};
for j=1:num_trials
    for f=1:length(fields)
        eval([fields{f} ' = trials_cell{j}.' fields{f} ';']);
    end
    T = getTrialConditions_SAC_dir(x,v,cp,d,mu_exp,sd_exp);

    %Check that the SAC level is the same
    assert(T.SAC == trials_cell{j}.SAC,'SAC level is not the same');

    %Copy all conditions into the trials_cell
    fldnames = fieldnames(T);
    for f=1:length(fldnames)
        trials_cell{j}.(fldnames{f}) = T.(fldnames{f});
    end
end

%Bin the trials according to SAC, and velocity strength and then compute accuracy and average confidence levels  
%Also split the confidence responses by whether the direction response was correct or not   
SAC_levels = 1:5;
vel_levels = 1:2;    
correct_or_not = cell(numel(SAC_levels),numel(vel_levels));
confidence_per_SACvel = cell(numel(SAC_levels),numel(vel_levels));
confidence_per_correct = cell(2,1);
for j=1:num_trials
    idx_SAC = trials_cell{j}.SAC;
    idx_vel = trials_cell{j}.target_vel_2_bin;
    correct_or_not{idx_SAC,idx_vel} = [correct_or_not{idx_SAC,idx_vel} trials_cell{j}.LocRespCorrect];
    confidence_per_SACvel{idx_SAC,idx_vel} = [confidence_per_SACvel{idx_SAC,idx_vel} trials_cell{j}.ConfidenceLevel];
    if trials_cell{j}.LocRespCorrect
        confidence_per_correct{1,1} = [confidence_per_correct{1,1} trials_cell{j}.ConfidenceLevel]; %correct
    else
        confidence_per_correct{2,1} = [confidence_per_correct{2,1} trials_cell{j}.ConfidenceLevel]; %incorrect
    end
end
fraction_correct = cellfun(@mean, correct_or_not); 
avg_confidence = cellfun(@mean, confidence_per_SACvel); 

%Plot the results for this subject
figure;

color_blind_red = [233 163 201]/255;
color_blind_green = [161 215 106]/255;

%Accuracy per SAC
subplot(2,2,1); hold on;
h1 = plot(SAC_levels,fraction_correct(:,1),'ro-');
h2 = plot(SAC_levels,fraction_correct(:,2),'bo-');
xlim([0.5 5.5]); ylim([-0.1 1.1]); ylabel('Accuracy'); xlabel('SAC level'); title('Accuracy per SAC level')
legend([h1 h2],{'hard','easy'},'location','northwest');

%Confidence per SAC
subplot(2,2,2); hold on;
h1 = plot(SAC_levels,avg_confidence(:,1),'ro-');
h2 = plot(SAC_levels,avg_confidence(:,2),'bo-');
xlim([0.5 5.5]); ylim([0.9 4.1]); ylabel('Avg Confidence'); xlabel('SAC level'); title('Average Confidence per SAC level') 
legend([h1 h2],{'hard','easy'},'location','northwest');

%Confidence histogram for correct trials
subplot(2,2,3); 
histogram(confidence_per_correct{1,1},.5:4.5,'FaceColor',color_blind_green);
xlim([0.5 4.5]); xticks(1:4); ylabel('trial counts'); xlabel('Confidence level'); title('Confidence histogram for correct trials')

%Confidence histogram for incorrect trials
subplot(2,2,4); hold on;
histogram(confidence_per_correct{2,1},.5:4.5,'FaceColor',color_blind_red);
xlim([0.5 4.5]); xticks(1:4); ylabel('trial counts'); xlabel('Confidence level'); title('Confidence histogram for incorrect trials')

end %[EoF]
