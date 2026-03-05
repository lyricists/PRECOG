% Author: Woojae Jeong

%% Preprocessing

eeglab; % Call EEGLab

% Start BrainStorm
if ~brainstorm('status')
    brainstorm nogui % Start BrainStorm without GUI
    %brainstorm    % Start BrainStorm with GUI
end

% EEG file directory path
path = '/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Data/Emotional Stroop/'; % Emotional Stroop
path2 = '/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Data/Sentence task/'; % Sentence task

items = dir(path);
folderNames = {items([items.isdir] & ~strcmp({items.name}, '.') & ~strcmp({items.name}, '..')).name};

%% Main script

for n = 1:size(folderNames,2)
    n
    % Concatenate the Emotional Stroop and the sentence task
    dataConcatenation;

    % Filter
    preprocFilter;

    % Bad segment detection using ASR
    preprocASR;

    % Run ICA
    preprocICA;

    nStop = folderNames{n};
    save('/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Code/stop.mat','nStop');
    clc;
end
