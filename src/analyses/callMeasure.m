function [] = callMeasure(analysis_function, params_file_name, options)
% Applies an analysis function to a set of RNN parameter vectors.
%
% This function loads stored RNN parameters together with their associated
% configuration identifiers and random seeds, optionally augments the
% analysis with supplementary variables, and applies a user-defined
% analysis function independently to each parameter vector.
%
% The analysis function must support two calling modes:
%   1) preprocess = analysis_function()
%        Performs any preprocessing shared across all networks and returns
%        a structure passed unchanged to subsequent calls.
%   2) output = analysis_function(params, Config, seed, preprocess)
%        Computes analysis outputs for a single network instance.
%
% Results are aggregated across networks and appended to the original
% parameter file.
%
% INPUTS ------------------------------------------------------------------
% analysis_function : <function_handle 1x1>
%     Handle to the analysis function to apply. Analysis functions are
%     expected to be in the 'src/analyses' folder.
%
% params_file_name : <string 1x1>
%     Name of the .mat file containing stored parameter vectors and
%     associated metadata.
%
% supp_variable (optional, named) : <string 1xN>
%     Names of supplementary variables stored in the parameter file that
%     should be passed to the analysis function for each network.
%
% select_data (optional, named) : <logical 1xM>
%     Logical mask selecting which parameter vectors should be analyzed.
%     If empty, all parameter vectors are processed.
%
% OUTPUTS -----------------------------------------------------------------
% (none)
%     Analysis outputs are appended to the parameter file specified by
%     'params_file_name' as separate variables.

arguments
    analysis_function (1, 1) function_handle
    params_file_name (1, 1) string
    options.supp_variable (1, :) string = []
    options.select_data (1, :) logical = []
end

% --- Load stored parameters and metadata --- %

params_file_path = fullfile(getPath("Models"), params_file_name);

% Load minimum analysis function arguments
all_params = load(params_file_path, "params").params;
all_config_ID = load(params_file_path, "config_ID").config_ID;
all_seed = load(params_file_path, "seed").seed;

n_data = size(all_params, 2);

% Load supplementary variables
SuppVariables = struct();
for supp_variable = options.supp_variable
    SuppVariables.(supp_variable) = load(params_file_path, supp_variable).(supp_variable);
end

% Load all available configuration structures
all_Config = getDesiredNetworkConfigs();

% By default, analyze all the data points
if isempty(options.select_data)
    options.select_data = true(1, n_data);
end
n_data_selected = sum(options.select_data);
all_i_selected = find(options.select_data);

% --- Initialize analysis outputs --- %

% Run preprocessing stage of the analysis function
preprocess_inputs = analysis_function();

% Run analysis once to infer output structure and dimensions
i_network = all_i_selected(1);
params = all_params(:, i_network);
params = params(~ isnan(params));
Config = all_Config{all_config_ID(i_network)};
seed = all_seed(i_network);

preprocess_inputs_with_supp = preprocess_inputs;
for supp_variable = options.supp_variable
    preprocess_inputs_with_supp.(supp_variable) = SuppVariables.(supp_variable)(:, i_network);
end

analysis_output = analysis_function(params, Config, seed, preprocess_inputs_with_supp);

all_output_names = string(fieldnames(analysis_output))';

% Preallocate final storage
AnalysisOutputs = struct();
for output_name = all_output_names
    AnalysisOutputs.(output_name) = NaN(numel(analysis_output.(output_name)), n_data_selected);
end

% Temporary storage for parallel loop (parfor-safe)
TempOutputs = cell(1, n_data_selected);

% --- Parallel analysis over parameter vectors --- %

if isempty(gcp("nocreate"))
    % Initialize parallel pool
    delete(gcp("nocreate"));
    % Define number of workers on a Slurm cluster
    num_workers = str2double(getenv("SLURM_CPUS_PER_TASK"));
    % Define number of workers when ran locally
    if isnan(num_workers) || num_workers < 1
        num_workers = feature('numcores');
    end
    % Activate the parallel pool
    parpool("local", num_workers);
end


% ~ Loop through parameter vectors ~ %
for i_data = 1:n_data_selected

    i_network = all_i_selected(i_data);

    % Extract parameters for this network
    params = all_params(:, i_network);
    params = params(~isnan(params));
    Config = all_Config{all_config_ID(i_network)};
    seed   = all_seed(i_network);

    % Assemble preprocessing inputs with supplementary variables
    preprocess_inputs_with_supp = preprocess_inputs;
    for supp_variable = options.supp_variable
        preprocess_inputs_with_supp.(supp_variable) = ...
            SuppVariables.(supp_variable)(:, i_network);
    end

    % Run analysis function
    TempOutputs{i_data} = analysis_function( ...
        params, Config, seed, preprocess_inputs_with_supp);

end

% --- Aggregate analysis outputs --- %

for i_data = 1:n_data_selected
    for output_name = all_output_names
        AnalysisOutputs.(output_name)(:, i_data) = reshape(TempOutputs{i_data}.(output_name), [], 1);
    end
end

% --- Save --- %

save(params_file_path, "-struct", "AnalysisOutputs", "-append");
