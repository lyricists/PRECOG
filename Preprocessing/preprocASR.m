% Author: Woojae Jeong

%% ASR routine

% EEG file
fileName = dir([sDirectory,'/*.vhdr']);

% Load data
dat = pop_loadbv(sDirectory, fileName.name, [], [1:64]);

% Clean_rawdata: automated artifact detection
EEG = pop_clean_rawdata(dat, 'FlatlineCriterion',4,'ChannelCriterion',0.8,'LineNoiseCriterion','off','Highpass','off',...
    'BurstCriterion',50,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );

% Save bad channels
chan = [];

if EEG.nbchan ~= 64
    id = find(EEG.etc.clean_channel_mask == 0);

    for i = 1:size(id,1)
        chan{i} = outEEG.chanlocs(id(i)).labels;
    end

else
    chan{1} = {''};
end

%% Save bad time segements
tmpbad = find(EEG.etc.clean_sample_mask == 0);
cldata = (length(EEG.etc.clean_sample_mask)-length(tmpbad))/length(EEG.etc.clean_sample_mask)*100;

id = find(diff(tmpbad) > 1);
tmp = tmpbad(1); tmp2 = [];

for i = 1:length(id)
    tmp = [tmp tmpbad(id(i)+1)];
    tmp2 = [tmp2 tmpbad(id(i))];
end

badseg = [tmp; [tmp2 tmpbad(end)]];

events.label = 'bad_time-segments';
events.color = [0 1 1];
events.epochs = ones(1,size(badseg,2));
events.times = badseg.*0.001;
events.reactTimes = [];
events.select = 1;
events.channels = [];
events.notes = [];

%% save files
spath = ['/ImagePTE2/woojaeje/DARPA/Data/Processed data/',folderNames{n},'/'];

save([spath,'badChan_',folderNames{n},'.mat'],'chan');
save([spath,'events_',folderNames{n},'_badseg.mat'],'events','cldata');