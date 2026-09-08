#!/usr/bin/env python3
"""
build_html_report.py

Aggregates per-sample confusion-matrix JSONs (produced by
generate_validation_report.py) into a single self-contained interactive
HTML report summarising reference-removal validation performance:
recall/sensitivity, precision, specificity, per-sample confusion
matrices, and data-integrity caveats.

Usage:
    build_html_report.py --jsons sample1.confusion.json sample2.confusion.json ... \
        -o validation_report.html
"""

import argparse
import json

import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

REQUIRED_FIELDS = [
    "sample_id",
    "read_type",
    "tp",
    "fp",
    "fn",
    "tn",
    "precision",
    "recall",
    "specificity",
    "f1",
    "untraceable_reads",
    "ref_truth_total",
    "background_truth_total",
    "deacon_seqs_in",
    "deacon_seqs_out",
    "count_consistency_ok",
]


def load_records(json_paths):
    records = []
    for path in json_paths:
        with open(path) as fh:
            rec = json.load(fh)
        missing = [f for f in REQUIRED_FIELDS if f not in rec]
        if missing:
            raise ValueError(f"{path} is missing expected field(s): {missing}")
        records.append(rec)
    if not records:
        raise ValueError("No confusion JSONs provided.")
    return pd.DataFrame(records)


def fmt_pct(x):
    return "n/a" if pd.isna(x) else f"{x * 100:.2f}%"


def confusion_matrix_figure(row):
    """2x2 heatmap: rows = truth (ref/background), cols = predicted (matched/not matched)."""
    z = [[row.tp, row.fn], [row.fp, row.tn]]
    text = [
        [f"TP<br>{row.tp}", f"FN<br>{row.fn}"],
        [f"FP<br>{row.fp}", f"TN<br>{row.tn}"],
    ]

    fig = go.Figure(
        data=go.Heatmap(
            z=z,
            x=["Predicted: reference match", "Predicted: not a match"],
            y=["Truth: reference read", "Truth: background read"],
            text=text,
            texttemplate="%{text}",
            textfont={"size": 16},
            colorscale=[[0, "#f4f9ff"], [1, "#2f6fed"]],
            showscale=False,
            xgap=3,
            ygap=3,
        )
    )
    fig.update_layout(
        title=f"{row.sample_id} ({row.read_type})",
        height=320,
        margin=dict(l=120, r=20, t=50, b=40),
        yaxis=dict(autorange="reversed"),
    )
    return fig


def metrics_bar_figure(df):
    metrics = ["recall", "specificity", "precision", "f1"]
    labels = {
        "recall": "Recall (sensitivity)",
        "specificity": "Specificity",
        "precision": "Precision",
        "f1": "F1",
    }
    fig = go.Figure()
    for m in metrics:
        fig.add_trace(
            go.Bar(
                name=labels[m],
                x=df["sample_id"],
                y=df[m] * 100,
                text=[fmt_pct(v) for v in df[m]],
                textposition="outside",
            )
        )
    fig.update_layout(
        barmode="group",
        title="Recall, specificity, precision and F1 by sample",
        yaxis_title="%",
        yaxis_range=[0, 105],
        legend_title_text="",
        height=450,
        margin=dict(t=60, b=80),
    )
    # Flag recall visually: it's the safety-critical metric for a depletion
    # tool (a low recall means reference material is escaping depletion).
    fig.add_hline(
        y=95,
        line_dash="dot",
        line_color="crimson",
        annotation_text="95% recall reference line",
        annotation_position="top left",
    )
    return fig


def caveats_table(df):
    rows = []
    for _, row in df.iterrows():
        issues = []
        if not row.count_consistency_ok:
            issues.append(
                f"deacon seqs_in ({row.deacon_seqs_in}) does not match "
                f"ref_truth + background_truth ({row.ref_truth_total + row.background_truth_total}) "
                "— the input FASTQ passed to deacon may not match the truth "
                "sets used for this comparison."
            )
        if row.untraceable_reads > 0:
            issues.append(
                f"{row.untraceable_reads} read ID(s) in the isolated-match output "
                "could not be traced to either truth set — check for read-ID "
                "normalisation mismatches (e.g. mate-pair /1 /2 suffixes)."
            )
        if row.recall < 0.95:
            issues.append(
                f"Recall is {fmt_pct(row.recall)} — below the 95% reference line. "
                f"{row.fn} true reference read(s) escaped depletion."
            )
        if row.fp > 0:
            issues.append(
                f"{row.fp} background read(s) were incorrectly classified as "
                "reference matches (false positives)."
            )
        rows.append(
            {
                "Sample": row.sample_id,
                "Read type": row.read_type,
                "Caveats": "; ".join(issues) if issues else "None detected",
            }
        )
    return pd.DataFrame(rows)


