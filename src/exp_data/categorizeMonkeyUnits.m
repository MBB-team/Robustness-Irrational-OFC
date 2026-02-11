function [] = categorizeMonkeyUnits()
% Categorizes single monkey units according to the type of decision-related
% variable they encode.
%
% This analysis follows the approach of Padoa-Schioppa & Assad (2006) and
% classifies each single-unit based on how well its activity is explained
% by linear regressions onto candidate task variables: offer values, chosen
% value, and chosen option identity (see also: categorizeIntegrationUnits).
%
% OUTPUTS -----------------------------------------------------------------
% None. Results are saved to disk in:
%   data/processed/monkeys/PadoaSchioppaCells.mat

% Load single-unit recordings
UnitRecordings = load(fullfile(getPath("MonkeyData"), "UnitRecordings.mat"));

% Use absolute trial index as unique trial identifier
UnitRecordings.i_trial = UnitRecordings.i_abs_trial;

% Initialize output structure
PadoaSchioppaCells = struct();

% Initialize the categorization pipeline (preprocessing mode)n
preprocess_inputs = categorizeIntegrationUnits();

% ~ Loop over monkeys and brain areas ~ %
for area = ["ACC", "OFC", "dlPFC"]

    PadoaSchioppaCells.(area) = struct();
    select_area = (UnitRecordings.area == area);

    for monkey = ["Franck", "Miles"]

        PadoaSchioppaCells.(area).(monkey) = struct();
        fprintf("%s - %s\n", area, monkey);

        % Select recordings from the current area and monkey
        select_area_monkey = select_area & (UnitRecordings.monkey == monkey);

        % Identify unique neurons (indexed by session ID)
        all_i_neuron = unique(UnitRecordings.i_session(select_area_monkey));
        n_neuron = length(all_i_neuron);

        % ~ Loop over neurons ~ %
        for i_neuron = 1:n_neuron

            % --- Prepare neural and behavioural datasets--- %

            % Copy preprocessing inputs (neuron-specific configuration)
            unit_preprocess_inputs = preprocess_inputs;

            % Select task variables during trials in which this neuron was 
            % recorded
            select_neuron = select_area_monkey & ...
                (UnitRecordings.i_session == all_i_neuron(i_neuron));
            UnitRecordingsCueSequences = selectStructFieldColumns(UnitRecordings, select_neuron);
            UnitDataSamples = expandCueSamples(UnitRecordingsCueSequences, ...
                monkey, override_choice=false);

            % Store this neuron's firing rate (column vector format)
            unit_preprocess_inputs.monkey_activity = ...
                UnitRecordings.firing_rate(select_neuron);
            unit_preprocess_inputs.monkey_activity = unit_preprocess_inputs.monkey_activity';

            % Replace synthetic datasets with this neuron's actual data
            for dataset_monkey = ["", "Franck", "Miles"]
                unit_preprocess_inputs.("DataSamples" + dataset_monkey) = UnitDataSamples;
            end

            % --- Run regression-based categorization --- %

            analysis_output = categorizeIntegrationUnits(NaN, ...
                struct("output_label", "loc"), [], unit_preprocess_inputs);

            % --- Store unit-level classification results --- %

            field_names = string(fieldnames(analysis_output))';
            for field_name = field_names
                if contains(field_name, "Franck") || contains(field_name, "Miles")
                    % Skip monkey-specific outputs (here, all outputes are
                    % the same across subjective/optimal decision frames)
                    continue
                end
                if ~ isfield(PadoaSchioppaCells.(area).(monkey), field_name)
                    PadoaSchioppaCells.(area).(monkey).(field_name) = NaN(n_neuron, 1);
                end
                PadoaSchioppaCells.(area).(monkey).(field_name)(i_neuron) = analysis_output.(field_name);
            end
        end

        % Compute the proportion of units of each type
        for variable = preprocess_inputs.regression_variables
            PadoaSchioppaCells.(area).(monkey).("prop_" + variable) = ...
                mean(PadoaSchioppaCells.(area).(monkey).("is_" + variable));
        end
    end
end

% Save categorization results
save(fullfile(getPath("MonkeyData"), "PadoaSchioppaCells.mat"), ...
    "-struct", "PadoaSchioppaCells");
