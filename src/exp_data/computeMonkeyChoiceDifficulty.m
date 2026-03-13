function [] = computeMonkeyChoiceDifficulty()
% Computes the difficulty of choices (i.e., |dV|) across decision steps and
% trial types.
%
% For each monkey, this function computes a proxy of choice difficulty
% (i.e., the absolute subjective value difference, computed using the 
% itted z-scored monkey value profile), separately for option trials,
% attribute trials, and pooled trials. Summary statistics (mean and
% standard error) are computed for each context.
%
% OUTPUTS -----------------------------------------------------------------
% None. Results are saved to disk in:
%   data/processed/monkeys/ChoiceDifficulty.mat
%
% The saved structure contains, for each monkey:
%   - choice difficulty per trial type and decision step
%   - the corresponding mean and standard error across trials

% Load cue sequences attended by the monkeys
CueSequences = load(fullfile(getPath("MonkeyData"), "CueSequences.mat"));

% Use absolute trial index as unique trial identifier
CueSequences.i_trial = CueSequences.i_abs_trial;

% Initialize output structure
ChoiceDifficulty = struct();

% ~ Loop over monkeys ~ %
for monkey = ["Franck", "Miles"]

    ChoiceDifficulty.(monkey) = struct();

    % --- Prepare behavioural dataset --- %

    % Select trials corresponding to the current monkey
    MonkeyCueSamples = selectStructFieldColumns(CueSequences, ...
        CueSequences.monkey == monkey);
    select_last_step = [MonkeyCueSamples.i_step(1:(end -1)) >= ...
        MonkeyCueSamples.i_step(2:end), true];
    DataSamples = expandCueSamples(MonkeyCueSamples, monkey, zscore_value_profile=true);

    % Retain decision step only
    MonkeyCueSamples = selectStructFieldColumns(MonkeyCueSamples, select_last_step);
    DataSamples = selectStructFieldColumns(DataSamples, select_last_step);

    % --- Organize choices by trial type and step --- %

    % ~ Loop over trial types ~ %
    for trial_type = ["option", "attribute", "both"]

        ChoiceDifficulty.(monkey).(trial_type) = cell(1, 4);
        ChoiceDifficulty.(monkey).(trial_type + "_mean") = NaN(1, 4);
        ChoiceDifficulty.(monkey).(trial_type + "_se") = NaN(1, 4);

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

            % Compute choice difficulty for each trial
            ChoiceDifficulty.(monkey).(trial_type){i_store} = abs(DataSamples.diff_value_loc(select_step));

            % Compute summary statistics
            ChoiceDifficulty.(monkey).(trial_type + "_mean")(i_store) = ...
                mean(ChoiceDifficulty.(monkey).(trial_type){i_store}, "omitnan");
            ChoiceDifficulty.(monkey).(trial_type + "_se")(i_store) = ...
                std(ChoiceDifficulty.(monkey).(trial_type){i_store}, "omitnan") / ...
                sqrt(sum(select_step));
        end
    end
end

% Save the results
save(fullfile(getPath("MonkeyData"), "ChoiceDifficulty.mat"), ...
    "-struct", "ChoiceDifficulty");
