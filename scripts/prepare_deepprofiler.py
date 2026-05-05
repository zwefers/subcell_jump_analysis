"""
Reformat the old DeepProfiler well-level CSVs to our schema.

The old ankit_eval run only covered the 7 U2OS compound plates. Until
DeepProfiler is rerun on the full set (see docs/deepprofiler_rebuild.md),
this script just copies + reformats those so postprocess.py can consume
them alongside the other models. The A549 / DeepProfiler combination will
simply be absent — downstream code handles that gracefully.

Old format:  plate, well, 0, 1, ..., 1279
New format:  plate, well, cell_type, timepoint, feature_0, ..., feature_1279

Usage:
    python scripts/prepare_deepprofiler.py
"""

import os
import sys

import pandas as pd

PROJECT_ROOT = os.environ["PROJECT_ROOT"]
sys.path.insert(0, PROJECT_ROOT)

from utils.metadata import load_plate_info  # noqa: E402


def reformat(old_csv: str, out_csv: str, plate_info: pd.DataFrame):
    df = pd.read_csv(old_csv)

    # Old columns are "plate", "well", "0", "1", ...
    feat_cols_old = [c for c in df.columns if c not in ("plate", "well")]
    rename_map = {c: f"feature_{c}" for c in feat_cols_old}
    df = df.rename(columns=rename_map)

    # Keep only plates that are in our config (drops any strays)
    df = df[df["plate"].isin(plate_info.index)].copy()

    # Merge cell_type + timepoint
    df = df.merge(
        plate_info[["cell_type", "timepoint"]].reset_index(),
        on="plate",
        how="left",
    )

    meta_cols = ["plate", "well", "cell_type", "timepoint"]
    feat_cols = [f"feature_{c}" for c in feat_cols_old]
    df = df[meta_cols + feat_cols]

    cell_types = df["cell_type"].value_counts().to_dict()
    print(f"  {len(df)} wells, {len(feat_cols)} features, cell_types={cell_types}")
    df.to_csv(out_csv, index=False)
    print(f"  -> {out_csv}")


def main():
    out_root = os.environ["EMBED_WELL_ROOT"]
    os.makedirs(out_root, exist_ok=True)

    plate_info = load_plate_info().set_index("plate")

    for agg, env_key in [("mean", "OLD_DEEPPROFILER_MEAN"),
                         ("median", "OLD_DEEPPROFILER_MEDIAN")]:
        old_csv = os.environ[env_key]
        out_csv = os.path.join(out_root, f"deepprofiler_well_{agg}.csv")
        print(f"Reformatting {agg}...")
        reformat(old_csv, out_csv, plate_info)


if __name__ == "__main__":
    main()
