#!/usr/bin/bash -l
#SBATCH --job-name=snakemake_savont
#SBATCH --output=job_%j_%x.out
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=0-08:00:00
#SBATCH --mail-type=END,FAIL,TIME_LIMIT_80
#SBATCH --mail-user=abc@email.com

# Exit on first error and if any variables are unset
set -euo pipefail

conda activate snakemake_savont

snakemake --executor slurm --jobs 96 --default-resources slurm_account=projectxyz
