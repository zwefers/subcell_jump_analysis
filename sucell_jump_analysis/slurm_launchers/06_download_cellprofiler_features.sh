#!/bin/bash
#SBATCH --job-name=baselines
#SBATCH --partition=emmalu
#SBATCH --mem=16G
#SBATCH -t 1:00:00
#SBATCH --output=slurm_out/cell_profiler_%j.out
#SBATCH --error=slurm_out/cell_profiler_%j.err
#
# Fetch CellProfiler profiles from S3 and reformat the old DeepProfiler
# CSVs. These don't depend on inference — can run anytime.

set -euo pipefail

set -a
source ../.env
set +a

set +u
source "${CONDA_ROOT}/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV_ANALYSIS}"
set -u

echo "[$(date)] CellProfiler (S3)"
python ../scripts/download_cellprofiler.py
