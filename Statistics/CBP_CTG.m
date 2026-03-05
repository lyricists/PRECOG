%% Cluster-based permutation test - Example
function [Sig, stat] = CBP_CTG(data, opt)
%%
numSub = size(data,3);
numT = size(data,2);
numF = size(data,1);

for i = 1:numSub
    Data(i,1,:,:) = data(:,:,i);
end

switch opt
    case 'Base'
        zero = zeros(numSub, 1, numF, numT);

    case 'Binary'
        zero = ones(numSub, 1, numF, numT) * 0.5;
end     
    
%% Parameters
allsubj_S.label     = cell(1,1);
allsubj_S.label{1}  = 'MLC11';
allsubj_S.powspctrm = Data;
allsubj_S.time      = 1:numT;
allsubj_S.freq      = 1:numF;
allsubj_S.dimord    = 'subj_chan_freq_time';

allsubj_Z.label     = cell(1,1);
allsubj_Z.label{1}  = 'MLC11';
allsubj_Z.powspctrm = zero;
allsubj_Z.time      = 1:numT;
allsubj_Z.freq      = 1:numF;
allsubj_Z.dimord    = 'subj_chan_freq_time';

cfg                  = [];
cfg.channel          = 1;
cfg.latency          = 'all';
cfg.frequency        = 'all';
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.clusterthreshold = 'nonparametric_individual';
cfg.neighbours       = [];
cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.correcttail      = 'alpha';
cfg.tail             = 0;
cfg.numrandomization = 5000;

% Design Datarix
subj = numSub;
design = zeros(2,2*subj);

for i = 1:subj
    design(1,i) = i;
end

for i = 1:subj
    design(1,subj+i) = i;
end

design(2,1:subj)        = 1;
design(2,subj+1:2*subj) = 2;

cfg.design = design;
cfg.uvar  = 1;
cfg.ivar  = 2;

[stat] = ft_freqstatistics(cfg, allsubj_S, allsubj_Z);

%% Visualization

switch cfg.tail
    case 0
        if isempty(stat.posclusters) && isempty(stat.negclusters)
            return
        end
        
        if ~isempty(stat.posclusters) && isempty(stat.negclusters)
            
            Prob_pos = []; mat1 = [];
            
            for i = 1:size(stat.posclusters,2)
                Prob_pos = [Prob_pos; stat.posclusters(i).prob];
            end
            
            Idx = find(Prob_pos < 0.05);
            Idx = max(Idx);
            mat = squeeze(stat.posclusterslabelmat);
            
            if isempty(Idx)
                mat = repmat(0,numF,numT);
            else
                
                for j = 1:numT
                    nIdx = find(mat(:,j) > Idx);
                    mat(nIdx,j) = 0;
                    
                    pIdx = find(mat(:,j) <= Idx & mat(:,j) > 0);
                    mat(pIdx,j) = 1;
                end
            end
            sigWind = mat;
            
        end
        %
        if isempty(stat.posclusters) && ~isempty(stat.negclusters)
            Prob_neg = []; mat1 = [];
            
            for i = 1:size(stat.negclusters,2)
                Prob_neg = [Prob_neg; stat.negclusters(i).prob];
            end
            
            Idx = find(Prob_neg < 0.05);
            Idx = max(Idx);
            mat = squeeze(stat.negclusterslabelmat);
            
            if isempty(Idx)
                mat = repmat(0,numF,numT);
            else
                for j = 1:numT
                    nIdx = find(mat(:,j) > Idx);
                    mat(nIdx,j) = 0;
                    
                    pIdx = find(mat(:,j) <= Idx & mat(:,j) > 0);
                    mat(pIdx,j) = 1;
                end
            end
            sigWind = mat;
        end
        
        if ~isempty(stat.posclusters) && ~isempty(stat.negclusters)
            Prob_pos = []; Prob_neg = []; mat1 = [];
            
            for i = 1:size(stat.posclusters,2)
                Prob_pos = [Prob_pos; stat.posclusters(i).prob];
            end
            
            Idx = find(Prob_pos < 0.05);
            Idx = max(Idx);
            mat1 = squeeze(stat.posclusterslabelmat);
            
            if isempty(Idx)
                mat1 = repmat(0,numF,numT);
            else
                for j = 1:numT
                    nIdx = find(mat1(:,j) > Idx);
                    mat1(nIdx,j) = 0;
                    
                    pIdx = find(mat1(:,j) <= Idx & mat1(:,j) > 0);
                    mat1(pIdx,j) = 1;
                end
            end
            
            for i = 1:size(stat.negclusters,2)
                Prob_neg = [Prob_neg; stat.negclusters(i).prob];
            end
            
            Idx = find(Prob_neg < 0.05);
            Idx = max(Idx);
            mat = squeeze(stat.negclusterslabelmat);
            
            if isempty(Idx)
                mat = repmat(0,numF,numT);
            else
                
                for j = 1:numT
                    nIdx = find(mat(:,j) > Idx);
                    mat(nIdx,j) = 0;
                    
                    pIdx = find(mat(:,j) <= Idx & mat(:,j) > 0);
                    mat(pIdx,j) = 1;
                end
            end
        end
        
    case 1
        
        if ~isempty(stat.posclusters) && isempty(stat.negclusters)
            
            Prob_pos = []; mat1 = [];
            
            for i = 1:size(stat.posclusters,2)
                Prob_pos = [Prob_pos; stat.posclusters(i).prob];
            end
            
            Idx = find(Prob_pos < 0.05);
            Idx = max(Idx);
            mat = squeeze(stat.posclusterslabelmat);
            
            if isempty(Idx)
                mat = repmat(0,numF,numT);
            else
                
                for j = 1:numT
                    nIdx = find(mat(:,j) > Idx);
                    mat(nIdx,j) = 0;
                    
                    pIdx = find(mat(:,j) <= Idx & mat(:,j) > 0);
                    mat(pIdx,j) = 1;
                end
            end
            sigWind = mat;
            
        end
                
    case -1
        
        if isempty(stat.posclusters) && ~isempty(stat.negclusters)
            Prob_neg = []; mat1 = [];
            
            for i = 1:size(stat.negclusters,2)
                Prob_neg = [Prob_neg; stat.negclusters(i).prob];
            end
            
            Idx = find(Prob_neg < 0.05);
            Idx = max(Idx);
            mat = squeeze(stat.negclusterslabelmat);
            
            if isempty(Idx)
                mat = repmat(0,numF,numT);
            else
                for j = 1:numT
                    nIdx = find(mat(:,j) > Idx);
                    mat(nIdx,j) = 0;
                    
                    pIdx = find(mat(:,j) <= Idx & mat(:,j) > 0);
                    mat(pIdx,j) = 1;
                end
            end
            sigWind = mat;
        end
end        
        
if ~isempty(mat1)
    for i = 1:numF
        for j = 1:numT
            if mat(i,j) ~= mat1(i,j)
                mat(i,j) = 1;
            end
        end
    end
end

Sig = mat;