def build_report(df, outpath):
    n = len(df)
    ncols = 2
    nrows = -(-n // ncols)  # ceil

    summary_fig = metrics_bar_figure(df)

    matrix_fig = make_subplots(
        rows=nrows,
        cols=ncols,
        subplot_titles=[f"{r.sample_id} ({r.read_type})" for r in df.itertuples()],
        horizontal_spacing=0.15,
        vertical_spacing=0.12,
    )
    for i, row in enumerate(df.itertuples()):
        r, c = divmod(i, ncols)
        z = [[row.tp, row.fn], [row.fp, row.tn]]
        text = [[f"TP: {row.tp}", f"FN: {row.fn}"], [f"FP: {row.fp}", f"TN: {row.tn}"]]
        matrix_fig.add_trace(
            go.Heatmap(
                z=z,
                text=text,
                texttemplate="%{text}",
                textfont={"size": 13},
                x=["Matched", "Not matched"],
                y=["Ref truth", "Background truth"],
                colorscale=[[0, "#f4f9ff"], [1, "#2f6fed"]],
                showscale=False,
                xgap=3,
                ygap=3,
            ),
            row=r + 1,
            col=c + 1,
        )
    matrix_fig.update_yaxes(autorange="reversed")
    matrix_fig.update_layout(
        height=320 * nrows,
        title="Per-sample confusion matrices",
        margin=dict(t=80),
    )

    caveats_df = caveats_table(df)
    any_caveats = (caveats_df["Caveats"] != "None detected").any()

    summary_table = df[
        [
            "sample_id",
            "read_type",
            "tp",
            "fp",
            "fn",
            "tn",
            "recall",
            "specificity",
            "precision",
            "f1",
        ]
    ].copy()
    for col in ["recall", "specificity", "precision", "f1"]:
        summary_table[col] = summary_table[col].map(fmt_pct)
    summary_table.columns = [
        "Sample",
        "Read type",
        "TP",
        "FP",
        "FN",
        "TN",
        "Recall",
        "Specificity",
        "Precision",
        "F1",
    ]

    def df_to_html_table(d, row_colors=None):
        header_cells = "".join(f"<th>{c}</th>" for c in d.columns)
        body_rows = []
        for i, (_, r) in enumerate(d.iterrows()):
            color = f' style="background:{row_colors[i]}"' if row_colors else ""
            cells = "".join(f"<td>{v}</td>" for v in r)
            body_rows.append(f"<tr{color}>{cells}</tr>")
        return f"<table><thead><tr>{header_cells}</tr></thead><tbody>{''.join(body_rows)}</tbody></table>"

    caveat_row_colors = [
        "#fff3f3" if c != "None detected" else "#f3fff5" for c in caveats_df["Caveats"]
    ]

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Reference removal validation report</title>
<style>
  body {{ font-family: -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
          margin: 0; padding: 0 0 60px 0; background: #fafbfc; color: #1a1a1a; }}
  header {{ background: #1f2d3d; color: white; padding: 28px 40px; }}
  header h1 {{ margin: 0 0 6px 0; font-size: 22px; }}
  header p {{ margin: 0; color: #b9c4d1; font-size: 14px; }}
  main {{ max-width: 1100px; margin: 0 auto; padding: 30px 40px; }}
  section {{ margin-bottom: 40px; }}
  h2 {{ font-size: 17px; border-bottom: 1px solid #e1e5ea; padding-bottom: 8px; }}
  table {{ border-collapse: collapse; width: 100%; font-size: 13px; margin-top: 10px; }}
  th, td {{ text-align: left; padding: 8px 10px; border-bottom: 1px solid #e8ebee; }}
  th {{ background: #f0f2f5; font-weight: 600; }}
  .banner {{ padding: 14px 18px; border-radius: 6px; font-size: 14px; margin-bottom: 20px; }}
  .banner.warn {{ background: #fff3f3; border: 1px solid #f4b8b8; color: #7a1f1f; }}
  .banner.ok {{ background: #f3fff5; border: 1px solid #b8e6c2; color: #1f6b34; }}
  .legend {{ font-size: 13px; color: #555; margin-top: 8px; }}
</style>
</head>
<body>
<header>
  <h1>Reference removal validation report</h1>
  <p>{n} sample(s) &middot; generated from spiked-sample deacon output vs. known reference/background read IDs</p>
</header>
<main>

<section>
  <div class="banner {"warn" if any_caveats else "ok"}">
    {"⚠ One or more samples have caveats flagged below — review before treating results as clean." if any_caveats else "✓ No data-integrity caveats detected across samples."}
  </div>
  <h2>Summary</h2>
  {df_to_html_table(summary_table)}
  <p class="legend">
    <b>Recall (sensitivity)</b> — proportion of true reference reads that were removed. This is the
    safety-critical metric: low recall means reference material is escaping depletion. &nbsp;
    <b>Precision</b> — proportion of reads flagged as reference matches that were actually reference reads.
    &nbsp; <b>Specificity</b> — proportion of true background reads correctly left alone.
  </p>
</section>

<section>
  <h2>Recall / specificity / precision / F1 by sample</h2>
  {summary_fig.to_html(full_html=False, include_plotlyjs="cdn")}
</section>

<section>
  <h2>Per-sample confusion matrices</h2>
  {matrix_fig.to_html(full_html=False, include_plotlyjs=False)}
</section>

<section>
  <h2>Caveats</h2>
  {df_to_html_table(caveats_df, row_colors=caveat_row_colors)}
</section>

</main>
</body>
</html>
"""

    with open(outpath, "w") as fh:
        fh.write(html)


def main():
    p = argparse.ArgumentParser()
    p.add_argument(
        "--jsons", nargs="+", required=True, help="per-sample confusion JSON files"
    )
    p.add_argument("-o", "--output", required=True)
    args = p.parse_args()

    df = load_records(args.jsons)
    df = df.sort_values(["read_type", "sample_id"]).reset_index(drop=True)
    build_report(df, args.output)


if __name__ == "__main__":
    main()
