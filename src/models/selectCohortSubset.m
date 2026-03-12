 function [subset_included_paths] = selectCohortSubset(path_specs, path_networks, ...
    delete_unshared_seeds, i_select_configs, constraint_weight)
% Identifies RNN seeds shared across all cohorts and optionally deletes
% unshared ones.
%
% This function checks which randomly initialized RNN seeds are present in
% all cohorts (i.e., trained successfully across all Config variants). It
% returns the paths to the RNNs corresponding to these shared seeds.
% Optionally, RNNs that are not shared across all cohorts can be deleted
% automatically.
%
% INPUTS ------------------------------------------------------------------
% path_specs : <string 1x1>
%     Path to the file where training specifications are stored.
%
% path_networks : <string 1x1>
%     Path to the directory in which RNNs meeting the performance threshold
%     are saved.
%
% delete_unshared_seeds (optional) : <logical 1x1>
%     Whether seeds that are not shared across cohorts should be deleted.
%     Defaults to false.
%
% i_select_configs (optional) : <logical 1xN>
%     Vector of configuration IDs indicating which RNN configurations to
%     consider. By default, considers all existing configurations.
%
% constraint_weight (optional) : <float 1xN>
%     Vector of relative weight of the biological constraint term compared
%     to the behavioural objective in the joint optimization.
%
% OUTPUTS -----------------------------------------------------------------
% subset_included_paths : <string 1xN>
%     Paths to RNNs corresponding to seeds that are shared across all
%     cohorts.

arguments
    path_specs (1, 1) string
    path_networks (1, 1) string
    delete_unshared_seeds (1,1) {mustBeNumericOrLogical} = false
    i_select_configs (1, :) double = 1:length(getDesiredNetworkConfigs())
    constraint_weight (1, :) double = 0
end


% Load initial parameters to determine total number of RNNs trained per
% cohort
init_params = load(path_specs).init_params;
n_trials_cohort = size(init_params, 2);

% Load cohort configurations
all_Config = getDesiredNetworkConfigs();
n_configs = length(getDesiredNetworkConfigs());
n_trained_configs = length(i_select_configs);

% --- Go through all trained RNNs --- %

% Initialize storage of training status for each seed x cohort
is_trained = false(n_trials_cohort, n_trained_configs);
% Get paths to all trained RNNs
all_path = getAllNetworkPaths(path_networks);
n_network = length(all_path);
% Define file patterns to match each cohort
all_patterns = strings(1, n_trained_configs);
for i_config = 1:n_trained_configs
    all_patterns(i_config) = defineFilenamePattern(all_Config{i_select_configs(i_config)}, NaN, constraint_weight);
end

% ~ Loop through RNNs and identify their cohort ~ %
for i_network = 1:n_network
    seeds = regexp(all_path(i_network), all_patterns, "tokens");
    i_cohort = find(~ cellfun(@isempty, seeds), 1);
    if ~ isempty(i_cohort)
        is_trained(str2double(seeds{i_cohort}{1}), i_cohort) = true;
    end
end

% Identify seeds present in all cohorts
subset_seeds = find(all(is_trained, 2))';

% --- Select shared seeds --- %

% Remove some shared seeds if there are more than the target number
n_target_networks_cohort = load(path_specs).n_target_networks_cohort;
n_subset = min(length(subset_seeds), n_target_networks_cohort);
subset_seeds = subset_seeds(1:n_subset);

% Create paths to all RNNs with a shared seed
subset_included_paths = strings(1, n_subset * n_trained_configs);
escaped_path_networks = strrep(fullfile(path_networks, " "), "\", "\\");
i_path = 1;
for i_config = 1:n_configs
    for seed = subset_seeds
        filename_pattern = escaped_path_networks + defineFilenamePattern(...
            all_Config{i_config}, seed);
        if constraint_weight == 0
            % Allow for any constraint weight
            filename_pattern = char(filename_pattern);
            filename_pattern = string(filename_pattern(1:(end-4)) + '(_(\d)?(\.)?(\d)+)?\.mat');
        end
        subset_included_paths(i_path) = filename_pattern;
        i_path = i_path + 1;
    end
end

% --- Delete RNNs with unshared seeds (optional) --- %

if delete_unshared_seeds
    % Identify unselected RNN paths
    is_included_path = false(size(all_path));
    for i_network = 1:n_network
        i_match = arrayfun(@(x) ~isempty(regexp(all_path(i_network), x, "once")), subset_included_paths);
        if any(i_match)
            is_included_path(i_network) = true;
        end
    end
    % Delete each unshared RNN
    for nonincluded_path = all_path(~ is_included_path)
        delete(nonincluded_path);
    end
end
