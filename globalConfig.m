function GlobalConfig = globalConfig()
% Returns global configuration parameters stored in a structure.

GlobalConfig = struct();

% Global rng seed
GlobalConfig.rng_seed = 0;

% Parameters for model training
GlobalConfig.batch_size_initial_training = 10;
GlobalConfig.n_models_per_cohort = 10;
GlobalConfig.n_trials_train_rational = 500;
GlobalConfig.n_trials_test_rational = 500;
GlobalConfig.n_trials_train_irrational = 2000;
GlobalConfig.n_trials_test_irrational = 2000;
GlobalConfig.init_model_param_variance = 0.05;
GlobalConfig.init_model_param_mean = 0;

end