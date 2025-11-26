function Specs = generateTrialsTrainTest()

% Define the path to the file storing training characteristics
path_specs = fullfile(getPath("Models"), "_TrainingSpecsNoisy.mat");

% --- Training specifications --- %

% Load them if possible
if isfile(path_specs)
    Specs = load(path_specs);

% Set default ANN training specifications
else
    Specs = struct();
    % Number of trials in the training and testing datasets
    Specs.n_trials = 500;
    % Variance of the initialisation weights
    Specs.noise_init = 5e-1;
    % Number of ANNs trained per cohort per training batch
    Specs.n_networks_per_batch = 50;
    % Desired final number of ANNs per cohort
    Specs.n_target_networks_cohort = 100;
    % Number of correctly trained ANNs which are common through cohorts
    Specs.n_networks_cohort = 0;
    % Is the last training batch completed?
    Specs.last_batch_trained = true;
    % Count the maximum number of parameters needed
    all_Config = getDesiredNetworkConfigs();
    n_config = length(all_Config);
    n_max_params = - Inf;
    for i_config = 1:n_config
        if all_Config{i_config}.n_params > n_max_params
            n_max_params = all_Config{i_config}.n_params;
        end
    end
    % Initialize the storage of random initialisation weights
    Specs.init_weights = NaN(n_max_params, 0);
    % Initialize the storage of training / testing datasets
    Specs.AllCueSamplesTrain = cell(1, 0);
    Specs.AllCueSamplesTest = cell(1, 0);

    % --- Save the specifications --- %
    save(path_specs, "-struct", "Specs");

end

end
