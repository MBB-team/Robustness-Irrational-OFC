% Computes the balanced accuracy of a model.

function bacc = computeBalancedAccuracy(output_true, output_predicted)
% --- INPUTS ---
% output_true: [n_samples x n_outputs] double
%   Array containing in column the true outputs.
% output_predicted: [n_samples x n_outputs] double
%   Array containing in column the outputs predicted by the model.
%
% --- OUTPUT ---
% bacc: [1 x n_outputs] double
%   Balanced accuracy on each output.
%
% --- CALLED BY ---
% trainNetworkCohorts
% checkInformationLoss
% simulateNetworkCohortsH0
% fitNetworkToBehaviour


% Get the number of different outputs
n_outputs = size(output_true, 2);

% Initialize bacc
bacc = NaN(1, n_outputs);

% Compute the balanced accuracy for each output separately
for i_output = 1:n_outputs
    % Convert the outputs into binary values
    output_true(output_true(:, i_output) < 0.5, i_output) = 0;
    output_true(output_true(:, i_output) >= 0.5, i_output) = 1;
    output_predicted(output_predicted(:, i_output) < 0.5, i_output) = 0;
    output_predicted(output_predicted(:, i_output) >= 0.5, i_output) = 1;
    % True positive, false positive, true negative, false negative
    TP = sum(output_predicted(:, i_output) & output_true(:, i_output));
    FP = sum(output_predicted(:, i_output) & ~ output_true(:, i_output));
    TN = sum(~ output_predicted(:, i_output) & ~ output_true(:, i_output));
    FN = sum(~ output_predicted(:, i_output) & output_true(:, i_output));
    % Balanced accuracy
    bacc(i_output) = ((TP / (TP + FN)) + (TN / (TN + FP))) / 2;
end
