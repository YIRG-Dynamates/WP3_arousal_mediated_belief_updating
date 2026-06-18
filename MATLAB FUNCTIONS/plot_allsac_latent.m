
function plot_allsac_latent = plot_allsac_latent(fignum, correct, SAC, latenttext, exptext, abscissa, col_var)
%%% FUNCTION STARTS FROM HERE

% color is coded as 1 = red and 2 = blue
%correct = cell2num(correct);

for sac_var = 1:5;
    %sac_var = 1;
    
    SAC_logical = SAC == sac_var; % value  means this trial ends on respective SAC   
    
    
    for sbj = 1:width(correct)
    
        rows = []; array_temp = [];
        rows = SAC_logical(:,sbj);
        array_temp = correct(rows,sbj);
        array_temp = array_temp(~isnan(array_temp));
        means_sac_sbj(sbj, sac_var) = sum(array_temp) / length(array_temp);
    
    end
end


% ========================== calc SEM and mean(mean) ==============

% Mean across subjects (per sac level)
means_sac  = mean(means_sac_sbj, 1, 'omitnan');

% SEM across subjects (per sac level)
sem_sac  = std(means_sac_sbj, 0, 1, 'omitnan')  ./ sqrt(sum(~isnan(means_sac_sbj),1));


x = 1:5; % sac levels

% green = alpha_val*[0 0.5 0] + (1-alpha_val)*[1 1 1];
% blue  = alpha_val*[0 0 1] + (1-alpha_val)*[1 1 1];

if col_var == 1
    col_code  = [1 0 0];
elseif col_var == 2
    col_code = [0 0 1];
end

%figure(fignum); 
hold on;

% Latent > median
errorbar(x + abscissa, means_sac, sem_sac, ...
    '-o', 'LineWidth', 1, 'MarkerSize', 3, 'Color', col_code);

xlabel('SAC');
%ylabel('Accuracy');

set(gca,'XTick',x)

%ylim([0 1.1]);
xlim([0.8 5.2]);
title([latenttext exptext])
set(gca,'XTick',1:5)

grid on;
hold off;

end %eof