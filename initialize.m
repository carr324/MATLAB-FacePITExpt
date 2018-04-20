clear
info = struct();

%% setup paths based on which computer this is running on
%% setup path
exp_dir = nz(fileparts(mfilename('fullpath')),pwd);
addpath(exp_dir);
addpath([exp_dir filesep() '/data']);
% base_dir = fileparts(mfilename('fullpath')); % get the directory for this file, probably in a /bin directory
% base_dir = fileparts(base_dir); % move up one more directory to the main info directory  
base_dir = exp_dir;

ef = struct();
ef.base_dir = base_dir;
ef.folder_s = enum_file('data/s%d/', base_dir);
ef.behav = enum_file('data/s%d/info_s%d_behav_#DATE#_#TIME#.mat', base_dir);

info.files = ef;
clear base_dir;

%% subject information
next_subject_id = info.files.behav.next_id;
info.subject_id = input(sprintf('What subject number? (Next unused ID is %d - Press ENTER to use): ', next_subject_id));
if isempty(info.subject_id)
    info.subject_id = next_subject_id; 
end
info.irb = get_irb_info;
info.behav_file = info.files.behav(info.subject_id);
clear next_subject_id;
    
%% Parameters
info.parameters.tms = 0;

%% make sure file can be saved
fprintf('Making subject directory: %s\n', fileparts(info.behav_file));
mkdir(fileparts(info.behav_file));
save(info.behav_file, 'info');


