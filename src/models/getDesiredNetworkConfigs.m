function all_Config = getDesiredNetworkConfigs()
% Returns the configurations defining each RNN cohort.
%
% This function generates a cell array of 'Config' structures, each
% specifying a variant of RNN to train. Each % Config structure contains
% the task-specific input-output mapping, layer architecture, activation
% function, recurrent connectivity, and parameter indexing.
%
% OUTPUTS -----------------------------------------------------------------
% all_Config : <cell 1xN>
%     Each element is a 'Config' structure describing one RNN cohort:
%       - inputs: labels of input features fed to the RNN
%       - outputs: labels of target outputs for training
%       - f_activation: activation function applied to hidden units
%       - recur_connect: defines the layer targeted by recurrent
%       connections
%       - n_units_x: number of units assigned to each input dimension
%       - n_units_z: nNumber of hidden units in the recurrent layer
%       - ParamRange: indices of each parameter type in the vectorized
%           weight representation (e.g., connect_x_to_z, biases_z,
%           connect_z_to_z, readout, etc.).
%       - n_params: total number of parameters in the RNN
%       - input_label / output_label: human-readable labels summarizing the
%           input and output types
%       - output_format_label: format of the network output
%       - i_arch: architecture index combining activation function and
%           recurrent connectivity


% --- Define input-output configurations --- %

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

% --- Define architectural properties (only one architecture here) --- %

F_ACTIVATION = {@sigANN};
RECUR_CONNECT = "to_z";
N_UNITS_Z = 10;
N_UNITS_BINARY = 2; % number of units per binary input in the x layer
N_UNITS_RANGE = 5; % number of units per non-binary input in the x layer

% --- Build Config structures --- %

n_config = length(INPUTS) * length(F_ACTIVATION) * length(RECUR_CONNECT);
all_Config = cell(1, n_config);
i_config = 1;

for i_function = 1:length(INPUTS)
    for i_f_act = 1:length(F_ACTIVATION)
        for i_recur = 1:length(RECUR_CONNECT)

            % Input-output mapping
            all_Config{i_config}.inputs = INPUTS{i_function};
            all_Config{i_config}.outputs = OUTPUTS{i_function};

            % Architecture properties
            all_Config{i_config}.f_activation = F_ACTIVATION{i_f_act};
            all_Config{i_config}.recur_connect = RECUR_CONNECT{i_recur};

            % --- Humean-readable labels --- %

            % Input label
            if any(contains(INPUTS{i_function}, "loc"))
                all_Config{i_config}.input_label = "loc";
            elseif any(contains(INPUTS{i_function}, "order"))
                all_Config{i_config}.input_label = "order";
            elseif any(contains(INPUTS{i_function}, "attention"))
                all_Config{i_config}.input_label = "attention";
            else
                warning("Undefined input label.");
            end

            % Output label
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

            % Output format label
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

            % --- Define layer sizes --- %

            n_inputs = length(INPUTS{i_function});
            all_Config{i_config}.n_units_x = NaN(1, n_inputs);
            all_Config{i_config}.n_units_z = N_UNITS_Z;
            for i_input = 1:n_inputs
                if all_Config{i_config}.inputs(i_input) == "cue_value"
                    all_Config{i_config}.n_units_x(i_input) = ...
                        N_UNITS_RANGE;
                else
                    all_Config{i_config}.n_units_x(i_input) = ...
                        N_UNITS_BINARY;
                end
            end

            % --- Parameter indexing --- %

            % Feedforward hidden connections
            all_Config{i_config}.ParamRange.connect_x_to_z = ...
                1:(sum(all_Config{i_config}.n_units_x) ...
                * all_Config{i_config}.n_units_z);
            % Biases in the second hidden layer
            all_Config{i_config}.ParamRange.biases_z = ...
                all_Config{i_config}.ParamRange.connect_x_to_z(end) ...
                + (1:all_Config{i_config}.n_units_z);
            % Recurrent connections
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
            % Readout vector
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

            % Increment for next configuration
            i_config = i_config + 1;
        end
    end
end

