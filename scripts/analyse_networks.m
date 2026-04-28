% =========================================================================
% MASTER ANALYSIS PIPELINE
% =========================================================================
%
% -------------------------------------------------------------------------
% USAGE
% -------------------------------------------------------------------------
% Activate or deactivate sections of the pipeline using the RUN flags
% defined below.
%
% -------------------------------------------------------------------------
% RUN TIME
% -------------------------------------------------------------------------
% Most analyses are completed across all models (last step only) in a few
% minutes, except for the robustness computations, which take approximately
% 40s per model.
%
% -------------------------------------------------------------------------
% AUTHOR & VERSION
% -------------------------------------------------------------------------
% Author: Juliette Bénon
% Date: 28/04/2026


%% === Environment set-up =================================================
setup;
clear variables;
close all hidden;


%% === Flags (toggle sections on/off) =====================================

FLAGS = struct();

% Whether to analyse all fitting steps or only the last one of each fit
% phase
FLAGS.analyse_last_step_only                      = true;

% Which networks to analyse (identified by their initial training procedure)
FLAGS.analyse_rational_networks                   = false;
FLAGS.analyse_irrational_networks                 = false;
FLAGS.analyse_rational_subj_networks              = false;
FLAGS.analyse_rational_constrained_networks       = false;

% --- Which analysis functions to run -------------------------------------

% Characterization of choice behaviour
FLAGS.fit_one_value_profile                       = false;
FLAGS.predict_monkey_choices                      = false;
FLAGS.predict_optimal_choices                     = false;

% Characterization of neural coding
FLAGS.compute_framework_information_loss          = false;

% Interference effects
FLAGS.compute_cue_attention_pollution             = false;
FLAGS.compute_cue_order_pollution                 = false;

% Neural properties
FLAGS.categorize_integration_units                = false;
FLAGS.generate_neural_geometry_matrices           = false;
FLAGS.compute_neural_distance                     = false;

% Biological constraints
FLAGS.compute_EI_balance                          = false;
FLAGS.compute_info_transfer_rate                  = false;
FLAGS.compute_energetic_budget                    = false;
FLAGS.compute_code_redundancy                     = false;
FLAGS.compute_robustness_to_unit_lesions          = false;
FLAGS.compute_robustness_to_connection_lesions    = false;
FLAGS.compute_robustness_to_noise                 = false;


%% === Call measure functions =============================================

% --- Loop over network types ---------------------------------------------

% Gather network folders
all_folder_names = strings(0);
if FLAGS.analyse_rational_networks
    all_folder_names(end + 1) = "rational";
end
if FLAGS.analyse_irrational_networks
    all_folder_names(end + 1) = "irrational_Franck";
    all_folder_names(end + 1) = "irrational_Miles";
end
if FLAGS.analyse_rational_subj_networks
    all_folder_names(end + 1) = "rational_subj";
end
if FLAGS.analyse_rational_constrained_networks
    subfolders_dir = dir(getPath("ModelsRaw"));
    subfolders_names = string({subfolders_dir([subfolders_dir(:).isdir]).name});
    for subfolder = subgolfer_names
        if startsWith(subfolder, "rational_") && subfolder ~= "rational_subj"
            all_folder_names(end + 1) = subfolder;
        end
    end
end

for folder_name = all_folder_names

    % Identify file of interest
    if FLAGS.analyse_last_step_only
        file_name = folder_name + "_last";
    else
        file_name = folder_name + "_full";
    end 
    file_name = file_name + ".mat";

    % Generate storing file if necessary
    if ~ isfile(fullfile(getPath("Models"), file_name))
        gatherAllModels(folder_name, FLAGS.analyse_last_step_only);
    end

    % --- Characterization of choice behaviour ----------------------------

    if FLAGS.fit_one_value_profile
        fprintf("\n Fit one value profile...\n");
        callMeasure(@fitOneValueProfile, file_name, ...
            supp_variable="folder_name");
        fprintf("Done.\n");
    end

    if FLAGS.predict_monkey_choices
        fprintf("\n Predict monkey choices...\n");
        callMeasure(@predictMonkeyChoices, file_name, ...
            supp_variable="fit_label");
        fprintf("Done.\n");
    end

    if FLAGS.predict_optimal_choices
        fprintf("\n Predict optimal choices...\n");
        callMeasure(@predictOptimalChoices, file_name);
        fprintf("Done.\n");
    end

    % --- Characterization of neural coding -------------------------------

    if FLAGS.compute_framework_information_loss
        fprintf("\n Compute framework information loss...\n");
        callMeasure(@computeFrameworkInformationLoss, file_name, ...
            supp_variable="folder_name");
        fprintf("Done.\n");
    end

    % --- Interference effects --------------------------------------------

    if FLAGS.compute_cue_attention_pollution
        fprintf("\n Compute cue attention pollution...\n");
        callMeasure(@computeCueAttentionPollution, file_name, ...
            supp_variable="folder_name");
        fprintf("Done.\n");
    end

    if FLAGS.compute_cue_order_pollution
        fprintf("\n Compute cue order pollution...\n");
        callMeasure(@computeCueOrderPollution, file_name);
        fprintf("Done.\n");
    end

    % --- Neural properties -----------------------------------------------
    
    if FLAGS.categorize_integration_units
        fprintf("\n Categorize integration units...\n");
        callMeasure(@categorizeIntegrationUnits, file_name);
        fprintf("Done.\n");
    end

    if FLAGS.generate_neural_geometry_matrices
        fprintf("\n Generate neural geometry matrices...\n");
        callMeasure(@generateNeuralGeometryMatrices, file_name);
        fprintf("Done.\n");
    end

    if FLAGS.compute_neural_distance
        fprintf("\n Compute neural distances...\n");
        callMeasure(@computeNeuralDistance, file_name, ...
            supp_variable=["RDM", "CCM_option", "CCM_attribute", "fit_label"]);
        fprintf("Done.\n");
    end

    % --- Biological constraints ------------------------------------------

    if FLAGS.compute_EI_balance
        fprintf("\n Compute E/I balance...\n");
        callMeasure(@computeEIbalance, file_name);
        fprintf("Done.\n");
    end

    if FLAGS.compute_info_transfer_rate
        fprintf("\n Compute information transfer rate...\n");
        callMeasure(@computeInfoTransferRate, file_name);
        fprintf("Done.\n");
    end

    if FLAGS.compute_energetic_budget
        fprintf("\n Compute energetic budget...\n");
        callMeasure(@computeEnergeticBudget, file_name);
        fprintf("Done.\n");
    end

    if FLAGS.compute_code_redundancy
        fprintf("\n Compute code redundancy...\n");
        callMeasure(@computeCodeRedundancy, file_name);
        fprintf("Done.\n");
    end

    if FLAGS.compute_robustness_to_unit_lesions
        fprintf("\n Compute robustness to unit lesions...\n");
        callMeasure(@computeRobustnessToUnitLesions, file_name);
        fprintf("Done.\n");
    end

    if FLAGS.compute_robustness_to_connection_lesions
        fprintf("\n Compute robustness to connection lesions...\n");
        callMeasure(@computeRobustnessToConnectionLesions, file_name);
        fprintf("Done.\n");
    end

    if FLAGS.compute_robustness_to_noise
        fprintf("\n Compute robustness to internal noise...\n");
        callMeasure(@computeRobustnessToInternalNoise, file_name);
        fprintf("Done.\n");
    end

end

% --- End -----------------------------------------------------------------

fprintf("\n === End of the script. === \n");
