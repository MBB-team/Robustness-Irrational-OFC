function [activity_x, activity_z, output] = propagateThroughANN(...
    Weights, f_activation, input, i_step, options)
% Propagate inputs through an RNN and return internal activity and outputs.
%
% This function performs a forward pass through an RNN defined by a set of
% weights and biases and an activation function. For each input sample, it
% computes the activity of the first (x) and second (z) hidden layers,
% applies recurrent connections, and generates the corresponding network
% output via a linear readout. See also: observeANN,
% shapeParametersIntoWeights.
%
% INPUTS ------------------------------------------------------------------
% Weights : <struct 1x1>
%     Structure containing weight matrices and bias vectors. See also:
%     shapeParametersIntoWeights.
%       - connect_in_to_x: input-to-x feedforward weight matrix
%       - biases_x: bias vector for the x layer
%       - connect_x_to_z: feedforward weight matrix from x to z
%       - bias_z: bias vector for the z layer
%       - connect_z_to_z: recurrent weight matrix from z to z
%       - connect_z_to_x: recurrent weight matrix from z to x
%       - readout: linear readout matrix mapping z activity to outputs
%     Exactly one of the two recurrent connection fields (connect_z_to_z,
%     connect_z_to_x) must be present.
%
% f_activation : <function_handle 1x1>
%     Activation function applied element-wise to x and z units.
%
% input : <float NxM>
%     Input samples provided to the network. Each row corresponds to one
%     cue sampling.
%
% i_step (optional) : <int 1xN>
%     Step index associated with each sample, used to reset recurrent
%     activity at the beginning of a trial. If empty, samples are assumed
%     to be grouped in trials of four steps.
%
% impaired_x (optional) : <bool 1xX>
%     Mask indicating x-layer units to be silenced (set to empty).
%
% impaired_z (optional) : <bool 1xZ>
%     Mask indicating z-layer units to be silenced (set to empty).
%
% noise_x (optional) : <float 1xX>
%     Neural noise added to x-layer units (set to 0).
%
% noise_z (optional) : <float 1xZ>
%     Neural noise added to z-layer units (set to 0).
%
% OUTPUTS -----------------------------------------------------------------
% activity_x : <float NxX>
%     Activity of x-layer units for each input sample.
%
% activity_z : <float NxZ>
%     Activity of z-layer units for each input sample.
%
% output : <float NxO>
%     Network output associated with each input sample.

arguments
    Weights (1,1) struct
    f_activation (1,1) function_handle
    input (:,:) double
    i_step (:,:) double = []
    options.impaired_x (:,:) double {mustBeFinite} = []
    options.impaired_z (:,:) double {mustBeFinite} = []
    options.noise_x (:,:) double {mustBeFinite} = zeros(size(input, 1), length(Weights.biases_x))
    options.noise_z (:,:) double {mustBeFinite} = zeros(size(input, 1), length(Weights.biases_z))
end

% Initialize storage variables
n_samples = size(input, 1);
activity_x = NaN(n_samples, length(Weights.biases_x));
activity_z = NaN(n_samples, length(Weights.biases_z));
output = NaN(n_samples, size(Weights.readout, 2));

% Default step indexing (four steps per trial)
if isempty(i_step)
    i_step = repmat(1:4, 1, floor(n_samples / 4));
end

% --- Forward propagation through the network --- %

for i_sample = 1:n_samples

    % First step of a trial: no recurrent contribution
    if i_step(i_sample) == 1

        activity_x(i_sample, :) = f_activation( ...
            (input(i_sample, :) * Weights.connect_in_to_x), ...
            Weights.biases_x);

        % Add internal noise if requested
        activity_x(i_sample, :) = activity_x(i_sample, :) + options.noise_x(i_sample, :);

        % Apply x-layer impairment if requested
        if ~ isempty(options.impaired_x)
            activity_x(i_sample, options.impaired_x) = 0;
        end

        activity_z(i_sample, :) = f_activation(...
            (activity_x(i_sample, :) * Weights.connect_x_to_z), ...
            Weights.biases_z);

        % Add internal noise if requested
        activity_z(i_sample, :) = activity_z(i_sample, :) + options.noise_z(i_sample, :);

        % Apply z-layer impairment if requested
        if ~ isempty(options.impaired_z)
            activity_z(i_sample, options.impaired_z) = 0;
        end

    % Recurrent connection from z to x
    elseif isfield(Weights, 'connect_z_to_x')

        activity_x(i_sample, :) = f_activation(...
            (input(i_sample, :) * Weights.connect_in_to_x) ...
            + (activity_z(i_sample - 1, :) * Weights.connect_z_to_x), ...
            Weights.biases_x);

        activity_x(i_sample, :) = activity_x(i_sample, :) + options.noise_x(i_sample, :);
        if ~ isempty(options.impaired_x)
            activity_x(i_sample, options.impaired_x) = 0;
        end

        activity_z(i_sample, :) = f_activation(...
            (activity_x(i_sample, :) * Weights.connect_x_to_z), ...
            Weights.biases_z);

        activity_z(i_sample, :) = activity_z(i_sample, :) + options.noise_z(i_sample, :); 
        if ~ isempty(options.impaired_z)
            activity_z(i_sample, options.impaired_z) = 0;
        end     
    
    % Recurrent connection from z to z
    elseif isfield(Weights, 'connect_z_to_z')

        activity_x(i_sample, :) = f_activation(...
            (input(i_sample, :) * Weights.connect_in_to_x), ...
            Weights.biases_x);

        activity_x(i_sample, :) = activity_x(i_sample, :) + options.noise_x(i_sample, :);
        if ~ isempty(options.impaired_x)
            activity_x(i_sample, options.impaired_x) = 0;
        end

        activity_z(i_sample, :) = f_activation(...
            (activity_x(i_sample, :) * Weights.connect_x_to_z) ...
            + (activity_z(i_sample - 1, :) * Weights.connect_z_to_z), ...
            Weights.biases_z);

        activity_z(i_sample, :) = activity_z(i_sample, :) + options.noise_z(i_sample, :); 
        if ~ isempty(options.impaired_z)
            activity_z(i_sample, options.impaired_z) = 0;
        end
    else
        error("No valid recurrent connection defined in Weights.");
    end

    % Linear readout from z-layer activity
    output(i_sample, :) = activity_z(i_sample, :) * Weights.readout;

end
