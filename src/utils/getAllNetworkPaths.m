% Returns a string array containing the path to all the networks stored in
% a folder.

function all_path = getAllNetworkPaths(folder_path, search_H0)
% --- INPUT ---
% folder_path: string
%   This string defines the path to a folder where we want to look for
%   saved ANNs.
% search_H0: bool
%   Optional. If this boolean equals true, then the function looks for ANNs
%   simulated under H0 instead.
%
% --- OUTPUT ---
% This function outputs a string array where each element is a path to a
% saved ANN.
%
% --- CALLED BY ---
% trainNetworkCohorts
% checkInformationLoss
% simulateNetworkCohortsH0
% fitNetworkToBehaviour
% computeNeuralRepresentation
% computeNeuralDistances
% computeLogLikelihoodDynamics


% Set the optional parameter
if nargin == 1
    search_H0 = false;
end

% Define the pattern of filename to match
filename_pattern = defineFilenamePattern();
% Update to a pattern matchin H0 ANNs
if search_H0
    filename_pattern = convertStringsToChars(filename_pattern);
    filename_pattern = filename_pattern(1:(end - 4));
    filename_pattern = convertCharsToStrings(filename_pattern);
    filename_pattern = filename_pattern + "_(\d){3}.mat";
    % Update the path
    folder_path = folder_path + "_H0";
end

% --- Look for matching files in the folder --- %

if isfolder(folder_path)
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
else
    all_path = [];
    warning("The path '%s' is not a folder.", folder_path);
end

end

