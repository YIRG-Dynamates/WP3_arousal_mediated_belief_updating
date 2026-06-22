function [S,trials_cell,stopTaskBool] = StaircaseControl(S,P,trials_cell)
% Control the staircase procedure trial by trial

%Initialize output argument
stopTaskBool = false;

%Find trial numbers
comingTrialNr = P.trial_counter;     
previousTrialNr = P.trial_counter-1;     

%%%
%Update staircase with last trial's response
%%%

if (comingTrialNr == S.nTrials) || ~isfield(trials_cell{comingTrialNr},'staircase')
    
    %Unpack the staircase stuff from the previous trial
    psy = trials_cell{previousTrialNr}.staircase{1};
    method = trials_cell{previousTrialNr}.staircase{2};
    vars = trials_cell{previousTrialNr}.staircase{3};
    x = trials_cell{previousTrialNr}.staircase{4};
    
    %Extract response
    response = trials_cell{previousTrialNr,1}.LocResponse;
    if response == -1
        response = 0;   %PsyBayes requires 1 or 0 responses
    end
    
    %Get next recommended point that minimizes predicted entropy given the current posterior and response at x
    %disp(['Upcoming Trial Nr = ' num2str(comingTrialNr) '. PsyBayes processing time is:']);
    %tic;
    [x, psy, output] = psybayes(psy, method, vars, x, response);
    %toc   %The above step takes roughly 20 ms
    
    %Save the updated psy struct 
    trials_cell{previousTrialNr}.staircase{1} = psy;
    
    %Save current MAA estimate
    S.MAA = output.sigma.mean;
    
    %Terminate or initiate a new trial?
    if comingTrialNr > (S.nTrials-1)
        stopTaskBool = true;
        S.nTrials = S.nTrials-1;
        return
    else
        trials_cell{previousTrialNr} = rmfield(trials_cell{previousTrialNr}, 'staircase');  %Remove staircase struct from previous trial (essential to minimize size and "saving time")
        trials_cell{comingTrialNr}.staircase = {psy,method,vars,x};                         %Add updated staircase struct to upcoming trial
    end

%If this is a first trial, then make a guess (this is the maximally allowed MAA for the 0 degrees location)
elseif comingTrialNr == 1
    
    S.MAA = 4.5;
    
end

%%%
%Determine stimuli locations for new trial
%%%

%Make some trials easy on purpose
easyRate = 0.2;
easyBool = rand() < easyRate;
if easyBool
    x = min(20,round(3*S.MAA));
    trials_cell{comingTrialNr}.staircase{4} = x;
else
    x = trials_cell{comingTrialNr}.staircase{4};
end

%Randomize standard (0) and probe location
%if x is positive, then sequence is [0 +] or [- 0]
%if x is negative, then sequence is [0 -] or [+ 0]
if rand() < 0.5
    azimuth_sequence = [0 x];
else
    azimuth_sequence = [-x 0];
end

%Add the azimuth offset
azimuth_sequence = azimuth_sequence + trials_cell{comingTrialNr}.azimuth_offset;

%Store the info of the coming trial
trials_cell{comingTrialNr}.sd_exp = 0;
trials_cell{comingTrialNr}.x = azimuth_sequence;
trials_cell{comingTrialNr}.cp = [NaN true];
trials_cell{comingTrialNr}.v_mean = diff(azimuth_sequence);
trials_cell{comingTrialNr}.v = diff(azimuth_sequence);
trials_cell{comingTrialNr}.SAC = 1;

%Add random jitter to lead in timing
trials_cell{comingTrialNr}.timing_lead_in = 750 + round(rand()*250);

end %[EOF]
