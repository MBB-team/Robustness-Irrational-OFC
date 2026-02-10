function analysis_output = computeCodeRedundancy(params, Config, ~, inputs)
% Quantifies the redundancy of integration-layer activations in an RNN.
%
% This measure computes the average co-activation probability between
% units, capturing the extent to which multiple units respond to the same
% cues. For each activation percentile threshold, the measure checks which
% units are active and computes the probability that two units are
% simultaneously active. The final redundancy measure is the mean
% co-activation probability across all percentiles.
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
%     Structure containing the measure result:
%       - code_redundancy <1x1>: mean co-activation probability across
%       units, cue sequences, and activation thresholds

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

    % --- Analysis mode: compute co-activtation probability --- %
    
    % Compute integration-layer unit activity
    all_inputs = selectDataInfo(inputs.DataSamples, Config.inputs);
    Weights = shapeParametersIntoWeights(params, Config);
    [~, activity_z, ~] = propagateThroughANN(Weights, Config.f_activation, all_inputs);
    
    % --- Compute co-activation probabilities across activation thresholds --- %

    % Compute the normalization factor for the co-activation probabilities
    n_neurons = size(activity_z, 2);
    norm_factor = 1 / (n_neurons * (n_neurons - 1));

    % Define the vector of activity percentile thresholds
    all_perc = 0:100;
    n_perc = length(all_perc);

    % Compute the absolute activation threshold for each neuron depending
    % on the percentile
    activity_threshold = prctile(activity_z, all_perc, 1);

    % Initialize the storage of co-activation probabilities
    all_prob_co_act = NaN(1, n_perc);

    % ~ Loop through percentiles thresholds ~ %
    for i_perc = 1:n_perc

        % Determine which units are active for the current threshold
        is_activated = (activity_z > activity_threshold(i_perc, :));

        % Compute co-activation: number of active unit pairs per cue sequence
        n_activated = sum(is_activated, 2);
        prob_co_act = n_activated .* (n_activated - 1);

        % Average over all cue sequences and normalize
        all_prob_co_act(i_perc) = norm_factor * mean(prob_co_act);
    end

    % Compute the mean co-activation probability across all percentiles
    analysis_output.code_redundancy = mean(all_prob_co_act);

end
