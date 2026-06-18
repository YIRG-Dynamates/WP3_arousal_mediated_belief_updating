
function included_sounds = incl_sounds(preprocessed_eye_data, excl_start)

%excl_start is how many stimuli from the start should be excluded 
% (at least 1)

included_sounds = cell(size(preprocessed_eye_data));

for i = 1:numel(preprocessed_eye_data)
    times = preprocessed_eye_data{i}.A_stim_times;
    intervals = preprocessed_eye_data{i}.missing_periods;

    % exclusion period first 1,5 seconds and last 1,5 seconds
    more_intervals = [1,1500; length(preprocessed_eye_data{i}.pupilSize)-1500, length(preprocessed_eye_data{i}.pupilSize)];

    % check if sounds are within periods
    included_sounds{i}.incl_sounds = ~isItInPeriod(times, intervals, more_intervals);
    included_sounds{i}.SAC_level = preprocessed_eye_data{i}.SAC_level  ;

    % exclude last sound and first two (if they didnt get caught by the time
    % periods
    included_sounds{i}.incl_sounds(end) = false;
    included_sounds{i}.incl_sounds(1: excl_start) = false;
end

end %eof





function indices = findPattern(array, pattern)
    % Convert input array and pattern to row vectors
    array = array(:)';
    pattern = pattern(:)';
    
    % Get the lengths
    lenArray = length(array);
    lenPattern = length(pattern);
    
    % Initialize an empty array to store indices
    indices = [];
    
    % Loop through the array to check for pattern matches
    for i = 1:(lenArray - lenPattern + 1)
        if isequal(array(i:i+lenPattern-1), pattern)
            indices = [indices, i];
        end
    end
end
