function analysis_output = fitUniqueValueProfile(params, Config, ~, inputs)
% Fits a shared option value function V(p, m) to the behaviour of an RNN.
%
% This measure fits a value function that maps an option’s probability p
% and magnitude m to a scalar value, assuming the same mapping applies to
% both options. It returns the fitted value function and the proportion of
% variance in the RNN outputs explained by this model.
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
%     Structure containing the result of the value profile fit:
%       - value_function <6x6>: fitted option value profile
%       - value_function_R2 <1x1>: variance explained by the value profile

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
    analysis_output.g_fname = @VBA_fitUniqueValueProfile;

    % Initialize VBA options
    analysis_output.options = struct();

    % Define observation function parameters
    analysis_output.options.inG = struct();
    analysis_output.options.inG.n_samples = length(CueSamples.i_step);
    analysis_output.options.inG.all_prob = ...
        [NaN, unique(round(analysis_output.DataSamples.prob_left, 2))];
    analysis_output.options.inG.all_mag = ...
        [NaN, unique(round(analysis_output.DataSamples.mag_left, 2))];

    % Define VBA priors
    analysis_output.options.priors = struct();
    [mesh_mag, mesh_prob] = meshgrid(...
        [mean(analysis_output.options.inG.all_prob, "omitnan"), ...
        analysis_output.options.inG.all_prob(2:end)], ...
        [mean(analysis_output.options.inG.all_mag, "omitnan"), ...
        analysis_output.options.inG.all_mag(2:end)]);
    analysis_output.options.priors.muPhi = reshape(mesh_mag .* mesh_prob, [], 1);

    % Define VBA model dimensions
    analysis_output.dim = struct("n", 0, "n_theta", 0, "n_phi", ...
        length(analysis_output.options.inG.all_prob) * ...
        length(analysis_output.options.inG.all_mag));
    
    % Disable VBA verbosity and display
    analysis_output.options.verbose = false;
    analysis_output.options.DisplayWin = false;
    
else

    % --- Analysis mode: fit the value profile --- %

    % Compute RNN outputs over all cue-sampling scenarios
    network_inputs = selectDataInfo(inputs.DataSamples, Config.inputs);
    Weights = shapeParametersIntoWeights(params, Config);
    [~, ~, network_outputs] = propagateThroughANN(Weights, ...
        Config.f_activation, network_inputs);
    network_outputs = reshape(network_outputs, [], 1);

    % Define VBA inputs based on the RNN output convention
    inputs.options.inG.output_format_label = Config.output_format_label;
    switch Config.output_label
        case "loc"
            option_1 = "left";
            option_2 = "right";
        case "order"
            option_1 = "first";
            option_2 = "second";
        case "attention"
            option_1 = "attended";
            option_2 = "unattended";
    end
    inputs.options.inG.prob_1 = inputs.DataSamples.("known_prob_" + option_1);
    inputs.options.inG.mag_1 = inputs.DataSamples.("known_mag_" + option_1);
    inputs.options.inG.prob_2 = inputs.DataSamples.("known_prob_" + option_2);
    inputs.options.inG.mag_2 = inputs.DataSamples.("known_mag_" + option_2);

    % Fit the value profile
    [posterior, out] = VBA_NLStateSpaceModel(network_outputs, [], ...
        inputs.f_fname, inputs.g_fname, inputs.dim, inputs.options);

    % Store fitted value profile and explained variance
    analysis_output.value_function = reshape(posterior.muPhi, ...
        length(inputs.all_prob), length(inputs.all_mag));
    analysis_output.value_function_R2 = out.fit.R2;

end

function output = VBA_fitUniqueValueProfile(~, P, ~, in)
% Predicts RNN outputs from a shared option value function V(p, m).
%
% This observation function maps each option's curerntly estimated
% probability and magnitude onto a scalar value using a shared value
% function, and converts these values into predicted RNN outputs according
% to the specified output format.
%
% INPUTS ------------------------------------------------------------------
% P : <float Px1>
%     Vectorized value profile.
%
% in : <struct 1x1>
%     Structure defining the attribute space and trial-wise attributes:
%       - n_samples: number of cue samples
%       - all_prob, all_mag: discrete attribute grids (including NaN)
%       - prob_1, mag_1, prob_2, mag_2: option attributes per cue sample
%       - output_format_label: RNN output format
%
% OUTPUTS -----------------------------------------------------------------
% output : <float Nx1>
%     Vector of predicted RNN outputs.

arguments
    ~
    P (:, 1) double
    ~
    in (1, 1) struct
end

% Shape the value function
value_function = reshape(P, 6, 6);

value_1 = NaN(in.n_samples, 1);
value_2 = NaN(in.n_samples, 1);

% ~ Loop through attribute pair ~ %
for i_prob = 1:length(in.all_prob)
    prob = in.all_prob(i_prob);
    for i_mag = 1:length(in.all_mag)
        mag = in.all_mag(i_mag);

        % Select trials where the option 1 (resp. 2) have this pair
        % of attributes
        if isnan(prob)
            select_1 = isnan(in.prob_1);
            select_2 = isnan(in.prob_2);
        else
            select_1 = in.prob_1 == prob;
            select_2 = in.prob_2 == prob;
        end
        if isnan(mag)
            select_1 = select_1 & isnan(in.mag_1);
            select_2 = select_2 & isnan(in.mag_2);
        else
            select_1 = select_1 & (in.mag_1 == mag);
            select_2 = select_2 & (in.mag_2 == mag);
        end

        % Map attribute pairs to option values
        value_1(select_1) = value_function(i_prob, i_mag);
        value_2(select_2) = value_function(i_prob, i_mag);
    end
end

% Conver the values to value difference or choice probabilities if needed
switch in.output_format_label
    case "both"
        output = reshape([value_1, value_2], [], 1);
    case "diff"
        output = value_1 - value_2;
    case "choice"
        output = sigANN(value_1 - value_2, 0);
end
