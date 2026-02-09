function analysis_output = computeFrameworkInformationLoss(params, ...
    Config, seed, inputs)
% Quantifies information loss induced by different encoding frameworks in
% the RNN integration layer.
%
% This measure evaluates how well task-relevant value information can be
% linearly decoded from population activity in the RNN’s integration layer
% under different representational frameworks. Linear decoders are trained
% to recover either the two option values or their difference, expressed in
% alternative frames of reference (spatial location, presentation order, or
% attentional focus). Decoder performance is assessed on held-out data
% using explained variance.
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
% seed : <int 1x1>
%     Seed used to generate the training and test datasets for the RNN.
%
% inputs : <struct 1x1>
%     Structure containing additional metadata. Required only in analysis
%     mode. Fields include:
%       - folder_name: name of the folder containing initial training 
%       specifications, such as the training and test datasets
% 
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Empty structure.
%     - In analysis mode:
%     Structure containing percentages of explained variance:
%       - R2_decode_[format]_[framework] <1x1>: mean explained variance of
%       a linear decoder trained to recover option values expressed in a
%       given format ("both" or "diff") and framework ("loc", "order",
%       "attention") from integration-layer activity

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    seed (1, 1) double = 0
    inputs (1,1) struct = struct()
end

if isempty(params)

    % --- Preprocessing mode: do nothing --- %

    analysis_output = struct();

else

    % --- Analysis mode: decode value information from population
    % activity --- %

    % Load training and test datasets
    path_specs = fullfile(getPath("ModelsRaw"), inputs.folder_name, ...
        "_DatasetSpecs.mat");
    Specs = generateTrainTestDataset(path_specs, false);
    DataSamplesTrain = expandCueSamples(Specs.CueDatasetTrain{seed});
    DataSamplesTest = expandCueSamples(Specs.CueDatasetTest{seed});

    % Compute RNN activity on training and test datasets
    input_train = selectDataInfo(DataSamplesTrain, Config.inputs);
    input_test = selectDataInfo(DataSamplesTest, Config.inputs);
    Weights = shapeParametersIntoWeights(params, Config);
    [~, activity_train, ~] = propagateThroughANN(Weights, ...
        Config.f_activation, input_train);
    [~, activity_test, ~] = propagateThroughANN(Weights, ...
        Config.f_activation, input_test);

    % Initialize output structure
    analysis_output = struct();

    % --- Train and evaluate linear decoders --- %

    % ~ Loop over encoding frameworks and output formats ~ %
    for output_label = ["loc", "order", "attention"]
        for output_format_label = ["both", "diff"]

            % Select the target variables to decode
            if output_format_label == "diff"
                field_data = "diff_value_" + output_label;
            else
                switch output_label
                    case "loc"
                        field_data = "value_" + ["left", "right"];
                    case "order"
                        field_data = "value_" + ["first", "second"];
                    case "attention"
                        field_data = "value_" + ["attended", "unattended"];
                end
            end
            target_output_train = selectDataInfo(DataSamplesTrain, field_data);
            target_output_test = selectDataInfo(DataSamplesTest, field_data);
    
            % Fit linear decoders on the training set
            warning("off")
            decode_weights = [];
            for i_data = 1:length(field_data)
                decode_weights = [decode_weights, ...
                    glmfit(activity_train, ...
                    target_output_train(:, i_data), ...
                    "normal", Constant = "off")];
            end
            warning("on")
    
            % Evaluate decoding performance on the test set
            pred_output_test = activity_test * decode_weights;
            field_output = "R2_decode_" + output_format_label + "_" + output_label;
            analysis_output.(field_output) = mean(computeR2(...
                target_output_test, pred_output_test));
              
        end
    end
end
