function R2 = computeR2(measure_true, measure_predicted)
% Computes the proportion of variance explained (R²).
%
% This function compares ground-truth measures with predicted values
% (possibly across multiple output dimensions) and computes the coefficient
% of determination (R²) for each dimension. R² is defined as:
%
%   R² = 1 − (SS_error / SS_total)
%
% where SS_error is the sum of squared prediction errors and SS_total is the
% total variance of the ground-truth data.
%
% INPUTS ------------------------------------------------------------------
% measure_true : <float NxM>
%     Ground-truth measures.
%
% measure_predicted : <float NxM>
%     Predicted measures.
%
% OUTPUTS -----------------------------------------------------------------
% R2 : <float 1xM>
%     Percentage of variance explained for each output dimension.

arguments
    measure_true (:, :) double
    measure_predicted (:, :) double
end

% Get the number of different outputs
n_outputs = size(measure_true, 2);

% Initialize R2
R2 = NaN(1, n_outputs);

% Compute R2 independently for each output dimension
for i_output = 1:n_outputs

    % Total explainable variance
    sum_squares_total = sum((measure_true(:, i_output) - ...
        mean(measure_true(:, i_output))).^2);

    % Residual prediction variance
    sum_squares_error = sum((measure_true(:, i_output) - ...
        measure_predicted(:, i_output)).^2);

    % Proportion of variance explained
    R2(i_output) = 1 - (sum_squares_error / sum_squares_total);
end
