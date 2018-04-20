%% FIT analysis
% Evan W. Carr, 02-04-2017 (Columbia Business School)

clear;
clc;

baseDir = 'C:\Users\Downloads';     % REPLACE WITH WORKING DIRECTORY
dataDir = [baseDir filesep() 'DATA\FIT_DATA_01172017'];
cd(dataDir);

%% Phase 1 data:
phase1_data = table();

for sbj = 1:29     % 29 different subjects as of 01-17-2017
    
    sbjDir = [dataDir filesep() 's' num2str(sbj)];
    sbjData = load([sbjDir filesep() 'FIT_phase1_s' num2str(sbj) '_17-Jan-2017.mat']);   % Creates a structure with branch dataset called "phase1_data"
    sbjTable = dataset2table(sbjData.phase1_data);
    
    sbjTable.sbj = zeros(height(sbjTable), 1) + sbj;
    
    if sbj == 1
        phase1_data = sbjTable;
    else
        phase1_data = [phase1_data; sbjTable];
    end    

end

%% Phase 2 data:
phase2_data = table();

for sbj = 1:29     % 29 different subjects as of 01-17-2017
    
    sbjDir = [dataDir filesep() 's' num2str(sbj)];
    sbjData = load([sbjDir filesep() 'FIT_phase2_s' num2str(sbj) '_17-Jan-2017.mat']);   % Creates a structure with branch dataset called "phase1_data"
    sbjTable = dataset2table(sbjData.phase2_data);
    
    sbjTable.sbj = zeros(height(sbjTable), 1) + sbj;
    
    if sbj == 1
        phase2_data = sbjTable;
    else
        phase2_data = [phase2_data; sbjTable];
    end    

end

%% Phase 3 data:
phase3_data = table();

for sbj = 1:29     % 29 different subjects as of 01-17-2017
    
    sbjDir = [dataDir filesep() 's' num2str(sbj)];
    sbjData = load([sbjDir filesep() 'FIT_phase3_s' num2str(sbj) '_17-Jan-2017.mat']);   % Creates a structure with branch dataset called "phase1_data"
    sbjTable = dataset2table(sbjData.phase3_data);
    
    sbjTable.sbj = zeros(height(sbjTable), 1) + sbj;
    
    if sbj == 1
        phase3_data = sbjTable;
    else
        phase3_data = [phase3_data; sbjTable];
    end    

end

%% Start analysis:

% Main DVs:
% - number of presses (go trials)
% - first press RTs (go trials)
% - no-go errors (no-go trials)

for i = 1:height(phase3_data)
    
    model_id_parts = strsplit(char(phase3_data.image(i)), '-N');
    phase3_data.model(i) = model_id_parts(1);
    
    if phase3_data.block(i) <= 2
        phase3_data.blocknew(i) = 1;
    else
        phase3_data.blocknew(i) = 2;
    end
    
end

phase3_data.sbj = categorical(phase3_data.sbj);
phase3_data.model = categorical(phase3_data.model);
phase3_data.block = categorical(phase3_data.block);
phase3_data.blocknew = categorical(phase3_data.blocknew);
phase3_data.stim = categorical(phase3_data.stim);

phase3_data_go = phase3_data(strcmpi(phase3_data.context, 'go'), :);
phase3_data_nogo = phase3_data(strcmpi(phase3_data.context, 'nogo'), :);

phase3_data_go.log10_first_press = log10(phase3_data_go.first_press * 1000);

varfun(@mean, phase3_data, 'InputVariables', 'correct', ...
    'GroupingVariables', {'sbj'})

varfun(@mean, phase3_data_go, 'InputVariables', 'num_presses', ...
    'GroupingVariables', {'block', 'stim'})
varfun(@mean, phase3_data_go, 'InputVariables', 'log10_first_press', ...
    'GroupingVariables', {'block', 'stim'})
varfun(@mean, phase3_data_nogo, 'InputVariables', 'correct', ...
    'GroupingVariables', {'block', 'stim'})

varfun(@mean, phase3_data_go, 'InputVariables', 'num_presses', ...
    'GroupingVariables', {'blocknew', 'stim'})
varfun(@mean, phase3_data_go, 'InputVariables', 'log10_first_press', ...
    'GroupingVariables', {'blocknew', 'stim'})
varfun(@mean, phase3_data_nogo, 'InputVariables', 'correct', ...
    'GroupingVariables', {'blocknew', 'stim'})

sem = @(x) std(x)/sqrt(29);

varfun(sem, phase3_data_go, 'InputVariables', 'num_presses', ...
    'GroupingVariables', {'blocknew', 'stim'})
varfun(sem, phase3_data_go, 'InputVariables', 'log10_first_press', ...
    'GroupingVariables', {'blocknew', 'stim'})
varfun(sem, phase3_data_nogo, 'InputVariables', 'correct', ...
    'GroupingVariables', {'blocknew', 'stim'})

% numPresses_mlm = fitlme(phase3_data_go, 'num_presses ~ block * stim + (1 + block * stim | sbj) + (1 + block * stim | model)', ...
%     'FitMethod', 'ML', 'DummyVarCoding', 'effects');
% firstPressRT_mlm = fitlme(phase3_data_go, 'first_press ~ block * stim + (1 + block * stim | sbj) + (1 + block * stim | model)', ...
%     'FitMethod', 'ML', 'DummyVarCoding', 'effects');
% nogoErrors_mlm = fitlme(phase3_data_nogo, 'correct ~ block * stim + (1 + block * stim | sbj) + (1 + block * stim | model)', ...
%     'FitMethod', 'ML', 'DummyVarCoding', 'effects');

% numPresses_mlm = fitlme(phase3_data_go, 'num_presses ~ block * stim + (1 + block * stim | sbj)', ...
%     'FitMethod', 'ML', 'DummyVarCoding', 'effects');
% log10firstPressRT_mlm = fitlme(phase3_data_go, 'log10_first_press ~ block * stim + (1 + block * stim | sbj)', ...
%     'FitMethod', 'ML', 'DummyVarCoding', 'effects');
% nogoErrors_mlm = fitlme(phase3_data_nogo, 'correct ~ block * stim + (1 + block * stim | sbj)', ...
%     'FitMethod', 'ML', 'DummyVarCoding', 'effects');

numPresses_mlm = fitlme(phase3_data_go, 'num_presses ~ blocknew * stim + (1 + blocknew * stim | sbj) + (1 + block * stim | model)', ...
    'FitMethod', 'ML', 'DummyVarCoding', 'effects');
log10firstPressRT_mlm = fitlme(phase3_data_go, 'log10_first_press ~ blocknew * stim + (1 + blocknew * stim | sbj) + (1 + block * stim | model)', ...
    'FitMethod', 'ML', 'DummyVarCoding', 'effects');
nogoErrors_mlm = fitlme(phase3_data_nogo, 'correct ~ blocknew * stim + (1 + blocknew * stim | sbj) + (1 + block * stim | model)', ...
    'FitMethod', 'ML', 'DummyVarCoding', 'effects');
