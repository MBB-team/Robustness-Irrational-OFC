function [subset_included_paths] = selectCohortSubset(options)
% Identifies models that are shared across cohorts and possibly deletes
% those that are not shared across cohorts.
%
%% INPUTS
%  ======
%
% Named:
% ------
% - n_networks_cohort [int] (100)
%       Target number of networks in each cohort. If the subset of networks
%       shared across is higher than this target number, only a subset is
%       selected.
% - delete_outside_subset [bool] (false)
%       Whether to delete the networks that are not shared across cohorts.
%
%% OUTPUTS
%  =======
%
% - subset_included_paths [vector string]
%       Vector containing the paths to all networks that are shared across
%       cohorts.
%
%% See also: getPath, getDesiredNetworkConfigs, getAllNetworkPaths, 
% defineFilenamePattern.

% --- CHECK INPUT ARGUMENTS --- %

arguments
    options.n_networks_cohort (1,1) {mustBeNumeric} = 100;
    options.delete_outside_subset (1,1) {mustBeNumericOrLogical} = false;
end


%% ----------------------------------- %
% --- Load training specifications --- %
% ------------------------------------ %

% Define the path to the file storing training characteristics
path_specs = fullfile(getPath("Models"), "_TrainingSpecs.mat");

% Get the number of ANN training trials per cohort
init_weights = load(path_specs, "init_weights").init_weights;
n_trials_cohort = size(init_weights, 2);

% Get the number of cohorts
all_Config = getDesiredNetworkConfigs();
n_config = length(all_Config);


%% -------------- %
% --- Process --- %
% --------------- %

% Initialize the storage of ANN presence within each cohort
is_trained = false(n_trials_cohort, n_config);

% Get the paths to all the trained ANNs
all_path = getAllNetworkPaths(getPath("Models"));
n_network = length(all_path);

% Define the pattern to identify each cohort
all_patterns = strings(1, n_config);
for i_config = 1:n_config
    all_patterns(i_config) = defineFilenamePattern(all_Config{i_config});
end

% ~ Loop through ANNs ~ %
for i_network = 1:n_network
    % Match the ANN path with all the patterns and store its seed
    seeds = regexp(all_path(i_network), all_patterns, "tokens");
    % Identify the cohort of the ANN
    i_cohort = find(~ cellfun(@isempty, seeds), 1);
    % Store that this ANN seed was successfully trained for this cohort
    is_trained(str2double(seeds{i_cohort}{1}), i_cohort) = true;
end

% Find seeds were the ANNs were all successfully trained across cohort
subset_seeds = find(all(is_trained, 2))';
n_subset = length(subset_seeds);
% Remove seeds if necessary
subset_seeds = subset_seeds(1:min(options.n_networks_cohort, n_subset));
n_subset = length(subset_seeds);

% Initialize the output vector containing the paths to all the ANNs with
% these seeds
subset_included_paths = strings(1, n_subset * n_config);

% Initialize the vector index
i_path = 1;
% ~ Loop through cohorts ~ %
for i_config = 1:n_config
    % ~ Loop through seeds ~ %
    for seed = subset_seeds
        % Store the path
        subset_included_paths(i_path) = fullfile(...
            getPath("Models"), defineFilenamePattern(...
            all_Config{i_config}, seed));
        % Update the path index
        i_path = i_path + 1;
    end
end


%% ----------------------------- %
% --- Delete unselected ANNs --- %
% ------------------------------ %

if options.delete_outside_subset
    % Define the subset of unselected ANNs
    i_nonincluded_paths = ~ ismember(all_path, subset_included_paths);
    subset_nonincluded_paths = all_path(i_nonincluded_paths);
    % ~ Loop through unselected ANNs ~ %
    for nonincluded_path = subset_nonincluded_paths
        % Delete the ANN
        delete(nonincluded_path);
    end
end

end
