function analysis_output = computeNeuralDistance(params, ~, ~, inputs)
% Computes RDM and CCM neural distances between an RNN and monkeys.
%
% This function quantifies how similar an RNN’s neural geometry is to that
% of individual monkeys or their pooled neural activity. Distances are
% computed for both the Representational Dissimilarity Matrix (RDM) and the
% Cross-Correlation Matrices (CCM) for option and attribute trials. The RDM
% distance is measured as one minus the Spearman correlation of the upper
% triangles of the RDMs, and the CCM distance is computed as the Euclidean
% norm of interpretable CCM cells that represent meaningful cue-step pairs.
%
% As with all functions in the 'measures' folder, this function can be
% called in two modes: when called without parameters, it performs any
% required preprocessing and returns the corresponding inputs; when called
% with parameters, it applies the measure to the RNN using these inputs.
%
% INPUTS ------------------------------------------------------------------
% params : <float Px1> | []
%     Vector of RNN parameters. If empty, the function runs in
%     preprocessing mode and returns the analysis inputs instead of
%     computing measures.
%
% inputs : <struct 1x1>
%     Structure containing all variables precomputed during preprocessing,
%     as well as supplementary variables previsouly computed. Required only
%     in analysis mode. Fields include:
%       - RDM, CCM_option, CCM_attribute: neural geometry of the RNN
%       - [monkey]_RDM_[area]: experimental RDM for each monkey (Franck,
%       Miles) or pooled data (both) and each area (OFC, dlPFC, ACC)
%       - [monkey]_CCM_option_[area], [monkey]_CCM_attribute_[area]:
%       experimental CCMs for option and attribute trials
%       - not_noise_CCM: logical mask selecting CCM cells that represent
%        meaningful cue-step pairs
%
% OUTPUTS -----------------------------------------------------------------
% analysis_output : <struct 1x1>
%     - In preprocessing mode:
%     Structure containing all precomputed datasets and regression matrices
%     needed for the analysis.
%     - In analysis mode:
%      Structure containing the neural geometry measures:
%           - dist_RDM_[monkey]_[area]: distance between RNN and monkey RDM
%           - dist_CCM_[monkey]_[area]: distance between RNN and monkey CCM

arguments
    params (:,1) double = []
    ~
    ~
    inputs (1,1) struct = struct()
end


if isempty(params)

    % --- Preprocessing mode: load experimental neural data --- %

    % Load experimental neural geometry for all monkeys, pooled data, and
    % areas
    MonkeyNeuralGeometry = load(fullfile(getPath("MonkeyData"), "NeuralGeometry.mat"));
    for area = ["OFC", "dlPFC", "ACC"]
        for monkey = ["Franck", "Miles", "both"]
            for geometry = ["RDM", "CCM_option", "CCM_option_p", ...
                    "CCM_attribute", "CCM_attribute_p"]
                analysis_output.(geometry + "_" + monkey + "_" + area) = ...
                    MonkeyNeuralGeometry.(area).(monkey).(geometry);
            end
        end
    end

    % Define CCM cells that represent meaningful cue-step pairs
    analysis_output.not_noise_CCM = true(9);
    analysis_output.not_noise_CCM([4, 7, 8], :) = false;
    analysis_output.not_noise_CCM(:, [4, 7, 8]) = false;

else

    % --- Analysis mode: compute neural distances --- %

    for monkey = ["Franck", "Miles", "both"]
        for area = ["OFC", "dlPFC", "ACC"]
        
            % --- RDM distance --- %

            % Select the experimental RDM
            expe_RDM = inputs.("RDM_" + monkey + "_" + area);
            
            % Vectorize the upper half of each RDM, diagonal excluded
            vec_expe_RDM = reshape(triu(expe_RDM, 1), [], 1);
            vec_network_RDM = reshape(triu(inputs.RDM, 1), [], 1);

            % Compute the correlation distance
            analysis_output.("dist_RDM_" + monkey + "_" + area) = ...
                1 - corr(vec_expe_RDM, vec_network_RDM, Type="Spearman");

            % --- CCM distance --- %            

            % Select the experimental CCMs
            expe_CCM_option = inputs.("CCM_option_" + monkey + "_" + area);
            expe_CCM_attribute = inputs.("CCM_attribute_" + monkey + "_" + area);

            % Create vectors of interpretable CCM cells
            vec_expe_CCM = [expe_CCM_option(inputs.not_noise_CCM) ; ...
                expe_CCM_attribute(inputs.not_noise_CCM)];
            vec_network_CCM = [inputs.CCM_option(inputs.not_noise_CCM) ; ...
                inputs.CCM_attribute(inputs.not_noise_CCM)];

            % Compute the Euclidian distance
            analysis_output.("dist_CCM_" + monkey + "_" + area) = ...
                norm(vec_expe_CCM - vec_network_CCM);
           
        end
    end
end
