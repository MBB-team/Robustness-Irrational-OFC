# Biological profits of irrational computations in the orbitofrontal cortex

## Repository structure

``` bash
biological_profits_irrational_OFC/
|-- README.md
|-- setup.m % Run once: adds paths + creates folders
|-- demo.m
|-- config.m % Central configuration (edit directly in MATLAB)
|-- scripts/
|   |-- train_and_analyze.m % Full pipeline: train models + run analyses
|   |-- analyze_data.m % Run analyses on experimental data only
|   |-- make_figures.m % Re-generate figures from saved results
|-- src/
|   |-- models/ % Training and model definition functions
|   |-- analyses/ % Each analysis = one function, auto-discovered
|   |-- expdata/ % Data loading and preprocessing
|   |-- plots/ % Plotting helper functions
|   |-- utils/ % Small helper utilities
|-- data/ % Raw experimental data
|-- results/ % Output: metrics and figures (auto-created)
```

## Quick start

1) **Clone the reposititory**

Open a console, navigate to your desired folder and run:

```bash
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

2) **Get the experimental data**

Download the experimental data from [Hunt et al. (2018)](https://www.nature.com/articles/s41593-018-0239-5) on the [CRCNS platform](https://crcns.org/data-sets/pfc/pfc-7/about-pfc-7).

Store the data to recreate the following architecture:

```bash
biological_profits_irrational_OFC/
|-- data/
|   |-- raw/
|       |-- monkeys/
|           |-- frank_area.mat
|           |-- miles_area.mat
```

2) **Setup MATLAB**

Open MATLAB and run:

```matlab
setup
```

3) **Run the demo**

```matlab
demo
```

## Full pipeline

Train models + run all analyses + generate figures:

```matlab
code here
```

Figures will appear in:

```bash
results/figures/
```

Metrics will be saved in:

```bash
results/metrics/
```

## Citation

If you use this repository, please cite:

> Citation here

## Contact
