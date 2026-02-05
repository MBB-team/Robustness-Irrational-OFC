function [out] = performTraining(Config, input_train, output_train, ...
    init_params, i_step, train_all_params)
% Trains a single RNN from a specified initial parameter state.
%
% This function fits an RNN to a training dataset using variational
% Bayesian inference. Training starts from a predefined set of initial
% parameters and can either optimize all network parameters or selectively
% re-train the recurrent connections while keeping all other parameters
% fixed.
%
% INPUTS ------------------------------------------------------------------
% Config : <struct 1x1>
%     Structure defining the task-specific input–output mapping and RNN
%     architecture. See also: getDesiredNetworkConfigs.
%
% input_train : <float NxM>
%     Matrix of task inputs used during training, with M input dimensions
%     defined over N time steps.
%
% output_train : <float NxR>
%     Matrix of target outputs used during training, with R output
%     dimensions defined over N time steps.
%
% init_params : <float Px1>
%     Vector of initial network parameters (connection weights and unit
%     biases) used to initialize RNN training.
%
% i_step (optional) : <int 1xN>
%     Within-trial time step at which each cue is sampled. Required when
%     fitting choice outputs; if empty, all trials are assumed to last
%     four time steps.
%
% train_all_params (optional) : <logical 1x1>
%     Whether to re-train all network parameters (true) or restrict
%     optimization to recurrent connections only (false, default).
% 
% OUTPUTS -----------------------------------------------------------------
% out : <struct 1x1>
%     Structure containing fitted model parameters, convergence statistics,
%     and training diagnostics. See also: VBA_NLStateSpaceModel.

arguments
    Config (1, 1) struct
    input_train (:, :) double
    output_train (:, :) double
    init_params (:, 1) double
    i_step (1, :) double {mustBeInteger} = []
    train_all_params (1, 1) logical = true
end

% Easily toggle test mode
TEST_MODE = false;

% --- Initialize the VBA model --- %
        
% Evolution and observation functions (static dynamics)
f_fname = [];
if train_all_params
    g_fname = @observeANN;
else
    g_fname = @observeANNTuneRecurrent;
end

% Parameters of the observation function
options = struct();
options.inG.Config = Config;
options.inG.input = input_train;
if ~ train_all_params
    % Send all parameters to the observation function
    Weights = shapeParametersIntoWeights(init_params, Config);
    options.inG.Weights = Weights;
end

% Model dimensions (no hidden states; parameters only)
if train_all_params
    dim = struct('n', 0, 'n_theta', 0, 'n_phi', Config.n_params);
else
    % Re-train recurrent connections only
    i_recur_connect = Config.ParamRange.("connect_z_" + Config.recur_connect);
    dim = struct('n', 0, 'n_theta', 0, 'n_phi', ...
        length(i_recur_connect) + 1);
end
% Prior mean different from 0
options.priors.muPhi = 1e-1 * ones(dim.n_phi, 1);
% Same prior variance for all parameters, no covariance
options.priors.SigmaPhi = 1e1 * eye(dim.n_phi);
% Specific options when fitting choice outputs
if Config.output_format_label == "choice"
    % Binary observations
    options.sources = struct("type", 1);
    options.updateHP = false;
    % Restrict predictions to the last time step of each trial
    if isempty(i_step)
        error("Cue steps must be provided when fitting choice outputs.");
    end
    options.isYout = [i_step(1:(end - 1)) < i_step(2:end), false]';
    options.inG.i_step = i_step;
end

% --- Set initial state --- %

% Run a single iteration to initialize the posterior structure
options.GnMaxIter = 1;
options.MaxIter = 1;
options.verbose = false;
options.DisplayWin = false;
[posterior, out] = VBA_NLStateSpaceModel(...
    reshape(output_train, [], 1), [], ...
    f_fname, g_fname, dim, options);

% Overwrite posterior mean with predefined initial parameters
posterior.muPhi = init_params;
if ~ train_all_params
    posterior.muPhi = posterior.muPhi(i_recur_connect);
end

% Special initialization for reduced ("value comparison") architectures
if Config.n_params < 220
    % Initialize readout weights as differences between single value
    % readouts
    posterior.muPhi(Config.ParamRange.readout) = ...
        posterior.muPhi(Config.ParamRange.readout) - ...
        init_params((Config.n_params + 1):(Config.n_params + Config.n_units_z));
    posterior.muPhi = posterior.muPhi(1:Config.n_params);
end

% --- Full training --- %

% Reset iteration counter
out.it = 0;

% Set stopping criteria
if TEST_MODE
    warning("Running in TEST_MODE: early stopping enabled.");
    out.options.GnMaxIter = 2;
    out.options.MinIter = 1;
    out.options.MaxIter = 2;
    out.options.TolFun = 1e1;
else
    out.options.GnMaxIter = 32;
    out.options.MinIter = 5;
    out.options.MaxIter = 32;
    out.options.TolFun = 1e1;
end

% Set desired verbosity settings
out.options.verbose = false;
out.options.DisplayWin = false;

% Store parameter trajectories across iterations
out.options.store_history = true;

% Re-run VBA from the specified initial state
in = struct();
in.posterior = posterior;
in.out = out;
[~, out] = VBA_NLStateSpaceModel(...
    reshape(output_train, [], 1), [], ...
    f_fname, g_fname, dim, out.options, in);
