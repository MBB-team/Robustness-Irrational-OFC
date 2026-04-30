% =========================================================================
% MASTER TRAINING PIPELINE
% =========================================================================
%
% -------------------------------------------------------------------------
% OVERVIEW
% -------------------------------------------------------------------------
% This script orchestrates the full model-training pipeline used in the
% paper. It controls:
%   - Initial training
%   - Re-training / distortion procedures
%   - Training under biological constraints
%
% -------------------------------------------------------------------------
% ADDITIONAL TRAINING PROCEDURES (NOT INCLUDED IN THIS SCRIPT)
% -------------------------------------------------------------------------
% The following procedures are available in the codebase but are not
% executed here. They can be launched manually if needed.
%
% 1) Rational  → Subjectively rational
%    trainModelsDistort("rational", "rational_subj", "", "Franck");
%    trainModelsDistort("rational", "rational_subj", "", "Miles");
%
% 2) Subjectively rational → Optimal rational
%    trainModelsDistort("rational_subj", "rational", "Franck", "");
%    trainModelsDistort("rational_subj", "rational", "Miles", "");
%
% 3) Irrational → Subjectively rational
%    trainModelsDistort("irrational_Franck", "rational_subj", "Franck", "Franck");
%    trainModelsDistort("irrational_Miles", "rational_subj", "Miles", "Miles");
%
% 4) Subjectively rational → Irrational
%    trainModelsDistort("rational_subj", "irrational_Franck", "Franck", "Franck");
%    trainModelsDistort("rational_subj", "irrational_Miles", "Miles", "Miles");
%
% 5) Training under additional biological constraints
%    (see trainModelsInitialRationalConstrained)
%
% -------------------------------------------------------------------------
% USAGE
% -------------------------------------------------------------------------
% Activate or deactivate sections of the pipeline using the flags defined
% below.
%
% -------------------------------------------------------------------------
% RUN TIME
% -------------------------------------------------------------------------
% Training on a CPU takes approximately 1h per model, and a few days if
% there is an additional training constraint. All training scripts are
% compatible with parallel processing.
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

% Main paper training pipeline
FLAGS.train_rational_networks                 = true;
FLAGS.train_irrational_networks               = false;
FLAGS.distort_rational_networks_to_irrational = false;

% Figure 1 only: training with biological constraints
FLAGS.constraint_energetic_budget             = false;
FLAGS.constraint_info_transfer_rate           = false;
FLAGS.constraint_robustness                   = false;
FLAGS.constraint_EI_balance                   = false;
FLAGS.constraint_weights                      = [0.001, 0.01, 0.1, 1, 10, 100, 1000];
FLAGS.train_rational_constrained_networks = ...
    any([...
    FLAGS.constraint_energetic_budget, ...
    FLAGS.constraint_info_transfer_rate, ...
    FLAGS.constraint_robustness, ...
    FLAGS.constraint_EI_balance]);

% Additional analyses (not included in the paper)
FLAGS.train_rational_subj_networks            = false;
FLAGS.distort_irrational_networks_to_rational = false;


%% === Call model training functions ======================================

% --- Initial training ----------------------------------------------------

tic
if FLAGS.train_rational_networks
    fprintf("\n Initial training of rational models...\n");
    trainModelsInitialRational();
    fprintf("Done.\n");
end
toc

tic
if FLAGS.train_irrational_networks
    fprintf("\n Initial training of irrational models...\n");
    trainModelsInitialIrrational("Franck");
    trainModelsInitialIrrational("Miles");
    fprintf("Done.\n");
end
toc

if FLAGS.train_rational_subj_networks
    fprintf("\n Initial training of subjectively rational models...\n");
    trainModelsInitialRationalSubj();
    fprintf("Done.\n");
end

% --- Re-training ---------------------------------------------------------

tic
if FLAGS.distort_rational_networks_to_irrational
    fprintf("\n Distortion of rational models into irrational models...\n");
    trainModelsDistort("rational", "irrational_Franck", "", "Franck");
    trainModelsDistort("rational", "irrational_Miles", "", "Miles");
    fprintf("Done.\n");
end
toc

if FLAGS.distort_irrational_networks_to_rational
    fprintf("\n Distortion of irrational models into rational models...\n");
    trainModelsDistort("irrational_Franck", "rational", "Franck", "");
    trainModelsDistort("irrational_Miles", "rational", "Miles", "");
    fprintf("Done.\n");
end

% --- Initial constrained training ----------------------------------------

if FLAGS.train_rational_constrained_networks
    fprintf("\n Initial training of rational models under biological constraints:");
    tic
    if FLAGS.constraint_energetic_budget
        fprintf("\nConstraint on the energetic budget...\n");
        trainModelsInitialRationalConstrained(@computeEnergeticBudget, FLAGS.constraint_weights);
        fprintf("Done.\n");
    end
    toc

    tic
    if FLAGS.constraint_info_transfer_rate
        fprintf("\nConstraint on the information transfer rate...\n");
        trainModelsInitialRationalConstrained(@computeInfoTransferRate, FLAGS.constraint_weights);
        fprintf("Done.\n");
    end
    toc
    
    tic
    if FLAGS.constraint_robustness
        fprintf("\nConstraint on the robustness to unit lesions...\n");
        trainModelsInitialRationalConstrained(@computeRobustnessToUnitLesions, FLAGS.constraint_weights);
        fprintf("Done.\n");
    end
    toc
    
    tic
    if FLAGS.constraint_EI_balance
        fprintf("\nConstraint on the E/I balance...\n");
        trainModelsInitialRationalConstrained(@computeEIbalance, FLAGS.constraint_weights);
        fprintf("Done.\n");
    end
    toc
    
end

% --- End -----------------------------------------------------------------

fprintf("\n === End of the script. === \n");
