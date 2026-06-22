function event = read_eyelink_event(data_eye)
% Read MSG, ESACC, EBLINK, EFIX and INPUT events from eyelink data
% 
% DETAILS: 
%   ft_read_event does not read MSG, SACC, FIX and BLINK events into the 
%   event structure as the syntax of those events can vary massively. This
%   function reads these events but with only the below syntax 
%   (see EyeLink manual for other syntaxes)
%   
%   MSG syntax: 
%       MSG <time> <message> 
%           (I assume, that <message> contains only digits)
%   
%   ESACC syntax: 
%       ESACC <eye> <stime> <etime> <dur> <sxp> <syp> <exp> <eyp> <ampl> <pv>
%   
%   EBLINK syntax: 
%       EBLINK <eye> <stime> <etime> <dur>
%   
%   EFIX syntax: 
%       EFIX <eye> <stime> <etime> <dur> <axp> <ayp> <aps>
%   
%   NOTATIONS
%       <eye>         which eye caused event ("L" or "R")
%       <time>        timestamp in milliseconds
%       <stime>       timestamp of first sample in milliseconds
%       <etime>       timestamp of last sample in milliseconds
%       <dur>         duration in milliseconds
%       <axp>, <ayp>  average X and Y position
%       <sxp>, <syp>  start X and Y position data
%       <exp>, <eyp>  end X and Y position data
%       <aps>         average pupil size (area or diameter)
%       <av>, <pv>    average, peak velocity (degrees/sec)
%       <ampl>        saccadic amplitude (degrees)
%       <xr>, <yr>    X and Y resolution (position units/degree)
% 
%   We make use of the function regexp (regular expression). 
%   The expressions are matched using the following 'metacharacters':
%
%   \s   = white space
%   \s+  = one or multiple white spaces
%   \d   = a digit
%   \d+  = one or multiple digits
%   []   = any of the characters contained within the brackets
%   ()   = group subexpression (token)

%Initialize
event.triggers = [];
event.fixation = [];
event.saccades = [];
event.blinks = [];

% Message events (triggers)
msg = data_eye.msg;
% Finding stimulus events amongst message events
% Other events are for example calibration and validation values (but we disregard those)      
msg = regexp(msg,'MSG\s\d+\s\d+','match','once');           
msg = msg(~strcmp(msg,''));
% Extracting MSG details
% MSG <time> <message> 
nMsg = size(msg,1);
if nMsg > 0
    temp = regexp(msg,'MSG\s+(\d+)\s+(\d+)','tokens');      %everything between brackets is a token, and will thus appear in the output
    temp = [temp{:}]';
    temp = vertcat(temp{:});
    temp = cellfun(@str2num,temp,'UniformOutput',false);
    % Saving MSG event as trigger numbers
    event.triggers.time = cell2mat(temp(:,1));
    event.triggers.value = cell2mat(temp(:,2));
end

% End of fixation events
fixx = data_eye.efix;
nFix = size(fixx,1);
% Extracting EFIX details
% EFIX <eye> <stime> <etime> <dur> <axp> <ayp> <aps>
if nFix > 0
    temp = regexp(fixx,'EFIX\s+([LR])\s+(\d+)\s+(\d+)\s+([0-9.]+)\s+([0-9.-]+)\s+([0-9.-]+)\s+([0-9.]+)','tokens');
    temp = [temp{:}]';
    temp = vertcat(temp{:});
    temp(:,2:7) = cellfun(@str2num,temp(:,2:7),'UniformOutput',false);
    event.fixation.eye = temp(:,1);
    event.fixation.start_time = cell2mat(temp(:,2));
    event.fixation.end_time = cell2mat(temp(:,3));
    event.fixation.duration = cell2mat(temp(:,4));
    event.fixation.avg_x_pos = cell2mat(temp(:,5));
    event.fixation.avg_y_pos = cell2mat(temp(:,6));
    event.fixation.avg_pupil_size = cell2mat(temp(:,7));
end

% End of saccade events
sacc = data_eye.esacc;
nSacc = size(sacc,1);
% Extracting ESACC details
% ESACC <eye> <stime> <etime> <dur> <sxp> <syp> <exp> <eyp> <ampl> <pv>
% For floating point values the exponential notation is also possible, so I included that in the regular expression.         
if nSacc > 0
    temp = regexp(sacc,...
        'ESACC\s+([LR])\s+(\d+)\s+(\d+)\s+([0-9.e+]+)\s+([0-9.e+-]+)\s+([0-9.e+-]+)\s+([0-9.e+-]+)\s+([0-9.e+-]+)\s+([0-9.e+]+)\s+([0-9.e+]+)','tokens');
    temp = [temp{:}]';
    temp = vertcat(temp{:});
    temp(:,2:10) = cellfun(@str2num,temp(:,2:10),'UniformOutput',false);
    event.saccades.eye = temp(:,1);
    event.saccades.start_time = cell2mat(temp(:,2));
    event.saccades.end_time = cell2mat(temp(:,3));
    event.saccades.duration = cell2mat(temp(:,4));
    event.saccades.start_x_pos = cell2mat(temp(:,5));
    event.saccades.start_y_pos = cell2mat(temp(:,6));
    event.saccades.end_x_pos = cell2mat(temp(:,7));
    event.saccades.end_y_pos = cell2mat(temp(:,8));
    event.saccades.amplitude = cell2mat(temp(:,9));
    event.saccades.peak_velocity = cell2mat(temp(:,10));
end

% End of blink events
blink = data_eye.eblink;
nBlink = size(blink,1);
% Extracting EBLINK details
% EBLINK <eye> <stime> <etime> <dur>
if nBlink > 0
    temp = regexp(blink,'EBLINK\s+([LR])\s+(\d+)\s+(\d+)\s+([0-9.e+]+)','tokens');
    temp = [temp{:}]';
    temp = vertcat(temp{:});
    temp(:,2:4) = cellfun(@str2num,temp(:,2:4),'UniformOutput',false);
    event.blinks.eye = temp(:,1);
    event.blinks.start_time = cell2mat(temp(:,2));
    event.blinks.end_time = cell2mat(temp(:,3));
    event.blinks.duration = cell2mat(temp(:,4));
end

end %[EOF]
