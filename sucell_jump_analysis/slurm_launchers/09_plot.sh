#!/bin/bash
#SBATCH --job-name=plot
#SBATCH --partition=emmalu
#SBATCH --mem=8G
#SBATCH -t 0:10:00
#SBATCH --output=slurm_out/plot_%j.out
#SBATCH --error=slurm_out/plot_%j.err
#
# Generate summary figures from the map results.
#
# Submit from project root:
#   cd $PROJECT_ROOT && sbatch slurm_launchers/07_plot.sh

set -euo pipefail

set -a
source ../.env
set +a

set +u
source "${CONDA_ROOT}/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV_ANALYSIS}"
set -u

python ../scripts/plot_results.py
