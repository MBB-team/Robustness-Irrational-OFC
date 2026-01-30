function data_info = selectDataInfo(DataSamples, info_labels)
% Extracts selected information fields from a DataSamples structure.
%
% This function selects a set of numeric fields from a 'DataSamples'
% structure and concatenates them into a matrix, with one column per
% selected field. Although generic in principle, it is primarily used to
% assemble input and/or output matrices for RNN training and evaluation.
%
%
% INPUTS ------------------------------------------------------------------
% DataSamples : <struct 1x1>
%     Structure containing original cue-sample fields and all derived
%     variables (see also: expandCueSamples). Each selected field must be
%     a numeric vector with one entry per sample.
%
% info_labels : <string 1xN>
%     Names of the fields to extract from DataSamples. All specified
%     fields are expected to correspond to double-valued vectors of
%     equal length.
%
% OUTPUTS -----------------------------------------------------------------
% data_info: <float MxN>
%     Matrix containing the selected information. Each column corresponds
%     to one entry in info_labels.

arguments
    DataSamples (1, 1) struct
    info_labels (1, :) string
end

% Initialize the output matrix
n_samples = length(DataSamples.i_trial);
n_info = length(info_labels);
data_info = NaN(n_samples, n_info);

% Extract each requested field
for i_info = 1:n_info
    try
        data_info(:, i_info) = DataSamples.(info_labels(i_info));
    catch
        warning("Impossible to select the field %s in DataSamples.", ...
            info_labels(i_info));
    end
end
