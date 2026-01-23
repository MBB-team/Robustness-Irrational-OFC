function [DatasetSpecs] = endInitialTrainingBatch(path_specs, path_networks)
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
% OUTPUTS -----------------------------------------------------------------
% DatasetSpecs : <struct 1x1>
%     Structure containing all training-specific elements for the current
%     batch (initial states, training datasets, and test datasets). See
%     also: generateTrainTestDataset, selectMonkeyTrainTestDataset.


arguments
    path_specs (1, 1) string
    path_networks (1, 1) string
end

% Load existing training specificities
DatasetSpecs = generateTrainTestDataset(path_specs);

%  Exclude seeds that failed in any cohort
[subset_included_paths] = selectCohortSubset(...
    path_specs, path_networks, ...
    n_networks_cohort = DatasetSpecs.n_target_networks_cohort, ...
    delete_outside_subset = true);

% Compute the number of successfully trained networks per cohort
all_Config = getDesiredNetworkConfigs();
n_config = length(all_Config);
DatasetSpecs.n_networks_cohort = length(subset_included_paths) / n_config;

% Mark this batch as fully trained
DatasetSpecs.last_batch_trained = true;

% Save updated training specifications
save(path_specs, "-struct", "DatasetSpecs");

% Display progress summary
fprintf(sprintf("\n%d / %d RNNs correctly trained per cohort\n\n", ...
    DatasetSpecs.n_networks_cohort, DatasetSpecs.n_target_networks_cohort));

% Delete the parallel progress bar file
parfor_progress(0);
