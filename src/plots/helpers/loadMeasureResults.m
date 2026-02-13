function Data = loadMeasureResults(measure_labels, measure_file)
% Loads previously computed measure results for a set of RNNs.
%
% This function extracts selected measures from a .mat file containing
% analysis results. Each measure must correspond to a variable stored
% in the file.
%
% INPUTS ------------------------------------------------------------------
% measure_labels : <string 1xN>
%     Names of the measures to load. Each label must match a variable
%     contained in the specified file.
%
% measure_file (optional) : <string 1xN>
%     Name of the file (without extension) from which to load the results.
%     The file must be located in getPath("Models"). Default to
%     "rational_last" (measures computed on the final state of initially 
%     rationally trained networks).
%
% OUTPUTS -----------------------------------------------------------------
% Data : <struct 1x1>
%     Structure whose fields are named after each successfully loaded
%     measure label and contain the corresponding results. If a requested
%     measure does not exist in the file, a warning is issued and the field
%     is omitted.

arguments
    measure_labels (1, :) string
    measure_file (1, 1) string = "rational_last"
end

% Initialize output structure
Data = struct();

% Sanity check: verify that the file exists
path_file = fullfile(getPath("Models"), measure_file + ".mat");
if ~ isfile(path_file)
    error("Non-existing file: %s", path_file);
end

% Load requested measures
available_measures = who("-file", path_file);
for label = measure_labels
    if ~ ismember(label, available_measures)
        warning("Non-existing variable: %s", label);
    else
        Data.(label) = load(path_file).(label);
    end
end
