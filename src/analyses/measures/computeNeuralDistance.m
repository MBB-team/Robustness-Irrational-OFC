function analysis_output = computeNeuralDistance(params, Config, ~, inputs)
% Computes the Representational Dissimilarity Matrices (RDM), Coefficients
% of Partial Determination (CPD) and Cross-Correlation Matrices (CCM) of an
% ANN, using the same analysis as in Hunt et al. (2018). Also computes the
% distance between the RDM / CPD / CCM of the ANN and that of both monkeys.
%
% This function is called by the function callMeasure once without
% any argument, to pre-compute any useful variables, and then with its full
% arguments.
%
% INPUTS ----------
% - params [vector num]
%       Vector of parameters defining an ANN.
% - Config [struct]
%       'Configuration' structure defining the architecture of the ANN.
% - inputs [struct]
%       Structure supposed to contain the variables pre-computed when the
%       function is called without any argument. Its fields are:
%       - DataSamplesRDM [struct]
%               Structure defining the properties of the trials used to
%               compute the RDM.
%       - DataSamplesCCM [struct]
%               Structure defining the properties of the trials used to
%               compute the two CCMs.
%       - select_option_samples [vector bool]
%               Whether each sample belongs to an option trial.
%       - select_attribute_samples [vector bool]
%               Whether each sample belongs to an attribute trial.
%       - CCM_regress_option [n x 6 num]
%               Regression matrix used to compute the CCM on option trials.
%       - CCM_regress_attribute [n x 6 num]
%               Regression matrix used to compute the CCM on attribute
%               trials.
%       - expe_Franck_RDM [20 x 20 num]
%               RDM of monkey Franck.
%       - expe_Miles_RDM [20 x 20 num]
%               RDM of monkey Miles.
%       - expe_Franck_CPD [1 x 5 num]
%               Vector of CPDs of the RDM of monkey Franck.
%       - expe_Miles_CPD [1 x 5 num]
%               Vector of CPDs of the RDM of monkey Miles.
%       - expe_Franck_CCM_option [9 x 9 num]
%               CCM of monkey Franck computed on option trials.
%       - expe_Franck_CCM_attribute [9 x 9 num]
%               CCM of monkey Franck computed on attribute trials.
%       - expe_Miles_CCM_option [9 x 9 num]
%               CCM of monkey Miles computed on option trials.
%       - expe_Miles_CCM_attribute [9 x 9 num]
%               CCM of monkey Miles computed on attribute trials.
%
% OUTPUTS -----
% - RDM [20 x 20 num]
%       RDM of the ANN.
% - CPD [1 x 5 num]
%       Vector of CPDs of the RDM of the ANN.
% - CCM_option [9 x 9 num]
%       CCM of the ANN computed on option trials.
% - CCM_attribute [9 x 9 num]
%       CCM of the ANN computed on attribute trials.
% - dist_Franck_RDM [num]
%       Distance (1 - Pearson correlation of half of the matrix, diagonal
%       excluded) between the RDM of the model and of monkey Franck.
% - dist_Miles_RDM [num]
%       Same format as dist_Franck_RDM, but for monkey Miles.
% - dist_Franck_CPD [num]
%       Distance between the vectors of CPDs of the model and of monkey
%       Franck.
% - dist_Miles_CPD [num]
%       Same format as dist_Franck_CPD, but for monkey Miles.
% - dist_Franck_CCM [num]
%       Distance between some selected cells of the CCMs of the model and
%       of monkey Franck.
% - dist_Miles_CCM [num]
%       Same format as dist_Franck_CCM, but for monkey Miles.

% --- CHECK INPUT ARGUMENTS --- %
arguments
    params (:,1) double {mustBeFinite} = [];
    Config (1,1) struct = struct();
    ~;
    inputs (1,1) struct = struct();
end

% ---------------------- %
% --- Pre-processing --- %
% ---------------------- %

