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

# the default resources set for each rule may not be appropriate for your particular data,
# you can always overwrite resource requirements for the individual rules by appending fx:
# "--default-resources slurm_account=phn --set-resources savont_asv:mem_mb=512000"
# to the snakemake command below
snakemake --executor slurm --jobs 96
