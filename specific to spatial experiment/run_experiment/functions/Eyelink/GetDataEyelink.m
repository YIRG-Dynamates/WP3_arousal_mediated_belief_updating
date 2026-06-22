function [SampleData, EventData, keyCode] = GetDataEyelink(P,timeMax)
% for help of function use: Eyelink('GetQueuedData?'),
% or http://psychtoolbox.org/docs/Eyelink-GetQueuedData,
% also see 'EyelinkQueuedDataDemo'

% Event type numbers (second row in events output of function):
% STARTBLINK 3    // pupil disappeared, time only
% ENDBLINK   4    // pupil reappeared, duration data
% STARTSACC  5    // start of saccade, time only
% ENDSACC    6    // end of saccade, summary data
% STARTFIX   7    // start of fixation, time only
% ENDFIX     8    // end of fixation, summary data
% FIXUPDATE  9    // update within fixation, summary data for interval
% 
% MESSAGEEVENT 24  // user-definable text: IMESSAGE structure
% 
% BUTTONEVENT  25  // button state change:  IOEVENT structure
% INPUTEVENT   28  // change of input port: IOEVENT structure

keyCode = false([1 256]);               %initialize output argument

startTime=GetSecs;

nMaxSamples = timeMax*1000+1000;        %assuming the sample freq of eyetracker is 1000 Hz (the additional 1000 is a buffer. All non-filled samples will be deleted afterwards).

SampleData = nan(4,nMaxSamples);    
EventData = nan(3,nMaxSamples);

sampleNum=1;
eventNum=1;

while true
    
    numDrains = 0;
    
    drained = false;
    while ~drained

        [samplesIn, eventsIn, drained] = Eyelink('GetQueuedData');  
        numDrains = numDrains + 1;
        
        %SAMPLE_DATA (http://psychtoolbox.org/docs/Eyelink-GetQueuedData)
        %old row 1 = sample time (new row 1)
        %old row 13 = pupil size (new row 2) - RIGHT EYE
        %old row 15 = x_gaze     (new row 3) - RIGHT EYE
        %old row 17 = y_gaze     (new row 4) - RIGHT EYE
        if ~isempty(samplesIn)
            
            %Delete samples with a negative 'sample time'
            samplesIn(:,samplesIn(1,:) <= 0) = [];
            
            %Save all other samples (relevant rows only)
            SampleData(:,sampleNum:sampleNum+size(samplesIn,2)-1)=samplesIn([1 13 15 17],:);
            sampleNum=sampleNum+size(samplesIn,2);
        end
        
        %EVENTS (http://psychtoolbox.org/docs/Eyelink-GetQueuedData)
        %old row 1 = time of event (for type = 24; messages)
        %old row 2 = type of event (new row 1)
        %old row 5 = start time    (new row 2) 
        %old row 6 = end time      (new row 3) 
        if ~isempty(eventsIn)
            
            %Correct the timing of the messages
            idx_msgs = find(eventsIn(2,:) == 24);
            if ~isempty(idx_msgs)
                eventsIn(5,idx_msgs) = eventsIn(1,idx_msgs);
                eventsIn(6,idx_msgs) = eventsIn(1,idx_msgs);
            end
            
            %Save all relevant rows
            EventData(:,eventNum:eventNum+size(eventsIn,2)-1)=eventsIn([2 5 6],:);
            eventNum=eventNum+size(eventsIn,2);
        end
    end    
    
%     %Display a warning if the number of drains is more than 1
%     if numDrains > 1
%         disp(' '); disp(['Warning: Number of drains was: ' num2str(numDrains) ', in Trial nr: ' num2str(P.trial_counter)]); 
%     end
    
    % Escape pressed?
    [pressed, ~, keyCode] = KbCheck;
    if pressed && keyCode(P.quitKey)
        break;                              %Break from while loop
    end
    
%     %Break because of nSamples --> don't use because we collect data samples at
%     %negative times too, but we don't know how many such datasamples..
%     if sampleNum >= nMaxSamples
%         break;                            %Break from while loop
%     end    
    
    %Break because of time?
    currentTime = GetSecs;
    if (currentTime-startTime) > timeMax
        break;                              %Break from while loop
    else
        %Ensure that we only ask for data once every 250 ms to not overload the system   
        Time2recordLeft = timeMax - (currentTime-startTime);
        WaitThisLong = min(Time2recordLeft,0.25);
        WaitSecs(WaitThisLong);     
    end
    
end
    
%Clean Up: delete columns that were not filled
SampleData(:,isnan(SampleData(1,:))) = [];    
EventData(:,isnan(EventData(1,:))) = [];
    
end %[EOF]
