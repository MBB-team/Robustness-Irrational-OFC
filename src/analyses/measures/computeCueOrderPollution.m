function analysis_output = computeCueOrderPollution(params, Config, ~, inputs)
% Quantifies the sensitivity of an RNN's output to cue order.
%
% This measure isolates the influence of the order in which cues are
% presented on the RNN's decision variable, independently of the cues'
% contents. For fixed option attributes (probability and magnitude, for
% both options), the function compares the RNN outputs obtained for all
% possible permutations of cue order.
%
% The analysis proceeds in three steps:
%   (1) Identify groups of cue sequences that share the same underlying
%       option attributes, trial type, and sampling step within the trial,
%       but differ only in cue order.
%   (2) For each such group, compute the standard deviation of the RNN
%       output across cue-order permutations. This variability reflects
%       sensitivity to cue order for a fixed informational content.
%   (3) Average this variability across trial types (option vs. attribute)
%       and trial steps to obtain summary indices of cue order pollution.
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
%       - DataSamples: all possible cue-sampling scenarios
%       - all_att_values: cell array listing all possible values for each
%       option attribute
%       - n_att: number of possible values per attribute
%       - n_sequences_per_step: number of possible cue sequences of fixed
%       length
%               
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing the precomputed dataset and VBA model.
%     - In analysis mode:
%     Structure containing the variance of the RNN outputs on different
%     trial subsets:
%       - std_order_option_per_step <3x1>: mean standard deviation of the
%       RNN output across cue orders at sampling steps 2, 3 and 4,
%       restricted to option trials
%       - std_order_attribute_per_step <3x1>: same as above, restricted to
%       attribute trials
%       - std_order_option <1x1>: mean standard deviation across all
%       sapling steps for option trials
%       - std_order_attribute <1x1>: same as above, for attribute trials
%       - std_order_per_step <3x1>: mean standard deviation across cue
%       orders at each sampling step, pooling option and attribute trials
%       - std_order <1x1>: overall mean standard deviation across all trial
%       types and sampling steps

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end

if isempty(params)

    % --- Preprocessing mode: define dataset --- %

    % Generate all possible cue-sampling scenarii
    CueSamples = generateAllCueSamples();
    analysis_output.DataSamples = expandCueSamples(CueSamples);

    % Number of cue sequences per sampling step
    analysis_output.n_sequences_per_step = ...
        round(length(CueSamples.i_step) / max(CueSamples.i_step));

    % Define all possible attribute values (probability and magnitude)
    all_prob = [NaN, unique(DataSamples.prob_left)];
    all_mag = [NaN, unique(DataSamples.mag_left)];
    analysis_output.n_att = length(all_mag);

    % Group attribute values for the four option attribues
    analysis_output.all_att_values = {all_prob, all_mag, all_prob, all_mag};

