function analysis_output = fitOneValueProfile(params, Config, seed, inputs)
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
%     Structure containing variables precomputed during preprocessing and
%     additional metadata. Required only in analysis mode. Fields include:
%       - folder_name: name of the folder containing initial training 
%       specifications, such as the test dataset
%       - f_fname, g_fname: VBA evolution and observation functions
%       - options: VBA options, priors, and observation parameters
%       
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing the VBA model.
%     - In analysis mode:
%     Structure containing the result of the value profile fit:
%       - value_function <6x6>: fitted option value profile
%       - value_function_R2 <1x1>: variance explained by the value profile

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    seed (1,1) double = 0
    inputs (1,1) struct = struct()
end

if isempty(params)

    % --- Preprocessing mode: define datasets and VBA model --- %

    % Define VBA evolution and observation functions
    analysis_output.f_fname = [];
    analysis_output.g_fname = @VBA_fitOneValueProfile;

    % Initialize VBA options
    analysis_output.options = struct();

    % Define observation function parameters
    analysis_output.options.inG = struct();
    analysis_output.options.inG.all_prob = ...
        [NaN, unique(round(0.1:0.2:0.9, 2))];
    analysis_output.options.inG.all_mag = ...
        [NaN, unique(round(0.1:0.2:0.9, 2))];

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

    if ~ isfield(inputs, "monkey_choices")
        % Load a subset of possible cue sequences
        path_specs = fullfile(getPath("ModelsRaw"), inputs.folder_name, ...
            "_DatasetSpecs.mat");
        DatasetSpecs = generateTrainTestDataset(path_specs, false);
        DataSamples = expandCueSamples(DatasetSpecs.CueDatasetTest{seed});
    end

    % --- Define the VBA model --- %

    % Define VBA model observations
    if ~ isfield(inputs, "monkey_choices")
        % Compute RNN outputs over all cue-sampling scenarios
        network_inputs = selectDataInfo(DataSamples, Config.inputs);
        Weights = shapeParametersIntoWeights(params, Config);
        [~, ~, network_outputs] = propagateThroughANN(Weights, ...
            Config.f_activation, network_inputs);
        system_outputs = reshape(network_outputs, [], 1);
    else
        % Fit monkey choices
        system_outputs = reshape(inputs.monkey_choices, [], 1);
    end

    % Define VBA model inputs
    if ~ isfield(inputs, "monkey_choices")
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
    else
        % Use the left/right convention
        option_1 = "left";
        option_2 = "right";
        % Predict binary outputs
        inputs.options.inG.output_format_label = "choice";
        inputs.options.sources = struct("type", 1);
        inputs.options.updateHP = false;
    end
    inputs.options.inG.prob_1 = DataSamples.("known_prob_" + option_1);
    inputs.options.inG.mag_1 = DataSamples.("known_mag_" + option_1);
    inputs.options.inG.prob_2 = DataSamples.("known_prob_" + option_2);
    inputs.options.inG.mag_2 = DataSamples.("known_mag_" + option_2);

    % Fit the value profile
    [posterior, out] = VBA_NLStateSpaceModel(system_outputs, [], ...
        inputs.f_fname, inputs.g_fname, inputs.dim, inputs.options);

    % Store fitted value profile and explained variance
    analysis_output.value_function = reshape(posterior.muPhi, ...
        length(inputs.options.inG.all_prob), ...
        length(inputs.options.inG.all_mag));
    analysis_output.value_function_R2 = out.fit.R2;

end
