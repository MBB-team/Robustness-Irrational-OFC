function [] = computeMonkeyDecisionResiduals()
% Quantifies decision errors beyond what is expected from trial difficulty.
%
% This function models the probability of making a suboptimal choice (i.e
% the "wrong" choice according to the monkey's subjective value profile) as
% a function of trial difficulty, defined as the absolute value difference
% between the two options (|ΔV|). A logistic regression is fitted to
% predict whether a choice is suboptimal from |ΔV| across all trials. The
% residuals of this regression (observed − predicted error probability)
% provide a measure of "excess errors", i.e. deviations from the level of
% irrationality expected based on difficulty alone.
%
% OUTPUTS -----------------------------------------------------------------
% None. Results are saved to disk in:
%   data/processed/monkeys/DecisionResiduals.mat
%
% The saved structure contains, for each monkey:
%   - residuals per trial type and decision step
%   - the corresponding mean and standard error

% Load cue sequences attended by the monkeys
CueSequences = load(fullfile(getPath("MonkeyData"), "CueSequences.mat"));

% Use absolute trial index as unique trial identifier
CueSequences.i_trial = CueSequences.i_abs_trial;

% Initialize output structure
DecisionResiduals = struct();

% ~ Loop over monkeys ~ %
for monkey = ["Franck", "Miles"]

    DecisionResiduals.(monkey) = struct();

    % --- Prepare behavioural dataset --- %

    % Select trials corresponding to the current monkey
    MonkeyCueSamples = selectStructFieldColumns(CueSequences, ...
        CueSequences.monkey == monkey);
    select_last_step = [MonkeyCueSamples.i_step(1:(end -1)) >= ...
        MonkeyCueSamples.i_step(2:end), true];
    DataSamples = expandCueSamples(MonkeyCueSamples, monkey, override_choice=true);

    % Retain decision step only
    MonkeyCueSamples = selectStructFieldColumns(MonkeyCueSamples, select_last_step);
    DataSamples = selectStructFieldColumns(DataSamples, select_last_step);

    % Suboptimal choices (1 = error, 0 = optimal)
    is_choice_suboptimal = MonkeyCueSamples.choice_loc ~= DataSamples.choice_loc;

    % Trial difficulty proxy: absolute value difference |ΔV|
    choice_easiness = abs(DataSamples.diff_value_loc);

    % --- Fit logistic regression model --- %

    % Predict probability of suboptimal choice from |ΔV|
    mdl = fitglm(choice_easiness', is_choice_suboptimal', Distribution="binomial");

    % Extract raw residuals (observed − predicted)
    all_residuals = mdl.Residuals.Raw;

    % --- Organize residuals by trial type and step --- %

    % ~ Loop over trial types ~ %
    for trial_type = ["option", "attribute", "both"]

        DecisionResiduals.(monkey).(trial_type) = cell(1, 4);
        DecisionResiduals.(monkey).(trial_type + "_mean") = NaN(1, 4);
        DecisionResiduals.(monkey).(trial_type + "_se") = NaN(1, 4);

        if trial_type == "both"
            select_trial_type = true(size(DataSamples.trial_type));
        else
            select_trial_type = DataSamples.trial_type == trial_type;
        end

        % ~ Loop over decision steps (0 = pooled across steps) ~ %
        for i_step = [0, 2:4]

            if i_step == 0
                select_step = true(size(DataSamples.i_step));
                i_store = 1;
            else
                select_step = (DataSamples.i_step == i_step);
                i_store = i_step;
            end

            select_step = select_trial_type & select_step;

            % Store residuals
            DecisionResiduals.(monkey).(trial_type){i_store} = all_residuals(select_step');

            % Compute summary statistics
            DecisionResiduals.(monkey).(trial_type + "_mean")(i_store) = ...
                mean(DecisionResiduals.(monkey).(trial_type){i_store});
            DecisionResiduals.(monkey).(trial_type + "_se")(i_store) = ...
                std(DecisionResiduals.(monkey).(trial_type){i_store}) / ...
                sqrt(sum(select_step));
        end
    end
end

% Save the residuals
save(fullfile(getPath("MonkeyData"), "DecisionResiduals.mat"), ...
    "-struct", "DecisionResiduals");
