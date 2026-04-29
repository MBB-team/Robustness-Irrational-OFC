% =========================================================================
% MASTER EXPERIMENTAL ANALYSIS PIPELINE
% =========================================================================
%
% -------------------------------------------------------------------------
% OVERVIEW
% -------------------------------------------------------------------------
% This script orchestrates the analysis pipeline applied to experimental
% (monkey) data. It controls:
%   - Pre-processing of raw data (extraction of trial structure and firing
%   rates)
%   - Execution of behavioural and neural analysis modules
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
% Date: 29/04/2026


%% === Environment set-up =================================================

setup;
clear variables;
close all hidden;


%% === Flags (toggle sections on/off) =====================================

FLAGS = struct();

% --- Which analysis functions to run -------------------------------------

% Pre-processing (necessary before any other analysis)
FLAGS.extract_trials_firing_rate                  = false;

% Behaviour analysis
FLAGS.fit_value_profile                           = false;
FLAGS.compute_choice_difficulty                   = false;
FLAGS.compute_prop_irrational_choices             = false;
FLAGS.compute_decision_residuals                  = false;
FLAGS.compute_cue_attention_pollution             = false;

% Neural analysis
FLAGS.categorize_neurons                          = false;
FLAGS.compute_neural_geometry                     = false;


%% === Call measure functions =============================================


% --- Pre-processing ------------------------------------------------------

if FLAGS.extract_trials_firing_rate
    fprintf("\n Extract trials info and firing rates...\n");
    fitMonkeyValueProfile();
    fprintf("Done.\n");
end


% --- Behaviour analysis --------------------------------------------------

if FLAGS.fit_value_profile
    fprintf("\n Fit value profile...\n");
    fitMonkeyValueProfile();
    fprintf("Done.\n");
end

if FLAGS.compute_choice_difficulty
    fprintf("\n Compute choice difficulty...\n");
    computeMonkeyChoiceDifficulty();
    fprintf("Done.\n");
end

if FLAGS.compute_prop_irrational_choices
    fprintf("\n Compute proportion of irrational choices...\n");
    computeMonkeyPropIrrationalChoices();
    fprintf("Done.\n");
end

if FLAGS.compute_decision_residuals
    fprintf("\n Compute corrected proportion of irrational choices...\n");
    computeMonkeyDecisionResiduals();
    fprintf("Done.\n");
end

if FLAGS.compute_cue_attention_pollution
    fprintf("\n Compute interferences due to cue attentional focus...\n");
    computeMonkeyCueAttentionPollution();
    fprintf("Done.\n");
end


% --- Neural analysis -----------------------------------------------------

if FLAGS.categorize_neurons
    fprintf("\n Categorize neurons...\n");
    categorizeMonkeyUnits();
    fprintf("Done.\n");
end

if FLAGS.compute_neural_geometry
    fprintf("\n Compute neural geometry...\n");
    computeMonkeyNeuralGeometry();
    fprintf("Done.\n");
end


% --- End -----------------------------------------------------------------

fprintf("\n === End of the script. === \n");
