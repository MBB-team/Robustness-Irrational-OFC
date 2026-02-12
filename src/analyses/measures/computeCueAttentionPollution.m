function analysis_output = computeCueAttentionPollution(params, Config, ~, inputs)
% Quantifies how attended and unattended cue information contribute
% differently to the value of the currently attended option.
%
% This measure characterizes how the RNN integrates attended and unattended
% attributes when computing option values. It does so by fitting a
% parametric value function to the network's choices across all possible
% cue-sampling sequences, and by explicitly separating the contribution of
% the attended attribute from that of the unattended one.
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
%       - f_fname, g_fname: VBA evolution and observation functions
%       - options: VBA options, priors, and observation parameters
%
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing the precomputed dataset and VBA model.
%     - In analysis mode:
%     Structure containing the fitted value profiles and their gradients:
%       - value_function_attended_prob_att <6x6>: value of the attended
%       option as a function of probability and magnitude, when the
%       probability cue is the last attended cue
%       - value_function_attended_mag_att <6x6>: same as above, when the
%       magnitude cue is the last attended cue
%       - value_function_attended <5x5>: value profile of the attended
%       option as a function of its attended and unattended attributes
%       - value_function_attended_gradient_att <4x5>: discrete gradient of
%       the value profile along the attended attribute dimension
%       - value_function_attended_gradient_unatt <5x4>: discrete gradient
%       of the value profile along the unattended attribute dimension
%       - value_function_attended_gradient_diff <1x1>: difference between
%       mean attended and unattended gradients

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end

if isempty(params)

    % --- Preprocessing mode: define datasets and VBA model --- %

    % Generate all possible cue-sampling scenarii
    CueSamples = generateAllCueSamples();
    analysis_output.DataSamples = expandCueSamples(CueSamples);

    % Define VBA evolution and observation functions
    analysis_output.f_fname = [];
    analysis_output.g_fname = @VBA_fitTwoValueProfiles;

    % Initialize VBA options
    analysis_output.options = struct();

    % Define observation function parameters
    analysis_output.options.inG = struct();
    analysis_output.options.inG.n_samples = length(CueSamples.i_step);
    analysis_output.options.inG.all_prob = ...
        [NaN, unique(round(analysis_output.DataSamples.prob_left, 2))];
    analysis_output.options.inG.all_mag = ...
        [NaN, unique(round(analysis_output.DataSamples.mag_left, 2))];
    analysis_output.exclude_sequences = (analysis_output.DataSamples.i_step <= 1);

    % Define observation function output format
    analysis_output.options.inG.output_format_label = "choice";
    analysis_output.options.sources = struct("type", 1);
    analysis_output.options.updateHP = false;

    % Define VBA priors
    analysis_output.options.priors = struct();
    [mesh_mag, mesh_prob] = meshgrid(...
        [mean(analysis_output.options.inG.all_prob, "omitnan"), ...
        analysis_output.options.inG.all_prob(2:end)], ...
        [mean(analysis_output.options.inG.all_mag, "omitnan"), ...
        analysis_output.options.inG.all_mag(2:end)]);
    analysis_output.options.priors.muPhi = repmat(...
        reshape(mesh_mag .* mesh_prob, [], 1), 2, 1);

    % Define VBA model dimensions
    analysis_output.dim = struct("n", 0, "n_theta", 0, "n_phi", ...
        2 * length(analysis_output.options.inG.all_prob) * ...
        length(analysis_output.options.inG.all_mag));

    % Disable VBA verbosity and display
    analysis_output.options.verbose = false;
    analysis_output.options.DisplayWin = false;

else

    % --- Analysis mode: fit the attended value profile and compute value
    % profile gradients --- %

    if ~ isfield(inputs, "monkey_choices")

        % Compute RNN outputs over all cue-sampling scenarios
        network_inputs = selectDataInfo(inputs.DataSamples, Config.inputs);
        Weights = shapeParametersIntoWeights(params, Config);
        [~, ~, network_outputs] = propagateThroughANN(Weights, ...
            Config.f_activation, network_inputs);
        network_outputs = reshape(network_outputs, [], 1);

        % Transform RNN outputs to the attended/unattended choice frame
        if size(network_outputs, 2) == 2
            network_outputs = network_outputs(:, 1) - network_outputs(:, 2);
        end
        if Config.output_label ~= "attention"
            switch_output = ...
                (inputs.DataSamples.("option_" + Config.output_label) == 1);
            network_outputs(switch_output) = - network_outputs(switch_output);
        end
        system_choices = ones(size(network_outputs));
        system_choices(network_outputs >= 0) = 0;

    else

        % Fit monkey choices
        system_choices = reshape(inputs.monkey_choices, [], 1);
    end

    % ~ Loop through which attribute was attended last ~ %
    for last_attended_attribute = ["prob", "mag"]

        % Select trials
        if last_attended_attribute == "prob"
            attended_cue_pos = [1, 3];
        else
            attended_cue_pos = [2, 4];
        end
        select_trials = ismember(inputs.DataSamples.cue_pos, attended_cue_pos) & ...
            ~ inputs.exclude_sequences;

        % Define VBA inputs
        inputs.options.inG.prob_1 = round(...
            inputs.DataSamples.known_prob_unattended(select_trials), 2);
        inputs.options.inG.mag_1 = round(...
            inputs.DataSamples.known_mag_unattended(select_trials), 2);
        inputs.options.inG.prob_2 = round( ...
            inputs.DataSamples.known_prob_attended(select_trials), 2);
        inputs.options.inG.mag_2 = round( ...
            inputs.DataSamples.known_mag_attended(select_trials), 2);
        inputs.options.inG.n_samples = sum(select_trials);
        inputs.options.inG.exclude_sequences = inputs.exclude_sequences(select_trials);
        

        % Fit VBA model
        [posterior, ~] = VBA_NLStateSpaceModel(...
            system_choices(select_trials), [], ...
            inputs.f_fname, inputs.g_fname, inputs.dim, inputs.options);
    
        % Store the value function for the attended option
        value_function_attended = reshape(posterior.muPhi(37:end), 6, 6);

        % Store it
        analysis_output.("value_function_attended_" + last_attended_attribute + "_att") = ...
            value_function_attended;
    end

    % --- Compute and analyse the value function of the attended option as
    % a function of its attended and unattended attributes --- %

    % Combine value functions
    analysis_output.value_function_attended = ...
        (analysis_output.value_function_attended_prob_att + ...
        analysis_output.value_function_attended_prob_att') / 2;

    % Only select cases when both attributes are known
    analysis_output.value_function_attended = ...
        analysis_output.value_function_attended(2:end, 2:end);

    % Difference between consecutive lines: discrete gradient with respect
    % to the attended attribute
    analysis_output.value_function_attended_gradient_att = ...
        analysis_output.value_function_attended(2:end, :) - ...
        analysis_output.value_function_attended(1:(end- 1), :);

    % Difference between consecutive columns: discrete gradient with respect
    % to the unattended attribute
    analysis_output.value_function_attended_gradient_unatt = ...
        analysis_output.value_function_attended(:, 2:end) - ...
        analysis_output.value_function_attended(:, 1:(end- 1));

    % Difference between mean gradients (attended - unattended attribute)
    analysis_output.value_function_attended_gradient_diff = ...
        mean(analysis_output.value_function_attended_gradient_att, "all") - ...
        mean(analysis_output.value_function_attended_gradient_unatt, "all");

end
