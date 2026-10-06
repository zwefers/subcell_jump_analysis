"""
Summarize + plot the copairs mAP results.

Reads {RESULTS_ROOT}/map_summary.csv (one row per model x cell_type x
postproc combo x task) and produces:

    best_config.csv          — which postproc combo maximizes mAP per
                               (model, cell_type, task)
    fig_best_map.png         — headline comparison: best-achievable mAP
                               per model, faceted by task x cell_type
    fig_best_frac.png        — same but for fraction_retrievable
    fig_postproc_sweep.png   — distribution of mAP across the full grid
                               per model (shows postproc sensitivity)

Missing model x cell_type combos (e.g. DeepProfiler x A549 until it's
rerun) just don't appear — the pandas groupbys and seaborn facets handle
that naturally.

Usage:
    python scripts/plot_results.py
"""

import os

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


# Consistent model ordering and colors across all figures
MODEL_ORDER = ["cellprofiler", "deepprofiler", "dino", "subcell_mae", "subcell_vit"]
PALETTE = "Set2"

sns.set_theme(style="whitegrid", context="notebook")


def load_summary() -> pd.DataFrame:
    path = os.path.join(os.environ["RESULTS_ROOT"], "map_summary.csv")
    df = pd.read_csv(path)
    # Only keep models we know about, in preferred order; anything else goes at the end
    present = df["model"].unique()
    order = [m for m in MODEL_ORDER if m in present] + sorted(set(present) - set(MODEL_ORDER))
    df["model"] = pd.Categorical(df["model"], categories=order, ordered=True)
    return df


def find_best_configs(df: pd.DataFrame) -> pd.DataFrame:
    """
    For each (model, cell_type, task), pick the postproc combo with the
    highest mAP. Returns one row per combo with all identifying columns.
    """
    idx = df.groupby(["model", "cell_type", "task"], observed=True)["mAP"].idxmax()
    best = df.loc[idx].sort_values(["task", "cell_type", "model"]).reset_index(drop=True)
    return best


def plot_best_metric(best: pd.DataFrame, metric: str, out_path: str):
    """
    Grouped bar chart of best-achievable `metric` per model, faceted by
    task (rows) x cell_type (cols).
    """
    g = sns.catplot(
        data=best,
        x="model", y=metric, hue="model",
        row="task", col="cell_type",
        kind="bar", palette=PALETTE, legend=True,
        height=3.5, aspect=1.4,
        sharey="row",
    )
    for ax in g.axes.flat:
        ax.set_xticklabels(ax.get_xticklabels(), rotation=30, ha="right")
    g.set_titles("{row_name} | {col_name}")
    g.figure.suptitle(f"Best {metric} per model (max over postproc grid)", y=1.02)
    g.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(g.figure)
    print(f"  -> {out_path}")


def plot_postproc_sweep(df: pd.DataFrame, out_path: str):
    """
    Strip plot showing every grid point. Spread = postproc sensitivity.
    The best config from find_best_configs is the top point of each strip.
    """
    g = sns.catplot(
        data=df,
        x="model", y="mAP", hue="model",
        row="task", col="cell_type",
        kind="strip", palette=PALETTE, legend=True,
        height=3.5, aspect=1.4,
        alpha=0.5, jitter=0.25, size=4,
        sharey="row",
    )
    for ax in g.axes.flat:
        ax.set_xticklabels(ax.get_xticklabels(), rotation=30, ha="right")
    g.set_titles("{row_name} | {col_name}")
    g.figure.suptitle("mAP across full postprocessing grid", y=1.02)
    g.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(g.figure)
    print(f"  -> {out_path}")


def main():
    results_root = os.environ["RESULTS_ROOT"]
    os.makedirs(results_root, exist_ok=True)

    df = load_summary()
    print(f"Loaded {len(df)} rows: "
          f"{df['model'].nunique()} models, "
          f"{df['cell_type'].nunique()} cell types, "
          f"{df['task'].nunique()} tasks")

    # Coverage report — flags missing combos
    print("\nCoverage (rows per model x cell_type x task):")
    cov = df.groupby(["model", "cell_type", "task"], observed=True).size().unstack(fill_value=0)
    print(cov.to_string())

    # --- Best config per model ---
    best = find_best_configs(df)
    best_path = os.path.join(results_root, "best_config.csv")
    best.to_csv(best_path, index=False)
    print(f"\nBest configs -> {best_path}")
    print(best[["task", "cell_type", "model", "agg", "fs", "norm1", "norm2",
                "mAP", "frac_retrievable"]].to_string(index=False))

    # --- Plots ---
    print("\nGenerating figures...")
    plot_best_metric(best, "mAP", os.path.join(results_root, "fig_best_map.png"))
    plot_best_metric(best, "frac_retrievable", os.path.join(results_root, "fig_best_frac.png"))
    plot_postproc_sweep(df, os.path.join(results_root, "fig_postproc_sweep.png"))


if __name__ == "__main__":
    main()
