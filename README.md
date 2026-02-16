# Biological profits of irrational computations in the orbitofrontal cortex

## Repository structure

The project is organised into five main components: configuration files, data, scripts, source code, and results.

```
├── globalConfig.m        → Controls RNN training parameters
├── setup.m               → Adds required folders to MATLAB path
├── README.md
├── data/
│   ├── models/
│   │   ├── raw/          → Individual trained RNN files
│   │   └── processed/    → Aggregated models and measure results
│   └── monkeys/
│       ├── raw/          → Raw monkey recordings
│       └── processed/    → Preprocessed behavioural and neural data
├── scripts/              → High-level scripts launching full pipelines
├── src/
│   ├── analyses/         → Functions analysing RNNs and monkey data
│   │   ├── helpers/
│   │   └── measures/     → Standardized analysis functions
│   ├── exp_data/         → Monkey data preprocessing
│   ├── models/           → Training procedures
│   ├── plots/            → Figure-generation functions
│   │   ├── helpers/
│   │   └── subplots/     → Functions plotting into a single axes (ax)
│   ├── utils/
│   └── VBA_dep/          → Adapted VBA toolbox functions
└── results/
    ├── figures/          → Paper figures
    └── metrics/          → Statistical results and metrics
```

## Quick start

1. **Clone the reposititory**

```bash
git clone https://github.com/jbenon/Biological-profits-of-irrational-computations-in-the-OFC.git <folder_name>
cd <folder_name>
```

2. **Get the experimental data**

The monkey recordings used for comparison are from:

> [Hunt et al. (2018), _Nature Neuroscience_](https://www.nature.com/articles/s41593-018-0239-5)

The dataset is publicly avaulable on the CRCNS platform: https://crcns.org/data-sets/pfc/pfc-7/about-pfc-7

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

3. **(Optional) Download trained RNNs**

Training all networks from scratch is time-consuming.
If you prefer to directly reproduce analyses and figures, you can download the trained RNN files (link forthcoming) and place them in ` data/models/raw/'. Expected structure:

```
data/
└── models/
    └── raw/
        ├── rational/                → RNNs initially trained to be rational
        │   ├── _DatasetSpecs.mat
        │   ├── loc_TO_attention-both_ARCH_sig_z_5.mat
        │   ├── loc_TO_attention-both_ARCH_sig_z_10.mat
        │   ├── ...
        │   ├── order_TO_order-diff_ARCH_sig_z_4096.mat
        │   └── order_TO_order-diff_ARCH_sig_z_4109.mat
        ├── irrational_Franck/      → RNNs initially trained to match the monkey Franck's behaviour
        │   └── _DatasetSpecs.mat
        └── irrational_Miles/       → RNNs initially trained to match the monkey Miles' behaviour
            └── _DatasetSpecs.mat

```

4. **(Optional) Download processed results**

If you only want to regenerate figures without recomputing analyses, download processed files (link forthcoming) and place them in `data/models/processed/`. Expected structure:

```
biological_profits_irrational_OFC/
data/
└── models/
    └── processed/
        ├── rational_full.mat   → Processing applied on all training steps
        └── rational_last.mat   → Processing applied on the last training step of each regime

```

5. **Setup MATLAB**

Open MATLAB in the project root directory and run:

```matlab
setup
```

This script adds all required folders to the MATLAB path and verifies toolbox dependencies.

## Full pipeline

### Training models

The training script is located in `scripts/training_models.m`. It launches the training of:

- Rational networks
- Irrational networks (monkey-specific)
- Subjectively rational networks (monkey-specific)
- Distorted networks (re-trained between regimes)
- Biologically constrained networks

Be aware that training time is long, especially for biologically constrained networks.
Since the training functions are compatible with parallel processing, it is recommended to launch them on a computing cluster.

The results are saved in `data/models/raw/`.

### Processing monkey records

The script is located in `scripts/process_monkey_data.m`. The results are saved in `data/monkeys/processed/`.

### Analysing trained models

The analysis script is located in `scripts/analyse_models.m`. It computes:

- Behavioural performance metrics
- Neural representational measures
- Distance metrics relative to monkey OFC recordings
- Interference measures
- Robustness and constraint-related measures

Note that robustness analayses and full trajectory analyses can be computationally intensive. Since the analysis functions are compatible with parallel processing, it is recommended to launch them on a computing cluster.
The results are saved in `data/models/processed/`.

### Producing figures and statistics

Figures are automatically saved in `results/figures/`. Statistical results and numerical summaries are saved in `results/metrics/`.

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
