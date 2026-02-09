function analysis_output = predictOptimalChoices(params, Config, ~, inputs)
% Quantifies how rational (optimal) are the choices of an RNN.
%
% This measure evaluates whether the choices produced by an RNN match the
% choices made rationally by following an optimal value profile.The RNN is
% run on all possible trials, its outputs are converted into binary
% choices, and prediction performance is assessed using balanced accuracy
% on the 2nd, 3rd and 4th step of each trial.
%
% As with all functions in the 'measures' folder, this function can be
% called in two modes: when called without parameters, it performs any
% required preprocessing and returns the corresponding inputs; when called
% with parameters, it applies the measure to the RNN using these inputs.
%
% INPUTS ------------------------------------------------------------------
% params : <float Px1> | []
%     Vector of RNN parameters. If empty, the function runs in
%     preprocessing mode and returns the analysis inputs instead of
%     computing measures.
%
% Config : <struct 1x1>
%     Configuration structure defining the RNN architecture.
%
% inputs : <struct 1x1>
%     Structure containing variables precomputed during preprocessing, as
%     well as supplementary variables. Required only in analysis mode.
%     Fields include:
%       - DataSamplesAll: cue-sampling datasets describing all possible
%       cue-sampling sequences
%       
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing monkey-specific cue sequences datasets.
%     - In analysis mode:
%     Structure containing balanced accuracies:
%       - bacc_optimal <3x1>: balanced accuracy for predicting optimal
%       choices at step 2, 3 and 4
%       - bacc_optimal_avg <1x1>: balanced accuracy averaged across all
%       trial steps

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end

if isempty(params)

    % --- Preprocessing mode: generate cue-sequence datasets --- %

    CueSamples = generateAllCueSamples();
    analysis_output.DataSamplesAll = expandCueSamples(CueSamples);

else

    % --- Analysis mode: predict optimal choices --- %

    % Select RNN inputs
    input_test = selectDataInfo(inputs.DataSamplesAll, Config.inputs);

    % Get RNN outputs
    Weights = shapeParametersIntoWeights(params, Config);
    [~, ~, network_output] = propagateThroughANN(Weights, ...
        Config.f_activation, input_test, CueSamplesTest.i_step);

    % Convert RNN outputs to choice probabilities
    if size(network_output, 2) == 2
        network_output = network_output(:, 1) - network_output(:, 2);
    end
    network_choices = sigANN(- network_output, 0);

    % --- Compare RNN and optimal choices --- %

    % Select monkey choices in the same reference frame as the RNN
    optimal_choices = inputs.DataSamplesAll.("choice_" + Config.output_label);
    optimal_choices = optimal_choices';

    % Compute balanced accuracy at each trial step
    analysis_output.bacc_optimal = NaN(3, 1);
    for i_step = 2:4
        select_step = inputs.DataSamplesAll.i_step == i_step;
        analysis_output.bacc_optimal(i_step - 1) = computeBalancedAccuracy(...
            optimal_choices(select_step), network_choices(select_step));
    end

    % Compute average balanced accuracy
    analysis_output.bacc_optimal_avg = mean(analysis_output.bacc_optimal);
    
end
