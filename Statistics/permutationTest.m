%% Load dataset

path = '/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/svmDecoding_sentiment_sen_3pc_lepoch_congruency_linear_commonPCA.mat';
load(fullfile(path))

% Subject Index
% load(fullfile('/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Data/Behavior/subject_index.mat'));

%% Cluster-based permutation test

[Sig, ~] = CBP_AB_single(Decode, 'SVM lepoch'); 

Sig = sort(Sig);

sigTime = [];

sigTime(1,1) = Sig(1);

tmp = 0;

for i = 1:size(Sig,2)-1
    if Sig(i+1) - Sig(i) > 4
        tmp = tmp+1;
        sigTime(tmp,2) = Sig(i);
        sigTime(tmp+1,1) = Sig(i+1);
    end
end

sigTime(tmp+1,2) = Sig(end);

%
time = -199:4:1500;
% time = -999:4:0;

for i = 1:size(sigTime,1)
    for j = 1:size(sigTime,2)

        sigTime(i,j) = find(time == sigTime(i,j));
    end
end

sigTime = (sigTime-1);

% Save

path = '/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/Significance/sigSenDecode_group.mat';
save(path, 'sigTime', '-v7.3');
clc;

%% CTG cluster-based permutation test

path = "/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/CTG_data.mat";
load(fullfile(path))

% Subject index
% load(fullfile('/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Data/Behavior/subject_index.mat'));

% Sentence
[Sig_sen, ~] = CBP_CTG(permute(CTG_sen, [2,3,1]), 'Binary');

% Group
% [Sig_sen_con, ~] = CBP_CTG(permute(CTG_sen(subject_index == 1,:,:), [2,3,1]), 'Binary');
% [Sig_sen_dep, ~] = CBP_CTG(permute(CTG_sen(subject_index == 2,:,:), [2,3,1]), 'Binary');
% [Sig_sen_sui, ~] = CBP_CTG(permute(CTG_sen(subject_index == 3,:,:), [2,3,1]), 'Binary');

% Save
save("/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/Significance/sigCTG_re.mat",...
    'Sig_sen','Sig_sen_con','Sig_sen_dep','Sig_sen_sui', '-v7.3');
