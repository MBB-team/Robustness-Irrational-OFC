function [] = trainModelsDistortRational(distort_folder, ...
    train_all_params)
% Re-trains RNNs to exhibit rational decision-making behaviour.
%
% This function re-trains a collection of previously trained RNNs
% exhibiting irrational behaviour so that they exhibit rational, optimal
% valuation mechanisms. Re-training relies on datasets and initial states
% from networks that were already successfully trained directly on the
% rational target behaviour. Depending on the specified options, either all
% parameters or only recurrent connections are optimized during
% re-training. This function does not support the retraining of RNNs
% producing rational *subjective* values.
%
% INPUTS ------------------------------------------------------------------
% distort_folder : <string 1x1>
%     Name of the sub-folder containing the RNNs to be re-trained (i.e.,
%     "irrational_Franck" or "irrational_Miles").
%
% train_all_params (optional) : <logical 1x1>
%     Whether to re-train all network parameters (true) or restrict
%     optimization to recurrent connections only (false, default).
%
% -------------------------------------------------------------------------
% AUTHOR & VERSION
% -------------------------------------------------------------------------
% Author: Juliette Bénon
% Date: 30/01/2026

arguments
    distort_folder (1, 1) string
    train_all_params (1, 1) logical = False
end

% Load training specifications and initialize parallel processing
[path_networks_distort, path_networks_target, DatasetSpecs] = ...
    prepareDistortTraining(distort_folder, "rational");

% ~ Re-train all RNNs in the specified folder ~ %
for i_network = 1:n_network

    try
        % Load the RNN to be re-trained and the corresponding RNN trained
        % directly on the irrational target behaviour
        NetworkRetrain = load(path_networks_distort{i_network});
        NetworkTarget = load(path_networks_target{i_network});
    catch
        warning("Impossible to load network n°%d", i_network);
        parfor_progress();
        continue;
    end

    % Skip networks that have already been re-trained under this condition
    if isfield(NetworkRetrain, "FitRational")
        parfor_progress();
        continue;
    end

    % Select the datasets successfully used for initial training of the
    % reference network already in the target irrational state
    [~, input_train, output_train, input_test, output_test] = ...
        selectTrainingData(DatasetSpecs, NetworkTarget.seed, ...
        NetworkRetrain.Config);

    % Re-train a single RNN
    switch distort_folder
        case "rational_subj"
            fit_label = "FitRationalSubj" + monkey;
        case "irrational_Franck"  || "irrational_Miles"
            fit_label = "FitIrrational" + monkey;
        otherwise
            error("Please specify a valid folder where to find RNNs to re-train.");
    end
    out = performTraining(NetworkRetrain.Config, input_train, output_train, ...
        NetworkRetrain.(fit_label).params(:, end), ...
        DatasetSpecs.CueDatasetTrain{i_network}.i_step, train_all_params);

    % Evaluate RNN performance on training and test datasets
    [fit_train, fit_test, params] = testTrainingGeneralizability(out, ...
        NetworkRetrain.Config, input_train, output_train, input_test, output_test, ...
        DatasetSpecs.CueDatasetTrain{i_network}.i_step, ...
        DatasetSpecs.CueDatasetTest{i_network}.i_step);

    % Save the RNN
    saveDistortTrainingNetwork(NetworkRetrain, "FitRational", ...
        params, fit_train, fit_test, out, path_networks_distort{i_network});

    % Update the progress bar
    parfor_progress();
end
