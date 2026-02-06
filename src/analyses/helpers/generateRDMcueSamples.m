function CueSamples = generateRDMcueSamples()
% Generates all single-cue sampling sequences used for RDM analyses.
%
% This function enumerates all possible cue samples of length one, spanning
% all cue positions and cue ranks. These samples are used to compute
% representational dissimilarity matrices (RDMs) at the first sampling step
% (see also: computeNeuralGeometryMatrices).
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

% Initialize output structure
CueSamples = struct();

% Total number of cue samples (all combinations of position × rank)
n_samples = len(POSSIBLE_CUE_RANKS) * len(POSSIBLE_CUE_POSITION);

% Trial index (one cue sample per trial)
CueSamples.i_trial = 1:n_samples;

% Step index (all samples correspond to the first sampling step)
CueSamples.i_step = ones(1, n_samples);

% Cue positions
% First half: left cues (position 1 and 2)
% Second half: right cues (position 3 and 4)
% Within each half:
%    First quarter: probability cues (position 1 and 3)
%    Second quarter: magnitude cues (position 2 and 4)
CueSamples.cue_pos = repelem(POSSIBLE_CUE_POSITION, 5);

% Cue ranks
CueSamples.cue_rank = repmat(POSSIBLE_CUE_RANKS, 1, 4);
