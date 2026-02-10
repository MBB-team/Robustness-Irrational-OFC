function analysis_output = computeInfoTransferRate(params, Config, ~, inputs)
% Quantifies the average information transfer rate of integration-layer
% units.
%
% This measure estimates the expected entropy of integration-layer unit
% activations under the distribution of all admissible cue sequences. At
% the low-noise limit, the information transfer rate reduces to the
% expected log of the absolute gradient of the activation function, where
% the expectation is taken across all cue-sampling scenarios.
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
%     Structure containing variables precomputed during preprocessing.
%     Required only in analysis mode. Fields include:
%       - DataSamples: all possible cue-sampling scenarii
%
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing the precomputed dataset of all admissible cue
%     sequences.
%     - In analysis mode:
%     Structure containing the measure results:
%       - info_transfer_rate <1x1>: mean log-derivative of
%       integration-layer unit activations, reflecting the average
%       information transfer rate

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end


if isempty(params)

    % --- Preprocessing mode: generate cue sequences dataset --- %

    CueSamples = generateAllCueSamples();
    analysis_output.DataSamples = expandCueSamples(CueSamples);

else

    % --- Analysis mode: compute mean information transfer rate --- %

    % Compute integration-layer unit activity
    Weights = shapeParametersIntoWeights(params, Config);
    all_inputs = selectDataInfo(inputs.DataSamples, Config.inputs);
    [~, activity_z, ~] = propagateThroughANN(Weights, ...
        Config.f_activation, all_inputs);

    % Compute the effective input to each unit, accounting for biases
    biases_z = repmat(Weights.biases_z, size(activity_z, 1), 1);
    inputs_z = - log((1 ./ activity_z) - 1) + biases_z;

    % Compute the derivative of the activation function for each unit
    % For sigmoid units: f'(x) = exp(-x) / (1 + exp(x))^2
    exp_i_b = exp(- inputs_z + biases_z);
    deriv_z = exp_i_b ./ ((1 + exp_i_b) .^ 2);

    % Average log-derivative across all units and cue sequences
    analysis_output.info_transfer_rate = mean(log(deriv_z));

end
