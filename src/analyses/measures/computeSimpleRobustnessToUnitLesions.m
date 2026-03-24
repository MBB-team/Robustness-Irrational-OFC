function analysis_output = computeSimpleRobustnessToUnitLesions(params, ...
    Config, ~, inputs)
% Quantifies the robustness of an RNN to lesions of one unit in the
% integration layer.
%
% This function is similar to computeRobustnessToUnitLesions, but
% reduces its computational cost to make it compatible with training under
% joint optimization: network behaviour is evaluated for one-unit lesions
% only, and only in comparison to the optimal behaviour.
%
% INPUTS ------------------------------------------------------------------
% params : <float Px1> | []
%     Vector of RNN parameters. If empty, the function runs in
%     preprocessing mode and returns the analysis inputs instead of
%     computing measures.
%
% Config : <struct 1x1>
%     Configuration structure defining the RNN architecture. Can have an
%     optional additional field, n_units_z_lesion, which defines the
%     maximum number of integration-layer units to lesion. If non-existent,
%     n_units_z_lesion = n_units_z.
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
%       - prop_optimal_impaired_one_unit <1x1>: mean proportion of optimal
%       choices when 1 unit is lesioned
%       - prop_optimal_impaired_one_unit_reversed <1x1>: 
%       '1 - prop_optimal_impaired_one_unit', so that the function's output
%       can readily be optimize toward 0 during RNN training with
%       constraints (see also: trainModelsInitialRationalConstrained).

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

    % Define the maximum number of units to lesion
    if ~ isfield(Config, "n_units_z_lesion")
        Config.n_units_z_lesion = Config.n_units_z;
    end

    % Generate all possible combinations of n impaired units
    all_impaired = 1:Config.n_units_z;
    all_impaired = all_impaired';
    n_comb = size(all_impaired, 1);

    % Initialize storage of choice proportions across combinations
    prop_optimal = NaN(n_comb, 1);

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
    end

     % Average across all combinations of impaired units
    analysis_output.prop_optimal_impaired_one_unit = mean(prop_optimal);
    analysis_output.prop_optimal_impaired_one_unit_reversed = ...
        1 - analysis_output.prop_optimal_impaired_one_unit;
    
end
