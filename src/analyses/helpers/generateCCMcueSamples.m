function CueSamples = generateCCMcueSamples()
% Generates all three-cue sampling sequences used for CCM analyses.
%
% This function exhaustively enumerates all legal sequences of three
% sampled cues, spanning all admissible combinations of cue positions and
% cue ranks. These sequences are used to compute cross-correlation matrices
% (CCMs) at the third sampling step (see also:
% computeNeuralGeometryMatrices).
%
% Sequence constraints:
%   - Cue positions must be distinct across the three steps.
%   - The second cue cannot be diagonally opposite to the first cue
%     (i.e., positions whose indices sum to 5).
%   - Cue ranks are sampled independently at each step.
%
% OUTPUTS -----------------------------------------------------------------
% CueSamples : <struct 1x1>
%     Structure containing row vectors describing sampled cues, with
%     fields:
%       - i_trial: trial index
%       - i_step: step index
%       - cue_pos: position (1-4) of the sampled cue:
%           1 = left probability
%           2 = left magnitude
%           3 = right probability
%           4 = right magnitude
%       - cue_rank: rank of the sampled cue (1–5)

% Possible cue ranks
POSSIBLE_CUE_RANKS = 1:5;

% Possible cue positions
% 1: left probability
% 2: left magnitude
% 3: right probability
% 4: right magnitude
POSSIBLE_CUE_POSITION = 1:4; 

% Total number of distinct three-cue trials given the positional constraints
n_trials = (length(POSSIBLE_CUE_RANKS) ^ 3) * ...
    length(POSSIBLE_CUE_POSITION) * ...
    (length(POSSIBLE_CUE_POSITION) - 2) * ...
    (length(POSSIBLE_CUE_POSITION) - 2);

% Initialize output structure
CueSamples = struct();
CueSamples.cue_pos = NaN(1, n_trials * 3);
CueSamples.cue_rank = NaN(1, n_trials * 3);

% Trial and step indices
CueSamples.i_trial = repelem(1:n_trials, 3);
CueSamples.i_step = repmat(1:3, 1, n_trials);

% --- Enumerate all admissible three-cue sampling sequences --- %

i_start = 1;

for cue1_pos = POSSIBLE_CUE_POSITION
    % The second cue cannot share the same position as the first cue,
    % nor be diagonally opposite (pos1 + pos2 == 5)
    possible_cue2_pos = POSSIBLE_CUE_POSITION(...
        (POSSIBLE_CUE_POSITION ~= cue1_pos) & ...
        ((POSSIBLE_CUE_POSITION + cue1_pos) ~= 5));

    for cue2_pos = possible_cue2_pos
        % The third cue must be at a position different from both previous cues
        possible_cue3_pos = POSSIBLE_CUE_POSITION(...
            (POSSIBLE_CUE_POSITION ~= cue1_pos) & ...
            (POSSIBLE_CUE_POSITION ~= cue2_pos));

        for cue3_pos = possible_cue3_pos
            % Number of rank combinations for this position triplet
            i_end = i_start + 3 * (5^3) - 1;

            % Store cue positions for all rank combinations
            CueSamples.cue_pos(i_start:i_end) = ...
                repmat([cue1_pos, cue2_pos, cue3_pos], 1, 5^3);

            % Enumerate cue ranks independently for each sampling step
            CueSamples.cue_rank(i_start:3:i_end) = ...
                repelem(POSSIBLE_CUE_RANKS, 5^2); % step 1
            CueSamples.cue_rank((i_start + 1):3:i_end) = ...
                repmat(repelem(POSSIBLE_CUE_RANKS, 5), 1, 5); % step 2
            CueSamples.cue_rank((i_start + 2):3:i_end) = ...
                repmat(POSSIBLE_CUE_RANKS, 1, 5^2); % step 3

            % Update index for the next batch of scenarii
            i_start = i_end + 1;
        end
    end
end
