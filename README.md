# Biological profits of irrational computations in the orbitofrontal cortex
[![MATLAB](https://img.shields.io/badge/MATLAB-R2024b-648fff)](https://www.mathworks.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-dc267f)](LICENSE)
[![DOI](https://img.shields.io/badge/DOI-10.6084%2Fm9.figshare.32124898-fe6100)](https://doi.org/10.6084/m9.figshare.32124898)

This repository contains the code used in:
> (in review)

**Quick navigation**
- :brain: Understand the code and data structure → see [Repository structure](#repository-structure)  
- :gear: Reproduce the results → go to [Full pipeline](#full-pipeline)

**Table of contents**:
- [Repository structure](#repository-structure)
    - [Configuration files](#configuration-files)
    - [Data](#data)
    - [Source code](#source-code)
    - [Scripts](#scripts)
    - [Results](#results)
- [Full pipeline](#full-pipeline)
    - [Overview](#overview)
    1. [Configure MATLAB project](#1-configure-matlab-project)
    2. [Download raw experimental data](#2-download-raw-experimental-data)
    3. [Process experimental data](#3-process-experimental-data)
    4. [Train models](#4-train-models)
    5. [Analyse trained models](#5-analyse-trained-models)
    6. [Generate results](#6-generate-results)
- [Dependencies](#dependencies)
- [Citation](#citation)
- [Contact](#contact)
- [License](#license)

# Repository structure

The project is organised into five main components: [configuration files](#configuration-files), [data](#data), [source code](#source-code), [scripts](#scripts), and [results](#results).

## Configuration files

At the root of the project, `setup.m` prepares the execution of scripts in MATLAB by adding all relevant folders to the MATLAB path and checking for required toolboxes. 
`globalConfig.m` defines the hyperparameters used for training the RNN models.

## Data

### :monkey: Experimental data

`data/monkeys/raw` contains the experimental raw data collected by [Hunt et al. (2018)](https://www.nature.com/articles/s41593-018-0239-5): trial structure, monkey choices, and neuronal spikes in the OFC, dlPFC and ACC. `data/monkeys/processed` contains the processed data used for comparisons between models and monkeys.

### :robot: Raw trained models

#### Subfolders

`data/models/raw` contains the outputs of model training. It includes one subfolder per training procedure, in alphabetical order:
- `irrational_Franck/`: models trained directly on the behaviour of monkey F
- `irrational_Miles/`: models trained directly on the behaviour of monkey M
- `rational/`: models trained to be rational, then distorted to match each monkey's behaviour
- `rational_energetic_budget_avg/`: models jointly trained to be rational while minimising energetic cost
- `rational_info_transfer_rate/`: models jointly trained to be rational while maximising information transfer
- `rational_prop_optimal_impaired_one_unit_reversed/`: models jointly trained to be rational while maximising robustness to unit lesions

#### Files

Each of these subfolders contains a `_DatasetSpecs.mat` storing training information (including initial states and training/testing datasets), as well as one file per trained model.
Each model file follows the naming convention: `[input format]_TO_[output format]_[value computation]_ARCH_sig_z_[rng seed].mat`, where:
- `input format` indicates how the attended option is encoded in the input: spatial location (`loc`) or temporal order (`order`)
- `output format` indicates how options are encoded in the output: spatial location (`loc`), temporal order (`order`) or attentional focus (`attention`)
- `value computation` indicates whether the model performs value synthesis (`both`) or value comparison (`diff`)
- `rng seed` refers to the random seed used for training, linked to the initial state and datasets stored in `_DatasetSpecs.mat`

For example, `loc_TO_attention_both_ARCH_sig_z_5.mat` corresponds to a model that takes spatial input (left/right option), outputs both attended and unattended values, and was trained with random seed 5.

> [!NOTE]
> `ARCH_sig_z` indicates a sigmoid activation function with recurrent connections within the integration layer (`z`). Alternative configurations (e.g. Gaussian activation or different recurrent connections) can be specified by modifying `getDesiredNetworkConfigs` (see [Source code > :arrows_clockwise: Model training](#arrows_clockwise-model-training)).

Models trained under biological constraints include an additional parameter: `[input format]_TO_[output format]_[value computation]_ARCH_sig_z_[rng seed]_[constraint weight].mat`.

#### File content

Each `.mat` files contains:
- a `Config` structure describing the model architecture
- one or more `Fit[fit label]` structure storing training trajectories
Rational models include multiple training stages:
- `FitRational`: initial rational training
- `FitIrrationalFranck`: distortion from the rational state to an irrational state based on monkey F's choices
- `FitIrrationalMiles`: distortion from the rational state to an irrational state based on monkey M's choices
- `FitRationalSubjFranck`: distortion from the rational state to a "subjectively rational" state based on monkey F's value function
- `FitRationalSubjMiles`: distortion from the rational state to a "subjectively rational" state based on monkey M's value function

Models which were not distorted after their initial training (e.g. in `data/raw/irrational_Franck/` contain only one such structure.

### :microscope: Model analysis results

`data/models/processed` contains outputs from model analyses. Each file `[training procedure]_[training stage].mat` stores outputs from multiple analysis functions, aggregated across models from `data/models/raw/[training procedure]/`. `[training stage]` specifies whether analyses are performed on final model states (`last`) or across full training histories (`full`).

## Source code

### :triangular_ruler: VBA toolbox

`src/VBA_dep/` contains the subset of functions from the [VBA toolbox](https://mbb-team.github.io/VBA-toolbox/) required for model training. This is a modified version that stores full training histories rather than final states only.

### :wrench: Utilities

`src/utils/` contains utility functions reused across modules.

### :busts_in_silhouette: Third-party utilities

`src/third-party/` contains external functions (from MATLAB File Exchange), currently used for plotting.

### :arrows_clockwise: Model training

`src/models/` contains all functions required to train models. Outputs are saved in `data/models/raw/`.

In particular, four functions are used to launch the training itself:
- `trainModelsInitialRational`: trains models from their initial (random) state to a rational state.
- `trainModelsInitialIrrational`: trains models from their initial (random) state to an irrational state, based on the choices of one of the monkeys.
- `trainModelsDistort`: distorts already trained models to produce another behaviour. For example, re-trains rational models to produce irrational choices.
- `trainModelsInitialRationalConstrained`: jointly trains models from their initial (random state) to maximize both their rationality and their adequacy to a biological constraint.
- In addition, `trainModelsInitialRationalSubj` can be used to train models from their initial (random) state to a "subjectively rational" state, based on the value function of one of the monkeys.

The function `getDesiredNetworkConfigs` defines all model architectures and cohort variants, and can be modified to explore alternative configurations.

After training, models must be prepared for analysis using `gatherAllModels` function, which aggregates model states into `data/models/processed/`.

### :mag: Model analysis

`src/analyses` contains functions for analysing both models and experimental data. Model analyses are orchestrated via `callMeasure`, which executes functions in `src/analyses/measures/`. Supporting utilities are located in `src/analyses/helpers`.

### :microscope: Experimental data analysis

`src/exp_data/` contains functions for processing experimental data. These functions automatically load raw data from `data/monkeys/raw/` and save results to `data/monkeys/processed/`, using shared analysis routines from `src/analyses/measures/`.

### :chart_with_upwards_trend: Plots

`src/plots/` contains scripts and functions for generating figures. These scripts load analysis outputs, generate figures and save them to `results/figures/`. They rely on subplot functions (`src/plots/subplots/`) and helper utilities (`src/plots/helpers/`).

### :abacus: Statistical tests

`src/stats_tests/` contains scripts and functions for computing statistical results reported in the paper. Outputs are saved to `results/metrics/`, with helper functions in `src/stats_tests/helpers/`.

## Scripts

`scripts/` contains three main scripts for running the pipeline, each controlled via boolean flags:
- `train_networks`: train models
- `analyse_exp_data`: analyse experimental data
- `analyse_networks`: analyse trained models

## Results

### :chart_with_upwards_trend: Figures

`results/figures/` contains all figures in `.pdf` and `.png` format. Note that this folder also includes schematic elements produced using third-party software. Cropping and final figure assembly were performed using [Affinity](https://www.affinity.studio/).

### :abacus: Statistical tests

`results/metrics/` contains `.csv` and `.mat` files storing statistical results. Each `.csv` file includes:

**Test description**:
| Column name | Description | Example |
|-------------|-------------|---------|
| `test_name` | statistical test | `paired_ttest` |
| `tail` | when applicable, test tail | `two_sided` |
| `dependent_variable` | variable being tested | `bacc_Franck` |
| `independent_variable` | grouping factor | `fit_phase` |
| `independent_variable_levels` | group labels | `rational`, `irrational` |
| `subset_factors` | filtering factors | `model_config` |
| `subset_levels` | selected subset levels | `9` |

This example describes a two-sided paired t-test comparing the balanced accuracy of models from the cohort n°9 predicting Monkey F's choices, between their rational and irrational state.

**Test result**:
| Column name | Description |
|-------------|-------------|
| `sample_size_1`, `sample_size_2` | sample size of both groups |
| `degrees_freedom` | test's degrees of freedom |
| `mean_1`, `mean_2` | mean of both groups |
| `standard_error_1`, `standard_error_2` | standard errors $\left(\frac{\text{standard deviation}}{\sqrt{\text{sample size}}}\right)$ of both groups |
| `r` | when applicable, Pearson's $r$ coefficient |
| `beta` | when applicable, regression coefficients |
| `p_value` | p-value |
| `cohens_d` | when applicable, Cohen's $d$ effect size |
| `p_value_threshold` | p-value threshold for rejecting the null hypothesis, corrected for multiple comparisons using Bonferroni correction |
| `conf_interval_95_1`, `conf_interval_95_2` | when applicable, lower and upper bound of the 95% confidence interval for the true population mean (one-sample and paired t-test) or the difference in group means (two-sample t-test) |

# Full pipeline

Below is a step-by-step guide to reproducing all results, either from scratch or using intermediate processed data.

## Overview

| Step | Approx. run time | Alternative |
|------|------------------|-------------|
| [1. Configure MATLAB project](#1-configure-matlab-project) | 5 seconds | |
| [2. Download raw experimental data](#2-download-raw-experimental-data) | 1 hour | Skip steps 2-3 |
| [3. Process experimental data](#3-process-experimental-data) | 5 minutes | Download processed data |
| [4. Train models](#4-train-models) | 1 month on a 32-core cluster | Skip steps 4-5 |
| [5. Analyse trained models](#5-analyse-trained-models) | 10 minutes / 1 day | Download processed data |
| [6. Generate results](#6-generate-results) | 3 minutes |

## 1. Configure MATLAB project

First, clone this repository. Open a terminal, navigate to your desired folder location, and run:

```bash
git clone https://github.com/jbenon/Biological-profits-of-irrational-computations-in-the-OFC.git <local_folder_name>
```

Then, open MATLAB in the project root directory and run `setup` to configure paths and verify dependencies. This step must be ran each time a new MATLAB session is started.

> [!NOTE]
> See also: [Dependencies](#dependencies)

## 2. Download raw experimental data

The experimental dataset is required for comparisons between models and monkeys. It was collected by Hunt and colleagues, with analysis results published in: 

> Hunt, L. T., Malalasekera, W. M. N., de Berker, A. O., Miranda, B., Farmer, S. F., Behrens, T. E. J., & Kennerley, S. W. (2018). Triple dissociation of attention and decision computations across prefrontal cortex. Nature Neuroscience, 21(10), 1471–1481. [https://doi.org/10.1038/s41593-018-0239-5](https://doi.org/10.1038/s41593-018-0239-5)

The dataset can be freely downloaded from the CRCNS platform:

> Hunt L.T., Malalasekera W.M.N, Kennerley, S.W. (2018); Recordings from three subregions of macaque prefrontal cortex during an information search and choice task. CRCNS.org [http://dx.doi.org/10.6080/K0PZ5712](http://dx.doi.org/10.6080/K0PZ5712)


After downloading, place the files in `data/monkeys/raw/` to reproduce the following architecture:

```
data/
└── monkeys/
    └── raw/
        ├── frank_area.mat
        ├── miles_area.mat
        └── neuronal_data/
            ├── F002/
            ├── F003/
            ├── ...
            ├── M048/
            └── M049/
```

## 3. Process experimental data

The experimental data can be processed using `scripts/analyse_exp_data.m`, which automates the execution of functions in `src/exp_data/`.

:stopwatch: Full processing takes approximately *5 minutes*.

:fast_forward: Alternatively, processed experimental data can be freely downloaded from:

> Bénon, J. (2026). <i>Irrational value computations in the orbitofrontal cortex reflect circuit-level robustness</i>. figshare. [https://doi.org/10.6084/m9.figshare.32124898](https://doi.org/10.6084/m9.figshare.32124898)

Download and unzip the file `monkeys_processed.zip`, then copy its content to `data/monkeys/processed/` to reproduce the following architecture:

```
data/
└── monkeys/
    └── processed/
        ├── choiceDifficulty.mat
        ├── CueAttentionPollution.mat
        ├── CueSequences.mat
        ├── DecisionResiduals.mat
        ├── NeuralGeometry.mat
        ├── PadoaSchioppaCells.mat
        ├── PropIrrational.mat
        ├── UnitRecordings.mat
        └── ValueProfile.mat
```

## 4. Train models

> [!NOTE]
> More details on the raw models data format: [Data > :robot: Raw trained models](#robot-raw-trained-models)

Models can be trained using `scripts/train_networks.m`, which automates the execution of functions in `src/models/`.

> [!IMPORTANT]
> Training is computationally demanding. A single model typically requires ~40–60 minutes, while constrained models may take several days. It is therefore strongly recommended to run the training on a multi-core computing cluster to fully exploit the scripts’ parallel processing capabilities.

:fast_forward: Alternatively, raw trained models can be freely downloaded from:

> Bénon, J. (2026). <i>Irrational value computations in the orbitofrontal cortex reflect circuit-level robustness</i>. figshare. [https://doi.org/10.6084/m9.figshare.32124898](https://doi.org/10.6084/m9.figshare.32124898)

Download and unzip the files corresponding to each training procedure, then copy their content to `data/models/raw/` to reproduce the following architecture (for more details, see [Data > :robot: Raw trained models](#robot-raw-trained-models)):

```
data/
└── models/
    └── raw/
        ├── irrational_Franck/
        ├── irrational_Miles/
        ├── rational/
        ├── rational_energetic_budget_avg/
        ├── rational_info_transfer_rate/
        └── rational_prop_optimal_impaired_one_unit_reversed/
```

## 5. Analyse trained models

> [!NOTE]
> More details on the analysis results data format: [Data > :microscope: Model analysis results](#microscope-model-analysis-results)

Models can be analysed using `scripts/analyse_networks.m`, which automated the execution of analysis functions in `src/analyses/measures/`. The script contains flags controlling:
- which training steps are analysed
- which training procedures are included
- which analyses are performed

Below are example flag configurations corresponding to different sets of results. For each configuration, all listed flags should be set to `true`, and all others to `false`.

1. **Main text results**: analyse the last training steps of models initially trained to be rational.
    - `analyse_last_step_only`
    - `analyse_rational_networks`
    - `fit_one_value_profile`
    - `predict_monkey_choices`
    - `predict_optimal_choices`
    - `compute_cue_attention_pollution`
    - `categorize_integration_units`
    - `generate_neural_geometry_matrices`
    - `compute_neural_distance`
    - `compute_EI_balance`
    - `compute_info_transfer_rate`
    - `compute_energetic_budget`
    - `compute_code_redundancy`
    - `compute_robustness_to_unit_lesions`
2. **Main text results (figure 1 only)**: analyse the last training step of models jointly trained under a biological constraint.
    - `analyse_last_step_only`
    - `analyse_rational_constrained_networks`
    - `predict_optimal_choices`
    - `compute_info_transfer_rate`
    - `compute_energetic_budget`
    - `compute_robustness_to_unit_lesions`
3. **Main text results (figure 2 only)**: analyse the full training history of models initially trained to be rational.
    - `analyse_rational_networks`
    - `generate_neural_geometry_matrices`
    - `compute_neural_distance`
4. **Supplementary results**: further analyses on the last training steps of models initially trained to be rational.
    - `analyse_last_step_only`
    - `analyse_rational_networks`
    - `compute_framework_information_loss`
    - `compute_robustness_to_connection_lesions`
    - `compute_robustness_to_noise`
5. **Supplementary results (figure S8 only)**: analyse the last training step of models trained directly to produce irrational behaviour.
    - `analyse_last_step_only`
    - `analyse_irrational_networks`
    - `compute_robustness_to_unit_lesions`
    - `compute_robustness_to_connection_lesions`
    - `compute_robustness_to_noise`

:stopwatch: Most analyses are completed across all models in a few minutes, except for the robustness computations, which take approximately 40s per model.

:fast_forward: Alternatively, processed model data can be freely downloaded from:

> Bénon, J. (2026). <i>Irrational value computations in the orbitofrontal cortex reflect circuit-level robustness</i>. figshare. [https://doi.org/10.6084/m9.figshare.32124898](https://doi.org/10.6084/m9.figshare.32124898)

Download and unzip the file `models_processed.zip`, then copy its content to `data/models/processed/` to reproduce the following architecture:

```
data/
└── models/
    └── processed/
        ├── irrational_Franck_last.mat
        ├── irrational_Miles_last.mat
        ├── rational_energetic_budget_avg_last.mat
        ├── rational_full.mat
        ├── rational_info_transfer_rate_last.mat
        ├── rational_last.mat
        └── rational_prop_optimal_impaired_one_unit_reversed_last.mat
```

## 6. Generate results

All figures can be generated by scripts in `src/plots/`. Each script corresponds to one figure.  
All statistical analyses can be computed by running scripts in `src/stats_tests/`.

> [!NOTE]
> More details on the statistical tables format: [Results > :abacus: Statistical tests](#abacus-statistical-tests-1)

## Dependencies

- MATLAB (tested on MATLAB R2024b)
- Statistic and Machine Learning Toolbox
- Parallel Processing Toolbox (required for model training only)
- VBA toolbox (adapted version included in `src/VBA_dep/`)

## Citation

If you use this repository, please cite:

> (in review)

## Contact

Juliette Bénon | <juliette.benon@proton.me>

## License

This repository is licensed under the MIT License. See [LICENSE](LICENSE) for details.
