function [] = trainModelsInitialIrrational(monkey)
% Trains RNNs to exhibit irrational decision-making behaviour.
%
% This function trains multiple cohorts of RNNs that implement slightly
% different input–output mappings. A total of 8 cohorts are trained; each
% cohort contains a fixed number of RNNs specified in the configuration
% file.
%
% In "rational" and "rational subjective" initial training settings, a
% total of 10 cohorts are trained. The 2 cohorts missing here correspond to
% RNNs mapping "location" inputs to "order" outputs, which are more
% difficult to train and have a storng tendency to overfit their training
% set. This issue must be corrected in the future.
%
% For each cohort, RNNs are trained from independently generated initial
% states and datasets. Using cohort-specific seeds, training and testing
% datasets are randomly selected from trials attended by the monkey, and
% initial network states are randomly generated. The same set of seeds is
% used across all cohorts to enable direct comparison between task
% variants.
%
% Networks are retained only if they generalize correctly to held-out test
% data (balanced accuracy > 85%). If an RNN associated with a given seed
% fails this criterion in any cohort, that seed is excluded from all
% cohorts.
%
% INPUTS ------------------------------------------------------------------
% monkey : <string 1x1>
%     Name of the monkey on whose behaviour the RNNs will be trained.
%
% -------------------------------------------------------------------------
% IMPLEMENTATION DETAILS
% -------------------------------------------------------------------------
% This function does not return outputs. Trained RNNs are saved to:
%   data/raw/models/irrational_Franck/
% or:
%   data/raw/models/irrational_Miles/
% with one file per network.
%
% Dataset generation details (initial states, training sets, and test sets)
% are saved in 'DatasetSpecs.mat' to allow exact re-training and
% re-testing. Training hyperparameters and model settings are defined in
% 'globalConfig.m'
%
% -------------------------------------------------------------------------
% AUTHOR & VERSION
% -------------------------------------------------------------------------
% Author: Juliette Bénon
% Date: 05/02/2026


arguments
    monkey (1, 1) string {mustBeMember(monkey, ["Franck", "Miles"])}
end

% List of indices indicating which configs to take into account when
% selecting seeds successfully trained across cohorts.
% Exclude cohorts 3 and 4, which never correctly generalize to a test
% dataset.
I_SELECT_CONFIG = [1, 2, 5, 6, 7, 8, 9, 10];

% Initialize folders and training specifications
[all_Config, n_config, path_networks, path_specs, DatasetSpecs] = ...
    prepareInitialTraining("irrational_" + monkey);

% ~ Train RNNs until the target number of models per cohort is reached ~ %
while DatasetSpecs.n_networks_cohort < DatasetSpecs.n_target_networks_cohort + 1

    % Load or initialize a new batch of training specifications for RNNs
    [DatasetSpecs, shift_i_network] = ...
        initializeNewInitialTrainingBatch(path_specs, monkey);

    % ~ Loop through configurations to train ~ %
    for i_config = 1:n_config % Exclude 3 and 4
   
        Config = all_Config{i_config};

        % Create a copy of the Config structure to store the actual outputs
        % used for training
        TrainingConfig = Config;
        TrainingConfig.output_format_label = "choice";
        TrainingConfig.outputs = "choice_" + Config.output_label;
    
        % ~ Loop through RNNs to train ~ %
        parfor i_network = (1:DatasetSpecs.batch_size) + shift_i_network

            % Select initial conditions and datasets for training and testing
            [init_params, input_train, output_train, input_test, ...
                output_test] = selectTrainingData(DatasetSpecs, i_network, TrainingConfig);

            % Train a single RNN
            out = performTraining(TrainingConfig, input_train, output_train, ...
                init_params, DatasetSpecs.CueDatasetTrain{i_network}.i_step);

            % Evaluate RNN performance on training and test datasets
            [fit_train, fit_test, params] = testTrainingGeneralizability(out, ...
                TrainingConfig, input_train, output_train, input_test, output_test, ...
                DatasetSpecs.CueDatasetTrain{i_network}.i_step, ...
                DatasetSpecs.CueDatasetTest{i_network}.i_step);     
            
            % Save the RNN if it achieves sufficient performance on the test set
            saveInitialTrainingNetwork(Config, i_network, "FitIrrational" + monkey, ...
                params, fit_train, fit_test, out, path_networks, I_SELECT_CONFIG);
            
        end
    end

    % Filter unsuccessful seeds from this batch
    DatasetSpecs = endInitialTrainingBatch(path_specs, path_networks, I_SELECT_CONFIG);

end
