function [all_Config, n_config, path_networks, path_specs, DatasetSpecs] = ...
    prepareInitialTraining(folder_name, monkey)
% Initializes folders and training specifications for initial RNN training.
%
% This function prepares the file structure used to store trained RNNs and
% loads or generates all training-specific elements required for initial
% training, including network initial states and training/testing datasets.
% It also starts parallel computing pools for subsequent training.
%
% INPUTS ------------------------------------------------------------------
% folder_name : <string 1x1>
%     Name of the sub-folder where trained models and training
%     specifications will be saved.
%
% monkey (optional) : <string 1x1>
%     If specified, training datasets are selected to match the behavioural
%     data of the given monkey rather than being synthetically generated.
%
% OUTPUTS -----------------------------------------------------------------
% all_Config : <cell 1xN>
%     Cell array of 'Config' structures defining the exact input–output
%     mappings used for each cohort. Each configuration corresponds to one
%     cohort variant. See also: getDesiredNetworkConfigs.
%
% n_config : <int 1x1>
%     Number of configurations (i.e., number of cohorts).
%
% path_networks : <string 1x1>
%     Path to the directory where trained RNNs will be saved.
%
% path_specs : <string 1x1>
%     Path to the file where training specifications are stored.
%
% DatasetSpecs : <struct 1x1>
%     Structure containing all training-specific elements (initial states,
%     training datasets, and test datasets). See also:
%     generateTrainTestDataset, selectMonkeyTrainTestDataset.

arguments
    folder_name (1, 1) string
    monkey (1, 1) string {mustBeMember(monkey, ["", "Franck", "Miles"])} = ""
end

% Get the input-output mapping variants for each cohort
all_Config = getDesiredNetworkConfigs();
n_config = length(all_Config);

% Prepare the RNN save folder
path_networks = fullfile(getPath("ModelsRaw"), folder_name);
if ~ isfolder(path_networks)
    mkdir(path_networks)
end

% Load the training information
path_specs = fullfile(path_networks, "_DatasetSpecs.mat");
if monkey == ""
    DatasetSpecs = generateTrainTestDataset(path_specs);
else
    DatasetSpecs = selectMonkeyTrainTestDataset(path_specs, monkey);
end

% Initialize the parallel pools
delete(gcp("nocreate"));
cluster = parcluster("local");
parpool(cluster, cluster.NumWorkers);

end