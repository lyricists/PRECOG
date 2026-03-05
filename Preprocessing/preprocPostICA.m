% Author: Woojae Jeong

%% Post preprocessing after artifact removal
% Start eeglab
eeglab;

% Start BrainStorm
if ~brainstorm('status')
    brainstorm nogui % Start BrainStorm without GUI
    %brainstorm    % Start BrainStorm with GUI
end

% Preprocessing pipeline Emotional
gui_brainstorm('EmptyTempFolder');  % Empty temporary folder

bst_db_dir = '/scratch1/woojaeje/ImagePTE2/woojaeje/brainstorm_db/DARPA-Neat/data/';    % BrainStorm db directory

path = '/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Data/Processed data/';

items = dir(path);
folderNames = {items([items.isdir] & ~strcmp({items.name}, '.') & ~strcmp({items.name}, '..')).name};

% folderNames([13,20,31,37,49,79,93,104,108,115,124,130]) = [];

for n = 1:size(folderNames,2)
    n
    fpath = [path, folderNames{n},'/'];
    fileName = dir([fpath, folderNames{n},'_preprocessed_sFiles_ICA.mat']);  % for ICA based

    load([fpath, fileName.name]);

    sFiles = sFiles.FileName;

    % Call protocol
    protocolID = bst_get('Protocol', protocolName);

    if isempty(protocolID)
        gui_brainstorm('CreateProtocol', protocolName, 0, 0); % If no, creat a new protocol
    else
        gui_brainstorm('SetCurrentProtocol', protocolID); % If yes, save on a current protocol
    end 

    % Rename bad time segment
    sFiles = bst_process('CallProcess', 'process_evt_rename', sFiles, [], ...
        'src',   'bad_time-segments', ...
        'dest',  'time-segments');

    % Process: Re-reference EEG
    sFiles = bst_process('CallProcess', 'process_eegref', sFiles, [], ...
        'eegref',      'AVERAGE', ...
        'sensortypes', 'EEG');
    
    % Process: Import MEG/EEG: Time
    sFiles = bst_process('CallProcess', 'process_import_data_time', sFiles, [], ...
        'subjectname',   SubjectNames{1}, ...
        'condition',     '', ...
        'timewindow',    [], ...
        'split',         0, ...
        'ignoreshort',   1, ...
        'usectfcomp',    1, ...
        'usessp',        1, ...
        'freq',          [], ...
        'baseline',      [], ...
        'blsensortypes', 'EEG');

    % Process: Remove linear trend: all time series
    sFiles = bst_process('CallProcess', 'process_detrend', sFiles, [], ...
        'timewindow',  [], ...
        'sensortypes', 'EEG', ...
        'overwrite',   1);

    %% Artifact dection post process
    RawFiles = {[fpath, 'preprocessed_EEG.eeg']};

    % Process: Export to file: Data
    sFiles = bst_process('CallProcess', 'process_export_file', sFiles, [], ...
        'exportdata', {RawFiles{1}, 'EEG-BRAINAMP'});

    fileName = dir([fpath,'/preprocessed_EEG.vhdr']);

    dat = pop_loadbv(fileName.folder, fileName.name, [], [1:64]);

    EEG = pop_clean_rawdata(dat, 'FlatlineCriterion',4,'ChannelCriterion',0.8,'LineNoiseCriterion','off','Highpass','off',...
        'BurstCriterion',50,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );

    %
    tmpbad = find(EEG.etc.clean_sample_mask == 0);
    cldata = (length(EEG.etc.clean_sample_mask)-length(tmpbad))/length(EEG.etc.clean_sample_mask)*100;

    id = find(diff(tmpbad) > 1);
    tmp = tmpbad(1); tmp2 = [];

    for i = 1:length(id)
        tmp = [tmp tmpbad(id(i)+1)];
        tmp2 = [tmp2 tmpbad(id(i))];
    end

    badseg = [tmp; [tmp2 tmpbad(end)]];

    events.label = 'post_processed_time-segments';
    events.color = [0 1 1];
    events.epochs = ones(1,size(badseg,2));
    events.times = badseg.*0.001;
    events.reactTimes = [];
    events.select = 1;
    events.channels = [];
    events.notes = [];

    % save files

    save([fpath,'events_',folderNames{n},'_badseg_postProcessed.mat'],'events','cldata');
    
    RawFiles = {[fpath,'/events_',SubjectNames{1},'_badseg_postProcessed.mat']};

    % Process: Import from file
    sFiles = bst_process('CallProcess', 'process_evt_import', sFiles, [], ...
        'evtfile', {RawFiles{1}, 'BST'}, ...
        'evtname', 'new', ...
        'delete',  0);

    %% Process: Import MEG/EEG: Events
    sFiles_rest = bst_process('CallProcess', 'process_import_data_event', sFiles, [], ...
        'subjectname',   SubjectNames{1}, ...
        'condition',     '', ...
        'eventname',     'S 10, S 12, S 14, S 16, S14, S16',...  % Marker name
        'timewindow',    [], ...
        'epochtime',     [0, 120], ...
        'split',         0, ...
        'createcond',    0, ...
        'ignoreshort',   0, ...
        'usectfcomp',    1, ...
        'usessp',        1, ...
        'freq',          [], ...
        'baseline',      [], ...
        'blsensortypes', 'EEG');

    % Process: Import MEG/EEG: Events
    sFiles_emo = bst_process('CallProcess', 'process_import_data_event', sFiles, [], ...
        'subjectname',   SubjectNames{1}, ...
        'condition',     '', ...
        'eventname',     'S 20, S 21, S 22, S 23',...  % Marker name
        'timewindow',    [], ...
        'epochtime',     [-0.199, 1], ...
        'split',         0, ...
        'createcond',    0, ...
        'ignoreshort',   0, ...
        'usectfcomp',    1, ...
        'usessp',        1, ...
        'freq',          [], ...
        'baseline',      [], ...
        'blsensortypes', 'EEG');

    % Process: Z-score transformation: [-199ms,-1ms]
    sFiles_emo = bst_process('CallProcess', 'process_baseline_norm', sFiles_emo, [], ...
        'baseline',    [-0.199, -0.001], ...
        'sensortypes', 'EEG', ...
        'method',      'zscore', ...  % Z-score transformation:    x_std = (x - &mu;) / &sigma;
        'overwrite',   1);

    % Process: Import MEG/EEG: Events
    sFiles_sent = bst_process('CallProcess', 'process_import_data_event', sFiles, [], ...
        'subjectname',   SubjectNames{1}, ...
        'condition',     '', ...
        'eventname',     'S76', ...  % Marker name
        'timewindow',    [], ...
        'epochtime',     [-0.199, 1], ...
        'split',         0, ...
        'createcond',    0, ...
        'ignoreshort',   0, ...
        'usectfcomp',    1, ...
        'usessp',        1, ...
        'freq',          [], ...
        'baseline',      [], ...
        'blsensortypes', 'EEG');

    % Process: Z-score transformation: [-199ms,-1ms]
    sFiles_sent = bst_process('CallProcess', 'process_baseline_norm', sFiles_sent, [], ...
        'baseline',    [-0.199, -0.001], ...
        'sensortypes', 'EEG', ...
        'method',      'zscore', ...  % Z-score transformation:    x_std = (x - &mu;) / &sigma;
        'overwrite',   1);

    %% Data save    
    epath = ['/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Data/Emotional Stroop/', folderNames{n},'/'];
    efile = dir([epath,'*EmotionalStroop.mat']);
    load(fullfile([epath, efile.name]));

    % Emotional Stroop
    Emo.data = []; Emo.label = []; Emo.index = [];
    
    for i = 1:size(sFiles_emo,2)

        file = [bst_db_dir, sFiles_emo(i).FileName];
        load(file);

        if i == 1
            fileChan = [bst_db_dir, sFiles_emo(i).ChannelFile];
            load(fileChan)
            Emo.Channel = Channel(1:64);
            Emo.Time = Time;
        else
        end

        id = 1;

        for j = 1:size(Events,2)
            if strcmp('post_processed_time-segments',Events(j).label)
                id = 0;
            end
        end
    
        Emo.index = [Emo.index, id];
        Emo.data = cat(3, Emo.data, F(1:64,:));
        Emo.label{i} = sFiles_emo(i).Comment;
    end

    % Log data

    Emo.log = cell(481,23);
    Emo.log(1,:) = config.logData(1,:);

    idx = strcmp(config.logData(:,7), 'Sad');
    id = find(idx == 1);

    Emo.log(2:121,:) = config.logData(id,:);

    idx = strcmp(config.logData(:,7), 'Happy ');
    id = find(idx == 1);

    Emo.log(122:241,:) = config.logData(id,:);

    idx = strcmp(config.logData(:,7), 'Neutral');
    id = find(idx == 1);

    Emo.log(242:361,:) = config.logData(id,:);

    idx = strcmp(config.logData(:,7), 'Suicide');
    id = find(idx == 1);

    Emo.log(362:481,:) = config.logData(id,:);

    % Resting state
    Rest.data = [];

    for i = 1:size(sFiles_rest,2)

        file = [bst_db_dir, sFiles_rest(i).FileName];
        load(file);

        if i == 1
            fileChan = [bst_db_dir, sFiles_emo(i).ChannelFile];
            load(fileChan)
            Rest.Channel = Channel(1:64);
            Rest.Time = Time;
        else
        end

        Rest.data = cat(3, Rest.data, F(1:64,:));
    end

    Rest.label{1} = 'Pre-eyes open'; Rest.label{2} = 'Pre-eyes closed';
    Rest.label{3} = 'Inter-eyes open'; Rest.label{4} = 'Inter-eyes closed';
    Rest.label{5} = 'Post-eyes open'; Rest.label{6} = 'Post-eyes closed';
        
    % Sentence task
    Sen.data = []; Sen.label = []; Sen.index = [];
    
    spath = ['/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Data/Sentence task/', folderNames{n},'/'];
    sfile = dir([spath,'*SentenceStroop.mat']);
    load(fullfile([spath, sfile.name]));

    for i = 1:size(sFiles_sent,2)

        file = [bst_db_dir, sFiles_sent(i).FileName];
        load(file);

        if i == 1
            fileChan = [bst_db_dir, sFiles_sent(i).ChannelFile];
            load(fileChan)
            Sen.channel = Channel(1:64);
            Sen.Time = Time;
        else
        end

        id = 1;

        for j = 1:size(Events,2)
            if strcmp('post_processed_time-segments',Events(j).label)
                id = 0;
            end
        end
    
        Sen.index = [Sen.index, id];
        Sen.data = cat(3, Sen.data, F(1:64,:));
        Sen.label{i} = sFiles_sent(i).Comment;
    end

    Sen.log = config.logData;

    % save datasets
    savefast([fpath,erase(name,'_EEG.set'),'_bst_preprocessed_sFiles_ICA_ver2.mat'],'sFiles','sFiles_rest','sFiles_emo','sFiles_sent');
    savefast([fpath,erase(name,'_EEG.set'),'_preprocessed_emo_ICA_ver2.mat'],'Emo');
    savefast([fpath,erase(name,'_EEG.set'),'_preprocessed_rest_ICA_ver2.mat'],'Rest');
    savefast([fpath,erase(name,'_EEG.set'),'_preprocessed_sen_ICA_ver2.mat'],'Sen');

    nStop = folderNames{n};
    save('/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Code/stop.mat','nStop');
    clc;
end

brainstorm stop