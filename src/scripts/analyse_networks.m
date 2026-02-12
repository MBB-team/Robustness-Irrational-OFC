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
% AUTHOR & VERSION
% -------------------------------------------------------------------------
% Author: Juliette Bénon
% Date: 12/02/2026


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
FLAGS.analyse_rational_networks                   = true;
FLAGS.analyse_irrational_networks                 = true;
FLAGS.analyse_rational_subj_networks              = true;
FLAGS.analyse_rational_constrained_networks       = true;

% --- Which analysis functions to run -------------------------------------

% Characterization of choice behaviour
FLAGS.fit_one_value_profile                       = true;
FLAGS.predictMonkeyChoices                        = true;
FLAGS.predictOptimalChoices                       = true;

% Characterization of neural coding
FLAGS.compute_framework_information_loss          = true;

% Interference effects
FLAGS.compute_cue_attention_pollution             = true;
FLAGS.compute_cue_order_pollution                 = true;

% Neural properties
FLAGS.generate_neural_geometry_matrices              = true;
FLAGS.compute_neural_distance                     = true;
FLAGS.categorize_integration_units                = true;

% Biological constraints
FLAGS.compute_EI_balance                          = true;
FLAGS.compute_info_transfer_rate                  = true;
FLAGS.compute_energetic_budget                    = true;
FLAGS.compute_code_redundancy                     = true;
FLAGS.compute_robustness_to_unit_lesions          = true;
FLAGS.compute_robustness_to_connection_lesions    = true;


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
    params_file = fullfile(getPath("Models"), file_name + ".mat");

    % Generate storing file if necessary
    if ~ isfile(params_file)
        gatherAllModels(folder_name, FLAGS.analyse_last_step_only);
    end

    % --- Characterization of choice behaviour ----------------------------

    if FLAGS.fit_one_value_profile
        fprintf("\n Fit one value profile...\n");
        callMeasure(@fitOneValueProfile, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.predictMonkeyChoices
        fprintf("\n Predict monkey choices...\n");
        callMeasure(@predictMonkeyChoices, params_file, ...
            supp_variable="fit_label");
        fprintf("Done.\n");
    end

    if FLAGS.predictOptimalChoices
        fprintf("\n Predict optimal choices...\n");
        callMeasure(@predictMonkeyChoices, params_file);
        fprintf("Done.\n");
    end

    % --- Characterization of neural coding -------------------------------

    if FLAGS.compute_framework_information_loss
        fprintf("\n Compute framework information loss...\n");
        callMeasure(@computeFrameworkInformationLoss, params_file);
        fprintf("Done.\n");
    end

    % --- Interference effects --------------------------------------------

    if FLAGS.compute_cue_attention_pollution
        fprintf("\n Compute cue attention pollution...\n");
        callMeasure(@computeCueAttentionPollution, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.compute_cue_order_pollution
        fprintf("\n Compute cue order pollution...\n");
        callMeasure(@computeCueOrderPollution, params_file);
        fprintf("Done.\n");
    end

    % --- Neural properties -----------------------------------------------
    
    if FLAGS.categorize_integration_units
        fprintf("\n Categorize integration units...\n");
        callMeasure(@categorizeIntegrationUnits, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.generate_neural_geometry_matrices
        fprintf("\n Generate neural geometry matrices...\n");
        callMeasure(@generateNeuralGeometryMatrices, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.compute_neural_distance
        fprintf("\n Compute neural distances...\n");
        callMeasure(@computeNeuralDistance, params_file, ...
            supp_variable=["RDM", "CCM_option", "CCM_attribute"]);
        fprintf("Done.\n");
    end

    % --- Biological constraints ------------------------------------------

    if FLAGS.compute_EI_balance
        fprintf("\n Compute E/I balance...\n");
        callMeasure(@computeEIbalance, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.compute_info_transfer_rate
        fprintf("\n Compute information transfer rate...\n");
        callMeasure(@computeInfoTransferRate, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.compute_energetic_budget
        fprintf("\n Compute energetic budget...\n");
        callMeasure(@computeEnergeticBudget, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.compute_code_redundancy
        fprintf("\n Compute code redundancy...\n");
        callMeasure(@computeCodeRedundancy, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.compute_robustness_to_unit_lesions
        fprintf("\n Compute robustness to unit lesions...\n");
        callMeasure(@computeRobustnessToUnitLesions, params_file);
        fprintf("Done.\n");
    end

    if FLAGS.compute_robustness_to_connection_lesions
        fprintf("\n Compute robustness to connection lesions...\n");
        callMeasure(@computeRobustnessToConnectionLesions, params_file);
        fprintf("Done.\n");
    end

end

% --- End -----------------------------------------------------------------

fprintf("\n === End of the script. === \n");
