% array = [1 2 3 4 5 2 3 4 6 2 3 4 7 2 3 4];
% pattern = [2 3 4];
% indices = findPattern(array, pattern);
% disp(indices);


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

end %eof