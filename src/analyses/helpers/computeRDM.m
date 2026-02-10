function RDM = computeRDM(RDM_activity)
% Computes the Representational Dissimilarity Matrix (RDM) from population
% activity patterns.
%
% The RDM is defined as the pairwise Pearson correlation between z-scored
% population activity vectors across task conditions. Each entry (i, j)
% quantifies the similarity between the neural representations elicited by
% conditions i and j.
%
% INPUTS ------------------------------------------------------------------
% RDM_activity : <float 20xN>
%     Activity of each observed unit (column) across 20 task conditions
%     (rows), corresponding to the 20 possible cues presented at the first
%     step of a trial.
%
% OUTPUTS -----------------------------------------------------------------
% RDM : <float 20x20>
%     Pairwise correlation matrix between z-scored population activity
%     vectors for all task conditions.

RDM = corr(zscore(RDM_activity)');
