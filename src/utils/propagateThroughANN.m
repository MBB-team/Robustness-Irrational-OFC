% Propagates inputs through an ANN defined by its weights, and outputs the
% ANN predicted outputs as well as its internal activity.

function [activity_x, activity_z, output] = propagateThroughANN(...
    Weights, f_activation, input, i_step, impaired)
% --- INPUT ---
% Weights: structure
%   .connect_in_to_x: [n_inputs x n_units_x] double
%       Sparse connection matrix between the inputs and the x layer.
%   .biases_x: [1 x n_units_x] double
%       Bias vector applied to the units of the x layer.
%   .connect_x_to_z: [n_units_x x n_units_z] double
%       Connection matrix between the x and z layer.
%   .bias_z: [1 x n_units_z] double
%       Bias vector applied to the units of the z layer.
%   .connect_z_to_z: [n_units_x x n_unit_x] double
%       If the network has a recurrent connection from the z layer to
%       itself, this matrix defines the connection.
%   .connect_z_to_x: [n_units_z x n_unit_x] double
%       If the network has a recurrent connection from the x layer to
%       the x layer, this matrix defines the connection.
%   .readout: [n_units_z x n_outputs] double
%       Readout vector enabling to decode the activity in the z layer
%       in order to extract the outputs.
% f_activation: function handle
%   Activation function applied by each internal unit.
% input: [n_sample x n_inputs] double
%   Inputs provided to the ANN, where each line corresponds to the sampling
%   of a cue.
% i_step: [1 x n_samples] double
%   [Optional] Index of the step at which each cue was sampled. If this
%   information is not provided, by default all trials are considered to
%   last 4 steps.
%
% --- OUTPUT ---
% activity_x: [n_samples x n_units_x] double
%   Activity of each unit in the x layer in response to each sampling.
% activity_z: [n_samples x n_units_z] double
%   Activity of each unit in the z layer in response to each sampling.
% output: [n_samples x n_outputs] double
%   Predicted output for each sampling.

% --- CHECK INPUT ARGUMENTS --- %

arguments
    Weights (1,1) struct;
    f_activation (1,1) function_handle;
    input (:,:) double {mustBeFinite};
    i_step (:,:) double {mustBeFinite} = [];
    impaired.impaired_x (:,:) double {mustBeFinite} = [];
    impaired.impaired_z (:,:) double {mustBeFinite} = [];
end

% Format input
impaired.impaired_x = logical(impaired.impaired_x);
impaired.impaired_z = logical(impaired.impaired_z);

% Initialize the storing variables
n_samples = size(input, 1);
activity_x = NaN(n_samples, length(Weights.biases_x));
activity_z = NaN(n_samples, length(Weights.biases_z));
output = NaN(n_samples, size(Weights.readout, 2));

% Set the default step index
if isempty(i_step)
    i_step = repmat(1:4, 1, floor(n_samples / 4));
end

% --- Propagate the inputs through the networks --- %

for i_sample = 1:n_samples

    % Do not take recurrent connection into account at the first step
    if i_step(i_sample) == 1
        activity_x(i_sample, :) = f_activation( ...
            (input(i_sample, :) * Weights.connect_in_to_x), ...
            Weights.biases_x);
        % Impair some units in layer x
        if ~ isempty(impaired.impaired_x)
            activity_x(i_sample, impaired.impaired_x) = 0;
        end
        activity_z(i_sample, :) = f_activation(...
            (activity_x(i_sample, :) * Weights.connect_x_to_z), ...
            Weights.biases_z);
        % Impair some units in layer z
        if ~ isempty(impaired.impaired_z)
            activity_z(i_sample, impaired.impaired_z) = 0;
        end

    % Take the z-to-x recurrent connection into account for the next steps
    elseif isfield(Weights, 'connect_z_to_x')
        activity_x(i_sample, :) = f_activation(...
            (input(i_sample, :) * Weights.connect_in_to_x) ...
            + (activity_z(i_sample - 1, :) * Weights.connect_z_to_x), ...
            Weights.biases_x);
        % Impair some units in layer x
        if ~ isempty(impaired.impaired_x)
            activity_x(i_sample, impaired.impaired_x) = 0;
        end
        activity_z(i_sample, :) = f_activation(...
            (activity_x(i_sample, :) * Weights.connect_x_to_z), ...
            Weights.biases_z);   
        % Impair some units in layer z
        if ~ isempty(impaired.impaired_z)
            activity_z(i_sample, impaired.impaired_z) = 0;
        end     
    
    % Take the z-to-z recurrent connection into account for the next steps
    elseif isfield(Weights, 'connect_z_to_z')
        activity_x(i_sample, :) = f_activation(...
            (input(i_sample, :) * Weights.connect_in_to_x), ...
            Weights.biases_x);
        % Impair some units in layer x
        if ~ isempty(impaired.impaired_x)
            activity_x(i_sample, impaired.impaired_x) = 0;
        end
        activity_z(i_sample, :) = f_activation(...
            (activity_x(i_sample, :) * Weights.connect_x_to_z) ...
            + (activity_z(i_sample - 1, :) * Weights.connect_z_to_z), ...
            Weights.biases_z);
        % Impair some units in layer z
        if ~ isempty(impaired.impaired_z)
            activity_z(i_sample, impaired.impaired_z) = 0;
        end
    else
        error("Unknown recurrent connection matrix.");
    end

    % Linear readout of the z layer activity
    output(i_sample, :) = activity_z(i_sample, :) * Weights.readout;

end

end
