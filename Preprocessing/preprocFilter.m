% Author: Woojae Jeong

%% Automated BrainStorm preprocessing pipeline

% EEG file
fileName = dir([sDirectory,'/*.set']);

% File name
name = fileName.name;

% Subject name (for BrainStorm)
SubjectNames = {erase(name,'_EEG.set')};

% EEG data in *.eeg format
RawFiles = {[sDirectory,'/',name]};

% Protocol name (for BrainStorm)
protocolName = 'DARPA-Neat';

% Check if the protocol exists
protocolID = bst_get('Protocol', protocolName);

if isempty(protocolID)
    gui_brainstorm('CreateProtocol', protocolName, 0, 0); % If no, creat a new protocol
else
    gui_brainstorm('SetCurrentProtocol', protocolID); % If yes, save on a current protocol
end

%% BrainStorm directory
bst_db_dir = '/ImagePTE2/woojaeje/brainstorm_db';    % BrainStorm db directory

%%
sFiles = [];

% Start a new report
bst_report('Start', sFiles);

% Process: Create link to raw file
sFiles = bst_process('CallProcess', 'process_import_data_raw', sFiles, [], ...
    'subjectname',    SubjectNames{1}, ...
    'datafile',       {RawFiles{1}, 'EEG-EEGLAB'}, ...
    'channelreplace', 1, ...
    'channelalign',   1, ...
    'evtmode',        'value');

% Resampling to 1000 Hz
if strcmp(SubjectNames,'sub001') || strcmp(SubjectNames, 'sub004')
    % Process: Resample: 1000Hz
    sFiles = bst_process('CallProcess', 'process_resample', sFiles, [], ...
        'freq',     1000, ...
        'read_all', 0);
end

% Process: Notch filter: 60Hz
sFiles = bst_process('CallProcess', 'process_notch', sFiles, [], ...
    'sensortypes', 'EEG', ...
    'freqlist',    [60], ...  % Define frequency of the line noise
    'cutoffW',     1, ...
    'useold',      0, ...
    'overwrite',   1);

% Process: Band-pass filter
sFiles = bst_process('CallProcess', 'process_bandpass', sFiles, [], ...
    'sensortypes', 'EEG', ...
    'highpass',    0.5, ...   % High-pass frequency
    'lowpass',     80, ...  % Low-pass frequency
    'tranband',    0, ...
    'attenuation', 'strict', ...  % 60dB
    'ver',         '2019', ...  % 2019
    'mirror',      0, ...
    'overwrite',   1);

% Process: Export to file: Raw
bst_process('CallProcess', 'process_export_file', sFiles, [], ...
    'exportraw', {[erase(RawFiles{1},'.set'),'.eeg'], 'EEG-BRAINAMP'});