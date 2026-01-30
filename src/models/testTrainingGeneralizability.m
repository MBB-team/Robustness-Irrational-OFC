function [fit_train, fit_test, params] = testTrainingGeneralizability(...
    out, Config, input_train, output_train, input_test, output_test, ...
    i_step_train, i_step_test)
% Evaluates RNN performance on training and held-out test datasets.
%
% This function computes prediction quality throughout training, using both
% the training dataset and an independent test dataset. Performance is
% evaluated at each training iteration through the full trajectory of
% fitted parameters.
%
% INPUTS ------------------------------------------------------------------
% out : <struct 1x1>
%     Structure containing fitted model parameters, convergence statistics,
%     and training diagnostics. See also: VBA_NLStateSpaceModel.
%
% Config : <struct 1x1>
%     Structure defining the task-specific input–output mapping and RNN
%     architecture. See also: getDesiredNetworkConfigs.
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
%
% i_step_train (optional) : <int Nx1>
%     Within-trial cue sampling time steps for the training set. Required
%     when evaluating choice outputs; if empty, trials are assumed to last
%     four time steps.
%
% i_step_test (optional) : <int Nx1>
%     Same as i_step_train, but for the test dataset.
% 
% OUTPUTS -----------------------------------------------------------------
% fit_train : <float TxR>
%      Prediction quality on the training dataset for each output dimension
%     (R), evaluated at each training iteration (T).
%
% fit_test : <float TxR>
%      Prediction quality on the test dataset for each output dimension (R),
%     evaluated at each training iteration (T).
%
% params : <float PxT>
%     Trajectory of network parameters across training iterations.
%

arguments
    out (1, 1) struct
    Config (1, 1) struct
    input_train (:, :) double
    output_train (:, :) double
    input_test (:, :) double
    output_test (:, :) double
    i_step_train (:, 1) double {mustBeInteger} = []
    i_step_test (:, 1) double {mustBeInteger} = []
end

% Retrieve parameter trajectories across training
params = out.suffStat.params_history;

% Initialize fit quality matrices
n_outputs = length(Config.outputs);
fit_train = NaN(size(params, 2), n_outputs);
fit_test = NaN(size(params, 2), n_outputs);

% Prepare observation function inputs for training and test datasets
in_train = struct();
in_train.Config = Config;
in_train.input = input_train;
in_test = in_train;
in_test.input = input_test;

% Select performance metric depending on output type
if Config.output_format_label == "choice"
    test_fit_function = @computeBalancedAccuracy;
    try
        in_train.i_step = i_step_train;
        in_test.i_step = i_step_test;
    catch
        error("Cue steps must be provided when evaluating choice networks.");
    end
else
    test_fit_function = @computeR2;
end

% ~ Loop through training iterations ~ %
for i_it = 1:size(params, 2)

    % Generate model predictions for training data
    vec_pred_output_train = observeANN(...
        [], params(:, i_it), [], in_train);
    pred_output_train = reshape(vec_pred_output_train, ...
        [], n_outputs);

    % Generate model predictions for test data
    vec_pred_output_test = observeANN(...
        [], params(:, i_it), [], in_test);
    pred_output_test = reshape(vec_pred_output_test, ...
        [], n_outputs);

    % Compute prediction quality
    fit_train(i_it, :) = test_fit_function(output_train, ...
        pred_output_train);
    fit_test(i_it, :) = test_fit_function(output_test, ...
        pred_output_test);
end