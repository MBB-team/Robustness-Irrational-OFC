% Completes the basic scenario information of each trial with relevant
% features.

function CueSamples = expandCueSamples(CueSamples, monkey, options)
% --- INPUT ---
% CueSamples: structure
%   .i_trial: [1 x n_samples] double
%       Trial index.
%   .i_step: [1 x n_samples] double
%       Step index.
%   .cue_pos: [1 x n_samples] double
%       Position (1-4) of the sampled cue.
%   .cue_rank: [1 x n_samples] double
%       Rank (1-5) of the sampled cue.
%
% --- OUTPUT ---
% This function returns an expanded version of the 'CueSamples' structure,
% containing the additional following fields:
%   .trial_type: [1 x n_samples] "undefined" / "option" / "attribute"
%       If at least two cues were sampled during the trial, it can be
%       either an option trial (two first cues belong to the same option)
%       or an attribute trial (two first cues represent the same
%       attribute). If only one cue was sampled, the trial type is
%       undefined.
%   .cue_rank: [1 x n_samples] double
%       Rank (1-5) of the attended cue.
%   .cue_value: [1 x n_samples] double
%       Value (from 0.1 to 0.9) of the attended cue.
%   .cue_type: [1 x n_samples] 0 / 1
%       Type (probability/magnitude) of the attended cue.
%   .option_loc: [1 x n_samples] 0 / 1
%       Location (left/right) of the attended option.
%   .option_order: [1 x n_samples] 0 / 1
%       Order of attendance (first/second) of the attended option within
%       the current trial.
%   .prob_left: [1 x n_samples] double
%       Estimated probability of the left option.
%   .mag_left: [1 x n_samples] double
%       Estimated magnitude of the left option.
%   .prob_right: [1 x n_samples] double
%       Estimated probability of the right option.
%   .mag_right: [1 x n_samples] double
%       Estimated magnitude of the right option.
%   .value_left: [1 x n_samples] double
%       Estimated value of the left option.
%   .value_right: [1 x n_samples] double
%       Estimated value of the right option.
%   .diff_value_loc: [1 x n_samples] double
%       Difference between the estimated values of the left and right
%       options.
%   .choice_loc: [1 x n_samples] double
%       Which option is currently the best (0 for the left, 1 for the
%       right, 0.5 in case of equality).
%   .prob_first: [1 x n_samples] double
%       Estimated probability of the first option.
%   .mag_first: [1 x n_samples] double
%       Estimated magnitude of the first option.
%   .prob_second: [1 x n_samples] double
%       Estimated probability of the second option.
%   .mag_second: [1 x n_samples] double
%       Estimated magnitude of the second option.
%   .value_first: [1 x n_samples] double
%       Estimated value of the firstly attended option.
%   .value_second: [1 x n_samples] double
%       Estimated value of the secondly attended option.
%   .diff_value_order: [1 x n_samples] double
%       Difference between the estimated values of the firstly and
%       secondly attended options.
%   .choice_order: [1 x n_samples] double
%       Which option is currently the best (0 for the first, 1 for the
%       second, 0.5 in case of equality).
%   .prob_attended: [1 x n_samples] double
%       Estimated probability of the attended option.
%   .mag_attended: [1 x n_samples] double
%       Estimated magnitude of the attended option.
%   .prob_unattended: [1 x n_samples] double
%       Estimated probability of the unattended option.
%   .mag_unattended: [1 x n_samples] double
%       Estimated magnitude of the unattended option.
%   .value_attended: [1 x n_samples] double
%       Estimated value of the attended option.
%   .value_unattended: [1 x n_samples] double
%       Estimated value of the unattended option.
%   .diff_value_attention: [1 x n_samples] double
%       Difference between the estimated values of the attended and
%       unattended options.
%   .choice_attention: [1 x n_samples] double
%       Which option is currently the best (0 for the attended, 1 for the
%       unattended, 0.5 in case of equality).
%
% --- CALLED BY ---
% trainNetworkCohorts
% checkInformationLoss
% simulateNetworkCohortsH0
% fitNetworkToBehaviour
% computeNeuralRepresentation
% computeLogLikelihoodDynamics


