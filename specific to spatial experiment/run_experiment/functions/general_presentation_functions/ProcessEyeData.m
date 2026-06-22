function eye_data = ProcessEyeData(F, nr_of_trials_completed)

%Initialize output argument
eye_data = 'dummy';

%Check whether the raw eye_data folder exists  
[save_path,filename] = fileparts(F.save_file);
eye_save_dir = fullfile(save_path,['RawEyeData_' filename]); 
if exist(eye_save_dir,'dir')
    
    % Only process eyetracker data if the datafile still exists     
    if exist(F.save_file,'file')
        
        %Load the eye_data timestamps that were saved in 'PresentStim.m'
        load(F.save_file,'eye_data');
        
        %Collect data for all trials
        for i=1:nr_of_trials_completed
            
            %...fixation at block starts and actual trial data
            for j=1:2 

                %1 = trials, 2 = fixation
                if j==1
                    fileNameStandard = 'Eyelink_Trial_'; 
                elseif j==2
                    fileNameStandard = 'Eyelink_Fixation_Trial_';
                end

                %if there should be eye data and not yet processed..
                if ~isempty(eye_data{i,j}) && ~iscell(eye_data{i,j})

                    %if there is indeed eye_data
                    if exist([eye_save_dir filesep fileNameStandard num2str(i) '.mat'],'file')
                        load([eye_save_dir filesep fileNameStandard num2str(i) '.mat'],'SampleData','EventData');                   
                        
                        StartTimeStamp = eye_data{i,j}(1);
                        StopTimeStamp = eye_data{i,j}(end);
                        
                        EMD=find((SampleData(1,:) > StartTimeStamp) & (SampleData(1,:) < StopTimeStamp));
                        if ~isempty(EMD)
                            EyeTime = SampleData(1,EMD)';                       %Raw timestamps in milliseconds     
                            GazeX = SampleData(3,EMD)';                         %Horizontal gaze location in pixels
                            GazeY = SampleData(4,EMD)';                         %Vertical gaze location in pixels
                            PupilSize = SampleData(2,EMD)';                     %Pupil size
                            EyeDataTemp = {EyeTime, GazeX, GazeY, PupilSize};
                        else
                            EyeDataTemp = {[],[],[],[]};
                        end
                        
                        EMD=find((EventData(3,:) > StartTimeStamp) & (EventData(2,:) < StopTimeStamp));
                        if ~isempty(EMD)
                            EventType = EventData(1,EMD)';                      %See GetDataEyelink.m for a description of the even type numbers      
                            EventStart = EventData(2,EMD)';                     %Raw timestamps in milliseconds
                            EventEnd = EventData(3,EMD)';                       %Raw timestamps in milliseconds
                            EyeEventsTemp = {EventType, EventStart, EventEnd};  
                        else
                            EyeEventsTemp = {[],[],[]};
                        end
                        
                        eye_data{i,j} = {EyeDataTemp,EyeEventsTemp};
                    
                    else %if eye_data file does not exist for this trial
                        eye_data{i,j} = {{[],[],[],[]},{[],[],[]}};
                    end
                end
            end
        end

        %Save the updated eye_data
        save(F.save_file,'eye_data','-append') 
        fprintf('\nEYE DATA WAS PROCESSED\n');
    
    end %end if 'saveFileName' was exists (incl. 'eye_data')
        
    %Delete the RawEyeData folder including the subdirectory ('s') tree and all files (careful!)
    rmdir(eye_save_dir,'s')

end %end if-statement does folder exist?

end %[EOF]