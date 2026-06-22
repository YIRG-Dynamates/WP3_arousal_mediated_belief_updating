function plotFirstTask(trials_cell)
%Quick and dirty plot of the first task results

num_trials = length(trials_cell);

v = cellfun(@(x) x.v, trials_cell);
correct = cellfun(@(x) x.LocRespCorrect, trials_cell);
confidence = cellfun(@(x) x.ConfidenceLevel, trials_cell);
t = 1:num_trials;
a = abs(v);

figure; 

color_blind_red = [233 163 201]/255;
color_blind_green = [161 215 106]/255;

%Accuracy per velocity
subplot(2,2,1); hold on;
plot(t,v,'k-');
for i=1:num_trials
    if correct(i)
        plot(i,v(i),'o','MarkerSize',10,'MarkerFaceColor',color_blind_green,'MarkerEdgeColor','k');
    else
        plot(i,v(i),'o','MarkerSize',10,'MarkerFaceColor',color_blind_red,'MarkerEdgeColor','k');
    end
end
title('Results per velocity: Green = correct, Red = incorrect');
xlabel('Trial number'); ylabel('Velocity');

%Accuracy per absolute velocity
subplot(2,2,2); hold on;
plot(t,a,'k-');
for i=1:num_trials
    if correct(i)
        plot(i,a(i),'o','MarkerSize',10,'MarkerFaceColor',color_blind_green,'MarkerEdgeColor','k');
    else
        plot(i,a(i),'o','MarkerSize',10,'MarkerFaceColor',color_blind_red,'MarkerEdgeColor','k');
    end
end
title('Results per absolute velocity');
xlabel('Trial number'); ylabel('Absolute velocity (speed)');

%Set confidence colours
%conf_colours = [1 0 0; 1 .7 .1; 1 1 0; 0 .8 0];                            %1=red, 2=orange, 3=yellow, 4=green
conf_colours = [12 123 220; 93 147 150; 174 170 80; 255 194 10]/255;        %1=blue, 2=orange, 3=yellow, 4=yellow

% figure; hold on;
% plot(1,1,'o','MarkerSize',10,'MarkerFaceColor',conf_colours(1,:),'MarkerEdgeColor','k');
% plot(2,1,'o','MarkerSize',10,'MarkerFaceColor',conf_colours(2,:),'MarkerEdgeColor','k');
% plot(3,1,'o','MarkerSize',10,'MarkerFaceColor',conf_colours(3,:),'MarkerEdgeColor','k');
% plot(4,1,'o','MarkerSize',10,'MarkerFaceColor',conf_colours(4,:),'MarkerEdgeColor','k');

%Confidence per velocity
subplot(2,2,3); hold on;
plot(t,v,'k-');
for i=1:num_trials
    plot(i,v(i),'o','MarkerSize',10,'MarkerFaceColor',conf_colours(confidence(i),:),'MarkerEdgeColor','k');
end
title('Results per velocity: Green = correct, Red = incorrect');
xlabel('Trial number'); ylabel('Velocity');

%Confidence per absolute velocity
subplot(2,2,4); hold on;
plot(t,a,'k-');
for i=1:num_trials
    plot(i,a(i),'o','MarkerSize',10,'MarkerFaceColor',conf_colours(confidence(i),:),'MarkerEdgeColor','k');
end
title('Results per absolute velocity');
xlabel('Trial number'); ylabel('Absolute velocity (speed)');

end %[EoF]