function bacc = computeBalancedAccuracy(measure_true, measure_predicted)
% Computes balanced accuracy for binary predictions.
%
% This function compares ground-truth binary measures with predicted values
% (possibly across multiple output dimensions) and computes the balanced
% accuracy for each dimension. Balanced accuracy is defined as the average
% of sensitivity (true positive rate) and specificity (true negative rate).
%
% INPUTS ------------------------------------------------------------------
% measure_true : <float NxM>
%     Ground-truth measures. Values are thresholded at 0.5 to obtain binary
%     labels (0 or 1).
%
% measure_predicted : <float NxM>
%     Predicted measures. Values are thresholded at 0.5 to obtain binary
%     predictions (0 or 1).
%
% OUTPUTS -----------------------------------------------------------------
% bacc : <float 1xM>
%     Balanced accuracy for each output dimension.

arguments
    measure_true (:, :) double
    measure_predicted (:, :) double
end

% Number of output dimensions
n_dim = size(measure_true, 2);

% Initialize output
bacc = NaN(1, n_dim);

% Compute balanced accuracy independently for each output dimension
for i_output = 1:n_dim

    % Binarize ground-truth and predicted values
    measure_true(measure_true(:, i_output) < 0.5, i_output) = 0;
    measure_true(measure_true(:, i_output) >= 0.5, i_output) = 1;
    measure_predicted(measure_predicted(:, i_output) < 0.5, i_output) = 0;
    measure_predicted(measure_predicted(:, i_output) >= 0.5, i_output) = 1;

    % Confusion matrix components
    TP = sum(measure_predicted(:, i_output) & measure_true(:, i_output));
    FP = sum(measure_predicted(:, i_output) & ~ measure_true(:, i_output));
    TN = sum(~ measure_predicted(:, i_output) & ~ measure_true(:, i_output));
    FN = sum(~ measure_predicted(:, i_output) & measure_true(:, i_output));
    
    % Balanced accuracy
    bacc(i_output) = ((TP / (TP + FN)) + (TN / (TN + FP))) / 2;
end
