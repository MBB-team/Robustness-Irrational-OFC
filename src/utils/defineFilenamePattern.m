function filename_pattern = defineFilenamePattern(Config, seed)
% Returns a regular-expression pattern identifying RNN model files.
%
% This function generates a regexp pattern matching filenames of saved
% RNNs. Depending on the input arguments, the pattern can match:
%   (i) any RNN file produced by this project,
%   (ii) all RNNs corresponding to a specific configuration, or
%   (iii) a single RNN identified by both configuration and seed.
%
% INPUTS ------------------------------------------------------------------
% Config (optional) : <struct 1x1>
%     Structure defining the RNN architecture, input–output mapping,
%     activation function, and output format. See also:
%     getDesiredNetworkConfigs.
%
% seed (optional) : <int 1x1>
%     Random seed used to generate the initial state and associated
%     training and test datasets for the RNN.
%
% OUTPUTS -----------------------------------------------------------------
% filename_pattern : <string 1x1>
%     Regular-expression pattern matching the corresponding RNN filename.

arguments
    Config (1, 1) struct = struct()
    seed (1, 1) double = NaN
end

% Match any RNN
if nargin == 0
    filename_pattern = ...
        "(loc|order)" ... input info
        + "_TO_(loc|order|attention)-(both|diff|choice)" ... output info
        + "_ARCH_(gauss|sig)_(x|z)" ... architecture
        + "_(\d+).mat" ... seed and extension
    ;

% Match a given RNN variant
else
    % Input-output mapping
    filename_pattern = Config.input_label + ...
        "_TO_" + Config.output_label + ...
        "-" + Config.output_format_label + ...
        "_ARCH_";
    % Activation function
    filename_pattern = filename_pattern + ...
        string(functions(Config.f_activation).function(1:end-3));
    % Recurrent connection
    if Config.recur_connect == "to_x"
        filename_pattern = filename_pattern + "_x";
    elseif Config.recur_connect == "to_z"
        filename_pattern = filename_pattern + "_z";
    else
        error("Unknown recurrent connection");
    end
    % Seed and extension
    if nargin == 2
        filename_pattern = filename_pattern + "_" + num2str(seed) + ".mat";
    else
        filename_pattern = filename_pattern + "_(\d+).mat";
    end

end
