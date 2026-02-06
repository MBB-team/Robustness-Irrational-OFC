function CPD = computeCPD(RDM)
% Computes Coefficients of Partial Determination (CPDs) for an input RDM.
%
% This function quantifies how much each of five predefined RDM templates
% contributes to the variance in an input RDM. Each template corresponds to
% a task-relevant feature (spatial attention, stimulus identity, attended 
% value, left/right value, accept/reject) as in Hunt et al. (2018).
%
% INPUTS ------------------------------------------------------------------
% RDM : <float 20x20>
%     Representational Dissimilarity Matrix containing pairwise
%     correlations of neural activity across all inputs.
%
% OUTPUTS -----------------------------------------------------------------
% CPD : <float 1x5>
%     Coefficient of partial determination for each of the five templates,
%     indicating the proportion of RDM variance uniquely explained by that
%     template.

arguments
    RDM (:, :) double
end

% --- Define RDM templates --- %

% Identity template
identity = eye(20);

% Spatial attention template (left vs. right)
spatial = [ones(10), -ones(10); -ones(10), ones(10)];

% Stimulus identity template
stimulus = [zeros(10), eye(10); eye(10), zeros(10)];

% Attended value template
ranks = repmat(-2:2, 5, 1);
attended_value = repmat(ranks .* ranks', 4, 4) / 4;

% Left/right value template
loc_value = (spatial > 0) .* attended_value;

% Accept/reject template
accept_reject = repmat((ranks .* ranks' > 0) - (ranks .* ranks' < 0), 4, 4);

% Combine all templates (flattened)
all_templates = [reshape(identity, [], 1), reshape(spatial, [], 1), ...
    reshape(stimulus, [], 1), reshape(attended_value, [], 1), ...
    reshape(loc_value, [], 1), reshape(accept_reject, [], 1)];

% --- Compute CPDs --- %

% Initialize storage
CPD = NaN(1, 5);

% Vectorize input RDM
vec_RDM = reshape(RDM, [], 1);

% Regress the RDM onto all templates
full_model = fitlm(all_templates, vec_RDM);

% Compute CPD for each template by leaving it out of the model
for i_template = 1:5
    partial_model = fitlm(all_templates(:, ~((1:6) == i_template + 1)), vec_RDM);
    CPD(i_template) = (partial_model.SSE - full_model.SSE) / ...
        partial_model.SSE;
end
