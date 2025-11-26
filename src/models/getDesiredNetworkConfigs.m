% Defines the 'Config' structures characterizing all the cohorts to train.

function all_Config = getDesiredNetworkConfigs()
% --- OUTPUT ---
% This function outputs a cell array of 'Config' structures, which contain
% the following fields:
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
% --- CALLED BY ---
% trainNetworkCohorts


%% --- PARAMETERS --- %%

% Define, by hand, the desired set of transformations to be performed by
% the cohorts of ANNs.

INPUTS = {...
    ... Location as input, location as output
    ["cue_type", "cue_value", "option_loc"], ...
    ["cue_type", "cue_value", "option_loc"], ...
    ... Location as input, order as output
    ["cue_type", "cue_value", "option_loc"], ...
    ["cue_type", "cue_value", "option_loc"], ...
    ... Location as input, attention as output
    ["cue_type", "cue_value", "option_loc"], ...
    ["cue_type", "cue_value", "option_loc"], ...
    ... Order as input, order as output
    ["cue_type", "cue_value", "option_order"], ...
    ["cue_type", "cue_value", "option_order"], ...
    ... Order as input, attention as output
    ["cue_type", "cue_value", "option_order"], ...
    ["cue_type", "cue_value", "option_order"], ...

};

OUTPUTS = {...
    ... Location as input, location as output
    ["value_left", "value_right"], ...
    "diff_value_loc", ...
    ... Location as input, order as output
    ["value_first", "value_second"], ...
    "diff_value_order", ...
    ... Location as input, attention as output
    ["value_attended", "value_unattended"], ...
    "diff_value_attention", ...
    ... Order as input, order as output
    ["value_first", "value_second"], ...
    "diff_value_order", ...
    ... Order as input, attention as output
    ["value_attended", "value_unattended"], ...
    "diff_value_attention", ...
};

% Define, by hand, the different architectural properties constraining the
% cohorts of ANNs.

F_ACTIVATION = {@sigANN};
RECUR_CONNECT = "to_z";
N_UNITS_Z = 10;
N_UNITS_BINARY = 2; % number of units per binary input in the x layer
N_UNITS_RANGE = 5; % number of units per non-binary input in the x layer


%% --- MAIN --- %%

% Initialize the cell array of 'Config' structures
if length(INPUTS) ~= length(OUTPUTS)
    error("The number of input and output configurations do not match.");
end
n_config = length(INPUTS) ...
    * length(F_ACTIVATION) ...
    * length(RECUR_CONNECT);
all_Config = cell(1, n_config);

% --- Aggregate 'Config' structures --- %

