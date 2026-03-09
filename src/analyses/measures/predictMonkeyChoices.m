function analysis_output = predictMonkeyChoices(params, Config, ~, inputs)
% Quantifies how well an RNN predicts monkey choices using balanced 
% accuracy.
%
% This measure evaluates whether the choices produced by an RNN match the
% choices made by individual monkeys when exposed to the same cue
% sequences. For each monkey, the RNN is run on the corresponding trials,
% its outputs are converted into binary choices, and prediction performance
% is assessed using balanced accuracy on the final decision step of each
% trial. When the training condition of the RNN can be linked to a specific
% monkey, prediction performance is additionally reframed in a
% same-monkey / other-monkey reference frame, allowing direct comparison
% between within-monkey and cross-monkey generalization.
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
%     Structure containing variables precomputed during preprocessing, as
%     well as supplementary variables. Required only in analysis mode.
%     Fields include:
%       - DataSamplesFranck, DataSamplesMiles: cue-sampling datasets
%       corresponding to trials experienced by each monkey, including their
%       choices for each cue sequence
%       - fit_label: label of the RNN's: training phase
%       
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing monkey-specific cue sequences datasets, as well
%     as the label of the fit session undergone by the RNN.
%     - In analysis mode:
%     Structure containing balanced accuracies:
%       - bacc_Franck, bacc_Miles, bacc_both <1x1>: balanced accuracy for
%       predicting the choices of each monkey or the pooled choices of both
%       monkeys
%       - bacc_same_monkey <1x1>: balanced accuracy for the monkey matching
%       the RNN's training condition (if identifiable)
%       - bacc_other_monkey <1x1>: balanced accuracy for the other monkey

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    inputs (1,1) struct = struct()
end

if isempty(params)

    % --- Preprocessing mode: load monkey trials and choices --- %

    % Load the experimental records
    MonkeyCueSequences = load(fullfile(getPath("MonkeyData"), "CueSequences.mat"));

    for monkey = ["Franck", "Miles", "both"]

        % Select trials attended by this monkey
        if monkey == "both"
            ThisMonkeyRecords = MonkeyCueSequences;
        else
            ThisMonkeyRecords = selectStructFieldColumns(MonkeyCueSequences, ...
                MonkeyCueSequences.monkey == monkey);
        end
        ThisMonkeyRecords.i_trial = ThisMonkeyRecords.i_abs_trial;

        % Expand cue-sampling scenarios while preserving observed choices
        analysis_output.("DataSamples" + monkey) = expandCueSamples(...
            ThisMonkeyRecords, override_choice=false);
    end

else

    % --- Analysis mode: predict monkey choices --- %

    for monkey = ["Franck", "Miles", "both"]
    
        % --- Run the RNN on the monkey's trials --- %

        % Select RNN inputs
        input_test = selectDataInfo(inputs.("DataSamples" + monkey), Config.inputs);

        % Get RNN outputs
        Weights = shapeParametersIntoWeights(params, Config);
        [~, ~, network_output] = propagateThroughANN(Weights, ...
            Config.f_activation, input_test, inputs.("DataSamples" + monkey).i_step);

        % Convert RNN outputs to choice probabilities
        if size(network_output, 2) == 2
            network_output = network_output(:, 1) - network_output(:, 2);
        end
        network_choices = sigANN(- network_output, 0);

        % --- Compare RNN and monkey choices --- %

        % Select monkey choices in the same reference frame as the RNN
        monkey_choices = inputs.("DataSamples" + monkey).("choice_" + Config.output_label);
        monkey_choices = monkey_choices';

        % Restrict evaluation to the final step of each trial
        is_last_step = [inputs.("DataSamples" + monkey).i_step(1:(end - 1)) >= ...
            inputs.("DataSamples" + monkey).i_step(2:end), true]';

        % Compute balanced accuracy
        analysis_output.("bacc_" + monkey) = computeBalancedAccuracy(...
            monkey_choices(is_last_step), network_choices(is_last_step));

    end

    % --- Convert performance to same-monkey / other-monkey frame --- %

    % Identify which monkey (if any) matches the RNN training condition
    monkey_match = regexp(inputs.fit_label, ".*(Franck|Miles).*", "tokens");
    if ~ isempty(monkey_match)
        monkey_match = monkey_match{1};
        analysis_output.bacc_same_monkey = analysis_output.("bacc_" + monkey_match);
        if monkey_match == "Franck"
            other_monkey = "Miles";
        else
            other_monkey = "Franck";
        end
        analysis_output.bacc_other_monkey = analysis_output.("bacc_" + other_monkey);
    else
        % Do not define accuracy in the same-monkey / other-monkey frame
        analysis_output.bacc_same_monkey = NaN;
        analysis_output.bacc_other_monkey = NaN;
    end
end
