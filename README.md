# SubCell JUMP Benchmark

Benchmarks SubCell (MAE and ViT) against DINO4Cells, DeepProfiler, and CellProfiler on the JUMP Pilot (cpg0000) dataset. Evaluates morphological embedding quality via replicate and mechanism-of-action (MoA) retrieval using mean Average Precision (mAP).

## Pipeline

```
Raw crops (192x1728 PNGs, 9 channels)
  → Inference (SubCell MAE/ViT, DINO4Cells)  [GPU]
  → Aggregate cells → wells                  [CPU]
  → Download CellProfiler / prepare DeepProfiler
  → Postprocess (normalize, feature-select)   [CPU]
  → Compute mAP (replicate + MoA)            [CPU]
  → Plot results + attention maps
```

## Setup

### 1. Clone

```bash
git clone --recurse-submodules <repo-url>
```

### 2. Environments

Two conda environments are used:

| Env | Purpose | Create |
|-----|---------|--------|
| `inference_gpu` | GPU inference (SubCell, DINO) | `conda env create -f envs/inference_gpu.yaml` |
| `moa` | Analysis, postprocessing, plotting | `conda env create -f envs/analysis.yaml` then `pip install copairs` |

For `inference_gpu` on systems with GLIBC < 2.27 (e.g., CentOS 7), see the workaround in `envs/inference_gpu.yaml`.

### 3. Environment Variables

Create a `.env` file in the project root (sourced by SLURM launchers via `set -a; source .env; set +a`). Required variables:

| Variable | Description |
|----------|-------------|
| `PROJECT_ROOT` | Path to this repo |
| `CROP_ROOT` | Path to JUMP cpg0000 pre-cropped single-cell images |
| `DP_ROOT` | Path to DeepProfiler data |
| `EMBED_CELL_ROOT` | Output dir for cell-level embeddings (.pth) |
| `EMBED_WELL_ROOT` | Output dir for well-level CSVs |
| `EMBED_PROCESSED_ROOT` | Output dir for postprocessed parquets |
| `RESULTS_ROOT` | Output dir for mAP results |
| `SUBCELL_MAE_CKPT` | SubCell MAE encoder checkpoint |
| `SUBCELL_MAE_CLF` | SubCell MAE classifier checkpoint |
| `SUBCELL_VIT_CKPT` | SubCell ViT encoder checkpoint |
| `SUBCELL_VIT_CLF` | SubCell ViT classifier checkpoint |
| `DINO_CKPT` | DINO4Cells checkpoint |
| `METADATA_ROOT` | Path to `metadata/` folder (included in repo) |
| `MOA_METADATA` | Path to `metadata/usable_moa_metadata.csv` |
| `CONDA_ROOT` | Path to miniconda/anaconda installation |
| `CONDA_ENV_ANALYSIS` | Name of analysis conda env (default: `moa`) |
| `CONDA_ENV_INFERENCE` | Name of GPU inference conda env (default: `inference_gpu`) |

Optional (for DeepProfiler/CellProfiler download steps):

| Variable | Description |
|----------|-------------|
| `OLD_DEEPPROFILER_MEAN` | Path to legacy DeepProfiler mean embeddings CSV |
| `OLD_DEEPPROFILER_MEDIAN` | Path to legacy DeepProfiler median embeddings CSV |
| `CP_S3_BUCKET` | S3 bucket for CellProfiler profiles (`cellpainting-gallery`) |
| `CP_S3_PREFIX` | S3 prefix for CellProfiler profiles |

### 4. Data

Input crops are not included in this repo. They must be pre-generated from the JUMP Pilot cpg0000 dataset as 192x1728 uint8 PNGs (9 channels stacked horizontally). See `docs/REPO_REFERENCE.md` for channel layout and directory structure.

## Running

SLURM launchers in `slurm_launchers/` run each pipeline stage. Execute them in numerical order:

```bash
sbatch slurm_launchers/01_inference_subcell.sh
sbatch slurm_launchers/02_inference_dino.sh
# ... etc.
```

## Project Structure

```
configs/          Model and plate configs (YAML)
docs/             Detailed reference documentation
envs/             Conda environment definitions
figures/          Output plots and attention maps
metadata/         JUMP metadata files
models/           Model code (git submodules)
notebooks/        Exploratory analysis notebooks
results/          mAP scores and summary tables
scripts/          Pipeline scripts (inference → eval → plot)
slurm_launchers/  SLURM job scripts
utils/            Shared utilities (crop loading, metadata, postprocessing)
```

See `docs/REPO_REFERENCE.md` for detailed documentation of every script, config, and utility.
