# Snakemake workflow: `snakemake_savont`

[![Snakemake](https://img.shields.io/badge/snakemake-≥7.18.2-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/kasperskytte/snakemake_savont/workflows/Tests/badge.svg?branch=main)](https://github.com/kasperskytte/snakemake_savont/actions?query=branch%3Amain+workflow%3ATests)

Simple snakemake workflow for processing amplicon data sequenced on ONT or PacBio platforms, using [savont](https://github.com/bluenote-1577/savont) to generate ASVs and [usearch](https://drive5.com/usearch) for generating an abundance table and taxonomic classification.

## Brief overview and description of steps (rules)
TODO

## Usage
First install snakemake and the required software into a conda environment (preferably using the [environment.yml](environment.yml) file) or use the container as described below. Then deploy the workflow using [snakedeploy](https://snakemake.github.io/snakemake-workflow-catalog/docs/workflows/KasperSkytte/snakemake_savont.html), adjust the [config file](config/README.md), then run, fx:
```
conda activate snakemake_savont
snakedeploy deploy-workflow https://github.com/KasperSkytte/snakemake_savont . --tag v1.2.1
snakemake --cores 96
```

Depending on the size of the data, you can use an executor if you are running on a HPC cluster to optimize utilization by submitting individual tasks as separate jobs. See the `slurm_submit.sbatch` for an example when running on a SLURM cluster.

## Requirements
Install the required software by using either the provided `Dockerfile` or `environment.yml` file to build a Docker container or conda environment with all the required tools, see below.

### Docker
The pre-built Docker container available from [`ghcr.io/kasperskytte/snakemake_savont:main`](https://github.com/KasperSkytte/snakemake_savont/pkgs/container/snakemake_savont) is built from the `Dockerfile` and includes all required software.

### Conda
Requirements are listed in `environment.yml`. To create as a conda environment simply run:
```
conda env create --file environment.yml -n snakemake_savont
```
