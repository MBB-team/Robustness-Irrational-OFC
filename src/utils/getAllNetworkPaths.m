function all_path = getAllNetworkPaths(folder_path)
% Returns all the paths corresponding to RNN files within a folder.
%
% This function scans a directory and returns the full paths to all files
% whose names match the RNN filename convention defined in
% defineFilenamePattern.
%
% INPUTS ------------------------------------------------------------------
% folder_path : <string 1x1>
%     Path to the directory in which RNN files are searched.
%
% OUTPUTS -----------------------------------------------------------------
% all_path : <string 1xN>
%     Full paths to all RNN files found in the directory.

arguments
    folder_path (1, 1) string
end

% Check that the folder exists
if ~ isfolder(folder_path)
    error("The path '%s' is not a folder.", folder_path);
end

% Define the filename pattern matching any RNN variant
filename_pattern = defineFilenamePattern();

% List all files in the directory
info_files = dir(folder_path);
n_files = length(info_files) - 2;
all_path = strings(1, n_files);

% ~ Loop through files ~ %
for i_file = 1:n_files
    filename = info_files(i_file + 2).name;
    % Keep only files matching the RNN naming convention
    if ~ isempty(regexp(filename, filename_pattern, 'once'))
        all_path(i_file) = fullfile(folder_path, filename);
    end
end

% Remove empty entries (non-matching files)
if n_files > 0
    all_path = all_path(~ (all_path == ""));
end
