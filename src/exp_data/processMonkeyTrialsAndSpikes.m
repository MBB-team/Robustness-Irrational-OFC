function [] = processMonkeyTrialsAndSpikes(window_start, window_end)
% Extracts, formats, and saves behavioural and neural data from raw monkey
% recording files.
%
% This function parses single-unit recording files and associated
% behavioural data to build two datasets:
%   (1) UnitRecordings: trial-by-trial cue sequence description paired with 
%       single-unit firing rates
%   (2) CueSequences: behavioural and task variables only (neural data
%       removed), with duplicate sessions stripped
%
% For each recorded unit, the function:
%   - Identifies valid experimental trials
%   - Extracts cue sampling sequences and their properties
%   - Computes average firing rates within a user-defined time window
%     relative to cue onset
%   - Encodes the monkey's choice in multiple task-relevant reference
%     frames
%
% The resulting structures follow the same conventions as cue sequence
% datasets generated to train and evaluate RNNs (see also:
% generateRandomCueSamples).
%
% INPUTS ------------------------------------------------------------------
% window_start : <1x1 int>
%   Start of the window used to average neuron activity, expressed in ms
%   from cue presentation.
% window_end : <1x1 int>
%   End of the window used to average neuron activity, expressed in ms
%   from cue presentation.
%
% OUTPUTS -----------------------------------------------------------------
% None. Results are saved to disk in the 'data/processed/monkeys' folder:
%   - UnitRecordings.mat
%   - CueSequences.mat

arguments
    window_start (1,1) double = 100
    window_end (1,1) double = 500
end

% --- Load raw data --- %

% Load metadata describing each monkey’s recording sessions
RecordingSessions = struct();
RecordingSessions.Franck = load(fullfile(getPath("MonkeyRawData"), ...
    "frank_area.mat")).area_index;
RecordingSessions.Miles = load(fullfile(getPath("MonkeyRawData"), ...
    "miles_area.mat")).miles_area;

% Gather all files containing single-unit recording and task data
path_units = fullfile(getPath("MonkeyRawData"), "neuronal_data");
name_units_files = dir(fullfile(path_units, '**', '*.mat'));
n_sessions = length(name_units_files);

% Map human-readable brain area labels to brain area IDs
all_brain_area = ["ACC", "dlPFC", "OFC", "other", "other", "other"];

% --- Initialize data storage --- %

% Overestimate the number of cue samples to preallocate memory
n_samples_overestimated = n_sessions * 400 * 4;
UnitRecordings = struct();

% Session characteristics
UnitRecordings.monkey = strings(1, n_samples_overestimated);
UnitRecordings.area = strings(1, n_samples_overestimated);
UnitRecordings.i_session = NaN(1, n_samples_overestimated);

% Cue sequences
UnitRecordings.i_trial = NaN(1, n_samples_overestimated);
UnitRecordings.i_step = NaN(1, n_samples_overestimated);
UnitRecordings.cue_pos = NaN(1, n_samples_overestimated);
UnitRecordings.cue_rank = NaN(1, n_samples_overestimated);

% Monkey choices
UnitRecordings.choice_loc = NaN(1, n_samples_overestimated);
UnitRecordings.choice_order = NaN(1, n_samples_overestimated);
UnitRecordings.choice_attention = NaN(1, n_samples_overestimated);

% Single-unit activity
UnitRecordings.firing_rate = NaN(1, n_samples_overestimated);

% ~ Loop over recording sessions (i.e. recorded units) ~ %

i_sample = 1;
f_wait = waitbar(0, sprintf("Session n° 0 / %d", n_sessions));

