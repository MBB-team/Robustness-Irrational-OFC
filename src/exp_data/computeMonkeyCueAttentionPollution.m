function [] = computeMonkeyCueAttentionPollution()
% Quantifies the influence of unattended cues on monkeys' value computation.
%
% This measure characterizes how each monkey integrates attended and
% unattended attributes when computing option values. It does so by fitting
% a parametric value function to each monkey choices across all attended
% cue-sampling sequences, and by explicitly separating the contribution of
% the attended attribute from that of the unattended one.
%
% OUTPUTS -----------------------------------------------------------------
% None. Results are saved to disk in:
%   data/processed/monkeys/CueAttentionPollution.mat
%
% This saved structure contains, for each monkey, the fitted value
% profiles, their gradients and the mean gradient difference (summary
% statistics).

% Load cue sequences attended by the monkeys
CueSequences = load(fullfile(getPath("MonkeyData"), "CueSequences.mat"));

% Use absolute trial index as unique trial identifier
CueSequences.i_trial = CueSequences.i_abs_trial;

% Initialize output structure
CueAttentionPollution = struct();

% ~ Loop over monkeys ~ %
for monkey = ["Franck", "Miles"]

    % --- Prepare behavioural dataset for this monkey --- %

    % Select cue sequences corresponding to the current monkey and expand
    % the cue sequence dataset
    MonkeyCueSequences = selectStructFieldColumns(CueSequences, ...
        CueSequences.monkey == monkey);
    DataSamples = expandCueSamples(MonkeyCueSequences, override_choice=false);

    % Keep decision step only (final sample of each trial)
    is_decision_step = [DataSamples.i_step(1:(end - 1)) >= ...
        DataSamples.i_step(2:end), true];
    DataSamples = selectStructFieldColumns(DataSamples, is_decision_step);

    % --- Initialize and fit the value model --- %

    % Initialize VBA model structure (preprocessing mode)
    preprocess_inputs = computeCueAttentionPollution();

    % Replace synthetic dataset by the monkey's actual cue sequences
    preprocess_inputs.DataSamples = DataSamples;
    preprocess_inputs.options.inG.n_samples = length(DataSamples.i_step);
    preprocess_inputs.exclude_sequences = (DataSamples.i_step <= 1);

    % Provide observed choices (in attention frame) to the model
    preprocess_inputs.monkey_choices = DataSamples.choice_attention;

    % Fit the model
    analysis_output = computeCueAttentionPollution(NaN, struct(), NaN, ...
        preprocess_inputs);

    % Store the result
    CueAttentionPollution.(monkey) = analysis_output;

end

% Save cue attention pollution metrics
save(fullfile(getPath("MonkeyData"), "CueAttentionPollution.mat"), ...
    "-struct", "CueAttentionPollution");
