function [] = trainModelsDistort(distort_folder, target_folder, ...
    distort_monkey, target_monkey, train_all_params)
% Re-trains RNNs by distorting their initial training parameters.
%
% This function re-trains a collection of previously trained RNNs to
% exhibit a target behaviour; either rational, rational subjective based on
% the value profile of one monkey, or irrational based on the choices of
% one monkey. Re-training relies on datasets and initial states from
% networks that were already successfully trained directly on the target
% behaviour. Depending on the specified options, either all parameters or
% only recurrent connections are optimized during re-training.
%
% INPUTS ------------------------------------------------------------------
% distort_folder : <string 1x1>
%     Name of the sub-folder containing the RNNs to be re-trained.
%
% target_folder : <string 1x1>
%     Name of the sub-folder containing the RNNs that were initially
%     trained to exhibit the desired target behaviour.
%
% distort_monkey (optional) : <string 1x1>
%     If applicable, name of the monkey used as a reference during initial
%     training (either 'rational subjective' or 'irrational' training).
%
% target_monkey (optional): <string 1x1>
%     If applicable, name of the monkey used as a reference during 
%     re-training (either 'rational subjective' or 'irrational' training).
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
    target_folder (1, 1) string
    distort_monkey (1, 1) string {mustBeMember(distort_monkey, ["", "Franck", "Miles"])} = ""
    target_monkey (1, 1) string {mustBeMember(target_monkey, ["", "Franck", "Miles"])} = ""
    train_all_params (1, 1) logical = false
end

% Load training specifications and initialize parallel processing
[path_networks_distort, path_networks_target, DatasetSpecs, distort_fit_label, target_fit_label] = ...
    prepareDistortTraining(distort_folder, target_folder, distort_monkey, target_monkey);

% ~ Re-train all RNNs in the specified folder ~ %
for i_network = 1:length(path_networks_distort)

    try
        % Load the RNN to be re-trained and the corresponding RNN trained
        % directly on the irrational target behaviour
        DistortNetwork = load(path_networks_distort{i_network});
        TargetNetwork = load(path_networks_target{i_network});
    catch
        warning("Impossible to load network n°%d", i_network);
        continue;
    end

    % Copy the Config structure to store the actual outputs used for
    % re-training
    TrainingConfig = DistortNetwork.Config;
    if contains(target_folder, "irrational")
        TrainingConfig.output_format_label = "choice";
        TrainingConfig.outputs = "choice_" + DistortNetwork.Config.output_label;
    end

    % Select the datasets successfully used for initial training of the
    % reference network
    [~, input_train, output_train, input_test, output_test] = ...
        selectTrainingData(DatasetSpecs, TargetNetwork.seed, ...
        TrainingConfig, target_monkey);

    % Re-train a single RNN
    out = performTraining(TrainingConfig, input_train, output_train, ...
        DistortNetwork.(distort_fit_label).params(:, end), ...
        DatasetSpecs.CueDatasetTrain{i_network}.i_step, train_all_params);

    % Evaluate RNN performance on training and test datasets
    [fit_train, fit_test, params] = testTrainingGeneralizability(out, ...
        TrainingConfig, input_train, output_train, input_test, output_test, ...
        DatasetSpecs.CueDatasetTrain{i_network}.i_step, ...
        DatasetSpecs.CueDatasetTest{i_network}.i_step, ...
        DistortNetwork.(distort_fit_label).params(:, end));

    % Save the RNN
    saveDistortTrainingNetwork(DistortNetwork, target_fit_label, ...
        params, fit_train, fit_test, out, path_networks_distort{i_network});

end
