#!/bin/bash
#SBATCH --job-name=umap
#SBATCH --partition=emmalu
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH -t 4:00:00
#SBATCH --array=0-7
#SBATCH --output=slurm_out/umap_%A_%a.out
#SBATCH --error=slurm_out/umap_%A_%a.err
#
# Array job: 3 best models x 2 cell types = 6 tasks.
#
#   0: cellprofiler       / A549
#   1: cellprofiler       / U2OS
#   2: dino               / A549
#   3: dino               / U2OS
#   4: subcell_mae_masked / A549
#   5: subcell_mae_masked / U2OS
#
# Submit from project root:
#   cd $PROJECT_ROOT && sbatch slurm_launchers/11_compute_umap.sh

set -euo pipefail

set -a
source ../.env
set +a

set +u
source "${CONDA_ROOT}/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV_ANALYSIS}"
set -u

PARQUETS=(
    "${EMBED_PROCESSED_ROOT}/cellprofiler/A549/median__fs1__mad_robustize__none.parquet"
    "${EMBED_PROCESSED_ROOT}/cellprofiler/U2OS/median__fs1__mad_robustize__none.parquet"
    "${EMBED_PROCESSED_ROOT}/dino/A549/mean__fs1__PCA__mad_robustize.parquet"
    "${EMBED_PROCESSED_ROOT}/dino/U2OS/mean__fs1__PCA__mad_robustize.parquet"
    "${EMBED_PROCESSED_ROOT}/subcell_mae_masked/A549/median__fs0__PCA__standardize.parquet"
    "${EMBED_PROCESSED_ROOT}/subcell_mae_masked/U2OS/median__fs0__PCA__standardize.parquet"
    "${EMBED_PROCESSED_ROOT}/deepprofiler/U2OS/mean__fs1__PCAcor__mad_robustize.parquet"
    "${EMBED_PROCESSED_ROOT}/deepprofiler/A549/mean__fs1__PCAcor__mad_robustize.parquet"
)

INPUT="${PARQUETS[$SLURM_ARRAY_TASK_ID]}"

echo "[$(date)] task=${SLURM_ARRAY_TASK_ID} input=${INPUT}"
python ../scripts/compute_umap.py "${INPUT}" --n-neighbors 5011 --min-dist 0.25
