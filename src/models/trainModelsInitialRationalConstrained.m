function [] = trainModelsInitialRationalConstrained(constraint, ...
    constraint_weight, constraint_field)
% Trains RNNs to exhibit rational decision-making behaviour under
% biological constraints.
%
% This function trains multiple cohorts of RNNs that implement slightly
% different input–output mappings corresponding to rational task variants.
% A total of 10 cohorts are trained; each cohort contains a fixed number of
% RNNs specified in the configuration file.
%
% -------------------------------------------------------------------------
% TRAINING PROCEDURE
% -------------------------------------------------------------------------
% For each cohort, RNNs are trained from independently generated initial
% states and datasets. Training and testing datasets, as well as initial
% network states, are randomly generated using cohort-specific seeds. The
% same set of seeds is used across all cohorts to enable direct comparison
% between task variants.
%
% Contrary to RNNs trained without biological constraints
% (see: trainModelsInitialRational), these RNNs are always saved to disk no
% matter their performance on held-out test data.
%
% -------------------------------------------------------------------------
% BIOLOGICAL CONSTRAINT DURING TRAINING
% -------------------------------------------------------------------------
% In addition to fitting the network's behavioural outputs, training
% incorporates a constraint defined by a function from the
% src/analyses/measures folder.
%
% When a constraint function is provided:
%   - The function is applied to the full network (i.e., to its
%     parameters).
%   - One scalar field of its output structure (specified by
%     'constraint_field') is selected.
%   - During optimization, this quantity is encouraged to approach 0.
%  
% Concretely, the predicted behavioural outputs of the network are
% concatenated with the selected constraint value, and the objective
% function jointly minimizes:
% (1) Behavioural prediction error (fit to rational targets), and
% (2) The magnitude of the constraint term (weighted by 
%     'constraint_weight').
%
% If no constraint is provided (default), training optimizes behaviour
% only.
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
% constraint : <function_handle 1x1>
%     Function from src/analyses/measures applied to the trained network.
%     It must follow the standard two-mode interface of measure functions.
%     Its selected scalar output is driven toward 0 during optimization.
%
% constraint_weight : <float 1xN>
%     Vector of relative weight of the constraint term compared to the
%     behavioural objective in the joint optimization.
%
% constraint_field (optional) : <string 1x1>
%     Name of the scalar field in the constraint function's output
%     structure that is used as the constraint signal.
%
% -------------------------------------------------------------------------
% IMPLEMENTATION DETAILS
% -------------------------------------------------------------------------
% This function does not return outputs. Trained RNNs are saved to:
%   data/raw/models/rational_[constraint_field]/
% with one file per network.
%
% Dataset generation details (initial states, training sets, and test sets)
% are saved in 'DatasetSpecs.mat' to allow exact re-training and
% re-testing. Training hyperparameters and model settings are defined in
% 'globalConfig.m'. Networks are trained by batch in order to resume
% training of the last ongoing batch if the session is interrupted.
%
% -------------------------------------------------------------------------
% AUTHOR & VERSION
% -------------------------------------------------------------------------
% Author: Juliette Bénon
% Date: 12/02/2026


arguments
    constraint (1, 1) function_handle
    constraint_weight (1, :) double
    constraint_field (1, 1) string = ""
end


% Automatically define relevant constraint function fields
if isequal(constraint, @computeEnergeticBudget) 
    constraint_field = "energetic_budget_avg";
elseif isequal(constraint, @computeInfoTransferRate) 
    constraint_field = "info_transfer_rate";
elseif isequal(constraint, @computeRobustnessToUnitLesions) 
    constraint_field = "prop_optimal_impaired_units";
elseif isequal(constraint, @computeCodeRedundancy) 
    constraint_field = "code_redundancy";
end

% Initialize folders and training specifications
[all_Config, n_config, path_networks, path_specs, DatasetSpecs] = ...
    prepareInitialTraining("rational_" + constraint_field);

% ~ Train RNNs until the target number of models per cohort is reached ~ %
while DatasetSpecs.n_networks_cohort < DatasetSpecs.n_target_networks_cohort

    % Load or initialize a new batch of training specifications for RNNs
    [DatasetSpecs, shift_i_network] = ...
        initializeNewInitialTrainingBatch(path_specs);

    % ~ Loop through configurations to train ~ %
    for i_config = 1:n_config
   
        Config = all_Config{i_config};

        % ~ Loop through constraint weights to apply ~ %
        for i_weight = 1:length(constraint_weight)
    
            % ~ Loop through RNNs to train ~ %
            for i_network = (1:DatasetSpecs.batch_size) + shift_i_network  

                % Select initial conditions and datasets for training and testing
                [init_params, input_train, output_train, input_test, ...
                    output_test] = selectTrainingData(DatasetSpecs, i_network, Config);
                
                % Train a single RNN
                out = performTraining(Config, input_train, output_train, init_params, ...
                    constraint=constraint, ...
                    constraint_field=constraint_field, ...
                    constraint_weight=constraint_weight(i_weight));
    
                % Evaluate RNN performance on training and test datasets
                [fit_train, fit_test, params] = testTrainingGeneralizability(out, ...
                    Config, input_train, output_train, input_test, output_test);      
                
                % Save the RNN if it achieves sufficient performance on the test set
                saveInitialTrainingNetwork(Config, i_network, "FitRationalConstrained", ...
                    params, fit_train, fit_test, out, path_networks, 1:n_config, ...
                    constraint_field, constraint_weight(i_weight));

            end
        end
    end

    % Filter unsuccessful seeds from this batch
    DatasetSpecs = endInitialTrainingBatch(path_specs, path_networks);

end
