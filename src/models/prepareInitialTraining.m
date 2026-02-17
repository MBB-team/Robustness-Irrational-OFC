function [all_Config, n_config, path_networks, path_specs, DatasetSpecs] = ...
    prepareInitialTraining(folder_name)
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
%     Absolute path to the directory where trained RNNs will be saved.
%
% path_specs : <string 1x1>
%     Absolute path to the file where training specifications are stored.
%
% DatasetSpecs : <struct 1x1>
%     Structure containing all training-specific elements (initial states,
%     training datasets, and test datasets). See also:
%     generateTrainTestDataset, selectMonkeyTrainTestDataset.

arguments
    folder_name (1, 1) string
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
monkey = regexp(folder_name, ".*(Franck|Miles).*", "tokens");
if ~ isempty(monkey) && contains(folder_name, "irrational")
    monkey = monkey{1};
    DatasetSpecs = selectMonkeyTrainTestDataset(path_specs, monkey, false);
else
    DatasetSpecs = generateTrainTestDataset(path_specs, false);
end

% --- Initialize the parallel pools --- %

if isempty(gcp("nocreate"))
    % Initialize parallel pool
    delete(gcp("nocreate"));
    % Define number of workers on a Slurm cluster
    num_workers = str2double(getenv("SLURM_CPUS_PER_TASK"));
    % Define number of workers when ran locally
    if isnan(num_workers) || num_workers < 1
        num_workers = feature('numcores');
    end
    % Activate the parallel pool
    parpool("local", num_workers);
end
