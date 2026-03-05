% Directory path
path = '/scratch1/woojaeje/ImagePTE2/woojaeje/DARPA/Data/Processed data/';

items = dir(path);
folderNames = {items([items.isdir] & ~strcmp({items.name}, '.') & ~strcmp({items.name}, '..')).name};

for n = 1:size(folderNames,2)
    n

    fpath = [path, folderNames{n},'/'];
    
    fileName = dir([fpath,'*emo_ICA_ver2.mat']);
    fileName2 = dir([fpath,'*sen_ICA_ver2.mat']);

    % Load preprocessed dataset
    load(fullfile([fpath, fileName.name]));
    load(fullfile([fpath, fileName2.name]));
    
    % Low-pass filtering using Fieldtrip function
    for i = 1:size(Emo.data,3)
        Emo.data(:,:,i) = ft_preproc_lowpassfilter(Emo.data(:,:,i), 1000, 20, 6, 'but','twopass');
    end

    for i = 1:size(Sen.data,3)
        Sen.data(:,:,i) = ft_preproc_lowpassfilter(Sen.data(:,:,i), 1000, 20, 6, 'but','twopass');
    end
    
    % Save data
    savefast([fpath, erase(fileName.name,'.mat'),'_filt_20_ver2.mat'], 'Emo')
    savefast([fpath, erase(fileName2.name,'.mat'),'_filt_20_ver2.mat'], 'Sen')    
end

