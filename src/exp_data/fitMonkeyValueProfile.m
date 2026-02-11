function [] = fitMonkeyValueProfile()
% Fits a shared option value function V(p, m) to each monkey's behaviour.
%
% This function fits a value function that maps an option’s probability p
% and magnitude m to a scalar value, assuming the same mapping applies to
% both options (see also: fitOneValueProfile). Choice probabilities are
% then obtained by passing the difference in option values through a 
% sigmoid function.
%
% OUTPUTS -----------------------------------------------------------------
% None. Results are saved to disk in:
%   data/processed/monkeys/ValueProfile.mat
%
% This saved structure contains, for each monkey, the fitted value profile
% and the fit's proportion of explained variance.

% Load cue sequences attended by the monkeys
CueSequences = load(fullfile(getPath("MonkeyData"), "CueSequences.mat"));

% Use absolute trial index as unique trial identifier
CueSequences.i_trial = CueSequences.i_abs_trial;

% Initialize output structure
ValueProfile = struct();

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
    preprocess_inputs = fitOneValueProfile();

    % Replace synthetic dataset by the monkey's actual cue sequences
    preprocess_inputs.DataSamples = DataSamples;

    % Provide observed choices (in location frame) to the model
    preprocess_inputs.monkey_choices = DataSamples.choice_loc;

    % Fit the model
    analysis_output = fitOneValueProfile(NaN, struct(), [], preprocess_inputs);
    ValueProfile.(monkey) = analysis_output;

end

% Save fitted value profiles
save(fullfile(getPath("MonkeyData"), "ValueProfile.mat"), "-struct", "ValueProfile");
