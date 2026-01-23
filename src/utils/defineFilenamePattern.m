% Returns the regexp pattern corresponding to the file where an ANN is
% saved.

function filename_pattern = defineFilenamePattern(Config, seed)
% --- INPUT --- %
% This function takes an optional input 'Config', which characterizes the
% only cohort configuration that the pattern should be able to match. If
% this input is not provided, the pattern should be able to match any ANN.
% If the optional double 'seed' is provided, then the function outputs the
% corresponding file name.
%
% --- OUTPUT --- %
% This function outputs the string of a regexp pattern matching all ANNs or
% a given configuration of ANN, or a givern ANN.
%
% --- CALLED BY ---
% getAllNetworkPaths
% saveNetwork
% trainNetworkCohorts
% simulateNetworkCohortsH0


% === The pattern matches any ANN === %

if nargin == 0
    filename_pattern = ...
        "(loc|order)" ... input info
        + "_TO_(loc|order|attention)-(both|diff|choice)" ... output info
        + "_ARCH_(gauss|sig)_(x|z)" ... architecture
        + "_(\d+).mat" ... seed and extension
    ;

% === The pattern matches a given ANN configuration === %

else

    % Function of the ANN
    filename_pattern = Config.input_label + ...
        "_TO_" + Config.output_label + ...
        "-" + Config.output_format_label + ...
        "_ARCH_";

    % Activation function (remove the "ANN" in the function name)
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

end
