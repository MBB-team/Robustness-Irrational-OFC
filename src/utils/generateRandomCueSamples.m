function CueSamples = generateRandomCueSamples(n_trials)
% Randomly generate legal cue sampling sequences.
%
% This function generates synthetic cue sampling data for a set of trials.
% Each trial consists of exactly four sampled cues, ordered in time. Trials
% are constrained to be legal, meaning that the first two cues must define
% either:
%   - an option trial (both cues belong to the same option), or
%   - an attribute trial (both cues correspond to the same attribute).
%
% INPUTS ------------------------------------------------------------------
% n_trials : <int 1x1>
%     Number of trials to generate.
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

arguments
    n_trials (1, 1) double
end

% Possible cue ranks
POSSIBLE_CUE_RANKS = 1:5;

% Possible cue positions
% 1: left probability
% 2: left magnitude
% 3: right probability
% 4: right magnitude
POSSIBLE_CUE_POSITION = 1:4; 

% Initialize output structure
n_samples = n_trials * 4;
CueSamples = struct();
CueSamples.i_trial = NaN(1, n_samples);
CueSamples.i_step = NaN(1, n_samples);
CueSamples.cue_pos = NaN(1, n_samples);
CueSamples.cue_rank = NaN(1, n_samples);

% ~ Loop through trials ~ %
for i_trial = 1:n_trials
    i_sample = ((i_trial - 1) * 4 + 1):(i_trial * 4);

    % Randomly permute cue positions
    cue_pos = randperm(POSSIBLE_CUE_POSITION(end));
    % The first two cues must not correspond to opposite option–attribute
    % combinations (i.e., left probability vs right magnitude, or vice
    % versa). This condition is equivalent to excluding pairs whose indices
    % sum to 5.
    while (cue_pos(1) + cue_pos(2)) == 5
        cue_pos = randperm(POSSIBLE_CUE_POSITION(end));
    end

    % Randomly sample cue ranks
    cue_rank = randi([POSSIBLE_CUE_RANKS(1), POSSIBLE_CUE_RANKS(end)], 1, 4);
    
    % Store trial information
    CueSamples.i_trial(i_sample) = i_trial;
    CueSamples.i_step(i_sample) = 1:4;
    CueSamples.cue_pos(i_sample) = cue_pos;
    CueSamples.cue_rank(i_sample) = cue_rank;
end
