%% Load dataset

% Decoding data
datPath = '/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/svmDecoding_sentiment_sen_3pc_lepoch_congruency_linear_commonPCA.mat';
wPath = '/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/senPCAweight.mat';

% Subject index
indexPath = '/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Data/Behavior/subject_index.mat';

load(fullfile(datPath))
load(fullfile(indexPath))
load(fullfile(wPath))

%% Onset latency, offset latency, Peak latency, and Peak amplitude calculation

rng('default')

t = -199:4:1500;
tPeak = [101:251];

conId = find(subject_index == 1);
depId = find(subject_index == 2);
suiId = find(subject_index == 3);

% Decoding
conLat = []; conPeak = []; conPeakLat = []; conOff = [];
depLat = []; depPeak = []; depPeakLat = []; depOff = [];
suiLat = []; suiPeak = []; suiPeakLat = []; suiOff = [];

for i = 1:1000
    fprintf(['Computing...(%d/1000)\n'], i);

    % Control
    rId = randi(length(conId),length(conId),1);
    conDecode = Decode(conId(rId),:);
    
    peak = mean(conDecode(:,tPeak),1);
    conPeakLat = [conPeakLat; t(tPeak(find(peak == max(peak),1)))];
    conPeak = [conPeak; max(peak)];

    [Sig, ~] = CBP_AB_single(conDecode, 'SVM lepoch');
    Sig = sigTimeGenerate(sort(Sig));
    sId = find(Sig(:,1) < conPeakLat(i) & Sig(:,2) > conPeakLat(i));
    conLat = [conLat; Sig(sId,1)];
    conOff = [conOff; Sig(sId,2)];
    
    % Depressed
    rId = randi(length(depId),length(depId),1);
    depDecode = Decode(depId(rId),:);
           
    peak = mean(depDecode(:,tPeak),1);
    depPeakLat = [depPeakLat; t(tPeak(find(peak == max(peak),1)))];
    depPeak = [depPeak; max(peak)];

    [Sig, ~] = CBP_AB_single(depDecode, 'SVM lepoch');
    Sig = sigTimeGenerate(sort(Sig));
    sId = find(Sig(:,1) < depPeakLat(i) & Sig(:,2) > depPeakLat(i));
    depLat = [depLat; Sig(sId,1)];
    depOff = [depOff; Sig(sId,2)];
    
    % Suicidal
    rId = randi(length(suiId),length(suiId),1);
    suiDecode = Decode(suiId(rId),:);
            
    peak = mean(suiDecode(:,tPeak),1);
    suiPeakLat = [suiPeakLat; t(tPeak(find(peak == max(peak),1)))];
    suiPeak = [suiPeak; max(peak)];

    [Sig, ~] = CBP_AB_single(suiDecode, 'SVM lepoch');
    Sig = sigTimeGenerate(sort(Sig));
    sId = find(Sig(:,1) < suiPeakLat(i) & Sig(:,2) > suiPeakLat(i));
    suiLat = [suiLat; Sig(sId,1)];
    suiOff = [suiOff; Sig(sId,2)];
    
    clc;
end

path = '/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/svmLatencyBoots_commonPCA.mat';

save(path, 'conLat','conPeak','conPeakLat',...
    'depLat','depPeak','depPeakLat',...
    'suiLat','suiPeak','suiPeakLat',...
    'conOff', 'depOff', 'suiOff', '-v7.3');

%% Correlation

rho_pc1_con = []; rho_pc2_con = [];
rho_pc1_dep = []; rho_pc2_dep = [];
rho_pc1_sui = []; rho_pc2_sui = [];

for i = 1:1000
     i
    rId = conId(randi(length(conId),length(conId),1));

    [r,~] = corr(mean(Decode(rId,:),1)', abs(mean(Weight(rId,:,1),1))', type = "Pearson");
    rho_pc1_con = [rho_pc1_con; r];

    [r,~] = corr(mean(Decode(rId,:),1)', abs(mean(Weight(rId,:,2),1))', type = "Pearson");
    rho_pc2_con = [rho_pc2_con; r];

    rId = depId(randi(length(depId),length(depId),1));

    [r,~] = corr(mean(Decode(rId,:),1)', abs(mean(Weight(rId,:,1),1))', type = "Pearson");
    rho_pc1_dep = [rho_pc1_dep; r];

    [r,~] = corr(mean(Decode(rId,:),1)', abs(mean(Weight(rId,:,2),1))', type = "Pearson");
    rho_pc2_dep = [rho_pc2_dep; r];

    rId = suiId(randi(length(suiId),length(suiId),1));

    [r,~] = corr(mean(Decode(rId,:),1)', abs(mean(Weight(rId,:,1),1))', type = "Pearson");
    rho_pc1_sui = [rho_pc1_sui; r];

    [r,~] = corr(mean(Decode(rId,:),1)', abs(mean(Weight(rId,:,2),1))', type = "Pearson");
    rho_pc2_sui = [rho_pc2_sui; r];
end


save("/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/group_corr.mat",...
    'rho_pc1_con','rho_pc1_dep','rho_pc1_sui',...
    'rho_pc2_con','rho_pc2_dep','rho_pc2_sui', '-v7.3');
