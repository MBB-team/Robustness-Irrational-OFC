function analysis_output = computeRobustnessToInternalNoise(params, ...
    Config, ~, inputs)
% Quantifies the robustness of an RNN to internal neural noise.
%
% This measure evaluates how the network's choices degrade when neural
% noise is added on its integration units. For different levels of noise
% magnitude (varaince = 0.001, 0.005, 0.01, 0.05, 0.1, 0.5), the
% function computes:
%   (1) The mean proportion of rational (optimal) choices
%   (2) The mean proportion of choices consistent with the unlesioned
%       network
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
%     sequences and random noise to be added to the integration units.
%     - In analysis mode:
%     Structure containing the measure results:
%       - prop_optimal_noise <Nx1>: mean proportion of optimal choices when
%       noise with variance 0.001, 0.05, ..., 0.5 is added
%       - avg_prop_optimal_noise <1x1>: proportion of optimal choices
%       averaged across all levels of noise variance
%       - prop_consistent_noise <Nx1>: mean proportion of choices
%       consistent with the network without noise when noise with varaince 
%       0.001, 0.005, ..., 0.5 is added
%       - avg_prop_consistent_noise <1x1>: proportion of consistent choices
%       averaged across all levels of noise variance

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end

if isempty(params)

    rng(0);

    % --- Preprocessing mode: generate cue sequences dataset and random
    % noise --- %

    % Generate all admisible cue sequences
    CueSamples = generateAllCueSamples();
    analysis_output.DataSamples = expandCueSamples(CueSamples);
    n_samples = length(CueSamples.i_step);

    % Define noise levels
    VAR_NOISE = [0.001, 0.005, 0.01, 0.05, 0.1, 0.5];
    n_noise_level = length(VAR_NOISE);
    
    % Initialize storage for internal noise
    analysis_output.noise = cell(n_noise_level, 1);

    % Randomly generate noise for each variance level
    N_SIMU = 50;
    N_UNITS_Z = 10;
    for i_noise_level = 1:n_noise_level
        analysis_output.noise{i_noise_level} = sqrt(VAR_NOISE(i_noise_level)) * ...
            randn(n_samples, N_UNITS_Z, N_SIMU);
    end

else

    % --- Analysis mode: compute network robustness to internal noise --- %

    % Prepare the computation of RNN behaviour
    all_inputs = selectDataInfo(inputs.DataSamples, Config.inputs);
    Weights = shapeParametersIntoWeights(params, Config);

    % Select rational (optimal) choices in the RNN's output frame
    rational_choice = inputs.DataSamples.("choice_" + Config.output_label);
    rational_choice = rational_choice';

    % Compute choices of the RNN without noise
    [~, ~, nonoise_choice] = propagateThroughANN(Weights, ...
        Config.f_activation, all_inputs);
    if size(nonoise_choice, 2) == 2
        nonoise_choice = nonoise_choice(:, 1) - nonoise_choice(:, 2);
    end
    nonoise_choice(nonoise_choice >= 0) = 0;
    nonoise_choice(nonoise_choice < 0) = 1;

    % Initialize results storage
    n_lesion_level = length(inputs.noise);
    analysis_output.prop_optimal_noise = NaN(n_lesion_level, 1);
    analysis_output.prop_consistent_noise = NaN(n_lesion_level, 1);

    % ~ Loop over the lesion proportions ~ %
    for i_noise_level = 1:n_lesion_level

        n_simu = size(inputs.noise{i_noise_level}, 3);

        % Initialize storage of choice proportions across noise simulations
        prop_optimal = NaN(n_simu, 1);
        prop_consistent = NaN(n_simu, 1);

        % ~ Loop through noise simulations ~ %
        for i_simu = 1:n_simu

            % Compute RNN output with the selected impaired connections
            [~, ~, choice] = propagateThroughANN(Weights, ...
                Config.f_activation, ...
                all_inputs, ...
                noise_z=inputs.noise{i_noise_level}(:, :, i_simu));

            % Convert network output to binary choices
            if size(choice, 2) == 2
                choice = choice(:, 1) - choice(:, 2);
            end
            choice(choice >= 0) = 0;
            choice(choice < 0) = 1;

            % Compute proportion of optimal choices
            prop_optimal(i_simu) = mean(choice == rational_choice);
            % Compute proportion of choices consistent with the unlesioned RNN
            prop_consistent(i_simu) = mean(choice == nonoise_choice);
        end

         % Average across all combinations of impaired units
        analysis_output.prop_optimal_noise(i_noise_level) = mean(prop_optimal);
        analysis_output.prop_consistent_noise(i_noise_level) = mean(prop_consistent);
    end

    % Average across all noise variance levels
    analysis_output.avg_prop_optimal_noise = mean(analysis_output.prop_optimal_noise);
    analysis_output.avg_prop_consistent_noise = mean(analysis_output.prop_consistent_noise);

end
