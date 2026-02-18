function [] = saveInitialTrainingNetwork(Config, i_network, fit_label, ...
    params, fit_train, fit_test, out, path_networks, i_select_configs, ...
    constraint_field, constraint_weight)
% Saves a trained RNN if it achieves sufficient performance on the test
% set.
%
% This function evaluates the final test-set performance of an RNN across
% one or more fit phases and saves the network only if the average test
% performance exceeds a defined threshold (R2 >= 0.95 or accuracy >= 0.95).
% The saved structure includes the network configuration, seed, parameter
% trajectories, training/test fit histories, and convergence diagnostics.
%
% INPUTS ------------------------------------------------------------------
% Config : <struct 1x1>
%     Structure defining the task-specific input–output mapping and RNN
%     architecture. See also: getDesiredNetworkConfigs.
%
% i_network : <int 1x1>
%     Index of the seed used to generate the initial state and associated
%     training and test datasets for the RNN.
%
% fit_label : <string 1x1>
%     Label identifying the training framework or fit phase. See also:
%     trainModelsInitialRational, trainModelsInitialRationalSubj,
%     trainModelsInitialIrrational.
%
% params : <float PxT>
%     Trajectory of network parameters across training iterations.
%
% fit_train : <float TxR>
%      Prediction quality on the training dataset for each output dimension
%     (R), evaluated at each training iteration (T).
%
% fit_test : <float TxR>
%      Prediction quality on the test dataset for each output dimension (R),
%     evaluated at each training iteration (T).
%
% out : <struct 1x1>
%     Structure containing fitted model parameters, convergence statistics,
%     and training diagnostics. See also: VBA_NLStateSpaceModel.
%
% path_networks : <string 1x1>
%     Path to the directory in which RNNs meeting the performance threshold
%     are saved.
%
% i_select_configs (optional) : <logical 1xN>
%     Vector of configuration IDs indicating which RNN configurations to
%     test. By default, considers all existing configurations.
%
% constraint_field (optional) : <string 1x1>
%     Name of the scalar field in the constraint function's output
%     structure that is used as the constraint signal.
%
% constraint_weight (optional) : <float 1x1>
%     Relative weight of the constraint term compared to the behavioural
%     objective in the joint optimization.

arguments
    Config (1, 1) struct
    i_network (1, 1) double {mustBeInteger}
    fit_label % Either a string or a cell array of strings
    params % Either a double matrix or a cell array of double matrices
    fit_train % Either a double matrix or a cell array of double matrices
    fit_test % Either a double matrix or a cell array of double matrices
    out % Either a struct or a cell array of structs
    path_networks (1, 1) string
    i_select_configs (1, :) double = 1:length(getDesiredNetworkConfigs())
    constraint_field (1, 1) string = ""
    constraint_weight (1, 1) double = 0
end

% Initialize performance criterion
save_network = true;

% Initialize network structure
Network = struct();
Network.Config = Config;
Network.seed = i_network;

% Generate all possible configurations
all_Config = getDesiredNetworkConfigs();

% Ensure all inputs are cell arrays for uniform processing
if ~ iscell(fit_label)
    fit_label = {fit_label};
end
if ~ iscell(params)
    params = {params};
end
if ~ iscell(fit_train)
    fit_train = {fit_train};
end
if ~ iscell(fit_test)
    fit_test = {fit_test};
end
if ~ iscell(out)
    out = {out};
end

% ~ Loop through fit phases ~ %
for i_fit = 1:length(fit_label)

    % Define the performance threshold
    test_network = ~ any(cellfun(@(x) isequaln(x, Config), all_Config(i_select_configs)));
    if test_network
        if contains(fit_label{i_fit}, "Irrational")
            % Performance quantified through balanced accuracy
            perf_threshold = 0.70;
        elseif constraint_weight ~= 0
            % Do not test RNN trained under constraints
            perf_threshold = - Inf;
        else
            % Performance quantified through R2
            perf_threshold = 0.95;
        end
    else
        % Do not apply any threshold to save the RNN
        perf_threshold = - Inf;
    end

    % Only save if the final test performance meets the threshold
    save_network = save_network && (mean(fit_test{i_fit}(end, :)) >= perf_threshold);

    % Store parameters, fit history, and convergence info
    Network.(fit_label{i_fit}) = struct();
    Network.(fit_label{i_fit}).params = params{i_fit};
    Network.(fit_label{i_fit}).fit_train = fit_train{i_fit};
    Network.(fit_label{i_fit}).fit_test = fit_test{i_fit};
    Network.(fit_label{i_fit}).i_end_GnLoop = out{i_fit}.suffStat.i_end_GnLoop;
    if constraint_weight ~= 0
        Network.(fit_label{i_fit}).constraint_label = constraint_field;
        Network.(fit_label{i_fit}).constraint_weight = constraint_weight;
    end
end

% Save the RNN if performance is sufficient
filename = defineFilenamePattern(Network.Config, Network.seed, constraint_weight);
if save_network
    save(fullfile(path_networks, filename), "-struct", "Network");
end

% Display network performance
if save_network
    save_string = "v";
else
    save_string = "x";
end
for i_fit = 1:length(fit_label)
    fprintf("%s: %0.2f (%s)\n", ...
        filename, mean(fit_test{i_fit}(end, :)), save_string);
end
