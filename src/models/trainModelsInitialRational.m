function [] = trainModelsInitialRational()
% Trains RNNs to exhibit rational decision-making behaviour.
%
% This function trains multiple cohorts of RNNs that implement slightly
% different input–output mappings corresponding to rational task variants.
% A total of 10 cohorts are trained; each cohort contains a fixed number of
% RNNs specified in the configuration file.
%
% For each cohort, RNNs are trained from independently generated initial
% states and datasets. Training and testing datasets, as well as initial
% network states, are randomly generated using cohort-specific seeds. The
% same set of seeds is used across all cohorts to enable direct comparison
% between task variants.
%
% Networks are retained only if they generalize correctly to held-out test
% data (R2 > 95%). If an RNN associated with a given seed fails this
% criterion in any cohort, that seed is excluded from all cohorts.
%
% -------------------------------------------------------------------------
% IMPLEMENTATION DETAILS
% -------------------------------------------------------------------------
% This function does not return outputs. Trained RNNs are saved to:
%   data/raw/models/rational/
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
% Date: 23/01/2026


% Initialize folders and training specifications
[all_Config, n_config, path_networks, path_specs, DatasetSpecs] = ...
    prepareInitialTraining("rational");

% ~ Train RNNs until the target number of models per cohort is reached ~ %
while DatasetSpecs.n_networks_cohort < DatasetSpecs.n_target_networks_cohort

    % Load or initialize a new batch of training specifications for RNNs
    [DatasetSpecs, shift_i_network] = ...
        initializeNewInitialTrainingBatch(path_specs, n_config);

    % ~ Loop through configurations to train ~ %
    for i_config = 1:n_config
   
        Config = all_Config{i_config};
    
        % ~ Loop through RNNs to train ~ %
        parfor i_network = (1:DatasetSpecs.batch_size) + shift_i_network  

            % Select initial conditions and datasets for training and testing
            [init_params, input_train, output_train, input_test, ...
                output_test] = selectInitialTrainingData(DatasetSpecs, i_network, Config);

            % Train a single RNN
            out = performInitialTraining(Config, input_train, output_train, init_params);

            % Evaluate RNN performance on training and test datasets
            [fit_train, fit_test, params] = testTrainingGeneralizability(out, ...
                Config, input_train, output_train, input_test, output_test);      
            
            % Save the RNN if it achieves sufficient performance on the test set
            saveInitialTrainingNetwork(Config, i_network, "FitRational", ...
                params, fit_train, fit_test, out, path_networks);
        
            % Update the progress bar
            parfor_progress();
            
        end
    end

    % Filter unsuccessful seeds from this batch
    DatasetSpecs = endInitialTrainingBatch(path_specs, path_networks);

end
