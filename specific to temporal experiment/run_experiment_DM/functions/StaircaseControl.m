function [S,trials_cell,stopTaskBool] = StaircaseControl(S,F,P,D,trials_cell)
% Control the staircase procedure every 10 trials

%Initialize output argument
stopTaskBool = false;

%Find trial numbers
comingTrialNr = P.trial_counter;
previousTrialNr = P.trial_counter-1;

% Generate 50 new trials after every 10 trials
% Make sure to choose 2 of each SAC levels(1-5) to include in these 10 trials
max_sac = 5;
% Done for both LD1 and LD2 blocks

if P.trial_counter == 1
    trials_selected = []; % trial indices
    all_sacs = cellfun(@(x) x.SAC, trials_cell); % sac levels of all 50 trials
    
    for saci = 1:max_sac % select for each sac level
        trials_selected = [trials_selected; find(all_sacs==saci,2)];
        
    end
    trials_cell = trials_cell(sort(trials_selected),:);
end

% After every 10 trials update the mu level based on performance
if mod(P.trial_counter,10) == 1 && P.trial_counter>1

% It takes a while to generate new trials, let participant know
myText = ['New trial is loading...'];
boundsText = Screen(P.win,'TextBounds',myText); %[L,T,R,B] from [L=0,T=0]
Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1);
Screen('DrawText',P.win, myText, round(D.win_center_x-boundsText(3)/2), round(D.win_center_y-boundsText(4)/2), P.draw_color);
Screen('Flip', P.win);

    num_correct = sum(cellfun(@(x) x.TempoDirRespCorrect, trials_cell(P.trial_counter-10:P.trial_counter-1,: )));
    if num_correct <8  % Make the task easier only if
        
        if ismember(S.block_nr, [1])
            
            %We don't want to keep making it easier because
            %generative function will reach the limits
            
            if S.SOA_settings.main_task_mu_exp < 1.4
                S.SOA_settings.main_task_limits(2) = S.SOA_settings.main_task_limits(2)+ 250;
                
                %Set difficulty in units of JND (larger is easier)
                S.SOA_settings.main_task_mu_exp = S.SOA_settings.main_task_mu_exp + .05 ;
            end
            
        elseif ismember(S.block_nr, [2])
            % Do nothing, we don't want to change the limits of SOA
            % We change the limits of SOA only for the first training block
        end
        
    elseif num_correct>8
        
        %Set difficulty in units of JND (larger is easier)
        S.SOA_settings.main_task_mu_exp = S.SOA_settings.main_task_mu_exp - .05 ;
        
    end
    % Create 50 more trials with new settings
    [S,trials_cell_new] = GenTrials(S,F,1);
    
    % Rearrange the trials cell
    % Assign new set of 10 trials
    trials_selected = []; % trial indices to select
    all_sacs = cellfun(@(x) x.SAC, trials_cell_new); % sac levels of 50 trials
    
    for saci = 1:max_sac % select for each sac level
        trials_selected = [trials_selected; find(all_sacs==saci,2)];
    end
    
    trials_cell_new = trials_cell_new(sort(trials_selected),:);
    
    trials_cell(P.trial_counter:P.trial_counter+9,:) = trials_cell_new(1:10,:);
    

% Only draw the fixation dot
Screen('DrawDots', P.win, [D.win_center_x,D.win_center_y], 5, P.draw_color, [], 1);
Screen('Flip', P.win);
end



end %[EOF]
