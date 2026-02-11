function [] = computeMonkeyNeuralGeometry()
% Computes neural geometry matrices from monkey single-unit recordings.
%
% This measure re-implements the neural geometry analyses presented in Hunt
% et al. (2018). It characterizes how populations of neurons encode cue
% information by combining three complementary analyses:
%   (1) Representational Dissimilarity Matrices (RDMs) computed from
%   population activity patterns,
%   (2) Coefficients of Partial Determination (CPDs) quantifying the
%   contribution of task-relevant factors to the RDM,
%   (3) Cross-Correlation Matrices (CCMs) capturing the temporal structure
%   of cue-rank encoding across the population.
%
% All analyses are performed separately for each recorded brain area, for
% each monkey individually, and once using data pooled across both monkeys.
%
% OUTPUTS -----------------------------------------------------------------
% None. Results are saved to disk in:
%   data/processed/monkeys/NeuralGeometry.mat
%
% The output structure mirrors the format used for RNN-derived neural
% geometry matrices (see also: generateNeuralGeometryMatrices).

% Load single-unit recordings
UnitRecordings = load(fullfile(getPath("MonkeyData"), "UnitRecordings.mat"));

% --- Prepare datasets and preliminary RDM/CCM variables --- %

% Initialize output structure
NeuralGeometry = struct();

% Generate cue-sampling scenarii for RDM analysis
CueSamplesRDM = generateRDMcueSamples();

% Uniquely identify cue sequences through an absolute trial ID
UnitRecordings.i_trial = UnitRecordings.i_abs_trial;

% ~ Loop over recorded brain areas ~ %
for area = unique(UnitRecordings.area)

    select_area = (UnitRecordings.area == area);
    NeuralGeometry.(area) = struct();

    % ~ Loop over monkeys (individual and pooled) ~ %
    for monkey = [unique(UnitRecordings.monkey), "both"]

        NeuralGeometry.(area).(monkey) = struct();
        fprintf("%s - %s\n", area, monkey);
        
        % Select recordings for the current monkey (or pooled dataset)
        if monkey == "both"
            select_monkey = true(size(select_area));
        else
            select_monkey = (UnitRecordings.monkey == monkey);
        end
        select_area_monkey = select_area & select_monkey;
        MonkeyUnitRecordings = selectStructFieldColumns(UnitRecordings, ...
            select_area_monkey);

        % --- Representational Dissimilarity Matrix (RDM) --- %

        % Initialize the matrix of population activity
        % Each session contributes one population activity vector
        all_session = unique(MonkeyUnitRecordings.i_session);
        n_sessions = length(all_session);
        n_RDM_samples = length(CueSamplesRDM.i_trial);
        RDM_activity = NaN(n_RDM_samples, n_sessions);

        % Compute mean firing rate for each RDM condition and session
        for i_session = 1:n_sessions
            id_session = all_session(i_session);

            for i_sample = 1:n_RDM_samples

               % Select recordings matching the current RDM condition
               is_RDM_sample = ...
                    (MonkeyUnitRecordings.i_step == CueSamplesRDM.i_step(i_sample)) & ...
                    (MonkeyUnitRecordings.cue_pos == CueSamplesRDM.cue_pos(i_sample)) & ...
                    (MonkeyUnitRecordings.cue_rank == CueSamplesRDM.cue_rank(i_sample));

               % Average firing rate across matching cue samples
               RDM_activity(i_sample, i_session) = mean(...
                   MonkeyUnitRecordings.firing_rate(...
                   is_RDM_sample & (MonkeyUnitRecordings.i_session == id_session)));
            end
        end

        % Compute the RDM
        RDM = computeRDM(RDM_activity);

        % --- Coefficients of Partial Determination (CPD) --- %

        CPD = computeCPD(RDM);

        % --- Cross-Correlation Matrices (CCM) --- %

        % Expand cue sequence dataset for CCM analysis
        DataSamples = expandCueSamples(MonkeyUnitRecordings, override_choice=false);

        % Identify trials containing at least three cue samples (required for CCMs)
        i_trials_three_cues = unique(MonkeyUnitRecordings.i_trial);
        i_trials_three_cues = i_trials_three_cues(...
            groupcounts(MonkeyUnitRecordings.i_trial') >= 3);
        select_CCM_sequences = ismember(MonkeyUnitRecordings.i_trial, ...
            i_trials_three_cues);
        i_CCM_samples = find(select_CCM_sequences);        

        % Build regression matrices defining cue-rank relationships
        DataSamplesCCM = selectStructFieldColumns(DataSamples, select_CCM_sequences);
        CCM_regress_all = computeCCMregressionMatrix(DataSamplesCCM);

        % Separate option and attribute cue trials
        select_option_samples = DataSamplesCCM.trial_type == "option";
        select_option_trials = select_option_samples(DataSamplesCCM.i_step < 4);
        select_option_trials = select_option_trials(1:3:end);
        CCM_regress_option = CCM_regress_all(select_option_trials, :);
        CCM_regress_attribute = CCM_regress_all(~ select_option_trials, :);

        % Initialize unit-by-sample activity matrix
        all_session = unique(MonkeyUnitRecordings.i_session(select_CCM_sequences));
        n_sessions = length(all_session);
        n_CCM_samples = sum(select_CCM_sequences);
        CCM_activity = NaN(n_CCM_samples, n_sessions);

        % ~ Loop over recorded units/sessions ~ %
        for i_session = 1:n_sessions

            % Identify CCM samples observed by this unit
            id_session = all_session(i_session);
            i_CCM_samples_this_unit = find(...
                MonkeyUnitRecordings.i_session(select_CCM_sequences) == id_session);

            % Map to global indices
            i_global_samples_this_unit = i_CCM_samples(i_CCM_samples_this_unit);

            % Store firing rates
            CCM_activity(i_CCM_samples_this_unit, i_session) = ...
                MonkeyUnitRecordings.firing_rate(i_global_samples_this_unit);
        end

        % Compute CCMs separately for option and attribute trials
        [tstats_option, CCM_option, CCM_option_p] = ...
            computeCCM(CCM_activity(select_option_samples, :), ...
            CCM_regress_option, ...
            DataSamplesCCM.i_step(select_option_samples));
        [tstats_attribute, CCM_attribute, CCM_attribute_p] = ...
            computeCCM(CCM_activity(~ select_option_samples, :), ...
            CCM_regress_attribute, ...
            DataSamplesCCM.i_step(~ select_option_samples));
    
        % --- Store neural geometry matrices --- %

        NeuralGeometry.(area).(monkey).RDM = RDM;
        NeuralGeometry.(area).(monkey).CPD = CPD;

        NeuralGeometry.(area).(monkey).tstats_option = tstats_option;
        NeuralGeometry.(area).(monkey).CCM_option = CCM_option;
        NeuralGeometry.(area).(monkey).CCM_option_p = CCM_option_p;

        NeuralGeometry.(area).(monkey).tstats_attribute = tstats_attribute;
        NeuralGeometry.(area).(monkey).CCM_attribute = CCM_attribute;
        NeuralGeometry.(area).(monkey).CCM_attribute_p = CCM_attribute_p;
    end
end

% Save the file
save(fullfile(getPath("MonkeyData"), "NeuralGeometry.mat"), ...
    "-struct", "NeuralGeometry");
