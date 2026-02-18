function output = VBA_fitTwoValueProfiles(~, P, ~, in)
% Predicts RNN outputs from two value functions V1(p1, m1) and V2(p2, m2).
%
% This observation function maps each option's currently estimated
% probability and magnitude onto a scalar value using two option-specific
% value functions, and converts these values into predicted RNN outputs
% according to the specified output format.
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
%       - exclude_sequences: logical vector selecting cue sequences to
%       exclude
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

% Extract value profiles size
n_prob = length(in.all_prob);
n_mag = length(in.all_mag);
n_function_params = n_prob * n_mag;

% Shape the value functions
value_function_1 = reshape(P(1:n_function_params), n_prob, n_mag);
value_function_2 = reshape(P((n_function_params + 1):end), n_prob, n_mag);

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
        value_1(select_1) = value_function_1(i_prob, i_mag);
        value_2(select_2) = value_function_2(i_prob, i_mag);
    end
end

% Convert the values to value difference or choice probabilities if needed
switch in.output_format_label
    case "both"
        output = reshape([value_1, value_2], [], 1);
    case "diff"
        output = value_1 - value_2;
    case "choice"
        output = sigANN(value_2 - value_1, 0);
end

% Exclude sequences
output = output(~ in.exclude_sequences);
