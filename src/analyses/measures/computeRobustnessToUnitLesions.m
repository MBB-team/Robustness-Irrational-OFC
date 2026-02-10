function analysis_output = computeRobustnessToUnitLesions(params, ...
    Config, ~, inputs)
% Quantifies the robustness of an RNN to lesions of units in the
% integration layer.
%
% This measure evaluates how the network's choices degrade when a subset
% of integration-layer units is artificially lesioned (silenced). For each
% possible number of lesioned units (from 1 to all units), the function
% computes:
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
%     sequences.
%     - In analysis mode:
%     Structure containing the measure results:
%       - prop_optimal_impaired_units <Nx1>: mean proportion of optimal
%       choices when 1, 2, ..., N integration-layer units are lesioned
%       - prop_consistent_impaired_units <Nx1>: mean proportion of choices
%       consistent with the unlesioned network when 1, 2, ..., N units are
%       lesioned

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

    % --- Analysis mode: compute network robustness to lesions --- %

    % Prepare the computation of RNN behaviour
    all_inputs = selectDataInfo(inputs.DataSamples, Config.inputs);
    Weights = shapeParametersIntoWeights(params, Config);

    % Select rational (optimal) choices in the RNN's output frame
    rational_choice = inputs.DataSamples.("choice_" + Config.output_label);
    rational_choice = rational_choice';

    % Compute choices of the unlesioned RNN
    [~, ~, unimpaired_choice] = propagateThroughANN(Weights, ...
        Config.f_activation, all_inputs);
    if size(unimpaired_choice, 2) == 2
        unimpaired_choice = unimpaired_choice(:, 1) - unimpaired_choice(:, 2);
    end
    unimpaired_choice(unimpaired_choice >= 0) = 0;
    unimpaired_choice(unimpaired_choice < 0) = 1;

    % Initialize results storage
    analysis_output.prop_optimal_impaired_units = NaN(Config.n_units_z, 1);
    analysis_output.prop_consistent_impaired_units = NaN(Config.n_units_z, 1);

    % ~ Loop over the number of impaired units ~ %
    for n_impaired = 1:Config.n_units_z

        % Generate all possible combinations of n impaired units
        all_impaired = nchoosek(1:Config.n_units_z, n_impaired);
        n_comb = size(all_impaired, 1);

        % Initialize storage of choice proportions across combinations
        prop_optimal = NaN(n_comb, 1);
        prop_consistent = NaN(n_comb, 1);

        % ~ Loop through combinations of impaired units ~ %
        for i_comb = 1:n_comb

            % Compute RNN output with the selected impaired units
            [~, ~, choice] = propagateThroughANN(Weights, ...
                Config.f_activation, ...
                all_inputs, ...
                impaired_z=all_impaired(i_comb, :));

            % Convert network output to binary choices
            if size(choice, 2) == 2
                choice = choice(:, 1) - choice(:, 2);
            end
            choice(choice >= 0) = 0;
            choice(choice < 0) = 1;

            % Compute proportion of optimal choices
            prop_optimal(i_comb) = mean(choice == rational_choice);
            % Compute proportion of choices consistent with the unlesioned RNN
            prop_consistent(i_comb) = mean(choice == unimpaired_choice);
        end

         % Average across all combinations of impaired units
        analysis_output.prop_optimal_impaired_units(n_impaired) = mean(prop_optimal);
        analysis_output.prop_consistent_impaired_units(n_impaired) = mean(prop_consistent);
    end
end
