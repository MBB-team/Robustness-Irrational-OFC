% From a scenario of cue sampling, builds the regressors used in the
% cross-correlation analysis.

function regression_matrix = computeCCMregressionMatrix(DataSamples)
% Builds regressors for cross-correlation (CCM) analyses from cue-sampling
% scenarios.
%
% This function converts a classical 'DataSamples' structure describing
% three-step cue sampling sequences into a regression matrix used for
% cross-correlation analyses of neural signals (see also:
% expandCueSamples, generateNeuralGeometryMatrices).
%
% INPUTS ------------------------------------------------------------------
% DataSamples : <struct 1x1>
%     Structure describing cue sampling scenarios (see also:
%     expandCueSamples).
%
% OUTPUTS -----------------------------------------------------------------
% regression_matrix : <double Nx6>
%     Regression matrix with one row per trial and the following columns:
%       1) intercept
%       2) relative rank of cue sampled at step 1
%       3) relative rank of cue sampled at step 2
%       4) relative rank of cue sampled at step 3
%       5) belief confirmation at step 2
%       6) belief confirmation at step 3

arguments
    DataSamples (1, 1) struct
end

% Map absolute cue ranks (1–5) to relative ranks (−2 to 2)
RELATIVE_CUE_RANKS = -2:2;
cue1_rank = RELATIVE_CUE_RANKS(DataSamples.cue_rank(DataSamples.i_step == 1));
cue2_rank = RELATIVE_CUE_RANKS(DataSamples.cue_rank(DataSamples.i_step == 2));
cue3_rank = RELATIVE_CUE_RANKS(DataSamples.cue_rank(DataSamples.i_step == 3));

% Belief confirmation at step 2: interaction between cue 2 rank and whether
% cue 1 was low, average, or high
consistency_step2 = cue2_rank;
is_cue1_low = cue1_rank < 0;
consistency_step2(is_cue1_low) = - consistency_step2(is_cue1_low);
consistency_step2(cue1_rank == 0) = 0;

% --- Belief confirmation at step 3 --- %
% Interaction between cue 3 rank and whether the previously sampled cues
% favored the currently attended option

consistency_step3 = cue3_rank;

% Option attended at step 3 (1 = left, 0 = right)
option_loc_step3 = DataSamples.option_loc(DataSamples.i_step == 3);

% Extract cue ranks sampled at step 2
select_step2 = (DataSamples.i_step == 2);

% Compute summed ranks for left and right options at step 2
previous_ranks_left = ...
    RELATIVE_CUE_RANKS(floor(5 * (DataSamples.prob_left(select_step2)) + 0.5)) + ...
    RELATIVE_CUE_RANKS(floor(5 * (DataSamples.mag_left(select_step2)) + 0.5));
previous_ranks_right = ...
    RELATIVE_CUE_RANKS(floor(5 * (DataSamples.prob_right(select_step2)) + 0.5)) + ...
    RELATIVE_CUE_RANKS(floor(5 * (DataSamples.mag_right(select_step2)) + 0.5));

% Select ranks of attended and unattended options
previous_ranks_attended_option = ...
    previous_ranks_left .* (option_loc_step3 == 1) ...
    + previous_ranks_right .* (option_loc_step3 == 0);
previous_ranks_unattended_option = ...
    previous_ranks_left .* (option_loc_step3 == 0) ...
    + previous_ranks_right .* (option_loc_step3 == 1);

% Identify trials where the unattended option was better supported
was_unattended_better = (previous_ranks_unattended_option > previous_ranks_attended_option);

% Apply interaction with cue 3 rank
consistency_step3(was_unattended_better) = ...
    - consistency_step3(was_unattended_better);
consistency_step3(previous_ranks_unattended_option == ...
    previous_ranks_attended_option) = 0;

% --- Assemble the regression matrix --- %

regression_matrix = ...
    [ones(size(cue1_rank')), ...
    cue1_rank', cue2_rank', cue3_rank', ...
    consistency_step2', consistency_step3'];
