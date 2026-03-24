function analysis_output = computeRobustnessToConnectionLesions(params, ...
    Config, ~, inputs)
% Quantifies the robustness of an RNN to lesions of forward and recurrent
% connections.
%
% This measure evaluates how the network's choices degrade when a subset of
% recurrent connections is randomly lesioned (set to zero). For different
% proportions of lesioned connections (10%, 20%, ..., 100%), the function
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
%     sequences and random recurrent connection subsets.
%     - In analysis mode:
%     Structure containing the measure results:
%       - prop_optimal_impaired_connec <Nx1>: mean proportion of optimal
%       choices when 10%, 20%, ..., 100% recurrent connections are lesioned
%       - avg_prop_optimal_impaired_connec <1>1: proportion of optimal
%       choices averaged between 10 and 50% of lesioned connections
%       - prop_consistent_impaired_connec <Nx1>: mean proportion of choices
%       consistent with the unlesioned network when 10%, 20%, ..., 100% 
%       recurrent connections are lesioned
%       - avg_prop_consistent_impaired_connec <1>1: proportion of
%       consistent choices averaged between 10 and 50% of lesioned
%       connections

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end

if isempty(params)

    rng(0);

    % --- Preprocessing mode: generate cue sequences dataset and random
    % recurrent connection subsets --- %

    % Generate all admisible cue sequences
    CueSamples = generateAllCueSamples();
    analysis_output.DataSamples = expandCueSamples(CueSamples);

    % Define the size of connection subsets to lesion. If RNNs have varying
    % numbers of recurrent connections, this block and the followings
    % should be moved to the analysis mode.
    N_UNITS_X = 9;
    N_UNITS_Z = 10;
    n_connections_forward = N_UNITS_X * N_UNITS_Z;
    n_connections_recur = N_UNITS_Z * N_UNITS_Z;
    N_COMB = 100;
    ALL_PROP_LESION = linspace(10, 100, 10) / 100;
    all_n_lesioned_forward_connec = round(n_connections_forward * ALL_PROP_LESION);
    all_n_lesioned_recur_connec = round(n_connections_recur * ALL_PROP_LESION);
    n_lesion_level = length(ALL_PROP_LESION);
    
    % Initialize storage for connection subsets
    analysis_output.forward_connec_subset = cell(n_lesion_level, 1);
    analysis_output.recur_connec_subset = cell(n_lesion_level, 1);

    % Randomly select recurrent connections for each lesion level
    for i_lesion_level = 1:n_lesion_level
        n_lesioned_forward_connec = all_n_lesioned_forward_connec(i_lesion_level);
        n_lesioned_recur_connec = all_n_lesioned_recur_connec(i_lesion_level);
        analysis_output.forward_connec_subset{i_lesion_level} = NaN(N_COMB, n_lesioned_forward_connec);
        analysis_output.recur_connec_subset{i_lesion_level} = NaN(N_COMB, n_lesioned_recur_connec);
        for i_comb = 1:N_COMB
            % Randomly pick connections to lesion
            all_i_forward_lesioned = randperm(n_connections_forward, n_lesioned_forward_connec);
            all_i_recur_lesioned = randperm(n_connections_recur, n_lesioned_recur_connec);
            analysis_output.forward_connec_subset{i_lesion_level}(i_comb, :) = all_i_forward_lesioned;
            analysis_output.recur_connec_subset{i_lesion_level}(i_comb, :) = all_i_recur_lesioned;
        end
    end

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
    n_lesion_level = length(inputs.recur_connec_subset);
    analysis_output.prop_optimal_impaired_connec = NaN(n_lesion_level, 1);
    analysis_output.prop_consistent_impaired_connec = NaN(n_lesion_level, 1);

    % ~ Loop over the lesion proportions ~ %
    for i_lesion_level = 1:n_lesion_level

        n_comb = size(inputs.recur_connec_subset{i_lesion_level}, 1);

        % Initialize storage of choice proportions across combinations
        prop_optimal = NaN(n_comb, 1);
        prop_consistent = NaN(n_comb, 1);

        % ~ Loop through combinations of lesioned connections ~ %
        for i_comb = 1:n_comb

            % Remove recurrent connections
            WeightsLesioned = Weights;
            WeightsLesioned.connect_x_to_z(...
                inputs.forward_connec_subset{i_lesion_level}(i_comb, :)) = 0;
            WeightsLesioned.connect_z_to_z(...
                inputs.recur_connec_subset{i_lesion_level}(i_comb, :)) = 0;

            % Compute RNN output with the selected impaired connections
            [~, ~, choice] = propagateThroughANN(WeightsLesioned, ...
                Config.f_activation, ...
                all_inputs);

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
        analysis_output.prop_optimal_impaired_connec(i_lesion_level) = mean(prop_optimal);
        analysis_output.prop_consistent_impaired_connec(i_lesion_level) = mean(prop_consistent);
    end

    % Average between 10% and 50% of lesions
    analysis_output.avg_prop_optimal_impaired_connec = ...
        mean(analysis_output.prop_optimal_impaired_connec(1:5));
    analysis_output.avg_prop_consistent_impaired_connec = ...
        mean(analysis_output.prop_consistent_impaired_connec(1:5));
end
