function AllNetworks = gatherAllModels(folder_name, last_step_only)
% Collects parameter vectors from all trained RNNs in a folder into a
% single, analysis-ready structure.
%
% This function loads every RNN stored in the specified folder and gathers
% the parameters produced during each training phase. Depending on the
% value of last_step_only, it either stores all fitting steps or only
% selected steps:
%   - for initial training phases, both the first step (priors) and the
%     final step are stored;
%   - for subsequent re-training phases, only the final step is stored.
%
% The collected parameters are concatenated into a single structure,
% together with metadata describing the network architecture, training
% configuration, training phase, and performance on training and test
% datasets, which is saved in the models/processed/ folder.
%
% INPUTS ------------------------------------------------------------------
% folder_name : <string 1x1>
%     Name of the folder containing the RNN files to gather (e.g.
%     "rational", "rational_subj", "irrational_Franck",
%     "irrational_Miles").
%
% last_step_only : <bool 1x1>
%     If true, only selected training steps are stored (priors + final step
%     for initial training; final step only for other fit phases). If
%     false, all training steps from all training phases are stored.
%
% OUTPUTS -----------------------------------------------------------------
% AllNetworks : <struct 1x1>
%     Structure gathering parameter vectors and associated metadata across
%     all networks and training steps. Fields include:
%       - params: parameter vectors
%       - input_label: input representation used by the network (e.g.,
%       "loc", "order")
%       - output_label: output representation predicted by the network
%       (e.g., "loc", "order", "attention")
%       - output_format_label: format of the model outputs (e.g., "both",
%       "diff", "choice")
%       - seed: random seed used to generate the datasets and initial state
%       - config_ID: ID identifying the model's 'Config' structure
%       - fit_label: name of the training phase from which the parameters
%       were extracted (e.g., "FitRational", "FitIrrationalFranck")
%       - fit_step: index of the training step within the corresponding
%       training phase
%       - fit_train: performance metric on the training dataset
%       - fit_test: performance metric on the test dataset
%       - is_initial_fit: true if the training phase is the initial
%       training, false it is a re-training
%       - is_rational: whether the network is trained to be rational
%       - is_irrational: whether the network is trained to be irrational

arguments
    folder_name (1, 1) string
    last_step_only (1, 1) logical
end

% Get paths to all RNN files in the target folder
all_path = getAllNetworkPaths(fullfile(getPath("ModelsRaw"), folder_name));
n_network = length(all_path);

% --- Count the total number of parameter vectors to store --- %

n_states = 0;
max_n_params = - Inf;

% ~ Loop through RNNs ~ %
for i_network = 1:n_network

    % Try to load the RNN
    try
        Network = load(all_path{i_network});
    catch
        [~, file_name, ~] = fileparts(all_path(i_network));
        warning("Impossible to load network n°%d: %s", i_network, file_name);
        continue;
    end

    % Identify all training phases
    fit_fields = string(fieldnames(Network))';
    fit_fields = fit_fields(contains(fit_fields, "Fit"));

    % Update parameter count and total number of stored states
    for fit_label = fit_fields
        max_n_params = max(max_n_params, size(Network.(fit_label).params, 1));
        if last_step_only
            if checkIfIsInitialTraining(folder_name, fit_label)
                % Store priors and final step
                n_states = n_states + 2;
            else
                % Store final step only
                n_states = n_states + 1;
            end
        else
            % Store all training steps
            n_states = n_states + size(Network.(fit_label).params, 2);
        end
    end
end

% --- Initialize storage structure --- %

AllNetworks = struct();

% RNN architecture
AllNetworks.input_label = strings(1, n_states);
AllNetworks.output_label = strings(1, n_states);
AllNetworks.output_format_label = strings(1, n_states);
AllNetworks.seed = NaN(1, n_states);
AllNetworks.config_ID = NaN(1, n_states);

% Training metadata
AllNetworks.fit_label = strings(1, n_states);
AllNetworks.fit_step = NaN(1, n_states);
AllNetworks.fit_train = NaN(1, n_states);
AllNetworks.fit_test = NaN(1, n_states);
AllNetworks.is_initial_fit = false(1, n_states);
AllNetworks.is_rational = false(1, n_states);
AllNetworks.is_irrational = false(1, n_states);

% Parameters
AllNetworks.params = NaN(220, n_states);

% Get all possible Config structures
all_Config = getDesiredNetworkConfigs();

% --- Extract and store all information --- %

i_state = 1;

% ~ Loop through RNNs ~ %
for i_network = 1:n_network

    try
        Network = load(all_path{i_network});
    catch
        [~, file_name, ~] = fileparts(all_path(i_network));
        warning("Impossible to load network n°%d: %s", i_network, file_name);
        continue;
    end

    % Get the Config ID
    config_ID = find(cellfun(@(x) isequaln(x, Network.Config), all_Config));

    % Loop through fit phases
    fit_fields = string(fieldnames(Network))';
    fit_fields = fit_fields(contains(fit_fields, "Fit"));
    for fit_label = fit_fields

        % Select training steps to store
        n_steps = size(Network.(fit_label).params, 2);
        if last_step_only
            if checkIfIsInitialTraining(folder_name, fit_label)
                all_i_step = [1, n_steps];
            else
                all_i_step = n_steps;
            end
        else
            all_i_step = 1:n_steps;
        end

        % Prepare parameters save
        n_params = size(Network.(fit_label).params, 1);

        % ~ Loop through selected training steps ~ %
        for i_step = all_i_step

            % Save RNN architecture
            AllNetworks.input_label(i_state) = Network.Config.input_label;
            AllNetworks.output_label(i_state) = Network.Config.output_label;
            AllNetworks.output_format_label(i_state) = Network.Config.output_format_label;
            AllNetworks.seed(i_state) = Network.seed;
            AllNetworks.config_ID(i_state) = config_ID;
            
            % Save training metadata
            AllNetworks.fit_label(i_state) = fit_label;
            AllNetworks.fit_step(i_state) = i_step;
            AllNetworks.fit_train(i_state) = Network.(fit_label).fit_train(i_step);
            AllNetworks.fit_test(i_state) = Network.(fit_label).fit_test(i_step);
            AllNetworks.params(1:n_params, i_state) = Network.(fit_label).params(:, i_step);
            AllNetworks.is_initial_fit(i_state) = checkIfIsInitialTraining(folder_name, fit_label);
            AllNetworks.is_rational(i_state) = (fit_label == "FitRational");
            AllNetworks.is_irrational(i_state) = contains(fit_label, "FitIrrational");


            i_state = i_state + 1;
        end
    end
end

% Rename first step of initial training as "Priors"
AllNetworks.fit_label(...
    checkIfIsInitialTraining(folder_name, AllNetworks.fit_label) & ...
    (AllNetworks.fit_step == 1)) = "Priors";
AllNetworks.is_rational(AllNetworks.fit_label == "Priors") = false;
AllNetworks.is_irrational(AllNetworks.fit_label == "Priors") = false;

% --- Save --- %

% Define file name
file_name = folder_name;
if last_step_only
    file_name = file_name + "_last";
else
    file_name = file_name + "_full";
end 
file_name = file_name + ".mat";
save(fullfile(getPath("Models"), file_name), "-struct", "AllNetworks");
