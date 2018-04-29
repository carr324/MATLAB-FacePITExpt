% This script is for the FIT experiment, in which points are
% delivered upon free operant responding according to a random ratio
% schedule and a Pavlovian stimulus ([un]familiar face) is simultaneously presented:

% Evan W. Carr (Columbia Business School)
% Last updated: 12.12.2016 

% This script was adapted from code provided by Scott Freeman (https://www.scottmfreeman.com/).

%% START EXPERIMENT AND GATHER INFO:
clear;
close all;
clc;

% Screen('Preference','SkipSyncTests', 1)  % !!! ONLY FOR DEBUGGING!!!

rand('seed', sum(100 * clock));

% Setup paths based on which computer this is running on:
% base_dir = fileparts(mfilename('fullpath')); % get the directory for this file
% base_dir = fileparts(base_dir); % move up one more directory to the main info directory

% Get basic subject number and directory information
subject_id = input('\nEnter subject ID (only numbers; no letters): ');
subject_age = input('\nEnter subject''s age (in years): ');
subject_sex = input('\nEnter subject''s sex (m = male, f = female): ', 's');
subject_handedness = input('\nEnter subject''s handedness (r = right, l = left)? ', 's');

subject_id = sprintf('%d', subject_id);
sub_dir = [pwd filesep() 'data' filesep() 's' subject_id];

% Check if the subject directory exists. If not, create data folder:
if ~exist(sub_dir, 'dir')
    mkdir(sub_dir);
    addpath(sub_dir);
    fprintf('\nGenerating data directory and adding to path ...\n')
end

% Give warning if subject directory already exists and there's already
% stuff it:
if isdir(sub_dir) && length(dir(sub_dir)) > 2
    sub_dir_check = input(['\nWARNING: A directory with saved files for that subject number already exists. Are you \n' ...
        'sure you want to create another one? You might delete or overwrite data! \nType 1 for yes or 0 for no: ']);
    if ~sub_dir_check
        error('ERROR: Script execution stopped because of existing directory. Please restart with different parameters.')
    end
end

subject_info_filename = sprintf('FIT_sbjInfo_s%s_%s.mat', num2str(subject_id), date);
save([sub_dir, filesep(), subject_info_filename], 'subject_id', 'subject_age', 'subject_sex', 'subject_handedness');

fprintf('\nEXPERIMENT READY TO START. Hit any key to initiate the script ...');
KbStrokeWait;

%% SETUP PARAMETERS:
response_duration = 1.75;

KbName('UnifyKeyNames');

esc = KbName('ESCAPE');
space = KbName('SPACE');
respBlue = KbName('b');
respGreen = KbName('g');

abortKey = esc;

phase1_total_points = 0;
phase3_total_points = 0;

%% CREATE INSTRUMENTAL PHASE 1 DATASET:
phase1_data = dataset();
phase1_dataLength = 36;   % No blocks -- only 36 trials (18 go / 18 no-go)

phase1_data.trial(1:phase1_dataLength,1) = 1:phase1_dataLength;
phase1_data.context(1:phase1_dataLength,1) = Shuffle([repmat({'go'},phase1_dataLength/2,1); repmat({'nogo'},phase1_dataLength/2,1)]);

% Randomize within a block and constrain repeats (streak no more than 3 in a row):
while true
    
    mix = randperm_chop(phase1_data);
    [~, go] = find_longest_streak(strcmp('go', mix.context));
    [~, nogo] = find_longest_streak(strcmp('nogo', mix.context));
    
    if go < 3 && nogo < 3
        break
    end
    
end

mix.trial(1:phase1_dataLength,1) = 1:phase1_dataLength; 
phase1_data = mix;

gen_nums = Shuffle([7:12 7:12 7:12]');  % Set up for 18 go trials
phase1_data.num_needed(1:phase1_dataLength,1) = 999;

j = 1;
for i = 1:phase1_dataLength
    if strcmp(phase1_data.context(i,1),'go')
        phase1_data.num_needed(i,1) = gen_nums(j);
        j = j + 1;
    elseif strcmp(phase1_data.context(i,1),'nogo')
        phase1_data.num_needed(i,1) = 0;
    end
end

% Ready dataset for collecting responses:
phase1_data.response(1:phase1_dataLength,1) = {'NAN'};
phase1_data.first_press(1:phase1_dataLength,1) = 0;
phase1_data.num_presses(1:phase1_dataLength,1) = 0;
phase1_data.correct(1:phase1_dataLength,1) = -1;
phase1_data.iti = (3 - 1.75) .* rand(phase1_dataLength, 1) + 1.75;

%% CREATE EXPOSURE PHASE 2 DATASET:
% Pre-load images for dataset prep ...
% Stores in variables according to model gender: male_neutral_faces &
% female_neutral faces:
load('FIT_face_pics');     

male_neutral_faces = Shuffle(male_neutral_faces);
female_neutral_faces = Shuffle(female_neutral_faces);

male_neutral_faces(1:6, 2) = {'familiar'};
male_neutral_faces(7:12, 2) = {'novel'};
female_neutral_faces(1:6, 2) = {'familiar'};
female_neutral_faces(7:12, 2) = {'novel'};

training_faces = [male_neutral_faces(strcmp(male_neutral_faces(:, 2), 'familiar')); ...
    female_neutral_faces(strcmp(female_neutral_faces(:, 2), 'familiar'))];

novel_faces = [male_neutral_faces(strcmp(male_neutral_faces(:, 2), 'novel')); ...
    female_neutral_faces(strcmp(female_neutral_faces(:, 2), 'novel'))];

phase2_data = dataset();
num_exposures = 10;
phase2_blockLength = 12;
phase2_dataLength = num_exposures * phase2_blockLength;

phase2_data.trial(1:phase2_dataLength,1) = 1:phase2_dataLength;

% Make the blocks:
p = 1;
for i = 1:phase2_blockLength:phase2_dataLength
    phase2_data.block(i:i+(phase2_blockLength-1),1) = p;
    p = p + 1;
end

% Plug in the image names for training (limit one exposure per block for each image):
phase2_data.image_name(1:phase1_dataLength,1) = {''};
for block = 1:num_exposures
    phase2_data.image_name(phase2_data.block==block,:) = Shuffle(training_faces);
end

% Set up the rest of the columns for the training data:
phase2_data.response(1:phase2_dataLength, 1) = {'NAN'};
phase2_data.rt(1:phase2_dataLength, 1) = -1;
phase2_data.correct(1:phase2_dataLength, 1) = -1;
phase2_data.iti = (3 - 1.75) .* rand(phase2_dataLength, 1) + 1.75;

%% CREATE TRANSFER PHASE 3 DATASET:
phase3_data = dataset();
phase3_numBlocks = 4;
phase3_blockLength = 48;
phase3_dataLength = phase3_numBlocks * phase3_blockLength;

phase3_data.trial(1:phase3_dataLength,1) = 1:phase3_dataLength;

% Make the blocks:
p = 1;
for i = 1:phase3_blockLength:phase3_dataLength
    phase3_data.block(i:i+(phase3_blockLength-1),1) = p;
    p = p + 1;
end

% This makes it so that every block has 50% go/no-go context & familiar/novel stim:
for i = 1:phase3_blockLength:phase3_dataLength
    phase3_data.context(i:i+((phase3_blockLength*(1/2))-1),1) = {'go'};
    phase3_data.context(i+(phase3_blockLength*(1/2)):i+(phase3_blockLength-1),1) = {'nogo'};
    phase3_data.stim(i:2:i+(phase3_blockLength-1),1) = {'familiar'};
    phase3_data.stim(i+1:2:i+(phase3_blockLength),1) = {'novel'};
end

% Add image names to trial dataset:
phase3_data = sortrows(phase3_data, 'stim');
phase3_data.image = [Shuffle(repmat(training_faces, 8, 1)); Shuffle(repmat(novel_faces, 8, 1))];
phase3_data = sortrows(phase3_data, 'trial');

% Randomize within a block and constrain repeats:
for block = 1:phase3_numBlocks
    
    while true
        
        mix = randperm_chop(phase3_data(phase3_data.block==block,:));
        [~, go] = find_longest_streak(strcmp('go', mix.context));
        [~, nogo] = find_longest_streak(strcmp('nogo', mix.context));
        [~, familiar] = find_longest_streak(strcmp('familiar', mix.stim));
        [~, novel] = find_longest_streak(strcmp('novel', mix.stim));
                        
        if go < 5 && nogo < 5 && familiar < 5 && novel < 5
            break
        end
        
    end
    
    phase3_data(phase3_data.block == block, :) = mix;
    
end

phase3_data.trial(1:phase3_dataLength,1) = 1:phase3_dataLength;

gen_nums = [7:12, 7:12];
gen_nums_familiar = Shuffle(gen_nums);
gen_nums_novel = Shuffle(gen_nums);
gen_nums_familiar = gen_nums_familiar';
gen_nums_novel = gen_nums_novel';

phase3_data.num_needed(1:phase3_dataLength,1) = 999;

for block = 1:phase3_numBlocks
    
    tmp = phase3_data(phase3_data.block==block,:);
    j = 1;
    k = 1;

    for i = 1:phase3_blockLength
        if strcmp(tmp.context(i,1),'go') && strcmp(tmp.stim(i,1),'familiar')
            tmp.num_needed(i,1) = gen_nums_familiar(j);
            j = j + 1;
        elseif strcmp(tmp.context(i,1),'go') && strcmp(tmp.stim(i,1),'novel')
            tmp.num_needed(i,1) = gen_nums_novel(k);
            k = k + 1;
        elseif strcmp(tmp.context(i,1),'nogo')
            tmp.num_needed(i,1) = 0;
        end
    end
    
    phase3_data(phase3_data.block==block,:) = tmp;
    gen_nums_familiar = Shuffle(gen_nums);
    gen_nums_novel = Shuffle(gen_nums);
    
end

% Ready dataset for collecting responses:
phase3_data.response(1:phase3_dataLength,1) = {'NAN'};
phase3_data.first_press(1:phase3_dataLength,1) = 0;
phase3_data.num_presses(1:phase3_dataLength,1) = 0;
phase3_data.correct(1:phase3_dataLength,1) = -1;
phase3_data.iti = (3 - 1.75) .* rand(phase3_dataLength, 1) + 1.75;

%% PRESENT PHASE 1 INSTRUCTIONS (INSTRUMENTAL):

AssertOpenGL;

% Open on-screen window:
screen = max(Screen('Screens'));
[win, scr_rect] = Screen('OpenWindow', screen);
[winWidth, winHeight] = Screen('WindowSize', win);

% Colors:
black = BlackIndex(win); % should be equal to 0
white = WhiteIndex(win); % should be equal to 255
red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
gray = GrayIndex(win);
background = white;

% Locations:
xcenter = winWidth / 2;
ycenter = winHeight / 2;
rectangle = [xcenter - 10, ycenter - 10, xcenter + 10, ycenter + 10];
cue_location1 = [xcenter - 20, ycenter - 130, xcenter + 20, ycenter - 90];
cue_location2 = [xcenter - 200, ycenter - 200, xcenter + 200, ycenter + 200];
triangle = [xcenter - 10, ycenter + 10; xcenter + 10, ycenter + 10; xcenter, ycenter - 10];

% Set up dot probes:
training_dot_probes = [{'blue'}; {'green'}; {'none'}];  % Equal probabilities for blue, green, and none
phase2_data.dot_probe = Shuffle(repmat(training_dot_probes, phase2_dataLength/numel(training_dot_probes), 1));

for i = 1:phase2_dataLength
    if ~strcmp(phase2_data.dot_probe(i, 1), 'none')
        phase2_data.dot_pos_x(i, 1) = ((xcenter + 100) - (xcenter - 100)) .* rand() + (xcenter - 100);   % Keep dot probe within 100 pixels from horizontal midpoint
        phase2_data.dot_pos_y(i, 1) = ((ycenter + 100) - (ycenter - 100)) .* rand() + (ycenter - 100);   % Keep dot probe within 100 pixels from vertical midpoint
        phase2_data.dot_onset(i, 1) = (2.5 - 0.5) .* rand() + 0.5;  % Probe onset restricted to 500-2500 ms during trial
    else
        phase2_data.dot_pos_x(i, 1) = -1;
        phase2_data.dot_pos_y(i, 1) = -1;
        phase2_data.dot_onset(i, 1) = -1;
    end
end

% Clear screen to background color:
Screen('FillRect', win, background);

% Initialize display and sync to timestamp:
vbl = Screen('Flip', win);

theFont = 'Arial';
Screen('TextSize', win, 36);
Screen('TextFont', win, theFont);
Screen('TextColor', win, black);

fixation = '+';
fixation_size = 80;

HideCursor;

Screen('TextSize',win,20);

if rem(str2num(subject_id), 2) == 1
    DrawFormattedText(win,['You are now ready for Phase 1.\n\n\n\n' ...
        'On these trials, you will see either a black rectangle or triangle appear on a gray background.\n\n\n\n' ...
        'When the black RECTANGLE appears, if you press the spacebar enough\n\ntimes with your index finger, you will get extra points (money).\n\n\n\n' ...
        'When the black TRIANGLE appears, do NOT press any button.\n\n\n\n' ...
        'Keep in mind that your total points will get converted to extra real money\n\nat the end of the session (on top of your standard $12 study payment).\n\n\n\n' ...
        'Hit any key to begin.'], 'center', 'center', black);
elseif rem(str2num(subject_id), 2) == 0
    DrawFormattedText(win,['You are now ready for Phase 1.\n\n\n\n' ...
        'On these trials, you will see either a black rectangle or triangle appear on a gray background.\n\n\n\n' ...
        'When the black TRIANGLE appears, if you press the spacebar enough\n\ntimes with your index finger, you will get extra points (money).\n\n\n\n' ...
        'When the black RECTANGLE appears, do NOT press any button.\n\n\n\n' ...
        'Keep in mind that your total points will get converted to extra real money\n\nat the end of the session (on top of your standard $12 study payment).\n\n\n\n' ...
        'Hit any key to begin.'], 'center', 'center', black);
end

Screen('Flip',win);
WaitSecs(10);  % Make sure they read the instructions
KbStrokeWait;

%% START TRIAL LOOP:
for trial = 1:phase1_dataLength
    
    trial_ITI = phase1_data.iti(trial, 1);
    
    Screen('TextSize', win, fixation_size);
    DrawFormattedText(win, fixation, 'center', 'center', black);
    [~, trial_ITI_onset_time] = Screen('Flip', win);
    WaitSecs(trial_ITI);
    
    % Present rectangle/triangle trials according to assigned subject ID:
    
    if rem(str2num(subject_id), 2) == 1
        if strcmp(phase1_data.context(trial, 1), 'go')
            Screen('FillRect', win, gray, cue_location2);
            Screen('FillRect', win, black, rectangle);
        elseif strcmp(phase1_data.context(trial, 1), 'nogo')
            Screen('FillRect', win, gray, cue_location2);
            Screen('FillPoly', win, black, triangle);
        end
    elseif rem(str2num(subject_id), 2) == 0
        if strcmp(phase1_data.context(trial, 1), 'go')
            Screen('FillRect', win, gray, cue_location2);
            Screen('FillPoly', win, black, triangle);
        elseif strcmp(phase1_data.context(trial, 1), 'nogo')
            Screen('FillRect', win, gray, cue_location2);
            Screen('FillRect', win, black, rectangle);
        end
    end
        
    Screen('Flip',win);
    phase1_data.pictureonset(trial, 1) = GetSecs;
    
    % Start out with 0 presses ...
    num_presses = 0;
    
    KbQueueCreate();
    KbQueueStart();

    while GetSecs <= phase1_data.pictureonset(trial, 1) + response_duration
        
        [key_was_pressed, firstPress, ~, ~, ~] = KbQueueCheck();

        if key_was_pressed
            if strcmp(phase1_data.context(trial, 1),'nogo')
                phase1_data.first_press(trial,1) = GetSecs - phase1_data.pictureonset(trial,1);
                num_presses = 1;
                phase1_data.response(trial,1) = {'space'};
                Screen('TextSize',win,40);
                DrawFormattedText(win,'Do not press the button!','center','center',red);
                Screen('Flip', win);
                WaitSecs(2);
            elseif phase1_data.first_press(trial,1) == 0 && strcmp(phase1_data.context(trial,1),'go')
                phase1_data.first_press(trial,1) = GetSecs - phase1_data.pictureonset(trial,1);
                num_presses = key_was_pressed;
                phase1_data.response(trial,1) = {'space'};
            elseif phase1_data.first_press(trial,1) > 0 && strcmp(phase1_data.context(trial,1),'go')
                num_presses = num_presses + key_was_pressed;
            end
        end
        
        if min(find(firstPress)) == esc
            Screen('CloseAll');
        end
        
    end
        
    KbQueueRelease;
        
    phase1_data.num_presses(trial,1) = num_presses;
    Screen('TextSize',win,40);
    
    if phase1_data.num_presses(trial,1) >= phase1_data.num_needed(trial,1) && strcmp(phase1_data.context(trial,1),'go')
        points_earned = Sample(50:75);
        points_msg = sprintf('+%d', points_earned);
        DrawFormattedText(win,points_msg,'center','center',green);
        phase1_total_points = phase1_total_points + points_earned;
        phase1_data.reward(trial,1) = 1;
        phase1_data.reward_amount(trial,1) = points_earned;
        Screen('Flip',win);
        WaitSecs(2);
    elseif phase1_data.num_presses(trial,1) < phase1_data.num_needed(trial,1) && strcmp(phase1_data.context(trial,1),'go')
        points_earned = 0;
        DrawFormattedText(win,'You didn''t press enough\n\ntimes to get points ...','center','center',red);
        phase1_data.reward(trial,1) = 0;
        phase1_data.reward_amount(trial,1) = 0;
        Screen('Flip',win);
        WaitSecs(2);
    end
    
    if phase1_data.first_press(trial,1) == 0 && strcmp(phase1_data.context(trial,1),'go')
        phase1_data.correct(trial,1) = 0;
    elseif phase1_data.first_press(trial,1) == 0 && strcmp(phase1_data.context(trial,1),'nogo')
        phase1_data.correct(trial,1) = 1;
    elseif phase1_data.first_press(trial,1) > 0 && strcmp(phase1_data.context(trial,1),'go')
        phase1_data.correct(trial,1) = 1;
    elseif phase1_data.first_press(trial,1) > 0 && strcmp(phase1_data.context(trial,1),'nogo')
        phase1_data.correct(trial,1) = 0;
    end
    
    % Save the data:
    outfile1 = sprintf('FIT_phase1_s%s_%s.mat', num2str(subject_id), date);
    save([sub_dir, filesep(), outfile1], 'phase1_data');
    
    % Check for end of phase 1:
    if phase1_data.trial(trial,1) == phase1_data.trial(end,1)
        phase1_end_points_msg = sprintf('You earned a total of %d points in Phase 1!\n\n\n\nYou are now finished with Phase 1.\n\nHit any key to move on to Phase 2.', phase1_total_points);
        Screen('TextSize',win,20);
        DrawFormattedText(win, phase1_end_points_msg, 'center', 'center', black);
        Screen('Flip',win);
        WaitSecs(.2);
        KbStrokeWait;
    end
        
end

%% PRESENT PHASE 2 INSTRUCTIONS (EXPOSURE):

dot_probe_size = 20;
dot_probe_duration = 0.2;

Screen('TextSize',win,20);

DrawFormattedText(win, ...
    ['You are now ready for Phase 2.\n\n\n\n' ...
    'During this part of the task, you will see different images appear on the screen.\n\n' ...
    'On some of the trials, a blue or green dot will quickly appear somewhere on the image.\n\n\n\n' ...
    'If you see a BLUE dot appear, hit the "B" key when asked after the trial ends.\n\n' ...
    'If you see a GREEN dot appear, hit the "G" key when asked after the trial ends.\n\n' ...
    'If you don''t see a dot at all, hit the spacebar when asked after the trial ends.\n\n\n\n' ...
    'Note that there won''t be any points during this task, but you will only advance to\n\nPhase 3 when you have achieved a satisfactory level of performance on this part.\n\n\n\n' ...
    'Hit any key to begin.'], 'center', 'center', black);

Screen('Flip',win);
WaitSecs(10);  % Make sure they read the instructions
KbStrokeWait;

%% START TRIAL LOOP:
for trial = 1:phase2_dataLength
    
    trial_ITI = phase2_data.iti(trial, 1);
    
    Screen('TextSize', win, fixation_size);
    DrawFormattedText(win, fixation, 'center', 'center', black);
    Screen('Flip',win);
    WaitSecs(trial_ITI);
    
    % Load and present image:
    a = phase2_data.image_name(trial);
    b = cell2str(a);
    picturename = strtrim(strrep(b,'\n',''));
    picturetex = imread(picturename);

    mytex = Screen('MakeTexture', win, picturetex);
    Screen('FillRect', win, white);
    Screen('DrawTexture', win, mytex, [ ], [xcenter-400 ycenter-300 xcenter+400 ycenter+300]);
    Screen('Flip',win);
    
    phase2_data.pictureonset(trial, 1) = GetSecs;
    
    if phase2_data.dot_onset(trial, 1) > 0
        
        WaitSecs(phase2_data.dot_onset(trial, 1));
        
        if strcmp(phase2_data.dot_probe(trial, 1), 'blue')
            Screen('DrawTexture', win, mytex, [ ], [xcenter-400 ycenter-300 xcenter+400 ycenter+300])
            Screen('DrawDots', win, [phase2_data.dot_pos_x(trial, 1) phase2_data.dot_pos_y(trial, 1)], dot_probe_size, blue);
            Screen('Flip',win);
            WaitSecs(dot_probe_duration);
            Screen('DrawTexture', win, mytex, [ ], [xcenter-400 ycenter-300 xcenter+400 ycenter+300]);
            Screen('Flip',win);
            WaitSecs(3 - (phase2_data.dot_onset(trial, 1) + dot_probe_duration));
        elseif strcmp(phase2_data.dot_probe(trial, 1), 'green')
            Screen('DrawTexture', win, mytex, [ ], [xcenter-400 ycenter-300 xcenter+400 ycenter+300])
            Screen('DrawDots', win, [phase2_data.dot_pos_x(trial, 1) phase2_data.dot_pos_y(trial, 1)], dot_probe_size, green);
            Screen('Flip',win);
            WaitSecs(dot_probe_duration);
            Screen('DrawTexture', win, mytex, [ ], [xcenter-400 ycenter-300 xcenter+400 ycenter+300]);
            Screen('Flip',win);
            WaitSecs(3 - (phase2_data.dot_onset(trial, 1) + dot_probe_duration));
        end
        
    elseif phase2_data.dot_onset(trial, 1) == -1
        WaitSecs(3);
    
    end
    
    Screen('Close', mytex);
    
    % Ask for response on whether probe == blue, green, or none:
    Screen('FillRect', win, white);
    Screen('TextSize', win, 20);
    DrawFormattedText(win,['Did you see a dot on that trial?\n\n\n\n' ...
        'If you did and it was BLUE, hit the "B" key.\n\n' ...
        'If you did and it was GREEN, hit the "G" key.\n\n' ...
        'If you did NOT see any dot, hit the SPACEBAR.'], 'center', 'center', black);
    Screen('Flip', win);
    
    KbQueueCreate;
    KbQueueStart;
    KbQueueFlush;
    key_was_pressed = 0;
    
    while ~key_was_pressed
        [key_was_pressed, firstPress, ~, ~, ~] = KbQueueCheck();
    end
        
    if firstPress(esc)
        Screen('CloseAll');
    end
    
    if key_was_pressed
        
        phase2_data.response(trial,1) = {KbName(min(find(firstPress)))};
        phase2_data.rt(trial,1) = GetSecs - phase2_data.pictureonset(trial, 1);
        
        if strcmp(phase2_data.dot_probe(trial, 1),'none')
            if min(find(firstPress)) == space
                phase2_data.correct(trial,1) = 1;
                Screen('TextSize',win,40);
                DrawFormattedText(win,'Correct!','center','center', green);
                Screen('Flip', win);
                WaitSecs(2);
            elseif min(find(firstPress)) ~= space
                phase2_data.correct(trial,1) = 0;
                Screen('TextSize',win,40);
                DrawFormattedText(win,'Incorrect!','center','center', red);
                Screen('Flip', win);
                WaitSecs(2);
            end
        elseif strcmp(phase2_data.dot_probe(trial, 1),'green')
            if min(find(firstPress)) == respGreen
                phase2_data.correct(trial,1) = 1;
                Screen('TextSize',win,40);
                DrawFormattedText(win,'Correct!','center','center', green);
                Screen('Flip', win);
                WaitSecs(2);
            elseif min(find(firstPress)) ~= respGreen
                phase2_data.correct(trial,1) = 0;
                Screen('TextSize',win,40);
                DrawFormattedText(win,'Incorrect!','center','center', red);
                Screen('Flip', win);
                WaitSecs(2);
            end
        elseif strcmp(phase2_data.dot_probe(trial, 1),'blue')
            if min(find(firstPress)) == respBlue
                phase2_data.correct(trial,1) = 1;
                Screen('TextSize',win,40);
                DrawFormattedText(win,'Correct!','center','center', green);
                Screen('Flip', win);
                WaitSecs(2);
            elseif min(find(firstPress)) ~= respBlue
                phase2_data.correct(trial,1) = 0;
                Screen('TextSize',win,40);
                DrawFormattedText(win,'Incorrect!','center','center', red);
                Screen('Flip', win);
                WaitSecs(2);
            end
        end
        
    end
            
    % Save the data:
    outfile2 = sprintf('FIT_phase2_s%s_%s.mat', num2str(subject_id), date);
    save([sub_dir, filesep(), outfile2], 'phase2_data');
    
    % Check for end of phase 2:
    if phase2_data.trial(trial,1) == phase2_data.trial(end,1)
        Screen('TextSize',win,20);
        DrawFormattedText(win,'You are now finished with Phase 2.\n\n\n\nHit any key to move on to Phase 3.','center','center',black);
        Screen('Flip',win);
        WaitSecs(.2);
        KbStrokeWait;
    end         
    
end

%% PRESENT PHASE 3 INSTRUCTIONS (TRANSFER):
Screen('TextSize',win,20);

if rem(str2num(subject_id), 2) == 1
    DrawFormattedText(win, ...
        ['You are now ready for Phase 3.\n\n\n\n' ...
        'During this part of the task, you will once again be pressing\n\nthe spacebar based on whether you see a black rectangle or triangle.\n\n\n\n' ...
        'When the black RECTANGLE appears, if you press the spacebar enough\n\ntimes with your index finger, you will get extra points (money).\n\n\n\n' ...
        'When the black TRIANGLE appears, do NOT press any button.\n\n\n\n' ...
        'Keep in mind that your total points will get converted to extra real money\n\nat the end of the session (on top of your standard $12 study payment).\n\n\n\n' ...
        'Hit any key to begin.'], 'center', 'center', black);
elseif rem(str2num(subject_id), 2) == 0
    DrawFormattedText(win, ...
        ['You are now ready for Phase 3.\n\n\n\n' ...
        'During this part of the task, you will once again be pressing\n\nthe spacebar based on whether you see a black rectangle or triangle.\n\n\n\n' ...
        'When the black TRIANGLE appears, if you press the spacebar enough\n\ntimes with your index finger, you will get extra points (money).\n\n\n\n' ...
        'When the black RECTANGLE appears, do NOT press any button.\n\n\n\n' ...
        'Keep in mind that your total points will get converted to extra real money\n\nat the end of the session (on top of your standard $12 study payment).\n\n\n\n' ...
        'Hit any key to begin.'], 'center', 'center', black);
end

Screen('Flip',win);
WaitSecs(10);  % Make sure they read the instructions
KbStrokeWait;

%% START TRIAL LOOP:
for trial = 1:phase3_dataLength 
    
    % Check for 1st trial, and if so, adapt number of presses to
    % performance in Phase 1:
    if phase3_data.trial(trial,1) == 1 
        
        mean_Lblock = round(mean(phase1_data.num_presses(strcmp(phase1_data.context,'go'))));
    
        if mean_Lblock < 6
            gen_nums = 2:7;
        elseif mean_Lblock == 7
            gen_nums = 4:9;
        elseif mean_Lblock == 8
            gen_nums = 5:10;
        elseif mean_Lblock == 9
            gen_nums = 6:11;
        elseif mean_Lblock == 10
            gen_nums = 7:12;
        elseif mean_Lblock == 11
            gen_nums = 8:13;
        elseif mean_Lblock == 12
            gen_nums = 9:14;
        elseif mean_Lblock == 13
            gen_nums = 10:15;
        elseif mean_Lblock == 14
            gen_nums = 11:16;
        elseif mean_Lblock > 15
            gen_nums = 12:17;
        end
            
        gen_nums = [gen_nums gen_nums];
        gen_nums_familiar = Shuffle(gen_nums);
        gen_nums_novel = Shuffle(gen_nums);
        gen_nums_familiar = gen_nums_familiar';
        gen_nums_novel = gen_nums_novel';
        
        j = 1;
        k = 1;
        
        for block = 1:phase3_numBlocks
            
            tmp = phase3_data(phase3_data.block==block,:);
            j = 1;
            k = 1;
            
            for i = 1:phase3_blockLength
                if strcmp(tmp.context(i,1),'go') && strcmp(tmp.stim(i,1),'familiar')
                    tmp.num_needed(i,1) = gen_nums_familiar(j);
                    j = j + 1;
                elseif strcmp(tmp.context(i,1),'go') && strcmp(tmp.stim(i,1),'novel')
                    tmp.num_needed(i,1) = gen_nums_novel(k);
                    k = k + 1;
                elseif strcmp(tmp.context(i,1),'nogo')
                    tmp.num_needed(i,1) = 0;
                end
            end
            
            phase3_data(phase3_data.block==block,:) = tmp;
            gen_nums_familiar = Shuffle(gen_nums);
            gen_nums_novel = Shuffle(gen_nums);
            
        end
        
    end
    
%     Start trial ...
    trial_ITI = phase3_data.iti(trial, 1);
            
    Screen('TextSize', win, fixation_size);
    DrawFormattedText(win, fixation, 'center', 'center', black);
    Screen('Flip',win);
    WaitSecs(trial_ITI);
    
    % Load and present image:
    a = phase3_data.image(trial);
    b = cell2str(a);
    picturename = strtrim(strrep(b,'\n',''));
    picturetex = imread(picturename);

    mytex = Screen('MakeTexture', win, picturetex);
    Screen('FillRect', win, white);
    Screen('DrawTexture', win, mytex, [ ], [xcenter-400 ycenter-300 xcenter+400 ycenter+300]);
    
    if rem(str2num(subject_id),2) == 1
        if strcmp(phase3_data.context(trial,1), 'go')
            Screen('FillRect', win, black, rectangle);
        elseif strcmp(phase3_data.context(trial,1), 'nogo')
            Screen('FillPoly', win, black, triangle);
        end
    elseif rem(str2num(subject_id),2) == 0
        if strcmp(phase3_data.context(trial,1), 'go')
            Screen('FillPoly', win, black, triangle);
        elseif strcmp(phase3_data.context(trial,1), 'nogo')
            Screen('FillRect', win, black, rectangle);
        end
    end
        
    Screen('Flip',win);
    phase3_data.pictureonset(trial, 1) = GetSecs;
    
%   Start out with 0 presses ...
    num_presses = 0;
    
    KbQueueCreate();
    KbQueueStart();

    while GetSecs <= phase3_data.pictureonset(trial, 1) + response_duration
        
        [key_was_pressed, firstPress, ~, ~, ~] = KbQueueCheck();

        if key_was_pressed
            if strcmp(phase3_data.context(trial, 1),'nogo')
                phase3_data.first_press(trial,1) = GetSecs - phase3_data.pictureonset(trial,1);
                num_presses = 1;
                phase3_data.response(trial,1) = {'space'};
                Screen('TextSize',win,40);
                DrawFormattedText(win,'Do not press the button!','center','center',red);
                Screen('Flip', win);
                WaitSecs(2);
            elseif phase3_data.first_press(trial,1) == 0 && strcmp(phase3_data.context(trial,1),'go')
                phase3_data.first_press(trial,1) = GetSecs - phase3_data.pictureonset(trial,1);
                num_presses = key_was_pressed;
                phase3_data.response(trial,1) = {'space'};
            elseif phase3_data.first_press(trial,1) > 0 && strcmp(phase3_data.context(trial,1),'go')
                num_presses = num_presses + key_was_pressed;
            end
        end
        
        if min(find(firstPress)) == esc
            Screen('CloseAll');
        end
        
    end
        
    KbQueueRelease;
    
    phase3_data.num_presses(trial,1) = num_presses;
    Screen('TextSize',win,40);
    
    if phase3_data.num_presses(trial,1) >= phase3_data.num_needed(trial,1) && strcmp(phase3_data.context(trial,1),'go')
        
        points_earned = Sample(50:75);
        points_msg = sprintf('+%d', points_earned);
        DrawFormattedText(win,points_msg,'center','center',green);
        phase3_total_points = phase3_total_points + points_earned;
        phase3_data.reward(trial,1) = 1;
        phase3_data.reward_amount(trial,1) = points_earned;
        Screen('Flip',win);
        WaitSecs(2);
    
    elseif phase3_data.num_presses(trial,1) < phase3_data.num_needed(trial,1) && strcmp(phase3_data.context(trial,1),'go')
        
        points_earned = 0;
        DrawFormattedText(win,'You didn''t press enough\n\ntimes to get points ...','center','center',red);
        phase3_data.reward(trial,1) = 0;
        phase3_data.reward_amount(trial,1) = 0;
        Screen('Flip',win);
        WaitSecs(2);
    
    end
    
    if phase3_data.first_press(trial,1) == 0 && strcmp(phase3_data.context(trial,1),'go')
        phase3_data.correct(trial,1) = 0;
    elseif phase3_data.first_press(trial,1) == 0 && strcmp(phase3_data.context(trial,1),'nogo')
        phase3_data.correct(trial,1) = 1;
    elseif phase3_data.first_press(trial,1) > 0 && strcmp(phase3_data.context(trial,1),'go')
        phase3_data.correct(trial,1) = 1;
    elseif phase3_data.first_press(trial,1) > 0 && strcmp(phase3_data.context(trial,1),'nogo')
        phase3_data.correct(trial,1) = 0;
    end
    
    % Save the data:
    outfile3 = sprintf('FIT_phase3_s%s_%s.mat', num2str(subject_id), date);
    save([sub_dir, filesep(), outfile3], 'phase3_data');
        
    % Check for end of block:
    curBlock = phase3_data.block(trial,1);
    
    if phase3_data.trial(trial,1) > 1 && phase3_data.trial(trial,1) < phase3_data.trial(end,1) && phase3_data.block(trial,1) ~= phase3_data.block(trial+1,1)
        
        if curBlock == 1
            mean_Lblock = round(mean(phase3_data.num_presses(strcmp(phase3_data.context,'go') & phase3_data.block < 2)));
        elseif curBlock == 2
            mean_Lblock = round(mean(phase3_data.num_presses(strcmp(phase3_data.context,'go') & phase3_data.block < 3)));
        elseif curBlock == 3
            mean_Lblock = round(mean(phase3_data.num_presses(strcmp(phase3_data.context,'go') & phase3_data.block < 4)));
        elseif curBlock == 4
            mean_Lblock = round(mean(phase3_data.num_presses(strcmp(phase3_data.context,'go'))));
        end
            
        if mean_Lblock < 6
            gen_nums = 2:7;
        elseif mean_Lblock == 7
            gen_nums = 4:9;
        elseif mean_Lblock == 8
            gen_nums = 5:10;
        elseif mean_Lblock == 9
            gen_nums = 6:11;
        elseif mean_Lblock == 10
            gen_nums = 7:12;
        elseif mean_Lblock == 11
            gen_nums = 8:13;
        elseif mean_Lblock == 12
            gen_nums = 9:14;
        elseif mean_Lblock == 13
            gen_nums = 10:15;
        elseif mean_Lblock == 14
            gen_nums = 11:16;
        elseif mean_Lblock > 15
            gen_nums = 12:17;
        end
            
        gen_nums = [gen_nums gen_nums];
        gen_nums_familiar = Shuffle(gen_nums);
        gen_nums_novel = Shuffle(gen_nums);
        gen_nums_familiar = gen_nums_familiar';
        gen_nums_novel = gen_nums_novel';
        
        j = 1;
        k = 1;
        
        for block = (curBlock+1):phase3_numBlocks
            
            tmp = phase3_data(phase3_data.block==block,:);
            j = 1;
            k = 1;
            
            for i = 1:phase3_blockLength
                if strcmp(tmp.context(i,1),'go') && strcmp(tmp.stim(i,1),'familiar')
                    tmp.num_needed(i,1) = gen_nums_familiar(j);
                    j = j + 1;
                elseif strcmp(tmp.context(i,1),'go') && strcmp(tmp.stim(i,1),'novel')
                    tmp.num_needed(i,1) = gen_nums_novel(k);
                    k = k + 1;
                elseif strcmp(tmp.context(i,1),'nogo')
                    tmp.num_needed(i,1) = 0;
                end
            end
            
            phase3_data(phase3_data.block==block,:) = tmp;
            gen_nums_familiar = Shuffle(gen_nums);
            gen_nums_novel = Shuffle(gen_nums);
            
        end
            
        for i = fliplr(0:40)
            Screen('TextSize',win,20);
            phase3_points_msg = sprintf('You have earned a total of %d points so far in Phase 3.\n\n\n\nYou are finished with the block. Please take a short break.\n\n\n\nSeconds remaining before next block: %d', phase3_total_points, i);
            DrawFormattedText(win,phase3_points_msg,'center','center',black);
            Screen('Flip',win);
            WaitSecs(1);
        end
        
    end
       
    % Check for end of experiment:
    if phase3_data.trial(trial,1) == phase3_data.trial(end,1)
        total_points = phase1_total_points + phase3_total_points;
        total_money = 5 * (total_points / (18*75 + 96*75));
        total_money = sprintf('%.1f0', total_money);
        total_points_msg = sprintf('You''re all done with the experiment!\n\n\n\nYou earned a total of %d points. This converts to $%s in bonus money that you will be paid for your participation today.\n\n\n\nPlease let the experimenter know that you''re done. Thank you!', total_points, total_money);
        Screen('TextSize',win,20);
        DrawFormattedText(win,total_points_msg,'center','center',black);
        Screen('Flip',win);
        WaitSecs(.2);
        KbStrokeWait;
        Screen('CloseAll');
    end
    
end

ShowCursor;

