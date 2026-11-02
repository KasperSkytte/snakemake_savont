#!/usr/bin/bash -l
#SBATCH --job-name=snakemake_savont
#SBATCH --output=job_%j_%x.out
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=END,FAIL,TIME_LIMIT_80
#SBATCH --mail-user=abc@email.com

# Exit on first error and if any variables are unset
set -euo pipefail

conda activate snakemake_savont

# Every rule is submitted as a separate job with memory and runtime estimated
# from the input size (see profiles/slurm/config.yaml). Failed jobs
# are retried with more resources. Overwrite resources for individual rules
# by appending fx "--set-resources savont_asv:mem_mb=512000" and set the
# account with "--default-resources slurm_account=myaccount".
# Use "--sdm conda" instead to use conda environments instead of containers
snakemake --workflow-profile slurm --sdm apptainer