arguments
    CueSamples (1, 1) struct;
    monkey (1, 1) string = "";
    options.override_choice = true;
end


% Get samples dimensions
n_samples = length(CueSamples.i_trial);

% --- Cue type --- %

%{
Cue positions:
1: left probability
2: left magnitude
3: right probability
4: right magnitude
%}
% Initialize all types to 1 (magnitude)
CueSamples.cue_type = ones(1, n_samples);
% Update concerned types to 0 (probability)
CueSamples.cue_type((CueSamples.cue_pos == 1)) = 0;
CueSamples.cue_type((CueSamples.cue_pos == 3)) = 0;

% --- Cue value --- %

CueSamples.cue_value = 0.2 * CueSamples.cue_rank - 0.1;

% --- Option location (left/right) --- %

% Initialize all locations to 1 (right)
CueSamples.option_loc = ones(1, n_samples);
% Update concerned locations to 0 (left)
CueSamples.option_loc((CueSamples.cue_pos == 1)) = 0;
CueSamples.option_loc((CueSamples.cue_pos == 2)) = 0;

% --- Option order (first/second) --- %

% Initialize all orders
CueSamples.option_order = NaN(1, n_samples);
no_sample_start_trial = 1;
for i_trial = unique(CueSamples.i_trial)
    % Get number of attended cues during the trial
    n_steps = max(CueSamples.i_step(CueSamples.i_trial == i_trial));
    % Compute the indices of the starting and ending samples
    no_sample_end_trial = no_sample_start_trial + n_steps - 1;
    range_sample_trial = no_sample_start_trial:no_sample_end_trial;
    % Initialize local identity of options to 0 (first option)
    option_order = zeros(1, n_steps);
    % Define the first option attended
    option_first = CueSamples.option_loc(no_sample_start_trial);
    % Update concerned orders to 1 (second option)
    option_order(CueSamples.option_loc(range_sample_trial) ~= option_first) = 1;
    % Save info in the output structure
    CueSamples.option_order(range_sample_trial) = option_order;
    % Update next trial start
    no_sample_start_trial = no_sample_start_trial + n_steps;
end

% --- Trial type (option/attribute) --- %

% Initialize all trial types
CueSamples.trial_type = repmat("undefined", 1, n_samples);
no_sample_start_trial = 1;
for i_trial = unique(CueSamples.i_trial)
    % Get number of attended cues during the trial
    n_steps = max(CueSamples.i_step(CueSamples.i_trial == i_trial));
    % Compute the indices of the starting and ending samples
    no_sample_end_trial = no_sample_start_trial + n_steps - 1;
    range_sample_trial = no_sample_start_trial:no_sample_end_trial;
    % Update trials with at least two cues sampled
    if n_steps >= 2
        % Option trial
        if CueSamples.option_loc(no_sample_start_trial) == ...
           CueSamples.option_loc(no_sample_start_trial + 1)
            CueSamples.trial_type(range_sample_trial) = "option";
        % Attribute trial
        elseif CueSamples.cue_type(no_sample_start_trial) == ...
               CueSamples.cue_type(no_sample_start_trial + 1)
            CueSamples.trial_type(range_sample_trial) = "attribute";
        end
    end
    % Update next trial start
    no_sample_start_trial = no_sample_start_trial + n_steps;
end

% --- Estimated attributes --- %

% Left/right
prob_left = NaN(1, n_samples);
mag_left = NaN(1, n_samples);
prob_right = NaN(1, n_samples);
mag_right = NaN(1, n_samples);
% First/second
prob_first = NaN(1, n_samples);
mag_first = NaN(1, n_samples);
prob_second = NaN(1, n_samples);
mag_second = NaN(1, n_samples);
% Attended/unattended
prob_attended = NaN(1, n_samples);
mag_attended = NaN(1, n_samples);
prob_unattended = NaN(1, n_samples);
mag_unattended = NaN(1, n_samples);

