function [tstats, CCM, CCM_p] = computeCCM(activity, regression_matrix, i_step)
% Computes cross-correlation matrices (CCM) from RNN activity during all
% legal three-cue sampling sequences.
%
% This function quantifies how strongly each unit in a neural population
% encodes the rank of sampled cues at each sampling step, and then measures
% how these encoding patterns are correlated across cues and time.
%
% First, for each unit and each sampling step, the unit's activity is
% regressed onto a set of task-related regressors describing the cue ranks
% and belief-confirmation variables. The resulting t-statistics associated
% with cue-rank regressors quantify the unit’s sensitivity to each cue at
% each step.
%
% Second, these unit-level t-statistics are treated as population vectors
% and cross-correlated across all pairs of cue identities and sampling
% steps. This yields a second-order correlation matrix (CCM) describing how
% similarly the population represents different cues over time, together
% with corresponding p-values.
%
% INPUTS ------------------------------------------------------------------
% activity : <float NxU>
%     Activity of each observed unit (columns) in response to each cue
%     sampling condition (rows).
%
% regression_matrix : <float Nx6>
%     Design matrix mapping each activity sample to task regressors (see
%     also: computeCCMregressionMatrix). Columns correspond to:
%       1) intercept
%       2) relative rank of cue sampled at step 1
%       3) relative rank of cue sampled at step 2
%       4) relative rank of cue sampled at step 3
%       5) belief confirmation at step 2
%       6) belief confirmation at step 3
%
% i_step (optional) : <double 1xN>
%     Sampling step index associated with each row of activity. If omitted,
%     trials are assumed to consist of exactly three sampling steps.
%
% OUTPUTS -----------------------------------------------------------------
% tstats : <float Ux3x3>
%     T-statistics quantifying cue-rank encoding. For each unit (first
%     dimension), t-statistics correspond to the rank of each cue (second
%     dimension) evaluated at each sampling step (third dimension).
%
% CCM : <float 9x9>
%     Cross-correlation matrix between population-level cue-rank encoding
%     patterns across all cue identities and sampling steps. Each row and
%     column corresponds to a (cue identity, observing step) pair, ordered
%     as:
%         (cue 1, step 1), (cue 1, step 2), (cue 1, step 3),
%         (cue 2, step 1), (cue 2, step 2), (cue 2, step 3),
%         (cue 3, step 1), (cue 3, step 2), (cue 3, step 3).
%     Entry (i, j) reflects the correlation between the population
%     sensitivity to the rank of the cue–step pair indexed by i and that
%     indexed by j.
%
% CCM_p : <float 9x9>
%     P-values associated with each entry of the CCM.

arguments
    activity (:, :) double
    regression_matrix (:, :) double
    i_step (1, :) = []
end

% By default, trials are assumed to consist of exactly three sampling steps
if isempty(i_step)
    i_step = repmat(1:3, 1, round(size(activity, 1) / 3));
end

% --- Compute unit-level t-statistics --- %

n_units = size(activity, 2);
tstats = NaN(n_units, 3, 3);

for i_unit = 1:n_units

    % Activity of the current unit across all samples
    unit_activity = activity(:, i_unit);

    for step = 1:3

        % Select activity samples corresponding to this step
        unit_step_activity = unit_activity(i_step == step);

        % Remove missing observations
        select_obs_samples = ~ isnan(unit_step_activity);
        unit_step_activity = unit_step_activity(select_obs_samples);
        obs_regression_matrix = regression_matrix(select_obs_samples, :);

        % Multivariate linear regression
        pseudoinv = pinv(obs_regression_matrix' * obs_regression_matrix);
        beta = pseudoinv * obs_regression_matrix' * unit_step_activity;
        epsilon = unit_step_activity - obs_regression_matrix * beta;

        % Estimate variance and covariance of regression coefficients
        sigma = var(epsilon);
        cov_beta = sigma * pseudoinv;

        % Correct numerical noise
        beta(abs(beta) < 1e-14) = 0;

        % Compute standard errors and t-statistics
        partial_standard_error = diag(sqrt(cov_beta));
        partial_standard_error(partial_standard_error==0) = realmin;
        all_tstats = beta./partial_standard_error;

        % Keep t-statistics associated with cue ranks only
        tstats(i_unit, :, step) = all_tstats(2:4);
    end
end

% Nullify numerically negligible t-statistics
tstats(abs(tstats) < 1e-2) = 0;

% --- Compute the cross-correlation matrix --- %

CCM = NaN(9, 9);
CCM_p = NaN(9, 9);

% Each dimension corresponds to a (cue, step) pair
for i_cue_step = 1:3
    for i_activity_step = 1:3

        i_CCM = (i_cue_step - 1) * 3 + i_activity_step;
        i_tstats = tstats(:, i_cue_step, i_activity_step);

        for j_cue_step = 1:3
            for j_activity_step = 1:3

                j_CCM = (j_cue_step - 1) * 3 + j_activity_step;
                j_t_stats = tstats(:, j_cue_step, j_activity_step);

                % Correlate population sensitivity vectors
                [rho, p] = corr(i_tstats, j_t_stats);
                CCM(i_CCM, j_CCM) = rho;
                CCM_p(i_CCM, j_CCM) = p;

            end
        end
    end
end

% Replace undefined correlations by zero
CCM(isnan(CCM)) = 0;
