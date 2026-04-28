# Biological profits of irrational computations in the orbitofrontal cortex

## Repository structure

The project is organised into five main components: configuration files, data, scripts, source code, and results.

```
├── data/
│   ├── models/
│   │   ├── raw/          → Individual trained RNN files
│   │   └── processed/    → Aggregated models and measure results
│   └── monkeys/
│       ├── raw/          → Raw behavioural data and neural recordings
│       └── processed/    → Preprocessed behavioural and neural data
├── results/
│   ├── figures/          → Paper figures
│   └── metrics/          → Statistical results
├── scripts/              → High-level scripts launching full pipelines
├── src/
│   ├── analyses/         → Functions analysing RNNs and monkey data
│   │   ├── helpers/
│   │   └── measures/
│   ├── exp_data/         → Experimental data preprocessing
│   ├── models/           → Training procedures
│   ├── plots/            → Functions generating figures
│   │   ├── helpers/
│   │   └── subplots/
│   ├── stats_test/       → Functions generating statistical test tables
│   ├── utils/
│   └── VBA_dep/          → Adapted VBA toolbox functions
├── globalConfig.m        → Controls RNN training parameters
├── setup.m               → Adds required folders to MATLAB path
└── README.md
```

## Quick start

1. **Clone the reposititory**

```bash
git clone https://github.com/jbenon/Biological-profits-of-irrational-computations-in-the-OFC.git <folder_name>
cd <folder_name>
```

2. **(Optional) Download raw experimental data**

The monkey recordings used for comparison are from:

> [Hunt et al. (2018), _Nature Neuroscience_](https://www.nature.com/articles/s41593-018-0239-5)

The dataset is publicly available on the CRCNS platform: https://crcns.org/data-sets/pfc/pfc-7/about-pfc-7

After downloading, place the files in `data/monkeys/raw/`. Expected structure:

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

The preprocessing pipeline will automatically generate files in `data/monkeys/processed/`.

3. **(Optional) Download processed experimental data**

The scripts processing raw experimental data run rather fast. However, you can also directly download the processed files (link forthcoming) and place them in `data/monkeys/processed/`.

4. **(Optional) Download trained RNNs**

Training all networks from scratch is time-consuming.
In order to immediately test the analysis functions, you can download the trained RNN files (link forthcoming) and place them in `data/models/raw/`. Expected structure:

```
data/
└── models/
    └── raw/
        ├── irrational_Franck/              → RNNs initially trained to match the behaviour of monkey F
        ├── irrational_Miles/               → RNNs initially trained to match the behaviour of monkey M
        ├── rational/                       → RNNs initially trained to be rational
        ├── rational_energetic_budget_avg   → RNNs trained jointly to maximize choice rationality and minimize their energetic budget
        ├── rational_info_transfer_rate     → RNNs trained jointly to maximize choice rationality and maximize their information transfer rate
        ├── rational_prop_optimal_impaired_one_unit_reversed   → RNNs trained jointly to maximize choice rationality and maximize robustness to lesions of one unit
```
where each subfolder contains one file per model, and a configuration file `_DatasetSpecs.mat` which stores training information.

5. **(Optional) Download processed RNN data**

In order to regenerate figures without re-running the analyses, download processed files (link forthcoming) and place them in `data/models/processed/`. Expected structure:

```
biological_profits_irrational_OFC/
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
where each file `[name]_last.mat` stores analysis results for the last training step of models contained in `/models/raw/[name]`, and `[name]_full.mat` stores analysis results for all training steps.

6. **Setup MATLAB**

Open MATLAB in the project root directory and run:

```matlab
setup
```

This script adds all required folders to the MATLAB path and verifies toolbox dependencies.

## Full pipeline

### Processing monkey records

The script is located in `scripts/process_monkey_data.m`. It loads raw data in `data/monkeys/raw/` and saves the results in `data/monkeys/processed/`.

### Training models

The training script is located in `scripts/training_models.m`. It can launch the training of:

- Rational networks
- Distorted networks (re-trained between the rational and irrational regimes)
- Irrational networks (monkey-specific)
- Biologically constrained networks
- Subjectively rational networks (monkey-specific)

Be aware that training time is long, especially for biologically constrained networks.
Since the training functions are compatible with parallel processing, it is recommended to launch them on a computing cluster.

The results are saved in `data/models/raw/`.

### Analysing trained models

The analysis script is located in `scripts/analyse_models.m`. It computes:

- Behavioural performance metrics
- Neural representational measures
- Distance metrics relative to monkey OFC recordings
- Interference measures
- Robustness and constraint-related measures

Note that robustness analyses and full trajectory analyses can be computationally intensive. Since the analysis functions are compatible with parallel processing, it is recommended to launch them on a computing cluster.

The results are saved in `data/models/processed/`.

### Producing figures and statistics

Figures can reproduced by launching any script contained in `src/plots/`. The results are saved in pdf and png format in `results/figures/`. Note that the cropping of pdf and the assembling of figures and schemes was done through a third-party software (Affinity).


Statistical tables can be reproduced by launching any script contained in `src/stats_tests/`. The results are saved as csv and mat files in `results/metrics/`.

## Dependencies

- MATLAB (tested on MATLAB R2024b)
- Statistic and Machine Learning Toolbox
- Parallel Processing Toolbox
- VBA toolbox (adapted version included in `stc/VBA_dep/`)

## Citation

If you use this repository, please cite:

> Citation here

## Contact

Juliette Bénon

juliette.benon@proton.me