for i_session = 1:n_sessions

    % --- Identify the monkey and brain area for this unit --- %

    % Extract monkey ID, session index, and channel index from the filename
    file_name = name_units_files(i_session).name;
    file_name_pattern = "(F|M)(\d{3})_C(\d{1,2})_U\d\.mat";
    file_name_tokens = regexp(file_name, file_name_pattern, "tokens");
    if ~ isempty(file_name_tokens)
        monkey_initial = file_name_tokens{1}{1};
        id_session = str2double(file_name_tokens{1}{2});
        i_channel = str2double(file_name_tokens{1}{3});
    else
        % Invalid file
        continue
    end

    % Define monkey full name
    switch monkey_initial
        case "F"
            monkey_name = "Franck";
        case "M"
            monkey_name = "Miles";
        otherwise
            warning("Unknown monkey in %s.", file_name);
            continue;
    end

    % Retrieve brain area and session type for this recording
    select_recording = ...
        RecordingSessions.(monkey_name)(:, 1) == id_session & ...
        RecordingSessions.(monkey_name)(:, 2) == i_channel;
    brain_area = all_brain_area(RecordingSessions.(monkey_name)(select_recording, 3));
    is_learning_session = RecordingSessions.(monkey_name)(select_recording, 12) == 0;

     % Exclude learning sessions and recordings outside target brain areas
    if is_learning_session || brain_area == "other"
        waitbar(i_session / n_sessions, f_wait, ...
            sprintf("Session n° %d / %d", i_session, n_sessions));
        continue;
    end

    % --- Process behavioural and neural data for this unit --- %

    % Load behavioural and spike timing information
    UnitInfo = load(fullfile(path_units, file_name(1:4), file_name)).BhvInfo;

    % Select option or attribute trials with no behavioural error
    has_correct_type = (UnitInfo.ConditionNumber == 3) | ...
                       (UnitInfo.ConditionNumber == 4);
    has_no_error = (UnitInfo.TrialError == 0) | (UnitInfo.TrialError == 6);
    is_correct_trial = (has_no_error & has_correct_type);
    i_correct_trial = UnitInfo.TrialNumber(is_correct_trial);

    % ~ Loop over trials ~ %
    for i_trial = i_correct_trial

        % --- Identify cue sampling events --- %

        % Get cue sampling events index
        is_starting_cue_sampling = ...
            (UnitInfo.CodeNumbers{i_trial} == 91) | ...
            (UnitInfo.CodeNumbers{i_trial} == 92) | ...
            (UnitInfo.CodeNumbers{i_trial} == 93) | ...
            (UnitInfo.CodeNumbers{i_trial} == 94);
        n_cues = sum(is_starting_cue_sampling);

        % Get cue onset times
        t_start_cue_sampling = UnitInfo.CodeTimes{i_trial}(...
            is_starting_cue_sampling);

        % Define time windows used to compute firing rates
        t_start_record_spikes = t_start_cue_sampling + window_start;
        t_end_record_spikes = t_start_cue_sampling + window_end;

        % --- Extract cue sequence information --- %

        % Convert experimental cue codes to standardized 1–4 position codes
        cue_pos_expe = UnitInfo.CodeNumbers{i_trial}(is_starting_cue_sampling);
        cue_pos_expe = cue_pos_expe - 90;
        if UnitInfo.Uservars{i_trial}.ProbTop == 1
            cue_pos_j = cue_pos_expe;
        elseif UnitInfo.Uservars{i_trial}.ProbTop == 2
            % Exchange top and bottom cues
            cue_pos_j = NaN(n_cues, 1);
            cue_pos_j(cue_pos_expe == 1) = 2;
            cue_pos_j(cue_pos_expe == 2) = 1;
            cue_pos_j(cue_pos_expe == 3) = 4;
            cue_pos_j(cue_pos_expe == 4) = 3;
        end
        cue_pos_j = cue_pos_j';

        % Compute discrete cue ranks from underlying probability/payoff
        cue_rank_j = NaN(1, n_cues);
        cue_rank_j(cue_pos_j == 1) = round(5 * ( ...
            UnitInfo.Uservars{i_trial}.ProbabilityTracker(1) + 0.1));
        cue_rank_j(cue_pos_j == 2) = round(5 *( ...
            UnitInfo.Uservars{i_trial}.PayoffTracker(1) + 0.05));
        cue_rank_j(cue_pos_j == 3) = round(5 * ( ...
            UnitInfo.Uservars{i_trial}.ProbabilityTracker(2) + 0.1));
        cue_rank_j(cue_pos_j == 4) = round(5 * ( ...
            UnitInfo.Uservars{i_trial}.PayoffTracker(2) + 0.05));

        % Store cue identity information
        i_cues_trial = i_sample:(i_sample + n_cues - 1);
        UnitRecordings.monkey(i_cues_trial) = monkey_name;
        UnitRecordings.area(i_cues_trial) = brain_area;
        UnitRecordings.i_session(i_cues_trial) = i_session;
        UnitRecordings.i_trial(i_cues_trial) = i_trial; 
        UnitRecordings.i_step(i_cues_trial) = 1:n_cues; 
        UnitRecordings.cue_pos(i_cues_trial) = cue_pos_j; 
        UnitRecordings.cue_rank(i_cues_trial) = cue_rank_j; 

        % -- Encode monkey choice --- %

        % Choice location (0: left option, 1: right option)
        choice = UnitInfo.Uservars{i_trial}.ChosenTarget;
        if choice == 1
            UnitRecordings.choice_loc(i_cues_trial) = 0;
        else
            UnitRecordings.choice_loc(i_cues_trial) = 1;
        end

        % Choice order (0: first option, 1: second option)
        if (choice == 1) && (cue_pos_j(1) <= 2)
            UnitRecordings.choice_order(i_cues_trial) = 0;
        elseif (choice == 2) && (cue_pos_j(1) >= 3)
            UnitRecordings.choice_order(i_cues_trial) = 0;
        else
            UnitRecordings.choice_order(i_cues_trial) = 1;
        end

        % Choice attentional focus (0: attended option, 1: unattended option)
        if (choice == 1) && (cue_pos_j(end) <= 2)
            UnitRecordings.choice_attention(i_cues_trial) = 0;
        elseif (choice == 2) && (cue_pos_j(end) >= 3)
            UnitRecordings.choice_attention(i_cues_trial) = 0;
        else
            UnitRecordings.choice_attention(i_cues_trial) = 1;
        end

        % --- Compute unit firing rate --- %

        % ~ Loop over cues in the sequence ~ %
        for i_cue = 1:n_cues
            n_spikes = sum(...
                (UnitInfo.SpikeCodes{i_trial} > t_start_record_spikes(i_cue)) & ...
                (UnitInfo.SpikeCodes{i_trial} < t_end_record_spikes(i_cue)));
            firing_rate = (1000 * n_spikes) / ...
                (t_end_record_spikes(i_cue) - t_start_record_spikes(i_cue));
            UnitRecordings.firing_rate(i_sample + i_cue - 1) = firing_rate;
        end

        % Update cue sample index
        i_sample = i_sample + n_cues;

    end

    % Update progress bar
    waitbar(i_session / n_sessions, f_wait, ...
        sprintf("Session n° %d / %d", i_session, n_sessions));

