function [] = computeMonkeyNeuralGeometry()

% Initialize the storage
Analysis = struct();

% Create RDM cue sampling scenarii
CueSamplesRDM = generateCueSamplesRDM();

% Select samples belonging to trials with at least three cues
i_trial_session = Records.i_trial + 1e3 * Records.i_session;
i_trials_3cues = unique(i_trial_session);
i_trials_3cues = i_trials_3cues(groupcounts(i_trial_session') >= 3);
select_3cues = ismember(i_trial_session, i_trials_3cues);

% --- Loop through areas --- %
for area = unique(Records.area)
    select_area = (Records.area == area);
    % Update storage
    Analysis.(area) = struct();

    % --- Loop through observed monkeys --- %
    for monkey = [unique(Records.monkey), "all"]
        % Display the progress
        fprintf("%s - %s ... ", area, monkey);
        % Update storage
        Analysis.(area).(monkey) = struct();
        % Select samples corresponding to the monkey of interest
        if monkey == "all"
            select_monkey = true(size(select_area));
        else
            select_monkey = (Records.monkey == monkey);
        end
        % Select all the samples taken into account
        select_area_monkey = select_area & select_monkey;

        % --- Compute the RDM --- %

        % Initialize the activity matrix
        all_session = unique(Records.i_session(select_area_monkey));
        n_sessions = length(all_session);
        n_RDM_samples = length(CueSamplesRDM.i_trial);
        RDM_activity = NaN(n_RDM_samples, n_sessions);
        % Compute the mean activity for each RDM sample
        for i_unit = 1:n_sessions
            i_session = all_session(i_unit);
            for i_sample = 1:n_RDM_samples
               is_RDM_sample = ...
                    (Records.i_step == CueSamplesRDM.i_step(i_sample)) ...
                    & (Records.cue_pos == CueSamplesRDM.cue_pos(i_sample)) ...
                    & (Records.cue_rank == CueSamplesRDM.cue_rank(i_sample));
               RDM_activity(i_sample, i_unit) = mean(...
                   Records.firing_rate(is_RDM_sample & ...
                   select_area_monkey & (Records.i_session == i_session)));
            end
        end
        % Compute the RDM
        RDM = computeRDM(RDM_activity);
        % Compute the CPDs
        CPD = computeCPD(RDM);

        % --- Compute the CCMs --- %
        
        % Update which samples are selected
        select_CCM_samples = select_area_monkey & select_3cues;
        i_select_CCM_samples = find(select_CCM_samples);

        % Define option and attribute trials
        CueSamples.i_trial = Records.i_trial(select_CCM_samples) + ...
            1e3 * Records.i_session(select_CCM_samples);
        CueSamples.i_step = Records.i_step(select_CCM_samples);
        CueSamples.cue_pos = Records.cue_pos(select_CCM_samples);
        CueSamples.cue_rank = Records.cue_rank(select_CCM_samples);
        DataSamples = expandCueSamples(CueSamples);
        select_option_samples = (DataSamples.trial_type == "option");
        select_attribute_samples = (DataSamples.trial_type == "attribute");
        select_option_trials = ismember(unique(CueSamples.i_trial), ...
            CueSamples.i_trial(select_option_samples));
        select_attribute_trials = ismember(unique(CueSamples.i_trial), ...
            CueSamples.i_trial(select_attribute_samples));
        % Compute the CCM regression matrix
        CCM_regression_matrix = computeCCMRegressionMatrix(DataSamples);

        % Format the activity matrix
        all_session = unique(Records.i_session(select_CCM_samples));
        n_sessions = length(all_session);
        n_CCM_samples = sum(select_CCM_samples);
        CCM_activity = NaN(n_CCM_samples, n_sessions);
        for i_unit = 1:n_sessions
            % Find which CCM samples are observed by this unit
            i_session = all_session(i_unit);
            i_select_CCM_unit = find(...
                Records.i_session(select_CCM_samples) == i_session);
            % Convert these indices into indices at the scale of all the
            % samples
            i_activity_CCM_unit = i_select_CCM_samples(i_select_CCM_unit);
            CCM_activity(i_select_CCM_unit, i_unit) = ...
                Records.firing_rate(i_activity_CCM_unit);
        end

        % Compute the tstats and CCMs
        [tstats_option, CCM_option, CCM_option_p] = ...
            computeCCM(CCM_activity(select_option_samples, :), ...
            CCM_regression_matrix(select_option_trials, :), ...
            CueSamples.i_step(select_option_samples));
        [tstats_attribute, CCM_attribute, CCM_attribute_p] = ...
            computeCCM(CCM_activity(select_attribute_samples, :), ...
            CCM_regression_matrix(select_attribute_trials, :), ...
            CueSamples.i_step(select_attribute_samples));
    
        % --- Plot and save --- %

        % Plot
        f_RDM = plotRDM(RDM, [-0.3, 0.3]);
        f_CPD = plotCPD(CPD, [-0.3, 0.3]);
        f_CCM_option = plotCCM(CCM_option);
        f_CCM_attribute = plotCCM(CCM_attribute);
        % Display the progress
        fprintf("OK\n");

        % Save the figures
        exportgraphics(f_RDM, fullfile(PATH_SAVE, ...
            area + "_RDM_" + monkey + ".png"), ...
            'Resolution', 800);
        exportgraphics(f_CPD, fullfile(PATH_SAVE, ...
            area + "_CPD_" + monkey + ".png"), ...
            'Resolution', 800);
        exportgraphics(f_CCM_option, fullfile(PATH_SAVE, ...
            area + "_CCM_option_" + monkey + ".png"), ...
            'Resolution', 800);
        exportgraphics(f_CCM_attribute, fullfile(PATH_SAVE, ...
            area + "_CCM_attribute_" + monkey + ".png"), ...
            'Resolution', 800);

        % Store the data
        Analysis.(area).(monkey).RDM = RDM;
        Analysis.(area).(monkey).CPD = CPD;
        Analysis.(area).(monkey).tstats_option = tstats_option;
        Analysis.(area).(monkey).CCM_option = CCM_option;
        Analysis.(area).(monkey).CCM_option_p = CCM_option_p;
        Analysis.(area).(monkey).tstats_attribute = tstats_attribute;
        Analysis.(area).(monkey).CCM_attribute = CCM_attribute;
        Analysis.(area).(monkey).CCM_attribute_p = CCM_attribute_p;
        close all;
    end
end

% Save the data
save(fullfile(PATH_SAVE, "Analysis.mat"), 'Analysis');