no_sample_start_trial = 1;
for i_trial = unique(CueSamples.i_trial)
    % Get number of attended cues during the trial
    n_steps = max(CueSamples.i_step(CueSamples.i_trial == i_trial));
    % Default cue values [P left, M left, P right, M right]
    % known_cue_values = 0.2 * [3, 3, 3, 3] - 0.1;
    known_cue_values = NaN(1, 4);
    % Store which cues have been seen
    seen_cue = false(1, 4);
    % First attended option
    option_first = CueSamples.option_loc(no_sample_start_trial);

    for i_step = 1:n_steps

        % Update current knowledge on trial cue ranks
        i_sample = no_sample_start_trial + i_step - 1;
        known_cue_values(CueSamples.cue_pos(i_sample)) = ...
            CueSamples.cue_value(i_sample);
        seen_cue(CueSamples.cue_pos(i_sample)) = true;
     
        % Update estimated left/right attributes
        prob_left(i_sample) = known_cue_values(1);
        mag_left(i_sample) = known_cue_values(2);
        prob_right(i_sample) = known_cue_values(3);
        mag_right(i_sample) = known_cue_values(4);

        % Update estimated first/second attributes
        if option_first == 0 % first option is on the left
            prob_first(i_sample) = prob_left(i_sample);
            mag_first(i_sample) = mag_left(i_sample);
            prob_second(i_sample) = prob_right(i_sample);
            mag_second(i_sample) = mag_right(i_sample);
        else % first option is on the right
            prob_first(i_sample) = prob_right(i_sample);
            mag_first(i_sample) = mag_right(i_sample);
            prob_second(i_sample) = prob_left(i_sample);
            mag_second(i_sample) = mag_left(i_sample);
        end

        % Update estimated attended/unattended option
        if CueSamples.option_loc(i_sample) == 0 % attended option is on the left
            prob_attended(i_sample) = prob_left(i_sample);
            mag_attended(i_sample) = mag_left(i_sample);
            prob_unattended(i_sample) = prob_right(i_sample);
            mag_unattended(i_sample) = mag_right(i_sample);
        else % attended option is on the right
            prob_attended(i_sample) = prob_right(i_sample);
            mag_attended(i_sample) = mag_right(i_sample);
            prob_unattended(i_sample) = prob_left(i_sample);
            mag_unattended(i_sample) = mag_left(i_sample);
        end
    end
    % Update next trial start
    no_sample_start_trial = no_sample_start_trial + n_steps;
end

% Store the known attributes
CueSamples.known_prob_left = prob_left;
CueSamples.known_mag_left = mag_left;
CueSamples.known_prob_right = prob_right;
CueSamples.known_mag_right = mag_right;
CueSamples.known_prob_first = prob_first;
CueSamples.known_mag_first = mag_first;
CueSamples.known_prob_second = prob_second;
CueSamples.known_mag_second = mag_second;
CueSamples.known_prob_attended = prob_attended;
CueSamples.known_mag_attended = mag_attended;
CueSamples.known_prob_unattended = prob_unattended;
CueSamples.known_mag_unattended = mag_unattended;

% Store the inferred attributes (i.e., replace unknown attributes by their
% expected value)
for field = ["known_prob_left", "known_mag_left", ...
        "known_prob_right", "known_mag_right", ...
        "known_prob_first", "known_mag_first", ...
        "known_prob_second", "known_mag_second", ...
        "known_prob_attended", "known_mag_attended", ...
        "known_prob_unattended", "known_mag_unattended"]
    inferred_field = char(field);
    inferred_field = string(inferred_field(7:end));
    CueSamples.(inferred_field) = CueSamples.(field);
    CueSamples.(inferred_field)(isnan(CueSamples.(inferred_field))) = ...
        0.2 * 3 - 0.1;
end

% --- Estimated values and choice --- %

all_prob = load(fullfile(getPath("MonkeyData"), "all_prob.mat")).all_prob;
all_mag = all_prob;
% Chose the correct value function
if monkey == ""
    all_prob_default = all_prob;
    all_prob_default(isnan(all_prob_default)) = 0.5;
    all_mag_default = all_mag;
    all_mag_default(isnan(all_mag_default)) = 0.5;
    value_function = all_prob_default' * all_mag_default;
