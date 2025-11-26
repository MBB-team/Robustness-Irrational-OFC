function [] = trainRationalModels()
% Trains artificial neural networks to perform optimally several variations
% of value-related computations on the task described in Hunt et al.
% (2018). Models are considered correctly trained once they explained at
% least 95% of variance on a test dataset. Across model cohorts, models
% must share the same initial state, training and testing datasets.
%
%% OUTPUTS
%  =======
%
% - Network [struct] [saved]
%       This function saves 'Network' structure containing the information
%       about the architecture of the model and its vectors of parameters
%       through training. The structure fields are:
%       - Config [struct]
%               'Configuration' structure defining the inputs and outputs
%               of the model as well as its internal architecture (number
%               of units, activation function, ...).
%       - FitOptimal [struct]
%               Structure containing information regarding the training of
%               the model. Its fields are:
%               - seed [num]
%                       Random seed defining the training and testing
%                       datasets for this model, as well as its
%                       initial state of parameters.
%               - params [n_params x n_fit num]
%                       Vector of parameters at each step of the fit. The
%                       first vector corresponds to the initial state of
%                       the model, while the last vector corresponds to the
%                       parameters defining the optimally trained model.
%               - fit_train [n_fit x n_output num]
%                       Percentage of explained variance (R2) on the
%                       training dataset, for each model output separately,
%                       through fit steps.
%               - fit_test [n_fit x n_output num]
%                       Same format as fit_train, but on a testing dataset.
%               - i_end_GnLoop [vector int]
%                       Number of the intermediate step at the end of each
%                       Gauss-Newton loop calculated by VBA.
%
%% See also: getPath, getDesiredNetworkConfigs, generateTrialsTrainTest,
% generateRandomCueSamples, expandCueSamples, selectDataInfo, observeANN,
% VBA_NLStateSpaceModel, computeR2, saveNetwork, selectCohortSubset.


Config = config();


% Get all the configurations of ANNs to train
all_Config = getDesiredNetworkConfigs();
n_config = length(all_Config);

% Get the IDs of the trials in the training and testing datasets
path_specs = fullfile(getPath("Models"), "_TrainingSpecs.mat");
Specs = generateTrialsTrainTest();

%% ----------------- %
% --- Train ANNs --- %
% ------------------ %

% Initialize the parallel pool
delete(gcp("nocreate"));
cluster = parcluster("local");
parpool(cluster, min(n_config, cluster.NumWorkers));

