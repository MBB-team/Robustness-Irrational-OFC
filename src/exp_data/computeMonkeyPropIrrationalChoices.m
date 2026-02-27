function [] = computeMonkeyPropIrrationalChoices()
% Computes the proportion of irrational choices across decision steps and
% trial types.
%
% For each monkey, this function estimates the proportion of suboptimal
% (irrational) choices at each decision step (2, 3, or 4), separately for
% option trials, attribute trials, and pooled trials. Proportions are
% computed independently for each recording session, and summary statistics
% (mean and standard error across sessions) are derived for every context.
%
% OUTPUTS -----------------------------------------------------------------
% None. Results are saved to disk in:
%   data/processed/monkeys/PropIrrational.mat
%
% The saved structure contains, for each monkey:
%   - session-level proportions of irrational choices per trial type and
%     decision step
%   - the corresponding mean and standard error across sessions

% Load cue sequences attended by the monkeys
CueSequences = load(fullfile(getPath("MonkeyData"), "CueSequences.mat"));

% Use absolute trial index as unique trial identifier
CueSequences.i_trial = CueSequences.i_abs_trial;

% Initialize output structure
PropIrrational = struct();

% ~ Loop over monkeys ~ %
for monkey = ["Franck", "Miles"]

    PropIrrational.(monkey) = struct();

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

    % Independent recording sessions
    all_i_session = unique(MonkeyCueSamples.i_session);
    n_session = length(all_i_session);

    % --- Organize choices by trial type and step --- %

    % ~ Loop over trial types ~ %
    for trial_type = ["option", "attribute", "both"]

        PropIrrational.(monkey).(trial_type) = cell(1, 4);
        PropIrrational.(monkey).(trial_type + "_mean") = NaN(1, 4);
        PropIrrational.(monkey).(trial_type + "_se") = NaN(1, 4);

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

            % Compute session-level proportion of suboptimal choices
            prop_choice_suboptimal = NaN(n_session, 1);
            for i_session = 1:n_session
                select_session = (MonkeyCueSamples.i_session == all_i_session(i_session));
                prop_choice_suboptimal(i_session) = mean(...
                    is_choice_suboptimal(select_session & select_step));
            end

            % Store session-level proportions
            PropIrrational.(monkey).(trial_type){i_store} = prop_choice_suboptimal;

            % Compute summary statistics
            PropIrrational.(monkey).(trial_type + "_mean")(i_store) = ...
                mean(PropIrrational.(monkey).(trial_type){i_store}, "omitnan");
            PropIrrational.(monkey).(trial_type + "_se")(i_store) = ...
                std(PropIrrational.(monkey).(trial_type){i_store}, "omitnan") / ...
                sqrt(sum(select_step));
        end
    end
end

% Save the results
save(fullfile(getPath("MonkeyData"), "PropIrrational.mat"), ...
    "-struct", "PropIrrational");
