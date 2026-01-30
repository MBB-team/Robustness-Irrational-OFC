% Returns a string array containing the path to all the networks stored in
% a folder.

function all_path = getAllNetworkPaths(folder_path)
% Returns all the paths corresponding to RNN files within a folder.
%
% Long description? See also: defineFilenamePattern.
%
% INPUTS ------------------------------------------------------------------
% folder_path : <string 1x1>
%     Path to the folder where RNNs will be searched.
%
% OUTPUTS -----------------------------------------------------------------
% all_path : <string 1xN>
%     Paths to all existing RNN files within the folder.

% Check that the folder exists
if ~ isfolder(folder_path)
    error("The path '%s' is not a folder.", folder_path);
end

% Define the pattern of filename to match
filename_pattern = defineFilenamePattern();

% Count how many files must be scanned
info_files = dir(folder_path);
n_files = length(info_files) - 2;
all_path = strings(1, n_files);
% Loop through each file
for i_file = 1:n_files
    filename = info_files(i_file + 2).name;
    if ~ isempty(regexp(filename, filename_pattern, 'once'))
        all_path(i_file) = fullfile(folder_path, filename);
    end
end
% Remove remaining NaNs
if n_files > 0
    all_path = all_path(~ (all_path == ""));
end
