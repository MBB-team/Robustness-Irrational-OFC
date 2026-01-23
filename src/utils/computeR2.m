% Computes the proportion of variance explained by a model.

function R2 = computeR2(output_true, output_predicted)
% --- INPUTS ---
% output_true: [n_samples x n_outputs] double
%   Array containing in column the true outputs.
% output_predicted: [n_samples x n_outputs] double
%   Array containing in column the outputs predicted by the model.
%
% --- OUTPUT ---
% R2: [1 x n_outputs] double
%   Percentage of variance explained by the model on each separate output.
%
% --- CALLED BY ---
% trainNetworkCohorts
% checkInformationLoss
% simulateNetworkCohortsH0


% Get the number of different outputs
n_outputs = size(output_true, 2);

% Initialize R2
R2 = NaN(1, n_outputs);

% Compute the R2 for each output separately
for i_output = 1:n_outputs
    % Total explainable variance
    sum_squares_total = sum((output_true(:, i_output) - ...
        mean(output_true(:, i_output))).^2);
    % Prediction error of the model
    sum_squares_error = sum((output_true(:, i_output) - ...
        output_predicted(:, i_output)).^2);
    % Proportion of variance explained by the model
    R2(i_output) = 1 - (sum_squares_error / sum_squares_total);
end

end
