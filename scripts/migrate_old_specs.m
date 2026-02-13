% Convert old RNN training specifications.

clear variables;

% Load old specs structures
path_folder_old_specs = fullfile("C:", "Users", "jbenon", "OneDrive - Universität Zürich UZH", ...
    "Code projects", "Hunt2018_ANN", "Data", "Models", "Sig_1000");
TrainingSpecs = load(fullfile(path_folder_old_specs, "_TrainingSpecs.mat"));
FittingSpecs = load(fullfile(path_folder_old_specs, "_FittingSpecs.mat"));

% Load new spec structure for initial rational training
path_example_new_specs = fullfile("C:", "Users", "jbenon", ...
    "OneDrive - Universität Zürich UZH", ...
    "Code projects", "Biological-profits-of-irrational-computations-in-the-OFC", ...
    "data_backup", "raw", "models", "rational", "_DatasetSpecs.mat");
DatasetSpecsRational = load(path_example_new_specs);

% Generate new spec structure for initial irrational training
DatasetSpecsIrrational = selectMonkeyTrainTestDataset(fullfile(getPath("ModelsRaw"), "irrational_Franck", "_DatasetSpecs.mat"), "Franck", true);

%% Create new rational initial training dataset
DatasetSpecs = struct();
DatasetSpecs.batch_size = TrainingSpecs.n_networks_per_batch;
DatasetSpecs.init_params = TrainingSpecs.init_weights;
DatasetSpecs.last_batch_trained = TrainingSpecs.last_batch_trained;
DatasetSpecs.n_networks_cohort = TrainingSpecs.n_networks_cohort;
DatasetSpecs.n_target_networks_cohort = TrainingSpecs.n_target_networks_cohort;
DatasetSpecs.CueDatasetTest = TrainingSpecs.AllCueSamplesTest;
DatasetSpecs.CueDatasetTrain = TrainingSpecs.AllCueSamplesTrain;

% Save it
save(fullfile(getPath("ModelsRaw"), "rational", "_DatasetSpecs.mat"), "-struct", "DatasetSpecs");


%% Create new irrational initial training datasets

MonkeyCueSequences = load(fullfile(getPath("MonkeyData"), "CueSequences.mat"));

for monkey = ["Franck", "Miles"]
    DatasetSpecs = struct();
    DatasetSpecs.batch_size = TrainingSpecs.n_networks_per_batch;
    DatasetSpecs.init_params = NaN(size(TrainingSpecs.init_weights));
    DatasetSpecs.last_batch_trained = TrainingSpecs.last_batch_trained;
    DatasetSpecs.n_networks_cohort = TrainingSpecs.n_networks_cohort;
    DatasetSpecs.n_target_networks_cohort = TrainingSpecs.n_target_networks_cohort;

    % Generate monkey trials dataset
    DatasetSpecs.CueDatasetTest = TrainingSpecs.AllCueSamplesTest;
    DatasetSpecs.CueDatasetTrain = TrainingSpecs.AllCueSamplesTrain;

    n_network = size(FittingSpecs.("i_trial_train_" + monkey), 2);
    CueDatasetTrain = cell(1, n_network);
    CueDatasetTest = cell(1, n_network);

    for i_network = 1:n_network

        select_train = ismember(MonkeyCueSequences.i_abs_trial, ...
            FittingSpecs.("i_trial_train_" + monkey)(:, i_network));
        select_test = ismember(MonkeyCueSequences.i_abs_trial, ...
            FittingSpecs.("i_trial_test_" + monkey)(:, i_network));
        CueDatasetTrain{i_network} = struct(...
            "i_trial", MonkeyCueSequences.i_abs_trial(select_train), ...
            "i_step", MonkeyCueSequences.i_step(select_train), ...
            "cue_pos", MonkeyCueSequences.cue_pos(select_train), ...
            "cue_rank", MonkeyCueSequences.cue_rank(select_train), ...
            "choice_loc", MonkeyCueSequences.choice_loc(select_train), ...
            "choice_order", MonkeyCueSequences.choice_order(select_train), ...
            "choice_attention", MonkeyCueSequences.choice_attention(select_train));
        CueDatasetTest{i_network} = struct(...
            "i_trial", MonkeyCueSequences.i_abs_trial(select_test), ...
            "i_step", MonkeyCueSequences.i_step(select_test), ...
            "cue_pos", MonkeyCueSequences.cue_pos(select_test), ...
            "cue_rank", MonkeyCueSequences.cue_rank(select_test), ...
            "choice_loc", MonkeyCueSequences.choice_loc(select_test), ...
            "choice_order", MonkeyCueSequences.choice_order(select_test), ...
            "choice_attention", MonkeyCueSequences.choice_attention(select_test));

    end

    DatasetSpecs.CueDatasetTrain = CueDatasetTrain;
    DatasetSpecs.CueDatasetTest = CueDatasetTest;

    % Save it
    save(fullfile(getPath("ModelsRaw"), "irrational_" + monkey, "_DatasetSpecs.mat"), "-struct", "DatasetSpecs");

end
