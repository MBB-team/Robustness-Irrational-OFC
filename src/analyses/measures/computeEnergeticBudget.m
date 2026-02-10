function analysis_output = computeEnergeticBudget(params, Config, ~, inputs)
% Computes an the average magnitude of integration-layer unit activity
% across all cue-sampling scenarii.
%
% This measure provides a simple proxy for the RNN's energy expenditure.
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
%       - energetic_budget <4x1>: mean integration-layer activity across
%       all cue sequences, separately for each sampling step
%       - energetic_budget_avg <1>: mean integration-layer activity
%       averaged across all cue sequences and sampling steps

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

    % --- Analysis mode: compute mean integration-layer unit firing rate --- %

    % Compute integration-layer unit activity
    Weights = shapeParametersIntoWeights(params, Config);
    all_inputs = selectDataInfo(inputs.DataSamples, Config.inputs);
    [~, activity_z, ~] = propagateThroughANN(Weights, ...
        Config.f_activation, all_inputs);

    % Compute the global energetic budget as the mean (absolute) unit activity
    analysis_output.energetic_budget_avg = mean(abs(activity_z), "all");

    % Compute step-wise energetic budget (averaged across units and trials)
    analysis_output.energetic_budget = NaN(4, 1);
    for step = 1:4
        analysis_output.energetic_budget(step) = mean(abs(activity_z(step:4:end, :)));
    end
end
