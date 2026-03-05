%% Cluster-based permutation test
function [Sig, p_stat] = CBP_AB_single(data, opt)

switch opt
    case 'Cue'
        time = 1:1:1500;

    case 'Pursuit'
        time = -99:500;
        
    case 'Saccade'
        time = -399:200;
    
    case 'VS'
        time = 1:size(data,2);
        
    case 'latency'
        time = -99:100;

    case 'Classic base'
        time = -199:1000;

    case 'SVM lepoch'
        time = -199:4:1500;

    case 'SVM base'
        time = -199:4:1000;

    case 'Classic'
        time = -199:1000;

    case 'Weight'
        time = -199:4:1500;

    case 'SVM 3 class'
        time = -50:24:1350;

    case 'ResEpoch'
        time = -999:4:0;
end

if strcmp(opt, 'Classic base')
    Zeros = repmat(mean(data(:,1:200),2),1,size(data,2));

elseif strcmp(opt, 'SVM base') || strcmp(opt, 'SVM lepoch') || strcmp(opt, 'ResEpoch')
    Zeros = repmat(repmat(0.5,size(data,1),1),1,size(data,2));

elseif strcmp(opt, 'SVM 3 class')
    Zeros = repmat(repmat(0.333,size(data,1),1),1,size(data,2));
    
else
    Zeros = zeros(size(data, 1), size(data, 2));
end

NoS  = size(data, 1); % Number of NoSect

%% Parameters
Cond1(:,1,:) = data; % Subject x Channel x Time
Cond2(:,1,:) = Zeros;

clear Cond1Mat
Cond1Mat.label      = cell(1,1);
Cond1Mat.label{1}   = 'MLC11'; % Any channel name
Cond1Mat.fsample    = 100;
Cond1Mat.individual = Cond1;
Cond1Mat.avg        = mean(Cond1,1);
Cond1Mat.time       = time;
Cond1Mat.dimord     = 'subj_chan_time';

clear Cond2Mat
Cond2Mat.label      = cell(1,1);
Cond2Mat.label{1}   = 'MLC11'; % Any channel name
Cond2Mat.fsample    = 100;
Cond2Mat.individual = Cond2;
Cond2Mat.avg        = mean(Cond2,1);
Cond2Mat.time       = time;
Cond2Mat.dimord     = 'subj_chan_time';

cfg                  = [];
cfg.channel          = 1;
cfg.latency          = 'all'; % Time of interest
cfg.parameter        = 'individual';
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

% Design matrix
design = zeros(2,2*NoS);
for i = 1:NoS
    design(1,i) = i;
end
for i = 1:NoS
    design(1,NoS+i) = i;
end
design(2,1:NoS)       = 1;
design(2,NoS+1:2*NoS) = 2;

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;

stat.posclusters = []; stat.negclusters = [];

[stat] = ft_timelockstatistics(cfg, Cond1Mat, Cond2Mat);

%% Visualization

switch cfg.tail
    case 0
        if isempty(stat.posclusters) && isempty(stat.negclusters)
            sigWind = []; stat = [];        
        
        elseif ~isempty(stat.posclusters) && isempty(stat.negclusters)
            
            sigMat_pos = [];
            for i = 1:size(stat.posclusters, 2)
                if stat.posclusters(i).prob < 0.05
                    sigMat_pos = [sigMat_pos i];
                end
            end
            
            sigWind = [];
            
            for j = 1:length(sigMat_pos)
                sigWind = [sigWind stat.time(find(stat.posclusterslabelmat==sigMat_pos(j)))];
            end
                       
        elseif  size(stat.negclusters,2) ~=0 && size(stat.posclusters,2) == 0
            sigMat_neg = [];
            for i = 1:size(stat.negclusters, 2)
                if stat.negclusters(i).prob < 0.05
                    sigMat_neg = [sigMat_neg i];
                end
            end
            
            sigWind = [];
            
            for j = 1:length(sigMat_neg)
                sigWind = [sigWind stat.time(find(stat.negclusterslabelmat==sigMat_neg(j)))];
            end
                
        elseif size(stat.posclusters,2) ~= 0 && size(stat.negclusters,2) ~=0
            sigMat_pos = [];
            for i = 1:size(stat.posclusters, 2)
                if stat.posclusters(i).prob < 0.05
                    sigMat_pos = [sigMat_pos i];
                end
            end
            
            sigMat_neg = [];
            for i = 1:size(stat.negclusters, 2)
                if stat.negclusters(i).prob < 0.05
                    sigMat_neg = [sigMat_neg i];
                end
            end
            
            sigWind = [];
            
            for j = 1:length(sigMat_pos)
                sigWind = [sigWind stat.time(find(stat.posclusterslabelmat==sigMat_pos(j)))];
            end
            
            for j = 1:length(sigMat_neg)
                sigWind = [sigWind stat.time(find(stat.negclusterslabelmat==sigMat_neg(j)))];
            end
        end
        
    case 1
        
        if ~isempty(stat.posclusters)
            sigMat_pos = [];
            for i = 1:size(stat.posclusters, 2)
                if stat.posclusters(i).prob < 0.05
                    sigMat_pos = [sigMat_pos i];
                end
            end
            
            sigWind = [];
            
            for j = 1:length(sigMat_pos)
                sigWind = [sigWind stat.time(find(stat.posclusterslabelmat==sigMat_pos(j)))];
            end
            
        end
        
    case -1
        if  size(stat.negclusters,2) ~=0 
            sigMat_neg = [];
            for i = 1:size(stat.negclusters, 2)
                if stat.negclusters(i).prob < 0.05
                    sigMat_neg = [sigMat_neg i];
                end
            end
            
            sigWind = [];
            
            for j = 1:length(sigMat_neg)
                sigWind = [sigWind stat.time(find(stat.negclusterslabelmat==sigMat_neg(j)))];
            end
        end
end
        
% 
Sig = sigWind;
p_stat = stat;
