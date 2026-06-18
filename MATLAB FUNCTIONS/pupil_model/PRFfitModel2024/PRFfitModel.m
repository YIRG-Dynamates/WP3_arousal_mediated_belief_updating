function PRFfitResults = PRFfitModel(input_data,options_struct)
% PRFfitResults = PRFfitModel(input_data,options_struct)
%
% Fit the Pupil Response Function (PRF) model to a dataset of pupil size 
% timecourses with event times (e.g. stimuli presentations). The events are
% modelled as a combination of non-negative delta functions (phasic input)
% as well as a change in the baseline level activation (tonic input). 

% The model is loosely based on the PRET toolbox: 
% https://github.com/jacobaparker/PRET, Denison, Parker & Carrasco (2020)
% Behavior Research Methods, https://doi.org/10.3758/s13428-020-01368-6
% The regression based fitting method was inspired by the Unfold toolbox: 
% https://www.unfoldtoolbox.org/, Ehinger B & Dimigen O, (2019) peerJ, 
% https://peerj.com/articles/7838/
%
% The PRF model makes use of David Meijer's general modelling framework. 
% Please see "fitModelStart.m" for a concise description of the input 
% arguments. For example usage, see "modelPlay.m" in the various folder.
%
% Author: David Meijer
% Affiliation: Acoustics Research Institute, Austrian Academy of Sciences
% Communication: MeijerDavid1@gmail.com
%
% Version: 19-06-2024

%% Add "functions" folder and its subfolders to the Matlab path

me = mfilename;                                                             %what is my filename
pathstr = fileparts(which(me));                                             %get my location
addpath(genpath([pathstr filesep 'functions']));                                     

%% Call the start function of the general modelling framework

PRFfitResults = fitModelStart(input_data,options_struct);

end %[EoF]