end

close(f_wait);

% Trim unused preallocated entries
remove_sample = isnan(UnitRecordings.i_session);
for field = fieldnames(UnitRecordings)'
    UnitRecordings.(field{1}) = UnitRecordings.(field{1})(~ remove_sample);
end

% Convert trial indices (relative to each session) into absolute trial IDs
% to allow unambiguous identification across sessions
UnitRecordings.i_abs_trial = UnitRecordings.i_trial + 1000 * UnitRecordings.i_session;

% --- Strip duplicate sessions --- %
% Multiple single units can be recorded simultaneously during the same
% behavioural session. This section removes duplicated behavioural
% information across such sessions, keeping a single copy of each unique
% cue sequence and choice pattern.

% Create a copy of the full dataset containing behavioural information only
CueSequences = UnitRecordings;
CueSequences = rmfield(CueSequences, "firing_rate");

% Identify unique session IDs
all_i_session = unique(UnitRecordings.i_session);
n_session = length(all_i_session);

f_wait = waitbar(0, sprintf("Stripped session similar to n° 0 / %d", n_session));

% ~ Loop over pairs of sessions ~ %
for i_select_session = 1:n_session
    i_session = all_i_session(i_select_session);

    % Decribe monkey behaviour during the reference session
    select_session_i = (CueSequences.i_session == i_session);
    monkey_i = CueSequences.monkey(select_session_i);
    i_step_i = CueSequences.i_step(select_session_i);
    cue_pos_i = CueSequences.cue_pos(select_session_i);
    cue_rank_i = CueSequences.cue_rank(select_session_i);
    choice_loc_i = CueSequences.choice_loc(select_session_i);
    choice_order_i = CueSequences.choice_order(select_session_i);
    choice_attention_i = CueSequences.choice_attention(select_session_i);

    % Compare against all subsequent sessions
    for j_select_session = (i_select_session + 1):n_session
        j_session = all_i_session(j_select_session);

        % Decribe the monkey behaviour during the subsequent session
        select_session_j = (CueSequences.i_session == j_session);
        monkey_j = CueSequences.monkey(select_session_j);
        i_step_j = CueSequences.i_step(select_session_j);
        cue_pos_j = CueSequences.cue_pos(select_session_j);
        cue_rank_j = CueSequences.cue_rank(select_session_j);
        choice_loc_j = CueSequences.choice_loc(select_session_j);
        choice_order_j = CueSequences.choice_order(select_session_j);
        choice_attention_j = CueSequences.choice_attention(select_session_j);

        % Check whether the two sessions are behaviourally identical:
        % same monkey, same cue sequence, and same choices at every step
        if (sum(select_session_i) == sum(select_session_j)) && ...
            all((monkey_i == monkey_j)) && ...
            all((i_step_i == i_step_j)) && ...
            all((cue_pos_i == cue_pos_j)) && ...
            all((cue_rank_i == cue_rank_j)) && ...
            all((choice_loc_i == choice_loc_j)) && ...
            all((choice_order_i == choice_order_j)) && ...
            all((choice_attention_i == choice_attention_j))

            % Remove the duplicated session from the dataset
            for field = fieldnames(CueSequences)'
                CueSequences.(field{1}) = CueSequences.(...
                    field{1})(~ select_session_j);
            end
        end
    end

    % Update the progress bar
    waitbar(i_select_session / n_session, f_wait, ...
        sprintf("Stripped session similar to n° %d / %d", ...
        i_select_session, n_session));
    
end

close(f_wait);

% --- Save neural and behavioural datasets --- %

save(fullfile(getPath("MonkeyData"), "UnitRecordings.mat"), "-struct", "UnitRecordings");
save(fullfile(getPath("MonkeyData"), "CueSequences.mat"), "-struct", "CueSequences");
