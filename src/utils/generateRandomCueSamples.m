% Generates a 'CueSamples' structure describing sampling scenarii for
% several trials.

function CueSamples = generateRandomCueSamples(n_trials)
% --- INPUT ---
% n_trials: double
%   Number of trials to generate, considering each trial consists in
%   sampling 4 cues.
%
% --- OUTPUT ---
% This function outputs a 'CueSamples' structure with the following fields:
%   .i_trial: [1 x n_samples] double
%       Trial index.
%   .i_step: [1 x n_samples] double
%       Step index.
%   .cue_pos: [1 x n_samples] double
%       Position (1-4) of the sampled cue.
%   .cue_rank: [1 x n_samples] double
%       Rank (1-5) of the sampled cue.
%
% --- CALLED BY ---
% trainNetworkCohorts
% checkInformationLoss
% simulateNetworkCohortsH0
% computeLogLikelihoodDynamics


%% --- PARAMETERS --- %%

% Initialize possible cue ranks
POSSIBLE_CUE_RANKS = 1:5;
RANGE_CUE_RANKS = POSSIBLE_CUE_RANKS(end) - POSSIBLE_CUE_RANKS(1);

% Initialize possible cue positions
%{
1: left probability
2: left magnitude
3: right probability
4: right magnitude
%}
POSSIBLE_CUE_POSITION = 1:4; 


%% --- MAIN --- %%

% Initialize output structure
n_samples = n_trials * 4;
CueSamples = struct();
CueSamples.i_trial = NaN(1, n_samples);
CueSamples.i_step = NaN(1, n_samples);
CueSamples.cue_pos = NaN(1, n_samples);
CueSamples.cue_rank = NaN(1, n_samples);

for i_trial = 1:n_trials
    i_sample = ((i_trial - 1) * 4 + 1):(i_trial * 4);

    % Generate cue positions for legal trials
    cue_pos = randperm(POSSIBLE_CUE_POSITION(end));
    % Legal trial must be either attribute or option trial
    %{
    If the first cue is in position 1, the second cannot be in 4.
    If the first cue is in position 2, the second cannot be in 3.
    If the first cue is in position 3, the second cannot be in 2.
    If the first cue is in position 4, the second cannot be in 1.
    %}
    while (cue_pos(1) + cue_pos(2)) == 5
        cue_pos = randperm(POSSIBLE_CUE_POSITION(end));
    end

    % Generate cue ranks
%     cue_rank = rand(1, 4) * RANGE_CUE_RANKS + POSSIBLE_CUE_RANKS(1);
    cue_rank = randi([1, 5], 1, 4);
    
    % Organize data in the output array
    CueSamples.i_trial(i_sample) = i_trial;
    CueSamples.i_step(i_sample) = 1:4;
    CueSamples.cue_pos(i_sample) = cue_pos;
    CueSamples.cue_rank(i_sample) = cue_rank;
end

end

