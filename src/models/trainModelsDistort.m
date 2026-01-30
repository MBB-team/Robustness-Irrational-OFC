function [] = trainModelsDistort(distort_folder, target_folder, ...
    train_all_params)

arguments
    distort_folder (1, 1) string
    target_folder (1, 1) string
    train_all_params (1, 1) logical = False
end

% Load training specifications and initialize parallel processing
[path_networks_distort, path_networks_target, DatasetSpecs, ...
    distort_label, target_label] = prepareDistortTraining(distort_folder, target_folder);

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
    if isfield(NetworkRetrain, "FitIrrational" + monkey)
        parfor_progress();
        continue;
    end

    % Create a copy of the Config structure to store the actual outputs
    % used for training
    TrainingConfig = NetworkRetrain.Config;
    TrainingConfig.output_format_label = "choice";
    TrainingConfig.outputs = "choice_" + Config.output_label;

    % Select the datasets successfully used for initial training of the
    % reference network already in the target irrational state
    [~, input_train, output_train, input_test, output_test] = ...
        selectTrainingData(DatasetSpecs, NetworkTarget.seed, ...
        TrainingConfig);

    % Re-train a single RNN
    switch distort_folder
        case "rational"
            fit_label = "FitRational";
        case "rational_subj"
            fit_label = "FitRationalSubj" + monkey;
        otherwise
            error("Please specify a valid folder where to find RNNs to re-train.");
    end
    out = performTraining(TrainingConfig, input_train, output_train, ...
        NetworkRetrain.(fit_label).params(:, end), ...
        DatasetSpecs.CueDatasetTrain{i_network}.i_step, train_all_params);

    % Evaluate RNN performance on training and test datasets
    [fit_train, fit_test, params] = testTrainingGeneralizability(out, ...
        TrainingConfig, input_train, output_train, input_test, output_test, ...
        DatasetSpecs.CueDatasetTrain{i_network}.i_step, ...
        DatasetSpecs.CueDatasetTest{i_network}.i_step);

    % Save the RNN
    saveDistortTrainingNetwork(NetworkRetrain, fit_label + "ToIrrational" + monkey, ...
        params, fit_train, fit_test, out, path_networks_distort{i_network});

    % Update the progress bar
    parfor_progress();
end