else

    % --- Analysis mode: compute cue order pollution metrics --- %

    % Define attribute fields according to the RNN output format
    switch Config.output_format
        case "loc"
            option_labels = ["left", "right"];
        case "order"
            option_labels = ["first", "second"];
        case "attention"
            option_labels = ["attended", "unattended"];
    end
    all_att_fields = "known_" + ...
        reshape(compose(["prob_%s", "mag_%s"], repelem(option_labels, 2, 1)')', 1, []);

    % --- Group cue sequences that differ only in order --- %

    % Each column of cue_sequence_IDs indexes all cue permutations sharing:
    %   (i) the same option attributes,
    %   (ii) the same trial type,
    %   (iii) the same sampling step
    cue_sequence_IDs = NaN(inputs.n_sequences_per_step, ...
        2 * (inputs.n_att ^ 4) *sum(factorial(2:4)));
    trial_type_col = strings(1, 2 * (inputs.n_att ^ 4) *sum(factorial(2:4)));
    i_step_col = NaN(1, 2 * (inputs.n_att ^ 4) *sum(factorial(2:4)));

    i_sequence = 1;

    % ~ Loop over trial types ~ %
    for trial_type = ["option", "attribute"]

        select_trial_type = (inputs.DataSamples.trial_type == trial_type);

        % ~ Loop over sampling steps ~ %
        for trial_step = 2:4

            select_step = inputs.DataSamples.i_step == trial_step;

            % ~ Loop over all combinations of option attributes ~ %
            for i_prob = 1:inputs.n_att
                for i_mag = 1:inputs.n_att
                    for j_prob = 1:inputs.n_att
                        for j_mag = 1:inputs.n_att

                            all_i_att = [i_prob, i_mag, j_prob, j_mag];

                            % Select trials matching this attribute configuration
                            select_attribute_pair = true(size(inputs.DataSamples.i_step));
                            for i_att = 1:length(all_i_att)
                                if ~ isnan(all_i_att(i_att))
                                    select_attribute_pair = select_attribute_pair & ...
                                        (inputs.DataSamples.(all_att_fields(i_att)) == ...
                                        inputs.all_att_values{i_att}(all_i_att(i_att)));
                                else
                                    select_attribute_pair = select_attribute_pair & ...
                                        isnan(inputs.DataSamples.(all_att_fields(i_att)));
                                end
                            end

                            % Select all cue permutations for this configuration
                            all_i_perm = find(select_trial_type & select_step & select_attribute_pair);

                            % Store the cue sequences and their information
                            if ~ isempty(all_i_perm) && length(all_i_perm) > 1

                                cue_sequence_IDs(1:length(all_i_perm), i_sequence) = all_i_perm;
                                trial_type_col(i_sequence) = trial_type;
                                i_step_col(i_sequence) = trial_step;

                                % Update the sequence index
                                i_sequence = i_sequence + 1;
                            end

                        end
                    end
                end
            end

            % Remove empty rows and columns
            is_nan_row = ~ any(~ isnan(cue_sequence_IDs), 2);
            is_nan_col = ~ any(~ isnan(cue_sequence_IDs), 1);
            cue_sequence_IDs(is_nan_row, :) = [];
            cue_sequence_IDs(:, is_nan_col) = [];
            trial_type_col(is_nan_col) = [];
            i_step_col(is_nan_col) = [];
        end
    end

    % --- Compute RNN outputs in a decision-variable frame --- %

    % Compute RNN outputs for all cue sequences
    input = selectDataInfo(inputs.DataSamples, Config.inputs);
    Weights = shapeParametersIntoWeights(params, Config);
    [~, ~, network_output] = propagateThroughANN(Weights, ...
        Config.f_activation, input);

    % Convert to value difference if required
    if Config.output_format_label == "both"
        network_output = network_output(:, 1) - network_output(:, 2);
    end

    % --- Compute output variability across cue order permutations --- %

    std_per_cue_sequence_config = NaN(size(cue_sequence_IDs, 2));

    for i_col = 1:size(cue_sequence_IDs, 2)

        % Select all cue sequence permutations
        cue_sequence_perm_IDs = cue_sequence_IDs(:, i_col);
        cue_sequence_perm_IDs = cue_sequence_perm_IDs(~ isnan(cue_sequence_perm_IDs));

        % Compute the standard deviation of the RNN output across sequence order
        std_per_cue_sequence_config(i_col) = std(network_output(cue_sequence_perm_IDs), 1);
    end
    

    % --- Average variability across trial types and sampling steps --- %

    % Initialize output
    analysis_output = struct();

    for trial_type = ["option", "attribute", "both"]

        if trial_type == "both"
            select_trial_type = true(size(trial_type_col));
            output_field = "std_order";
        else
            select_trial_type = (trial_type_col == trial_type);
            output_field = "std_order_" + trial_type;
        end

        for trial_step = [0, 2:4]

            % Initialize output storage
            if trial_step == 0
                select_step = true(size(i_step_col));
                analysis_output.(output_field) = NaN();
            else
                select_step = (i_step_col == trial_step);
                if ~ contains(output_field, "_per_step")
                    output_field = output_field + "_per_step";
                    analysis_output.(output_field) = NaN(3, 1);
                end
            end

            % Select cue sequence columns
            select_cue_sequence_col = select_trial_type & select_step;

            % Compute the mean standard deviation
            if trial_step == 0
                analysis_output.(output_field) = mean(...
                    std_per_cue_sequence_config(select_cue_sequence_col));
            else
                analysis_output.(output_field)(trial_step - 1) = mean(...
                    std_per_cue_sequence_config(select_cue_sequence_col));
            end

        end
    end
end
