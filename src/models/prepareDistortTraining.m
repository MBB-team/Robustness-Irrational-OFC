function [path_networks_distort, path_networks_target, DatasetSpecs, distort_fit_label, target_fit_label] = ...
    prepareDistortTraining(distort_folder, target_folder, distort_monkey, target_monkey)
% Prepares datasets and paths for RNN re-training under distorted
% conditions.
%
% This function loads the training and testing datasets used for initial
% RNN training and reuses them to re-train existing networks under modified
% (distorted) conditions. It relies on datasets that were already validated
% during successful initial training. The function also initializes the
% parallel computing pool and a progress bar for subsequent training, and
% defines the names of the sub-structures in which the re-training
% informati
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
% distort_monkey : <string 1x1>
%     If applicable, name of the monkey used as a reference during initial
%     training (either 'rational subjective' or 'irrational' training).
%
% target_monkey : <string 1x1>
%     If applicable, name of the monkey used as a reference during 
%     re-training (either 'rational subjective' or 'irrational' training).
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
%
% distort_fit_label : <string 1<1>
%     Name of the 'Network' sub-structure which will be re-trained.
%
% target_fit_label : <string 1<1>
%     Name of the 'Network' sub-structure in which re-training information
%     will be stored.

arguments
    distort_folder (1, 1) string
    target_folder (1, 1) string
    distort_monkey (1, 1) string {mustBeMember(distort_monkey, ["", "Franck", "Miles"])}
    target_monkey (1, 1) string {mustBeMember(target_monkey, ["", "Franck", "Miles"])}
end

% Path to RNNs that will be re-trained
path_networks_distort = getAllNetworkPaths(fullfile(getPath("ModelsRaw"), distort_folder));

% Path to reference RNNs and their associated dataset specifications
path_folder_networks_target = fullfile(getPath("ModelsRaw"), target_folder);
path_networks_target = getAllNetworkPaths(path_folder_networks_target);

% Prepare loading of the dataset specifications from the reference (target)
% folder
path_specs = fullfile(path_folder_networks_target, "_DatasetSpecs.mat");

% If applicable, extract monkey name from folder name
target_monkey_match = regexp(target_folder, ".*(Franck|Miles).*", "tokens");
if ~ isempty(target_monkey_match)
    target_monkey = target_monkey_match{1};
end
distort_monkey_match = regexp(distort_folder, ".*(Franck|Miles).*", "tokens");
if ~ isempty(distort_monkey_match)
    distort_monkey = distort_monkey_match{1};
end

% Select monkey-specific datasets when applicable
if contains(target_folder, "irrational")
    DatasetSpecs = selectMonkeyTrainTestDataset(path_specs, target_monkey, false);
else
    DatasetSpecs = generateTrainTestDataset(path_specs, false);
end

% Define sub-structure names
if contains(distort_folder, "irrational")
    distort_fit_label = "FitIrrational" + distort_monkey;
elseif contains(distort_folder, "rational_subj")
    distort_fit_label = "FitRationalSubj" + distort_monkey;
else
    distort_fit_label = "FitRational";
end
if contains(target_folder, "irrational")
    target_fit_label = "FitIrrational" + target_monkey;
elseif contains(target_folder, "rational_subj")
    target_fit_label = "FitRationalSubj" + target_monkey;
else
    target_fit_label = "FitRational";
end

