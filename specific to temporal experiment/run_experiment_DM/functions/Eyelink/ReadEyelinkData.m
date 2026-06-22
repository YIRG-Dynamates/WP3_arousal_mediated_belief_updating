%clean workspace 
clc
clear all
close all

%Select and convert (if necessary) the eyelink datafile (.edf)
[fileName, dirName] = uigetfile('*.edf', 'Select EyeLink data file in edf format');
ascFullFileName = fullfile(dirName, [fileName(1:(end-4)) '.asc']);
if ~(exist(ascFullFileName, 'file') == 2)
    disp('Converting .edf file to .asc file'); disp(' ');
    try %to convert edf to asc
        old_cd = cd(dirName); tic;              %Temporarily switch current folder to avoid problems with foldernames                    
        system(['edf2asc ' fileName]);          %This is a pre-installed function provided by EyeLink (install: EyeLinkDevKit_Windows_1.11.5 - it's in S:\CCNlab\Technical_stuff\EyeLink)
        Time2Covert = toc;
        disp(' '); disp(['Time to convert: ' num2str(Time2Covert) ' seconds']); disp(' ');
        cd(old_cd);                             %Switch back current folder
    catch
        error('Could not convert edf to asc');
    end
else
    disp('.asc file was found, using that one (not converting the .edf file)'); disp(' '); 
end

%Read data using fieldtrip function that was slightly extended by Mate
data_eye = read_eyelink_asc_ext(ascFullFileName);                           %This function needs the Fieldtrip function 'tokenize.m' (Note: the SPM12 function tokenize.m will throw an error)           

%Read the event data using a function initially written by Mate and adapted by David       
event_eye = read_eyelink_event(data_eye);

%Create "FieldTrip-type" data structure
eyeData.hdr = data_eye.header;
eyeData.label = {'Timestamps'; 'X_position'; 'Y_position'; 'Pupil_size'};   %Keep Timestamps for reference to the events
eyeData.time = {(1:length(data_eye.dat(1,:)))./1000};                       %Note: we use fsample = 1000 Hz here                                         
eyeData.trial = {data_eye.dat(1:4,:)};
eyeData.fsample = 1000;                                                     
eyeData.sampleinfo = [1 length(eyeData.time{1,1})];
eyeData.event = event_eye;

%Clean up
clear data_eye event_eye fileName dirName