i_config = 1;
for i_function = 1:length(INPUTS)
    for i_f_act = 1:length(F_ACTIVATION)
        for i_recur = 1:length(RECUR_CONNECT)

            % Store the information defining the cohort
            all_Config{i_config}.inputs = INPUTS{i_function};
            all_Config{i_config}.outputs = OUTPUTS{i_function};
            all_Config{i_config}.f_activation = F_ACTIVATION{i_f_act};
            all_Config{i_config}.recur_connect = RECUR_CONNECT{i_recur};

            % --- Labels defining the cohort in human-friendly terms --- %

            % What information is provided as input
            if any(contains(INPUTS{i_function}, "loc"))
                all_Config{i_config}.input_label = "loc";
            elseif any(contains(INPUTS{i_function}, "order"))
                all_Config{i_config}.input_label = "order";
            elseif any(contains(INPUTS{i_function}, "attention"))
                all_Config{i_config}.input_label = "attention";
            else
                warning("Undefined input label.");
            end

            % What information is provided as output
            if any(contains(OUTPUTS{i_function}, "loc"))
                all_Config{i_config}.output_label = "loc";
            elseif any(contains(OUTPUTS{i_function}, "left"))
                all_Config{i_config}.output_label = "loc";
            elseif any(contains(OUTPUTS{i_function}, "order"))
                all_Config{i_config}.output_label = "order";
            elseif any(contains(OUTPUTS{i_function}, "first"))
                all_Config{i_config}.output_label = "order";
            elseif any(contains(OUTPUTS{i_function}, "attention"))
                all_Config{i_config}.output_label = "attention";
            elseif any(contains(OUTPUTS{i_function}, "attended"))
                all_Config{i_config}.output_label = "attention";
            else
                warning("Undefined output label.");
            end

            % What format is used as output
            if length(OUTPUTS{i_function}) == 2
                all_Config{i_config}.output_format_label = "both";
            elseif contains(OUTPUTS{i_function}, "diff")
                all_Config{i_config}.output_format_label = "diff";
            elseif contains(OUTPUTS{i_function}, "choice")
                all_Config{i_config}.output_format_label = "choice";
            else
                warning("Undefined output format label.");
            end

            % Architecture index
            if isequal(F_ACTIVATION{i_f_act}, @sigANN) && ...
                    (RECUR_CONNECT{i_recur} == "to_x")
                all_Config{i_config}.i_arch = 1;
            elseif isequal(F_ACTIVATION{i_f_act}, @sigANN) && ...
                    (RECUR_CONNECT{i_recur} == "to_z")
                all_Config{i_config}.i_arch = 2;
            elseif isequal(F_ACTIVATION{i_f_act}, @gaussANN) && ...
                    (RECUR_CONNECT{i_recur} == "to_x")
                all_Config{i_config}.i_arch = 3;
            elseif isequal(F_ACTIVATION{i_f_act}, @gaussANN) && ...
                    (RECUR_CONNECT{i_recur} == "to_z")
                all_Config{i_config}.i_arch = 4;
            else
                warning("Undefined architecture index.");
            end

            % --- Define unit indices depending on the architecture --- %

            % Store the number of units per layer
            n_inputs = length(INPUTS{i_function});
            all_Config{i_config}.n_units_x = NaN(1, n_inputs);
            all_Config{i_config}.n_units_z = N_UNITS_Z;
            for i_input = 1:n_inputs
                % Store the number of units dedicated to each input
                % depending on whether it is binary or not
                if all_Config{i_config}.inputs(i_input) == "cue_value"
                    all_Config{i_config}.n_units_x(i_input) = ...
                        N_UNITS_RANGE;
                else
                    all_Config{i_config}.n_units_x(i_input) = ...
                        N_UNITS_BINARY;
                end
            end

            % Index of the parameters for the connection from x to z
            all_Config{i_config}.ParamRange.connect_x_to_z = ...
                1:(sum(all_Config{i_config}.n_units_x) ...
                * all_Config{i_config}.n_units_z);
            % Index of the parameters for the biases of z
            all_Config{i_config}.ParamRange.biases_z = ...
                all_Config{i_config}.ParamRange.connect_x_to_z(end) ...
                + (1:all_Config{i_config}.n_units_z);
            % Index of the parameters for the recurrent connection
            if RECUR_CONNECT(i_recur) == "to_x"
                all_Config{i_config}.ParamRange.connect_z_to_x = ...
                    all_Config{i_config}.ParamRange.biases_z(end) ...
                    + (1:(all_Config{i_config}.n_units_z ...
                    * sum(all_Config{i_config}.n_units_x)));
            elseif RECUR_CONNECT(i_recur) == "to_z"
                all_Config{i_config}.ParamRange.connect_z_to_z = ...
                    all_Config{i_config}.ParamRange.biases_z(end) ...
                    + (1:(all_Config{i_config}.n_units_z ^ 2));
            else
                error("No recurrent connection defined.");
            end
            % Index of the parameters for the readout vector
            if RECUR_CONNECT(i_recur) == "to_x"
                all_Config{i_config}.ParamRange.readout = ...
                    all_Config{i_config}.ParamRange.connect_z_to_x(end) ...
                    + (1:(all_Config{i_config}.n_units_z ...
                    * length(all_Config{i_config}.outputs)));
            else
                all_Config{i_config}.ParamRange.readout = ...
                    all_Config{i_config}.ParamRange.connect_z_to_z(end) ...
                    + (1:(all_Config{i_config}.n_units_z ...
                    * length(all_Config{i_config}.outputs)));
            end
            if any(contains(OUTPUTS{i_function}, "choice"))
                all_Config{i_config}.ParamRange.readout_sigmoid = ...
                    all_Config{i_config}.ParamRange.readout(end) + (1:2);
            end
            % Total number of parameters
            all_Config{i_config}.n_params = ...
                all_Config{i_config}.ParamRange.readout(end);

            % Move on to the next structure
            i_config = i_config + 1;
        end
    end
end

