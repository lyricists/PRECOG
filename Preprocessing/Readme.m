%% Preprocessing pipeline

% Prerequisite softwares
% 1. BrainStorm
% 2. EEGLab
% 3. EEGLab plugins
%       Adjust
%       Cleanline
%       PrepPipeline
%       clean_rawdata
%
% Running preprocessing
% 1. Run runPreprocDarpa.m
% 2. Remove ICs from Brainstorm (manual inspection)
% 3. Run preprocPostICA.mt
% 4. (optional) Run preprocFilterData.m for additional low-pass filtering
% * Set path accordingly before running each codes