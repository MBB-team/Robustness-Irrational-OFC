% Shapes the parameters vector of an ANN into easily manipulable weights.

function Weights = shapeParametersIntoWeights(parameters, Config)
% --- INPUT ---
% parameters: [n_params x 1] double
%   Vector of parameters of the ANN (without the connection between the
%   inputs and x layer, and the biases of the x layer).
% Config: structure
%   .input_labels: [1 x n_inputs] string
%       List of labels defining the information taken as input by the ANN.
%       The labels correspond to the fields that will be selected from the
%       'SamplesData' structure defining all the possible information
%       regarding each sample.
%   .output_labels: [1 x n_outputs] string
%       List of labels defining the target information outputted by the
%       ANN.
%   .f_activation: function handle
%       Activation function applied by each internal unit of the ANN.
%   .recur_connect: "to_x" or "to_z"
%       String defining whether the recurrent connection of the ANN
%       connects the x layer to itself, or the x layer to the z layer.
%   .n_units_x: [1 x n_inputs] double
%       List containing the number of units dedicated to encoding each
%       input in the x layer, depending on whether it is binary or not.
%   .n_units_z: double
%       Number of units in the z layer.
%   .ParamRange: structure
%       The fields of this structure contain the indices of the
%       parameters constructing the corresponding field in a 'Weights'
%       structure: connect_x_to_z, biases_z, connect_z_to_x or
%       connect_z_to_z and readout.
%   .n_params: double
%       Total number of parameters in the ANN.
%
% --- OUTPUT ---
% Weights: structure
%   .connect_in_to_x: [n_inputs x n_units_x] double
%       Sparse connection matrix between the inputs and the x layer.
%   .biases_x: [1 x n_units_x] double
%       Bias vector applied to the units of the x layer.
%   .connect_x_to_z: [n_units_x x n_units_z] double
%       Connection matrix between the x and z layer.
%   .bias_z: [1 x n_units_z] double
%       Bias vector applied to the units of the z layer.
%   .connect_x_to_x: [n_units_x x n_unit_x] double
%       If the network has a recurrent connection from the x layer to
%       itself, this matrix defines the connection.
%   .connect_z_to_x: [n_units_z x n_unit_x] double
%       If the network has a recurrent connection from the x layer to
%       the z layer, this matrix defines the connection.
%   .readout: [n_units_z x n_outputs] double
%       Readout vector enabling to decode the activity in the z layer
%       in order to extract the outputs.
%   .readout_sigmoid: [1 x 2] double
%       If the ANN outputs a categorical prediction (i.e the choice of the
%       best option), this vector contains the slope and bias of the
%       sigmoid applied to the linear readout.
%
% --- CALLED BY ---
% observeANN
% trainNetworkCohort
% checkInformationLoss
% computeNeuralRepresentation


% --- Create the connections and biases to the x layer using population
% code --- %

% Initialize the matrices
Weights.connect_in_to_x = zeros(length(Config.inputs), ...
    sum(Config.n_units_x));
Weights.biases_x = zeros(1, sum(Config.n_units_x));

% Fill in the connection matrix and biases input per input
i_unit = 1;
for i_input = 1:length(Config.inputs)
    % Get the range of inputs for binary inputs
    if Config.n_units_x(i_input) == 2
        range_min = 0;
        range_max = 1;
    % Get the range of inputs for non-binary inputs (cue value)
    else
        range_min = 0.1;
        range_max = 0.9;
    end
    % Compute the interval between uniformaly distributed activation 
    % functions on this range
    interval = (range_max - range_min) / Config.n_units_x(i_input);
    % Define the slope of the transformation between input and unit
    % activity
    if functions(Config.f_activation).function == "gaussANN"
        slope = (2 / interval) * sqrt(log(2));
    elseif functions(Config.f_activation).function == "sigANN"
        slope = (2 / interval) * log(3);
    else
        error("Unknown activation function");
    end
    % Define the biases of each unit
    peaks = range_min:interval:range_max;
    peaks = (interval / 2) + peaks(1:(end - 1));
    biases = slope * peaks;
    % Store this information into the weight matrices
    Weights.connect_in_to_x(...
        i_input, i_unit:(i_unit + Config.n_units_x(i_input) - 1)) = ...
        slope;
    Weights.biases_x(i_unit:(i_unit + Config.n_units_x(i_input) - 1)) = ...
        biases;
    % Update the unit index
    i_unit = i_unit + Config.n_units_x(i_input);
end

% --- Shape the parameters into easily manipulable weight matrices --- %

% Connection from x to z
Weights.connect_x_to_z = reshape(...
    parameters(Config.ParamRange.connect_x_to_z), ...
    sum(Config.n_units_x), Config.n_units_z);
% z biases
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
% Readout vector
Weights.readout = reshape(...
    parameters(Config.ParamRange.readout), ...
    Config.n_units_z, []);

end