else
    value_function = load(fullfile(getPath("MonkeyData"), ...
        "ValueFunction.mat")).(monkey);
end
% Map the value function onto attribute pairs for each option
for output_label = ["loc", "order", "attention"]
    switch output_label
        case "loc"
            field_option = ["left", "right"];
        case "order"
            field_option = ["first", "second"];
        case "attention"
            field_option = ["attended", "unattended"];
    end
    field_values = "value_" + field_option;
    % For each option, map its known pair of attributes onto the
    % value function estimated forthe monkey
    for i_option = 1:2
        CueSamples.(field_values(i_option)) = NaN(1, n_samples);
        for i_prob = 1:length(all_prob)
            prob = round(all_prob(i_prob), 1);
            for i_mag = 1:length(all_mag)
                mag = round(all_mag(i_mag), 1);
                if isnan(prob)
                    select_trial = isnan(...
                        CueSamples.("known_prob_" + ...
                        field_option(i_option)));
                else
                    select_trial = (round(...
                        CueSamples.("known_prob_" + ...
                        field_option(i_option)), 1) == prob);
                end
                if isnan(mag)
                    select_trial = select_trial & isnan(...
                        CueSamples.("known_mag_" + ...
                        field_option(i_option)));
                else
                    select_trial = select_trial & (round(...
                        CueSamples.("known_mag_" + ...
                        field_option(i_option)), 1) == mag);
                end
                % Store the value
                CueSamples.(field_values(i_option))(select_trial) = ...
                    value_function(i_prob, i_mag);
            end
        end
    end
    % Compute the value difference and the choice
    field_value_diff = "diff_value_" + output_label;
    field_choice = "choice_" + output_label;
    CueSamples.(field_value_diff) = CueSamples.(field_values(1)) - ...
        CueSamples.(field_values(2));
    if ~ isfield(CueSamples, field_choice) || options.override_choice
        CueSamples.(field_choice) = -0.5 * sign(CueSamples.(field_value_diff)) + 0.5;
        CueSamples.(field_choice)(CueSamples.(field_choice) == 0.5) = 0;
    end
end

% --- Decision confidence --- %

% Initialize decision confidence to 1
CueSamples.decision_conf = ones(1, n_samples);
% Select the last step
select_last_step = [(CueSamples.i_step(1:(end - 1)) >= ...
    CueSamples.i_step(2:end)), true];
% Define field names
field_conf = "decision_conf";
field_choice = "choice_loc";

% ~ Loop through time steps ~ %
for step = 1:3
    % Get all possible unique states at this time step
    select_step = (CueSamples.i_step == step);
    unique_state = unique(...
        [CueSamples.prob_left(select_step) ; ...
        CueSamples.prob_right(select_step) ; ...
        CueSamples.mag_left(select_step) ; ...
        CueSamples.mag_right(select_step)]', "rows");
    n_state = size(unique_state, 1);
    % ~ Loop through states ~ %
    for i_state = 1:n_state
        % Select all the trials with this state at this time step
        select_samples = select_step & ...
            (CueSamples.prob_left == unique_state(i_state, 1)) & ...
            (CueSamples.prob_right == unique_state(i_state, 2)) & ...
            (CueSamples.mag_left == unique_state(i_state, 3)) & ...
            (CueSamples.mag_right == unique_state(i_state, 4));
        % Select all the last steps of these trials
        select_last_samples = ...
            ismember(CueSamples.i_trial, ...
            CueSamples.i_trial(select_samples)) & ...
            select_last_step;
        % Count the proportion of choices at the considered step that are
        % the same as the choices at the last step
        prop_same_choice = sum(...
            CueSamples.(field_choice)(select_samples) == ...
            CueSamples.(field_choice)(select_last_samples)) ./ ...
            sum(select_samples);
        % Store this proportion as the decision confidence
        CueSamples.(field_conf)(select_samples) = prop_same_choice;
    end
end

end
