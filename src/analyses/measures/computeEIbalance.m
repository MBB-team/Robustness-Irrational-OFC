function analysis_output = computeEIbalance(params, Config, ~, ~)
% Computes the excitatory / inhibitory balance of an RNN.
%
% This measure quantifies the ratio of excitatory (positive) to inhibitory
% (negative) connections within the network, considering both feedforward
% and recurrent weights.
%
% As with all functions in the 'measures' folder, this function can be
% called in two modes: when called without parameters, it performs any
% required preprocessing and returns the corresponding inputs; when called
% with parameters, it applies the measure to the RNN using these inputs.
%
% INPUTS ------------------------------------------------------------------
% params : <float Px1> | []
%     Vector of RNN parameters. If empty, the function runs in
%     preprocessing mode and returns the analysis inputs instead of
%     computing measures.
%
% Config : <struct 1x1>
%     Configuration structure defining the RNN architecture.
%
%
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Empty structure.
%     - In analysis mode:
%     Structure containing the measure results:
%       - EI_balance <1x1>: ratio of excitatory (positive) to inhibitory
%       (negative) connections, computed over feedforward and recurrent
%       connections
%       - EI_balance_shifted <1x1>: 'EI_balance' shifted by 1, so that the
%       function's output can readily be optimize toward 0 during RNN
%       training with constraints (see also: trainModelsInitialRational).

arguments
    params (:,1) double = []
    Config (1,1) struct = struct()
    ~
    ~
end

if isempty(params)
    
    % --- Preprocessing mode: do nothing --- %

    analysis_output = struct();

else

    % --- Analysis mode: compute the E/I balance --- %

    % Reshape the flat parameter vector into network weights
    Weights = shapeParametersIntoWeights(params, Config);

    % Select the recurrent connections
    if Config.recur_connect == "to_x"
        recur_connect = Weights.connect_z_to_x;
    else
        recur_connect = Weights.connect_z_to_z;
    end

    % Compute the excitatory/inhibitory ratio of weights within feedforward
    % and recurrent connections
    analysis_output.EI_balance = ...
        (sum(Weights.connect_x_to_z > 0, "all") + sum(recur_connect > 0, "all")) / ...
        (sum(Weights.connect_x_to_z < 0, "all") + sum(recur_connect < 0, "all"));

    % Shift the result so that the desired state (E/I balance = 1) is
    % obtained at 0
    analysis_output.EI_balance_shifted = analysis_output.EI_balance - 1;
end
