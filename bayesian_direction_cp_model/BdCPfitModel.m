function BdCPfitResults = BdCPfitModel(input_data,options_struct)
% BdCPfitResults = BdcPfitModel(input_data,options_struct)
%
% Fit various versions of the Bayesian direction Change Point (BdCP) model
% that we have developed for the Dynamates project at the Acoustics 
% Research Institute (ARI), Austrian Academy of Sciences, Vienna, Austria.
%
% The BdCP model makes use of David Meijer's general modelling framework. 
% Please see "fitModelStart.m" for a concise description of the input 
% arguments. For example usage, see "modelPlay.m" in the various folder.
%
% Author: David Meijer
% Affiliation: Acoustics Research Institute, Austrian Academy of Sciences
% Communication: MeijerDavid1@gmail.com
%
% Version: 06-06-2024

%% Add "functions" folder and its subfolders to the Matlab path

me = mfilename;                                                             %what is my filename
pathstr = fileparts(which(me));                                             %get my location
addpath(genpath([pathstr filesep 'functions']));                                     

%% Call the start function of the general modelling framework

BdCPfitResults = fitModelStart(input_data,options_struct);

end %[EoF]
