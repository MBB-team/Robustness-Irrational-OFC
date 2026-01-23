function [] = trainModelsDistort(start_state, end_state)
% 
% Mandatory:
% ----------
% - start_state [string]
%       From which trained state of the model to start. Can be "Optimal" or
%       "Rational". In the latter case, the monkey on which the model was
%       fitted will be selected depending on which monkey is considered for
%       the new fit.
% - end_state [string]
%       Target state of the model to fit. If "Rational", the model must
%       compute values based on the value function fitted to monkey
%       choices, which only depends on the known attributes of one option.
%       If "Irrational", the model must predict monkey choices as best as
%       possible, possibly accounting for interferences between and across
%       options, changing only its recurrent connections.


%% === INITIALIZATION === %%

% Check input arguments
switch start_state
    case "Rational"
        load_models = true;
    case "RationalSubj"
        load_models = true;
    otherwise
        error("Unknown 'start_state' : " + start_state);
end

switch end_state
    case "Rational"
        output_choice = false;
        fit_quality_function = @computeR2;
        load_value_function = false;
    case "RationalSubj"
        output_choice = false;
        fit_quality_function = @computeR2;
        load_value_function = true;
    case "Irrational"
        output_choice = true;
        fit_quality_function = @computeBalancedAccuracy;
        load_value_function = false;
    otherwise
        error("Unknown 'end_state' : " + end_state);
end

% Initialize the simulation
GlobalConfig = globalConfig();
rng(GlobalConfig.rng_seed);

% Initialize parallel computing clusters
delete(gcp("nocreate"));
cluster = parcluster("local");
parpool(cluster, cluster.NumWorkers);

% Load
if load_models
    all_path = getAllNetworkPaths(getPath("Models"));
    n_network = length(all_path);
end
if load_value_function
    ValueFunction = load(fullfile(path_monkey_behavior, ...
        "ValueFunction.mat")).ValueFunction;
end
if output_choice
    path_monkey_behavior = getPath("MonkeyAnalysis");
    StrippedRecords = load(fullfile(path_monkey_behavior, ...
        "StrippedRecords.mat")).StrippedRecords;
end


% Get the IDs of the trials in the training and testing datasets
% switch end_state
%     case "Optimal"
%         Specs = generateTrialsTrainTest();
%     case "Rational"
%         Specs = generateTrialsTrainTest();
%     case "Irrational"
%         Specs = selectMonkeyTrialsTrainTest();
%     otherwise
%         error("Unknown 'end_state'.");
% end

%% === MODEL TRAINING LOOP === %%



% Define the size of the batches of ANNs to train at once
if load_models
    batch_size = GlobalConfig.batch_size_initial_training;
else
    batch_size = n_network;
end

% Start training the first batch of ANNs
train_new_batch = true;
i_batch = 1;

