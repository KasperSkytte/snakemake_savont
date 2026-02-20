#!/usr/bin/bash -l
#SBATCH --job-name=snakemake_savont
#SBATCH --output=job_%j_%x.out
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --partition=general
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=abc@bio.aau.dk

# Exit on first error and if any variables are unset
set -euo pipefail

conda activate snakemake_savont

# if database doesnt exist, download
#savont download ...
snakemake --executor slurm --jobs 64
