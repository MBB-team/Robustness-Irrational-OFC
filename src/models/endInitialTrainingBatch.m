function [DatasetSpecs] = endInitialTrainingBatch(path_specs, path_networks, ...
    i_select_configs, constraint_weight)
% Finalizes a batch of initial RNN training by filtering unsuccessful
% seeds.
%
% This function removes RNN seeds that failed to reach the performance
% threshold in any cohort and updates the batch training specifications
% accordingly. It also records the number of correctly trained networks per
% cohort and marks the batch as completed.
%
% INPUTS ------------------------------------------------------------------
% path_specs : <string 1x1>
%     Path to the file where training specifications are stored.
%
% path_networks : <string 1x1>
%     Path to the directory in which RNNs meeting the performance threshold
%     are saved.
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
% DatasetSpecs : <struct 1x1>
%     Structure containing all training-specific elements for the current
%     batch (initial states, training datasets, and test datasets). See
%     also: generateTrainTestDataset, selectMonkeyTrainTestDataset.


arguments
    path_specs (1, 1) string
    path_networks (1, 1) string
    i_select_configs (1, :) double = 1:length(getDesiredNetworkConfigs())
    constraint_weight (1, :) double = []
end

% Load existing training specificities
DatasetSpecs = generateTrainTestDataset(path_specs);

%  Exclude seeds that failed in any cohort
[subset_included_paths] = selectCohortSubset(path_specs, path_networks, ...
    true, i_select_configs, constraint_weight);

% Compute the number of successfully trained networks per cohort
all_Config = getDesiredNetworkConfigs();
n_config = length(all_Config);
DatasetSpecs.n_networks_cohort = length(subset_included_paths) / n_config;
if ~ isempty(constraint_weight)
    % Consider that each cohort is defined by a pair (configuration,
    % constraint weight)
    DatasetSpecs.n_networks_cohort = DatasetSpecs.n_networks_cohort / length(constraint_weight);
end

% Mark this batch as fully trained
DatasetSpecs.last_batch_trained = true;

% Save updated training specifications
save(path_specs, "-struct", "DatasetSpecs");

% Display progress summary
fprintf(sprintf("\n%d / %d RNNs correctly trained per cohort\n\n", ...
    DatasetSpecs.n_networks_cohort, DatasetSpecs.n_target_networks_cohort));
