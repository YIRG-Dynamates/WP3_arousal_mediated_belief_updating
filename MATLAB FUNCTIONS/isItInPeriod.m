function isInPeriod = isItInPeriod(times, intervals, more_intervals);
% this function checks which stim times are within the missing period
% (intervals) or start and end of trial (more_intervals)
periods = vertcat(intervals, more_intervals);

%initialize
isInPeriod = false(1, length(times));

% Loop through each time
for i = 1:length(times);
    % Check if the current time falls within any of the periods
    for j = 1:size(periods, 1);
        if times(i) >= periods(j, 1) && times(i) <= periods(j, 2);
            isInPeriod(i) = true;
            break; % No need to check other periods for this time
        end
    end
end
end %eof