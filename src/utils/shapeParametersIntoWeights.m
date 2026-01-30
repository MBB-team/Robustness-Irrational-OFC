function Weights = shapeParametersIntoWeights(parameters, Config)
% Shapes a parameter vector into structured weight matrices of an RNN.
%
% This function converts the flat parameter vector into a structured,
% ready-to-use set of weight matrices and bias vectors. Connections and
% biases between the inputs and the x layer are not learned but
% deterministically constructed using a population-code scheme:
%   - Each input projects onto a dedicated pool of x units.
%   - Unit sensitivities span the input range uniformly.
%   - Input-to-x mappings are strictly monotonic, such that increasing
%     input values always increase x-unit activity.
%
% INPUTS ------------------------------------------------------------------
% parameters : <float Nx1>
%     Vector of free parameters of the RNN. This vector excludes the
%     input-to-x connection weights and x-layer biases, which are fixed
%     and defined by the population code.
%
% Config : <struct 1x1>
%     Structure defining the network architecture, input-output mapping,
%     activation function, and output format. See also:
%     getDesiredNetworkConfigs.
%
% --- OUTPUT ---
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
%     connect_z_to_x) is present, as specified by Config.recur_connect.

arguments
    parameters (:, 1) double
    Config (1, 1) struct
end

% --- Construct fixed input-to-x connections using a population code --- %

% Initialize input-to-x weights and biases
Weights.connect_in_to_x = zeros(length(Config.inputs), ...
    sum(Config.n_units_x));
Weights.biases_x = zeros(1, sum(Config.n_units_x));

% Fill in the population code for each input dimension
i_unit = 1;
for i_input = 1:length(Config.inputs)

    % Define the input range
    if Config.n_units_x(i_input) == 2
        % Binary inputs
        range_min = 0;
        range_max = 1;
    else
        % Continuous cue values
        range_min = 0.1;
        range_max = 0.9;
    end

    % Uniform spacing of unit sensitivities over the input range
    interval = (range_max - range_min) / Config.n_units_x(i_input);
    if functions(Config.f_activation).function == "gaussANN"
        slope = (2 / interval) * sqrt(log(2));
    elseif functions(Config.f_activation).function == "sigANN"
        slope = (2 / interval) * log(3);
    else
        error("Unknown activation function");
    end

    % Biases positioning unit tuning curves over the input range
    peaks = range_min:interval:range_max;
    peaks = (interval / 2) + peaks(1:(end - 1));
    biases = slope * peaks;

    % Store weights and biases
    Weights.connect_in_to_x(...
        i_input, i_unit:(i_unit + Config.n_units_x(i_input) - 1)) = ...
        slope;
    Weights.biases_x(i_unit:(i_unit + Config.n_units_x(i_input) - 1)) = ...
        biases;

    % Update unit index
    i_unit = i_unit + Config.n_units_x(i_input);
end

% --- Reshape free parameters into ready-to-use weight matrices --- %

% Feedforward connection from x to z
Weights.connect_x_to_z = reshape(...
    parameters(Config.ParamRange.connect_x_to_z), ...
    sum(Config.n_units_x), Config.n_units_z);
% Biases of the z layer
Weights.biases_z = reshape(...
    parameters(Config.ParamRange.biases_z), ...
    1, Config.n_units_z);
% Recurrent connection
if Config.recur_connect == "to_x"
    Weights.connect_z_to_x = reshape(...
        parameters(Config.ParamRange.connect_z_to_x), ...
        Config.n_units_z, sum(Config.n_units_x));
elseif Config.recur_connect == "to_z"
    Weights.connect_z_to_z = reshape(...
        parameters(Config.ParamRange.connect_z_to_z), ...
        Config.n_units_z, Config.n_units_z);
else
    error("Undefined recurrent connection.");
end
% Linear readout from z layer to outputs
Weights.readout = reshape(...
    parameters(Config.ParamRange.readout), ...
    Config.n_units_z, []);

end
