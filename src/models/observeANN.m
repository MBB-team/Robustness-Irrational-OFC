function output = observeANN(~, P, ~, in)
% Predicts the outputs of an RNN given its parameters and inputs.
%
% This observation function is used by VBA to compute the network outputs
% for a given set of parameters and inputs. It reshapes the parameter
% vector into weight matrices, propagates inputs through the RNN according
% to its architecture, applies the activation function, and returns
% vectorized predictions. If weight matrices are already provided, only
% recurrent connections are optimized. If the network produces choice
% outputs, the predictions are converted to probabilities. Optional
% biological constraints can also be applied.
%
% INPUTS ------------------------------------------------------------------
% P : <float Px1>
%     Vector of RNN parameters (weights and biases).
%
% in : <struct 1x1>
%     Structure containing RNN configuration and inputs:
%       - Config : defines the architecture, input-output mapping,
%           activation function, and output format of the RNN (see also:
%           getDesiredNetworkConfigs)
%       - input : inputs provided to the RNN, where each row corresponds to
%           one sample
%       - Weights : structure containing weight matrices and bias vectors
%           (see also: reshapeParametersIntoWeights)
%       - i_step (optional) : index of the within-trial step at which each
%           input is sampled (if missing, all trials are assumed to last
%           four steps)
%       - function_constraint, target_constraint, weight_constraint,
%         args_constraint (optional) : fields used to apply additional
%           biological constraints
%
% OUTPUTS -----------------------------------------------------------------
% output : <float Nx1>
%     Vectorized predictions produced by the RNN, optionally concatenated
%     with constraint outputs.
%

arguments
    ~
    P (:, 1) double
    ~
    in (1, 1) struct
end

if isfield(in, "Weights")
    % Replace existing recurrent connection parameters with tunable
    % parameters
    Weights = in.Weights;
    Weights.("connect_z_" + in.Config.recur_connect) = reshape(P, ...
        size(Weights.("connect_z_" + in.Config.recur_connect)));
else
    % Reshape parameters into weight matrices
    Weights = shapeParametersIntoWeights(P, in.Config);
end

% Propagate inputs through the RNN
if isfield(in, 'i_step')
    [~, ~, output] = propagateThroughANN(Weights, ...
        in.Config.f_activation, in.input, in.i_step);
else
    [~, ~, output] = propagateThroughANN(Weights, ...
        in.Config.f_activation, in.input);
end

% Conver the outputs to choice probabilities if needed
if in.Config.output_format_label == "choice"
    if size(output, 2) == 2
        output = output(:, 1) - output(:, 2);
    end
    output = sigANN(- output, 0);
end

% Vectorize outputs
output = reshape(output, [], 1);

% Append biological constraints (optional)
if isfield(in, "function_constraint") && isfield(in, "target_constraint")
    [~, activity_z_all, output_all] = propagateThroughANN(Weights, ...
        in.Config.f_activation, in.input_all, in.i_step_all);
    model_constraint = in.weight_constraint * ...
        in.function_constraint(Weights, activity_z_all, output_all, in.args_constraint);
    model_constraint = repmat(model_constraint, size(output, 1), size(output, 2));
    output = [output ; model_constraint];
end
