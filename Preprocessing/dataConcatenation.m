% Author: Woojae Jeong

%% EEG data concatenation

fpath = [path, folderNames{n},'/'];
fpath2 = [path2, folderNames{n},'/'];

% EEG file
fileName = dir([fpath,'*.vhdr']);
fileName2 = dir([fpath2,'*.vhdr']);

% Load data
dat = pop_loadbv(fpath, fileName.name, [], [1:64]);
dat2 = pop_loadbv(fpath2, fileName2.name, [], [1:64]);

% Mering data
outEEG = pop_mergeset(dat, dat2);

sDirectory = ['/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Data/Processed data/',folderNames{n}];

% Save data
pop_saveset(outEEG, 'filename',[folderNames{n},'_EEG.set'],'filepath',...
    sDirectory,'version','7.3');