% ~ Train ANNs until the target number of ANNs per cohort is reached ~ %
while Specs.n_networks_cohort < Specs.n_target_networks_cohort

    % Get the indices of the first and last training states to consider
    if Specs.last_batch_trained
        i_network_start = size(Specs.init_weights, 2) + 1;
    else
        i_network_start = size(Specs.init_weights, 2) - ...
            Specs.n_networks_per_batch + 1;
    end
    i_network_end = i_network_start + Specs.n_networks_per_batch - 1;

    % --- If necessary, create new initialisation states --- %

    if Specs.last_batch_trained
        % Random initial ANN parameters
        Specs.init_weights = [Specs.init_weights, ...
            Specs.noise_init * randn(size(Specs.init_weights, 1), ...
            Specs.n_networks_per_batch)];
        % Random samples in the training and testing sets
        Specs.AllCueSamplesTrain = [Specs.AllCueSamplesTrain, ...
            cell(1, Specs.n_networks_per_batch)];
        Specs.AllCueSamplesTest = [Specs.AllCueSamplesTest, ...
            cell(1, Specs.n_networks_per_batch)];
        for i_network = i_network_start:i_network_end
            Specs.AllCueSamplesTrain{i_network} = ...
                generateRandomCueSamples(Specs.n_trials);
            Specs.AllCueSamplesTest{i_network} = ...
                generateRandomCueSamples(Specs.n_trials);
        end
        % Update the training state
        Specs.last_batch_trained = false;
        % Save the specifications
        save(path_specs, "-struct", "Specs");
    end

    % --- Train this batch of ANNs --- %

    % Initialize the progress bar
    parfor_progress(n_config * Specs.n_networks_per_batch);

    % ~ Loop through configurations to train ~ %
    parfor i_config = 1:n_config
    
        % Select the configuration
        Config = all_Config{i_config};
    
        % ~ Loop through ANNs to train ~ %
        for i_network = i_network_start:i_network_end

            % Select training and testing data
            DataSamplesTrain = expandCueSamples(...
                Specs.AllCueSamplesTrain{i_network});
            DataSamplesTest = expandCueSamples(...
                Specs.AllCueSamplesTest{i_network});
            input_train = selectDataInfo(DataSamplesTrain, Config.inputs);
            output_train = selectDataInfo(DataSamplesTrain, Config.outputs);
            vec_output_train = reshape(output_train, [], 1);
            input_test = selectDataInfo(DataSamplesTest, Config.inputs);
            output_test = selectDataInfo(DataSamplesTest, Config.outputs);
        
            % --- Initialize the VBA model --- %
        
            % Evolution and observation functions
            f_fname = [];
            g_fname = @observeANN;
            % Parameters of the observation function
            options = struct();
            options.inG.Config = Config;
            options.inG.input = input_train;
            % Model dimensions (number of parameters)
            dim = struct('n', 0, 'n_theta', 0, 'n_phi', Config.n_params);
            % Prior mean different from 0
            options.priors.muPhi = 1e-1 * ones(dim.n_phi, 1);
            % Same prior variance for all parameters, no covariance
            options.priors.SigmaPhi = 1e1 * eye(dim.n_phi);
        
            % --- Set initialization state --- %
        
            % Set early stopping conditions
            options.GnMaxIter = 1;
            options.MaxIter = 1;
            % Shut VBA up
            options.verbose = false;
            options.DisplayWin = false;
            % Train
            [posterior, out] = VBA_NLStateSpaceModel(...
                vec_output_train, [], ...
                f_fname, g_fname, dim, options);
            % Set the new posterior as the pre-defined vector of random
            % parameters
            posterior.muPhi = Specs.init_weights(1:Config.n_params, ...
                i_network);
            % If it is a "value comparison" ANN, set the posterior on the
            % readout vector as the difference of the corresponding pair of
            % readout vectors in a "value construction" ANN
            if Config.output_format_label == "diff"
                posterior.muPhi(Config.ParamRange.readout) = ...
                    posterior.muPhi(Config.ParamRange.readout) - ...
                    Specs.init_weights((Config.n_params + 1):...
                    (Config.n_params + Config.n_units_z), i_network);
            end
        
            % --- Fully train the ANN --- %
        
            % Re-set normal stopping conditions
            out.it = 0;
            out.options.GnMaxIter = 32;
            out.options.MinIter = 5;
            out.options.MaxIter = 32;
            out.options.TolFun = 1e1;
            % Set desired verbosity settings
            out.options.verbose = false;
            out.options.DisplayWin = false;
            % Store history of parameters
            out.options.store_history = true;
            % Fit the model with the new initialization state
            in = struct();
            in.posterior = posterior;
            in.out = out;
            [~, out] = VBA_NLStateSpaceModel(...
                vec_output_train, [], ...
                f_fname, g_fname, dim, out.options, in);
        
            % --- Test the ANN generalizability --- %
        
            % Initialize the storage of parameters and percentage of explained
            % variance
            params = out.suffStat.params_history;
            n_outputs = length(Config.outputs);
            fit_train = NaN(size(params, 2), n_outputs);
            fit_test = NaN(size(params, 2), n_outputs);
            % ~ Loop through training steps ~ %
            for i_step = 1:size(params, 2)
                % Get model predictions
                vec_pred_output_train = observeANN(...
                    [], params(:, i_step), [], ...
                    struct('Config', Config, 'input', input_train));
                pred_output_train = reshape(vec_pred_output_train, ...
                    [], n_outputs);
                vec_pred_output_test = observeANN(...
                    [], params(:, i_step), [], ...
                    struct('Config', Config, 'input', input_test));
                pred_output_test = reshape(vec_pred_output_test, ...
                    [], n_outputs);
                % Compute the quality of predictions
                fit_train(i_step, :) = computeR2(output_train, ...
                    pred_output_train);
                fit_test(i_step, :) = computeR2(output_test, ...
                    pred_output_test);
            end
            
            % --- Wrap-up the ANN info --- %
        
            if mean(fit_test(end, :)) >= 0.95
                Network = struct();
                % Cohort configuration
                Network.Config = Config;
                % Info on the initial training (on a normative function)
                Network.FitOptimal = struct();
                Network.FitOptimal.seed = i_network;
                Network.FitOptimal.params = params;
                Network.FitOptimal.fit_train = fit_train;
                Network.FitOptimal.fit_test = fit_test;
                Network.FitOptimal.i_end_GnLoop = out.suffStat.i_end_GnLoop;
                % Save the ANN
                saveNetwork(Network);
            end
        
            % Update the progress bar
            parfor_progress();
            
        end
    end

    % Strip the cohorts from the ANNs which were not correctly trained
    % among all cohorts
    [subset_included_paths] = selectCohortSubset(...
        n_networks_cohort = Specs.n_target_networks_cohort, ...
        delete_outside_subset = true);
    % Count the number of correctly trained ANNs
    Specs.n_networks_cohort = length(subset_included_paths) / n_config;
    % Update the training status of this batch
    Specs.last_batch_trained = true;
    % Save the specifications
    save(path_specs, "-struct", "Specs");

    % Write how many ANNs are currently correctly trained
    fprintf(sprintf("\n%d / %d ANNs correctly trained per cohort\n\n", ...
        Specs.n_networks_cohort, Specs.n_target_networks_cohort));
end

% Delete the progress file
parfor_progress(0);

end
