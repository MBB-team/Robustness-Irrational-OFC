function output = VBA_fitOneValueProfile(~, P, ~, in)
% Predicts RNN outputs from a shared option value function V(p, m).
%
% This observation function maps each option's currntly estimated
% probability and magnitude onto a scalar value using a shared value
% function, and converts these values into predicted RNN outputs according
% to the specified output format.
%
% INPUTS ------------------------------------------------------------------
% P : <float Px1>
%     Vectorized value profile.
%
% in : <struct 1x1>
%     Structure defining the attribute space and trial-wise attributes:
%       - all_prob, all_mag: discrete attribute grids (including NaN)
%       - prob_1, mag_1, prob_2, mag_2: option attributes per cue sample
%       - output_format_label: RNN output format
%
% OUTPUTS -----------------------------------------------------------------
% output : <float Nx1>
%     Vector of predicted RNN outputs.

arguments
    ~
    P (:, 1) double
    ~
    in (1, 1) struct
end

% Extract value profile size
n_prob = length(in.all_prob);
n_mag = length(in.all_mag);

% Shape the value function
value_function = reshape(P, n_prob, n_mag);

% Round all attributes to ensure proper comparison
for attribute = ["prob_1", "prob_2", "mag_1", "mag_2", "all_prob", "all_mag"]
    in.(attribute) = round(in.(attribute), 2);
end

value_1 = NaN(length(in.prob_1), 1);
value_2 = NaN(length(in.prob_1), 1);

% ~ Loop through attribute pair ~ %
for i_prob = 1:n_prob
    prob = in.all_prob(i_prob);
    for i_mag = 1:n_mag
        mag = in.all_mag(i_mag);

        % Select trials where the option 1 (resp. 2) have this pair
        % of attributes
        if isnan(prob)
            select_1 = isnan(in.prob_1);
            select_2 = isnan(in.prob_2);
        else
            select_1 = in.prob_1 == prob;
            select_2 = in.prob_2 == prob;
        end
        if isnan(mag)
            select_1 = select_1 & isnan(in.mag_1);
            select_2 = select_2 & isnan(in.mag_2);
        else
            select_1 = select_1 & (in.mag_1 == mag);
            select_2 = select_2 & (in.mag_2 == mag);
        end

        % Map attribute pairs to option values
        value_1(select_1) = value_function(i_prob, i_mag);
        value_2(select_2) = value_function(i_prob, i_mag);
    end
end

% Convert the values to value difference or choice probabilities if needed
switch in.output_format_label
    case "both"
        output = reshape([value_1, value_2], [], 1);
    case "diff"
        output = value_1 - value_2;
    case "choice"
        output = sigANN(value_1 - value_2, 0);
end