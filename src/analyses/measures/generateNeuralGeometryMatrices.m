function analysis_output = generateNeuralGeometryMatrices(params, Config, ~, inputs)
% Generate neural geometry matrices and measures (RDM, CPD and CCM) for a
% given RNN.
%
% This measure implements the neural geometry analyses presented in Hunt
% et al. (2018). It characterizes how an RNN encodes cue information by
% combining three complementary analyses:
%   1) Representational Dissimilarity Matrices (RDMs) computed from
%   population activity patterns,
%   2) Coefficients of Partial Determination (CPDs) quantifying the
%   contribution of task-relevant factors to the RDM,
%   3) Cross-Correlation Matrices (CCMs) capturing the temporal structure
%   of cue-rank encoding across the population.
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
%     Structure containing all variables precomputed during preprocessing.
%     Required only in analysis mode. Fields include:
%       - DataSamplesRDM: structure describing all single-cue sampling
%       sequences
%       - DataSamplesCCM: structure describing all three-cue sampling
%       sequences
%       - select_option_samples: vector selecting option trials within the
%       CCM sampling sequences
%       - select_attribute_samples: vector selecting attribute trials
%       within the CCM sampling sequences
%       - CCM_regress_option: regression matrix for the option trials
%       within the CCM sampling sequences
%       - CCM_regress_attribute: regression matrix for the attribute trials
%       within the CCM sampling sequences
%
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing all precomputed datasets and regression matrices
%     needed for the analysis.
%     - In analysis mode:
%      Structure containing the neural geometry measures:
%           - RDM <20x20>: Representational Dissimilarity Matrix containing
%           pairwise correlations of neural activity across all inputs
%           - CPD <1x5>: Coefficients of Partial Determination quantifying
%           the contribution of each feature to the RDM
%           - CCM_option <9x9>: Cross-Correlation Matrix of unit
%           sensitivities to cue ranks on option trials (see also:
%           computeCCM)
%           - CCM_option_p <9x9>: p-values associated with each entry in
%           CCM_option
%           - CCM_attribute <9x9>: Cross-Correlation Matrix of unit
%           sensitivities to cue ranks on attribute trials
%           - CCM_attribute_p <9x9>: p-values associated with each entry in
%           CCM_attribute

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end

if isempty(params)

    % --- Preprocessing mode: generate datasets and regression matrices --- %

    % Generate cue-sampling scenarii for RDM and CCM analyses
    CueSamplesRDM = generateRDMcueSamples();
    CueSamplesCCM = generateCCMcueSamples();
    DataSamplesRDM = expandCueSamples(CueSamplesRDM);
    DataSamplesCCM = expandCueSamples(CueSamplesCCM);
    
    % Identify option and attribute trials in the CCM dataset
    select_option_samples = DataSamplesCCM.trial_type == "option";
    select_attribute_samples = DataSamplesCCM.trial_type == "attribute";
    select_option_trials = select_option_samples(1:3:end);
    select_attribute_trials = select_attribute_samples(1:3:end);
    
    % Build CCM regression matrices for each trial type
    CCM_regress_all = computeCCMregressionMatrix(DataSamplesCCM);
    CCM_regress_option = CCM_regress_all(...
        select_option_trials, :);
    CCM_regress_attribute = CCM_regress_all(...
        select_attribute_trials, :);

    % Return all precomputed inputs for the analysis stage
    analysis_output = struct(...
        "DataSamplesRDM", DataSamplesRDM, ...
        "DataSamplesCCM", DataSamplesCCM, ...
        "select_option_samples", select_option_samples, ...
        "select_attribute_samples", select_attribute_samples, ...
        "CCM_regress_option", CCM_regress_option, ...
        "CCM_regress_attribute", CCM_regress_attribute);

else

    % --- Analysis mode: compute neural geometry matrices --- %

    % Initialize output structure
    analysis_output = struct();

    % Select RDM and CCM inputs according to the RNN configuration
    inputs_RDM = selectDataInfo(inputs.DataSamplesRDM, Config.inputs);
    inputs_CCM_all = selectDataInfo(inputs.DataSamplesCCM, Config.inputs);
    inputs_CCM_option = inputs_CCM_all(inputs.select_option_samples, :);
    inputs_CCM_attribute = inputs_CCM_all(inputs.select_attribute_samples, :);

    % Reshape parameter vector into network weight matrices
    Weights = shapeParametersIntoWeights(params, Config);
            
    % --- Representational Dissimilarity Matrix (RDM) --- %

    [~, activity_RDM, ~] = propagateThroughANN(Weights, ...
        Config.f_activation, inputs_RDM, ones(1, size(inputs_RDM, 1)));
    analysis_output.RDM = corr(zscore(activity_RDM)');

    % --- Coefficients of Partial Determination (CPD) --- %

    analysis_output.CPD = computeCPD(analysis_output.RDM);

    % --- Cross-Correlation Matrices (CCM) --- %

    % Option trials
    [~, activity_CCM_option, ~] = propagateThroughANN(Weights, ...
        Config.f_activation, inputs_CCM_option, ...
        repmat(1:3, 1, size(inputs_CCM_option, 1) / 3));
    [~, analysis_output.CCM_option, analysis_output.CCM_option_p] = ...
        computeCCM(activity_CCM_option, inputs.CCM_regress_option);

    % Attribute trials
    [~, activity_CCM_attribute, ~] = propagateThroughANN(Weights, ...
        Config.f_activation, inputs_CCM_attribute, ...
        repmat(1:3, 1, size(inputs_CCM_attribute, 1) / 3));
    [~, analysis_output.CCM_attribute, analysis_output.CCM_attribute_p] = ...
        computeCCM(activity_CCM_attribute, inputs.CCM_regress_attribute);

end
