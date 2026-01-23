function [init_params, input_train, output_train, input_test, output_test] = ...
    selectInitialTrainingData(DatasetSpecs, i_network, Config, monkey)
% Selects initial conditions and datasets for training and testing one RNN.
%
% This function extracts the initial network parameters and the
% corresponding training and test datasets for a single RNN, identified by
% its seed index. Inputs and target outputs are selected according to the
% specified RNN configuration.
%
% INPUTS ------------------------------------------------------------------
% DatasetSpecs : <struct 1x1>
%     Structure containing all training-specific elements (initial states,
%     training datasets, and test datasets). See also:
%     generateTrainTestDataset, selectMonkeyTrainTestDataset.
%
% i_network : <int 1x1>
%     Index of the seed used to generate the initial state and associated
%     training and test datasets for the RNN.
% 
% Config : <struct 1x1>
%     Structure defining the task-specific input–output mapping of the RNN.
%     See also: getDesiredNetworkConfigs.
%
% monkey (optional) : <string 1x1>
%     If specified, task outputs are derived from the behavioural data of
%     the given monkey rather than from synthetic value profiles.
%
% OUTPUTS -----------------------------------------------------------------
% init_params : <float Px1>
%     Vector of initial network parameters (connection weights and unit
%     biases) used to initialize RNN training.
%
% input_train : <float NxM>
%     Matrix of task inputs used during training, with M input dimensions
%     defined over N time steps.
%
% output_train : <float NxR>
%     Matrix of target outputs used during training, with R output
%     dimensions defined over N time steps.
%
% input_test : <float NxM>
%     Same as input_train, but for evaluation on held-out test data.
%
% output_test : <float NxR>
%     Same as output_train, but for evaluation on held-out test data.

arguments
    DatasetSpecs (1, 1) struct
    i_network (1, 1) int
    Config (1, 1) struct
    monkey (1, 1) string {mustBeMember(monkey, ["", "Franck", "Miles"])} = ""
end

% Extract initial network parameters for the selected seed
init_params = DatasetSpecs.init_params(:, i_network);

% Expand basic cue sample information into full task variables
DatasetTrain = expandCueSamples(DatasetSpecs.CueDatasetTrain{i_network}, ...
    monkey, override_choice=false);
DatasetTest = expandCueSamples(DatasetSpecs.CueDatasetTest{i_network}, ...
    monkey, override_choice=false);

% Select inputs and target outputs
input_train = selectDataInfo(DatasetTrain, Config.inputs);
output_train = selectDataInfo(DatasetTrain, Config.outputs);
input_test = selectDataInfo(DatasetTest, Config.inputs);
output_test = selectDataInfo(DatasetTest, Config.outputs);
