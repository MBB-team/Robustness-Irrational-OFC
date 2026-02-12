function [DatasetSpecs, shift_i_network] = ...
    initializeNewInitialTrainingBatch(path_specs, monkey)
% Loads or initializes a new batch of training specifications for RNNs.
%
% This function retrieves the training specifications corresponding to the
% next untrained batch of RNNs, or generates a new batch if none exists. The
% specifications include network initial states and training/testing
% datasets. The function also initializes a progress bar for batch training.
%
% INPUTS ------------------------------------------------------------------
% path_specs : <string 1x1>
%     Path to the file where training specifications are stored.
%
% monkey (optional) : <string 1x1>
%     If specified, training datasets are selected to match the behavioural
%     data of the given monkey; otherwise, datasets are synthetically
%     generated.
%
% OUTPUTS -----------------------------------------------------------------
% DatasetSpecs : <struct 1x1>
%     Structure containing all training-specific elements for the current
%     batch (initial states, training datasets, and test datasets). See also:
%     generateTrainTestDataset, selectMonkeyTrainTestDataset.
%
% shift_i_network : <int 1x1>
%     Index offset corresponding to the number of RNNs previously trained in
%     each cohort. Used to resume training without overwriting existing
%     networks.

arguments
    path_specs (1, 1) string
    monkey (1, 1) string {mustBeMember(monkey, ["", "Franck", "Miles"])} = ""
end

% Load or generate training datasets and initial states for the next batch
if monkey == ""
    DatasetSpecs = generateTrainTestDataset(path_specs);
else
    DatasetSpecs = selectMonkeyTrainTestDataset(path_specs, monkey);
end

% Determine how many networks have already been trained per cohort
% (used to shift the network index in the main training loop)
shift_i_network = length(DatasetSpecs.CueDatasetTrain) - ...
    DatasetSpecs.batch_size;

end