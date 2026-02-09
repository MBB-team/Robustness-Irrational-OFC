function analysis_output = categorizeIntegrationUnits(params, Config, ~, inputs)
% Categorizes units in the RNN integration layer according to the type of
% decision-related variable they encode.
%
% This analysis follows the approach of Padoa-Schioppa & Assad (2006) and
% classifies each integration-layer unit based on how well its activity is
% explained by linear regressions onto candidate task variables: offer
% values, chosen value, and chosen option identity. This analysis is
% seprately conducted:
%   (1) using rational optimal values and choices
%   (2) using monkey-specific value profiles and choices
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
%       - DataSamplesFranck, DataSamplesMiles: all cue-sampling scenarii
%       attended by the monkeys
%       - regression_variables: name of the candidate variables used for
%       unit categorization
%
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing the precomputed dataset and VBA model.
%     - In analysis mode:
%     Structure containing unit-wise regression statistics and
%     categorization results, separately for the rational optimal framework
%     and each monkey dataset:
%       - R2_[variable] <Nx1>: percentage of variance in each unit's
%       activity explained by regressing onto a candidate task variable
%       - slope_[variable] <Nx1>: regression slope relating each unit's
%       activity to a candidate task variable
%       - is_[variable] <Nx1>: indicator of whether each unit is
%       categorized as encoding the candidate task variable (including
%       "none"), based on the highest significant R2
%       - prop_[variable] <1x1>: proportion of integration-layer units
%       categorized as encoding a given task variable (including "none")
%       - R2_[variable]_[monkey], slope_[variable]_[monkey],
%       is_[variable]_[monkey], prop_[variable]_[monkey]: same as above,
%       but using monkey value profiles and choices to compute the task
%       variables

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end

if isempty(params)

    % --- Preprocessing mode: generate and load cue sequence datasets --- %

    % Define the set of task variables used to categorize units
    analysis_output.regression_variables = ["chosen_value", "offer1", "offer2", ...
        "chosen_offer"];
    analysis_output.n_regression = length(analysis_output.regression_variables);

    % Generate all possible cue-sampling scenarii
    CueSamples = generateAllCueSamples();
    analysis_output.DataSamples = expandCueSamples(CueSamples);

    % Load monkey datasets
    MonkeyRecords = load(fullfile(getPath("MonkeyData"), "StrippedRecords.mat"));
    for monkey = ["Franck", "Miles"]
        ThisMonkeyRecords = selectStructFieldColumns(MonkeyRecords, ...
            MonkeyRecords.monkey == monkey);
        ThisMonkeyRecords.i_trial = ThisMonkeyRecords.i_abs_trial;
        DataSamples = expandCueSamples(ThisMonkeyRecords, ...
            monkey=monkey, override_choice=false);
        analysis_output.("DataSamples" + monkey) = DataSamples;
    end

else

    % --- Analysis mode: categorize integration layer units --- %

    % Disable warnings (ill-conditioned regressions for some units)
    warning("off");

    analysis_output = struct();

    % ~ Loop over decision frame (rational or monkey-specific) ~ %
    for monkey = ["", "Franck", "Miles"]

        % Select the cue sequence dataset
        DataSamples = inputs.("DataSamples" + monkey);

        % --- Define regression variables --- %

        % Map offer 1 / offer 2 onto the RNN's output frame
        switch Config.output_label
            case "loc"
                option1 = "left";
                option2 = "right";
            case "order"
                option1 = "first";
                option2 = "second";
            case "attention"
                option1 = "attended";
                option2 = "unattended";
        end
        offer1 = DataSamples.("value_" + option1);
        offer2 = DataSamples.("value_" + option2);
        % Enhance the dataset with the value of the ultimately chosen
        % option
        is_last_step = [...
            DataSamples.i_step(2:end) <= ...
            DataSamples.i_step(1:(end - 1)), true];
        chosen_offer = logical(repelem(...
            DataSamples.("choice_" + Config.output_label)(is_last_step), ...
            DataSamples.i_step(is_last_step)));
        chosen_value = offer1;
        chosen_value(chosen_offer) = offer2(chosen_offer);

        % Initialize storage of regression results
        if monkey == ""
            monkey_label = "";
        else
            monkey_label = "_" + monkey;
        end
        for variable = inputs.regression_variables
            analysis_output.("R2_" + variable + monkey_label) = NaN(Config.n_units_z, 1);
            analysis_output.("is_" + variable + monkey_label) = false(Config.n_units_z, 1);
            analysis_output.("slope_" + variable + monkey_label) = NaN(Config.n_units_z, 1);
        end
        analysis_output.("is_none" + monkey_label) = false(Config.n_units_z, 1);

        % --- Compute integration-layer unit activity --- %
    
        all_inputs = selectDataInfo(DataSamples, Config.inputs);
        Weights = shapeParametersIntoWeights(params, Config);
        [~, activity_z, ~] = propagateThroughANN(Weights, ...
            Config.f_activation, all_inputs, DataSamples.i_step);

        % --- Regress unit activity onto task variables --- %

        % ~ Loop over integration-layer units ~ %
        for i_unit = 1:Config.n_units_z

            % Fit linear models relating unit activity to each candidate
            % decision variable
            mdl.chosen_value = fitlm(chosen_value', activity_z(:, i_unit));
            mdl.offer1 = fitlm(offer1', activity_z(:, i_unit));
            mdl.offer2 = fitlm(offer2', activity_z(:, i_unit));
            mdl.chosen_offer = fitlm(chosen_offer', activity_z(:, i_unit));

            % Store regression slopes
            for variable = inputs.regression_variables
                if (length(mdl.(variable).Coefficients.Estimate) > 1)
                    field_slope = "slope_" + variable + monkey_label;
                    analysis_output.(field_slope)(i_unit) = ...
                        mdl.(variable).Coefficients.Estimate(2);
                end
            end

            % Store the percentage of explained variance for fits with a
            % significant slope
            max_R2 = - Inf;
            max_variable = "none";
            for i_variable = 1:inputs.n_regression

                variable = inputs.regression_variables(i_variable);
                field_R2 = "R2_" + variable + monkey_label;

                if (length(mdl.(variable).Coefficients.pValue) > 1) && ...
                        (mdl.(variable).Coefficients.pValue(2) < 0.05)

                    analysis_output.(field_R2)(i_unit) = ...
                        mdl.(variable).Rsquared.Ordinary;

                    % Select the variable explaining the largest
                    % significant proportion of variance in the unit's
                    % activity
                    if analysis_output.(field_R2)(i_unit) > max_R2
                        max_R2 = analysis_output.(field_R2)(i_unit);
                        max_variable = variable;
                    end
                end
            end

            % Assign unit to the category corresponding to the highest R2
            analysis_output.("is_" + max_variable + monkey_label)(i_unit) = true;
        end

        % Compute the percentage of integration-layer units assigned to
        % each category
        for variable = ["none", inputs.regression_variables]
            analysis_output.("prop_" + variable + monkey_label) = ...
                100 * sum(analysis_output.("is_" + variable + monkey_label)) / ...
                Config.n_units_z;
        end
    end

    % Re-enable warnings
    warning("on");

end
