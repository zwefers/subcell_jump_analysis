#!/bin/bash
#SBATCH --job-name=dp_prepare
#SBATCH --partition=emmalu
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH -t 2-00:00:00
#SBATCH --output=slurm_out/dp_prepare_%j.out
#SBATCH --error=slurm_out/dp_prepare_%j.err
#
# DeepProfiler prepare: illumination correction + compression (CPU-only).
# Usage: sbatch 04a_deepprofiler_prepare.sh

set -euo pipefail

set -a
source ../.env
set +a

source "${DEEPPROF_ENV}/bin/activate"

DEEPPROFILER=/home/groups/emmalu/zwefers/DeepProfiler/deepprofiler

python "${DEEPPROFILER}" \
    --root="${DP_ROOT}" \
    --config=profiling.json \
    --metadata=index.csv \
    --cores=16 \
    prepare
