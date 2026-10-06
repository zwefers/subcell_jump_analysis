#!/bin/bash
#SBATCH --job-name=postproc
#SBATCH --partition=emmalu
#SBATCH --mem=64G
#SBATCH -t 4:00:00
#SBATCH --output=slurm_out/postproc_%j.out
#SBATCH --error=slurm_out/postproc_%j.err
#
# Run the full postprocessing grid: 2 feat_sel x 18 norm combos per
# (input CSV, cell_type). At ~1-2s/combo this is well under an hour
# for the small embeddings; CellProfiler (5792D) will dominate.
#
# Resumable — skips existing parquets.

set -euo pipefail

set -a
source ../.env
set +a

set +u
source "${CONDA_ROOT}/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV_ANALYSIS}"
set -u

# No model list = every CSV in EMBED_WELL_ROOT:
# python ../scripts/postprocess.py
# models=(cell_dino cell_dino_avgpool cell_dino_masked cell_dino_avgpool_masked)
# aggs=(mean median)
# Unmasked SubCell MAE re-run: only the agg used by its best config (median)
models=(subcell_mae)
aggs=(median)

for model in "${models[@]}"; do
    for agg in "${aggs[@]}"; do
        python ../scripts/postprocess.py --input "${model}_well_${agg}.csv"
    done
done
