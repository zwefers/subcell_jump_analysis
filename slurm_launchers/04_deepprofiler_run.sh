#!/bin/bash
#
# Submit DeepProfiler prepare + profile as two jobs with dependency.
# Usage: bash 05_deepprofiler_run.sh
#
# Step 1 (prepare): CPU-only, illumination correction + compression
# Step 2 (profile): GPU, feature extraction with Cell Painting CNN

set -euo pipefail

PREPARE_JOB=$(sbatch --parsable <<'PREPARE'
#!/bin/bash
#SBATCH --job-name=dp_prepare
#SBATCH --partition=emmalu
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH -t 2-00:00:00
#SBATCH --output=slurm_out/dp_prepare_%j.out
#SBATCH --error=slurm_out/dp_prepare_%j.err

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
PREPARE
)

echo "Submitted prepare job: ${PREPARE_JOB}"

PROFILE_JOB=$(sbatch --parsable --dependency=afterok:${PREPARE_JOB} <<'PROFILE'
#!/bin/bash
#SBATCH --job-name=dp_profile
#SBATCH --partition=emmalu
#SBATCH -G 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH -t 3-00:00:00
#SBATCH --output=slurm_out/dp_profile_%j.out
#SBATCH --error=slurm_out/dp_profile_%j.err

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
    --exp=results \
    profile
PROFILE
)

echo "Submitted profile job: ${PROFILE_JOB} (depends on ${PREPARE_JOB})"