if nargin == 0

    % Create the RDM and CCM datasets
    CueSamplesRDM = generateRDMcueSamples();
    CueSamplesCCM = generateCCMcueSamples();
    DataSamplesRDM = expandCueSamples(CueSamplesRDM);
    DataSamplesCCM = expandCueSamples(CueSamplesCCM);
    
    % Prepare selection of trials depending on their type
    select_option_samples = DataSamplesCCM.trial_type == "option";
    select_attribute_samples = DataSamplesCCM.trial_type == "attribute";
    select_option_trials = select_option_samples(1:3:end);
    select_attribute_trials = select_attribute_samples(1:3:end);
    
    % Create the CCM regression matrices
    CCM_regress_all = computeCCMregressionMatrix(DataSamplesCCM);
    CCM_regress_option = CCM_regress_all(...
        select_option_trials, :);
    CCM_regress_attribute = CCM_regress_all(...
        select_attribute_trials, :);

    % Load the experimental neural data
    MonkeyNeuralGeometry = load(fullfile(getPath("MonkeyData"), "NeuralGeometry.mat"));

    % Gather the result of the pre-processing into inputs for next function
    % call
    analysis_output = struct(...
        "DataSamplesRDM", DataSamplesRDM, ...
        "DataSamplesCCM", DataSamplesCCM, ...
        "select_option_samples", select_option_samples, ...
        "select_attribute_samples", select_attribute_samples, ...
        "CCM_regress_option", CCM_regress_option, ...
        "CCM_regress_attribute", CCM_regress_attribute);

    % Select all CCM cells that can represent something other than noise
    analysis_output.p_nonnoise = zeros(9);
    analysis_output.p_nonnoise(4, :) = 1;
    analysis_output.p_nonnoise(7, :) = 1;
    analysis_output.p_nonnoise(8, :) = 1;
    analysis_output.p_nonnoise(:, 4) = 1;
    analysis_output.p_nonnoise(:, 7) = 1;
    analysis_output.p_nonnoise(:, 8) = 1;

    for area = ["OFC", "dlPFC", "ACC"]
        output_suffix = "_" + area;
        for monkey = ["Franck", "Miles"]
            for geometry = ["RDM", "CPD", "CCM_option", "CCM_option_p", ...
                    "CCM_attribute", "CCM_attribute_p"]
                analysis_output.("expe_" + monkey + "_" + geometry + output_suffix) = ...
                    MonkeyNeuralGeometry.(area).(monkey).(geometry);
            end
        end
    end

end

% ---------------------------------------- %
% --- Analyze the vector of parameters --- %
% ---------------------------------------- %

if nargin > 0
    
    % --- Compute the neural distances --- %

    for area = ["OFC", "dlPFC", "ACC"]
        if area == "OFC"
            output_suffix = "";
        else
            output_suffix = "_" + area;
        end
        for monkey = ["Franck", "Miles"]

            % Compute the RDM distance
            RDM_label = monkey + "_RDM" + output_suffix;
            analysis_output.("dist_" + RDM_label) = computeRDMdistance(...
                inputs.("expe_" + RDM_label), analysis_output.RDM);

            % Compute the CPD distance
            CPD_label = monkey + "_CPD" + output_suffix;
            analysis_output.("dist_" + CPD_label) = ...
                norm(inputs.("expe_" + CPD_label) - analysis_output.CPD);

            % Compute the CCM distance
            CCM_label = monkey + "_CCM" + output_suffix;
            CCM_option_label = monkey + "_CCM_option" + output_suffix;
            CCM_option_p_label = monkey + "_CCM_option_p" + output_suffix;
            CCM_attribute_label = monkey + "_CCM_attribute" + output_suffix;
            CCM_attribute_p_label = monkey + "_CCM_attribute_p" + output_suffix;
            analysis_output.("dist_" + CCM_label) = computeCCMdistance(...
                inputs.("expe_" + CCM_option_label), ...
                inputs.("expe_" + CCM_option_p_label), ...
                inputs.("expe_" + CCM_attribute_label), ...
                inputs.("expe_" + CCM_attribute_p_label), ...
                analysis_output.CCM_option, analysis_output.CCM_attribute);
            analysis_output.("dist_" + CCM_label + "_full") = computeCCMdistance(...
                inputs.("expe_" + CCM_option_label), ...
                inputs.p_nonnoise, ...
                inputs.("expe_" + CCM_attribute_label), ...
                inputs.p_nonnoise, ...
                analysis_output.CCM_option, analysis_output.CCM_attribute);
        end
    end

end

end
