function [path_networks_distort, path_networks_target, DatasetSpecs] = ...
    prepareDistortTraining(distort_folder, target_folder)
% Prepares datasets and paths for RNN re-training under distorted
% conditions.
%
% This function loads the training and testing datasets used for initial
% RNN training and reuses them to re-train existing networks under modified
% (distorted) conditions. It relies on datasets that were already validated
% during successful initial training. The function also initializes the
% parallel computing pool and a progress bar for subsequent training.
%
% INPUTS ------------------------------------------------------------------
% distort_folder : <string 1x1>
%     Name of the sub-folder containing RNNs to be re-trained.
%
% target_folder : <string 1x1>
%     Name of the sub-folder containing successfully trained RNNs and their
%     associated training specifications, which are used as a reference for
%     re-training.
%
% OUTPUTS -----------------------------------------------------------------
% path_networks_distort : <string 1x1>
%     Absolute path to the directory containing the RNNs to be re-trained.
%
% path_networks_target : <string 1x1>
%     Absolute path to the directory containing the reference (successfully
%     trained) RNNs.
%
% DatasetSpecs : <struct 1x1>
%     Structure containing training and test datasets required for
%     re-training. See also: generateTrainTestDataset,
%     selectMonkeyTrainTestDataset.

arguments
    distort_folder (1, 1) string
    target_folder (1, 1) string
end

% Path to RNNs that will be re-trained
path_networks_distort = fullfile(getPath("ModelsRaw"), distort_folder);
% Path to reference RNNs and their associated dataset specifications
path_networks_target = fullfile(getPath("ModelsRaw"), target_folder);

% Prepare loading of the dataset specifications from the reference (target)
% folder
path_specs = fullfile(path_networks_target, "_DatasetSpecs.mat");

% Select monkey-specific datasets when applicable
monkey = regexp(target_folder, ".*(Franck|Miles).*", "tokens");
if ~ isempty(monkey) && contains(target_folder, "irrational")
    monkey = monkey{1};
    DatasetSpecs = selectMonkeyTrainTestDataset(path_specs, monkey, False);
else
    DatasetSpecs = generateTrainTestDataset(path_specs, False);
end

% Initialize the parallel pools
delete(gcp("nocreate"));
cluster = parcluster("local");
parpool(cluster, cluster.NumWorkers);

% Initialize progress bar
parfor_progress(len(path_networks_distort));

end