while train_new_batch

    % Initialize the progress file
    parfor_progress(batch_size);

    % ~ Loop through ANNs to fit ~ %
    for i_network = (1 + (i_batch - 1) * batch_size):(i_batch * batch_size)
    
        % Generate the training and testing datasets
        if ~ load_models % Initial training
            network_seed = i_network;

        else % Re-training of existing ANNs
            try
                network_seed = load(all_path{i_network}).Network.seed;
            catch
                parfor_progress();
                warning("Unable to load file %s", all_path{i_network});
                continue;
            end
            if output_choice
                
            else
            end
        end

    
        % ~ Loop through monkey on which to fit ~ %
        for monkey = ["Franck", "Miles"]
    
            % Pass if it has already been fitted
            if start_state == "Priors"
                fit_label = "Fit" + end_state + monkey;
            elseif start_state == "Optimal"
                fit_label = "Fit" + start_state + "To" + end_state + monkey;
            elseif start_state == "Irrational"
                fit_label = "Fit" + start_state + monkey + "To" + end_state;
            end
            if isfield(Network, fit_label)
                continue;
            end
    
            % --- Select the training dataset --- %
    
            switch end_state
                case "Optimal"
                    CueSamplesTrain = Specs.AllCueSamplesTrain{Network.FitOptimal.seed};
                case "Rational"
                    CueSamplesTrain = Specs.AllCueSamplesTrain{Network.FitOptimal.seed};
                case "Irrational"
                    % Select the trials included in the training set
                    i_trials_train = Specs.("i_trial_train_" + monkey)(:, ...
                        Network.FitOptimal.seed);
                    select_train = ismember(StrippedRecords.i_abs_trial, ...
                        i_trials_train);
                    % Gather the sampling scenarii
                    CueSamplesTrain = struct(...
                        "i_trial", StrippedRecords.i_abs_trial(select_train), ...
                        "i_step", StrippedRecords.i_step(select_train), ...
                        "cue_pos", StrippedRecords.cue_pos(select_train), ...
                        "cue_rank", StrippedRecords.cue_rank(select_train));
            end
            % Expand the sampling data
            DataSamplesTrain = expandCueSamples(CueSamplesTrain);
            % Select the inputs
            input_train = selectDataInfo(DataSamplesTrain, ...
                Network.Config.inputs);
            % Select the outputs
            switch end_state
                % Aim: use expected rewards as values
                case "Optimal"
                    switch Network.Config.output_label
                        case "loc"
                            field_option = ["left", "right"];
                        case "order"
                            field_option = ["first", "second"];
                        case "attention"
                            field_option = ["attended", "unattended"];
                    end
                output_train = ...
                    [DataSamplesTrain.("value_" + field_option(1))', ...
                    DataSamplesTrain.("value_" + field_option(2))'];
                if Network.Config.output_format_label == "diff"
                    output_train = output_train(:, 1) - output_train(:, 2);
                end
                % Aim: use the monkey value function
                case "Rational"
                    switch Network.Config.output_label
                        case "loc"
                            field_option = ["left", "right"];
                        case "order"
                            field_option = ["first", "second"];
                        case "attention"
                            field_option = ["attended", "unattended"];
                    end
                    value_both_option = NaN(length(CueSamplesTrain.i_trial), 2);
                    for option = 1:2
                        for i_prob = 1:length(all_prob)
                            prob = round(all_prob(i_prob), 1);
                            for i_mag = 1:length(all_mag)
                                mag = round(all_mag(i_mag), 1);
                                if isnan(prob)
                                    select_trial = isnan(...
                                        DataSamplesTrain.("known_prob_" + ...
                                        field_option(option)));
                                else
                                    select_trial = (round(...
                                        DataSamplesTrain.("known_prob_" + ...
                                        field_option(option)), 1) == prob);
                                end
                                if isnan(mag)
                                    select_trial = select_trial & isnan(...
                                        DataSamplesTrain.("known_mag_" + ...
                                        field_option(option)));
                                else
                                    select_trial = select_trial & (round(...
                                        DataSamplesTrain.("known_mag_" + ...
                                        field_option(option)), 1) == mag);
                                end
                                value_both_option(select_trial, option) = ...
                                    ValueFunction.(monkey)(i_prob, i_mag);
                            end
                        end
                    end
                    if Network.Config.output_format_label == "both"
                        output_train = value_both_option;
                    else
                        output_train = value_both_option(:, 1) - ...
                            value_both_option(:, 2);
                    end
                % Aim: predict the choice of the monkey
                case "Irrational"
                    choice_label = "choice_" + Network.Config.output_label;
                    output_train = StrippedRecords.(choice_label)(select_train)';
            end
            vec_output_train = reshape(output_train, [], 1);
    
            % --- Fit the ANN recurrent connections only --- %
    
            % Evolution and observation functions
            f_fname = [];
            switch end_state
                case "Optimal"
                    g_fname = @observeANNTuneRecurrent;
                case "Rational"
                    g_fname = @observeANN;
                case "Irrational"
                    if start_state == "Priors"
                        g_fname = @observeANN;
                    else
                        g_fname = @observeANNTuneRecurrent;
                    end
            end
            % Model dimensions (number of recurrent connections)
            switch end_state
                case "Optimal"
                    % Change only the recurrent connections
                    if Network.Config.recur_connect == "to_z"
                        field_recur = "connect_z_to_z";
                    else
                        field_recur = "connect_x_to_z";
                    end
                    n_params = length(Network.Config.ParamRange.(field_recur)) + 1;
                case "Rational"
                    % Change all ANN parameters
                    n_params = Network.Config.n_params;
                case "Irrational"
                    % Change all ANN parameters
                    if start_state == "Priors"
                        n_params = Network.Config.n_params;
                    else
                        % Change only the recurrent connections
                        if Network.Config.recur_connect == "to_z"
                            field_recur = "connect_z_to_z";
                        else
                            field_recur = "connect_x_to_z";
                        end
                        n_params = length(Network.Config.ParamRange.(field_recur));
                    end
            end
            dim = struct('n', 0, 'n_theta', 0, 'n_phi', n_params);
            % Parameters of the observation function
            options = struct();
            options.inG.input = input_train;
            options.inG.i_step = CueSamplesTrain.i_step;
            options.inG.Config = Network.Config;
            if start_state == "Priors" && end_state == "Irrational" 
                % The observation function must output a choice
                options.inG.output_choice = true;
            end
            if start_state ~= "Priors"
                % Pass all the parameters of the ANN, except for recurrent
                % connections, as parameters of the observation function
                if start_state == "Irrational"
                    fit_start = "Fit" + start_state + monkey;
                else
                    fit_start = "Fit" + start_state;
                end
                Weights = shapeParametersIntoWeights(...
                    Network.(fit_start).params(:, end), Network.Config);
                all_fields_weights = string(fieldnames(Weights)');
                for field_weight = all_fields_weights
                    if field_weight == field_recur
                        continue;
                    end
                    options.inG.(field_weight) = Weights.(field_weight);
                end
            end
            if end_state == "Irrational"
                % The ANN must predict binary choices
                options.sources = struct("type", 1);
                options.updateHP = false;
            end
            if end_state == "Optimal"
                % The observation function can use an additional linear factor
                % to scale the outputs
                options.inG.linear_output_factor = true;
            end
            % Store history of parameters
            options.store_history = true;
            % Set the priors of the model
            options.priors = struct();
            switch start_state
                case "Priors"
                    prior_params = Network.FitOptimal.params(:, 1);
                case "Optimal"
                    prior_params = Network.FitOptimal.params(:, end);
                case "Rational"
                    prior_params = Network.("FitOptimalToRational" + monkey).params(:, end);
                case "Irrational"
                    prior_params = Network.("FitIrrational" + monkey).params(:, end);
                otherwise
                    error("Unknown 'start_state'.");
            end
            switch end_state
                case "Optimal"
                    options.priors.muPhi = [prior_params(...
                        Network.Config.ParamRange.(field_recur)) ; 1];
                case "Rational"
                    options.priors.muPhi = prior_params;
                case "Irrational"
                    if start_state == "Priors"
                        options.priors.muPhi = prior_params;
                    else
                        options.priors.muPhi = prior_params(...
                            Network.Config.ParamRange.(field_recur));
                    end
            end
            % Same prior variance for all parameters, no covariance
            options.priors.SigmaPhi = 1e1 * eye(dim.n_phi);
            % Set desired verbosity settings
            options.verbose = false;
            options.DisplayWin = false;
            % Set stopping condition
            options.TolFun = 1e1;
            switch end_state
                case "Optimal"
                    options.isYout = false(length(vec_output_train), 1);
                case "Rational"
                    options.isYout = false(length(vec_output_train), 1);
                case "Irrational"
                    % Only use the last step of each trial for the fit
                    options.isYout = [CueSamplesTrain.i_step(1:(end - 1)) < ...
                        CueSamplesTrain.i_step(2:end), false]';
            end
    
            % Fit the model
            [~, out] = VBA_NLStateSpaceModel(...
                vec_output_train, [], ...
                f_fname, g_fname, dim, options);
    
            % --- Test the quality of fit --- %
    
            % Gather the parameters
            posterior_params = out.suffStat.params_history;
            % Initialize fit quality storage
            fit_train = NaN(size(posterior_params, 2), 1);
    
            % Loop through fitting steps
            for i_step = 1:size(posterior_params, 2)
                % Get model predictions at each step
                pred_output_train = feval(g_fname, ...
                    [], posterior_params(:, i_step), [], options.inG);
                pred_output_train = reshape(pred_output_train, [], ...
                    size(output_train, 2));
                % Compute the quality of predictions on last steps only
                options.isYout = reshape(options.isYout, size(output_train));
                fit_train(i_step, :) = feval(fit_quality_function, ...
                    output_train(~ options.isYout), ...
                    pred_output_train(~ options.isYout));
            end
    
            % --- Save --- %
    
            % Add all the frozen parameters in the ANN to the fitted recurrent
            % connections
            switch end_state
                case "Optimal"
                    all_params = repmat(prior_params, 1, ...
                        size(posterior_params, 2));
                    all_params(Network.Config.ParamRange.(field_recur), :) = ...
                        posterior_params(1:(end - 1), :);
                    for fit_step = 1:size(posterior_params, 2)
                        all_params(Network.Config.ParamRange.readout, fit_step) = ...
                            posterior_params(end, fit_step) * ...
                            all_params(Network.Config.ParamRange.readout, fit_step);
                    end
                case "Rational"
                    all_params = posterior_params;
                case "Irrational"
                    if start_state == "Priors"
                        all_params = posterior_params;
                    else
                        all_params = repmat(prior_params, 1, ...
                            size(posterior_params, 2));
                        all_params(Network.Config.ParamRange.(field_recur), :) = ...
                            posterior_params;
                    end
            end
            % Wrap-up the info
            Network.(fit_label).params = all_params;
            Network.(fit_label).fit_train = fit_train;
            Network.(fit_label).i_end_GnLoop = out.suffStat.i_end_GnLoop;
        end
    
        % Save the ANN
        saveNetwork(Network);
        % Update progress
        parfor_progress;
    end
    
    % Delete progress file
    parfor_progress(0);

end

end
