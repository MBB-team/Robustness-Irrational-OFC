function DatasetSpecs = selectMonkeyTrainTestDataset(path_specs, monkey, new_batch)
% Loads or initializes RNN training specifications and selects monkey
% trials to generate datasets.
%
% This function loads an existing batch training specification file or
% initializes a new one if it does not exist. It generates random initial
% network parameters and training/test datasets for a new batch when
% needed. The datasets are randomly sampled from all trials attended by the
% monkey.
%
% INPUTS ------------------------------------------------------------------
% path_specs : <string 1x1>
%     Path to the file where training specifications are stored.
%
% monkey : <string 1x1>
%     Name of the monkey on whose behaviour the RNNs will be trained.
%
% new_batch (optional) : <bool 1x1>
%     Whether to generate datasets for a new training batch. Defaults to
%     True.
%
% OUTPUTS -----------------------------------------------------------------
% DatasetSpecs : <struct 1x1>
%     Structure containing all training-specific elements for the batch:
%       - init_params: network initialization parameters
%       - TrialIDTrain / TrialID Test: IDs of the trials constituting the
%       training and test datasets
%       - CueDatasetTrain / CueDatasetTest: cue sequences for training and
%       test datasets
%       - n_target_networks_cohort: desired number of networks per cohort
%       - n_networks_cohort: number of successfully trained networks
%       - last_batch_trained: boolean indicating if the previous batch is
%       complete
%     See also: generateTrainTestDataset.

arguments
    path_specs (1, 1) string
    monkey (1, 1) string {mustBeMember(monkey, ["Franck", "Miles"])}
    new_batch (1, 1) logical = true
end

% Load global configuration
GlobalConfig = globalConfig();

% --- Load or initialize DatasetSpecs --- %

if isfile(path_specs)
    DatasetSpecs = load(path_specs);
else
    DatasetSpecs = struct();
    DatasetSpecs.batch_size = GlobalConfig.batch_size_initial_training;
    DatasetSpecs.n_target_networks_cohort = GlobalConfig.n_models_per_cohort;
    DatasetSpecs.n_networks_cohort = 0;
    % Determine maximum number of parameters across all RNN variants
    all_Config = getDesiredNetworkConfigs();
    n_config = length(all_Config);
    n_max_params = - Inf;
    for i_config = 1:n_config
        if all_Config{i_config}.n_params > n_max_params
            n_max_params = all_Config{i_config}.n_params;
        end
    end
    % Initialize storage
    DatasetSpecs.init_params = NaN(n_max_params, 0);
    DatasetSpecs.TrialIDTrain = cell(1, 0);
    DatasetSpecs.TrialIDTest = cell(1, 0);
    DatasetSpecs.CueDatasetTrain = cell(1, 0);
    DatasetSpecs.CueDatasetTest = cell(1, 0);
    % Previous batch (empty) is considered fully trained
    DatasetSpecs.last_batch_trained = true;
end

% --- Generate new batch if previous batch is complete --- %

if new_batch && DatasetSpecs.last_batch_trained

    % Generate random initial RNN parameters
    DatasetSpecs.init_params = [DatasetSpecs.init_params, ...
        GlobalConfig.init_model_param_variance * ...
        randn(size(DatasetSpecs.init_params, 1), DatasetSpecs.batch_size) + ...
        GlobalConfig.init_model_param_mean];

    % Generate random trials for training and testing
    StrippedRecords = load(fullfile(getPath("MonkeyData"), "StrippedRecords.mat"));
    select_monkey = (StrippedRecords.monkey == monkey);
    all_trial_ID = unique(StrippedRecords.i_abs_trial(select_monkey));
    NewTrialIDTrain = cell(1, DatasetSpecs.batch_size); 
    NewTrialIDTest = cell(1, DatasetSpecs.batch_size);
    NewCueDatasetTrain = cell(1, DatasetSpecs.batch_size); 
    NewCueDatasetTest = cell(1, DatasetSpecs.batch_size); 
    for i_network = 1:DatasetSpecs.batch_size
        % Select trials experienced by the monkey
        shuffled_trial_ID = all_trial_ID(randperm(length(all_trial_ID)));
        NewTrialIDTrain{i_network} = shuffled_trial_ID(1:GlobalConfig.n_trials_train_irrational);
        NewTrialIDTest{i_network} = shuffled_trial_ID(GlobalConfig.n_trials_train_irrational + ...
            (1:GlobalConfig.n_trials_test_irrational));
        % Select cue sequences and monkey choices corresponding to these
        % trials
        select_train = ismember(StrippedRecords.i_abs_trial, ...
            NewTrialIDTrain{i_network});
        select_test = ismember(StrippedRecords.i_abs_trial, ...
            NewTrialIDTest{i_network});
        NewCueDatasetTrain{i_network} = struct(...
            "i_trial", StrippedRecords.i_abs_trial(select_train), ...
            "i_step", StrippedRecords.i_step(select_train), ...
            "cue_pos", StrippedRecords.cue_pos(select_train), ...
            "cue_rank", StrippedRecords.cue_rank(select_train), ...
            "choice_loc", StrippedRecords.choice_loc(select_train), ...
            "choice_order", StrippedRecords.choice_order(select_train), ...
            "choice_attention", StrippedRecords.choice_attention(select_train));
        NewCueDatasetTest{i_network} = struct(...
            "i_trial", StrippedRecords.i_abs_trial(select_test), ...
            "i_step", StrippedRecords.i_step(select_test), ...
            "cue_pos", StrippedRecords.cue_pos(select_test), ...
            "cue_rank", StrippedRecords.cue_rank(select_test), ...
            "choice_loc", StrippedRecords.choice_loc(select_test), ...
            "choice_order", StrippedRecords.choice_order(select_test), ...
            "choice_attention", StrippedRecords.choice_attention(select_test));
    end
    DatasetSpecs.TrialIDTrain = [DatasetSpecs.TrialIDTrain, ...
        NewTrialIDTrain];
    DatasetSpecs.TrialIDTest = [DatasetSpecs.TrialIDTest, ...
        NewTrialIDTest];
    DatasetSpecs.CueDatasetTrain = [DatasetSpecs.CueDatasetTrain, ...
        NewCueDatasetTrain];
    DatasetSpecs.CueDatasetTest = [DatasetSpecs.CueDatasetTest, ...
        NewCueDatasetTest];

    % Mark batch as in-progress
    DatasetSpecs.last_batch_trained = false;

    % Save updated training specifications
    save(path_specs, "-struct", "DatasetSpecs");
end


end
