#!/usr/bin/env python3
"""Create reproducible SVG plots and summary metrics from OpenModelica CSV files."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt


CASES = {
    "Isochronous": "trollheim_isochronous_res.csv",
    "Droop": "trollheim_droop_res.csv",
    "AGC": "trollheim_agc_res.csv",
}


def read_case(path: Path) -> dict[str, list[float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        data = {name: [] for name in reader.fieldnames or []}
        for row in reader:
            for name, value in row.items():
                data[name].append(float(value))
    return data


def series(data: dict[str, list[float]], name: str) -> list[float]:
    if name in data:
        return data[name]
    matches = [key for key in data if key.endswith("." + name)]
    if len(matches) == 1:
        return data[matches[0]]
    raise KeyError(f"Cannot resolve {name!r}; available columns: {sorted(data)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    results = {
        label: read_case(args.input_dir / filename)
        for label, filename in CASES.items()
    }

    fig, ax = plt.subplots(figsize=(8.2, 4.7))
    metrics = []
    for label, data in results.items():
        time = series(data, "time")
        deviation = series(data, "frequencyDeviation")
        frequency = [50.0 * (1.0 + value) for value in deviation]
        ax.plot(time, frequency, linewidth=2.0, label=label)
        tail = max(1, len(frequency) // 10)
        metrics.append((label, min(frequency), sum(frequency[-tail:]) / tail))
    ax.axvline(5.0, color="0.35", linestyle="--", linewidth=1.0, label="0.1 pu load step")
    ax.axhline(50.0, color="0.65", linewidth=0.8)
    ax.set(xlabel="Time (s)", ylabel="Frequency (Hz)",
           title="Trollheim reduced-order frequency-control comparison")
    ax.grid(True, alpha=0.25)
    ax.legend(ncol=2)
    fig.tight_layout()
    fig.savefig(args.output_dir / "frequency_comparison.svg")
    plt.close(fig)

    agc = results["AGC"]
    time = series(agc, "time")
    fig, axes = plt.subplots(3, 1, figsize=(8.2, 7.5), sharex=True)
    axes[0].plot(time, [50.0 * (1.0 + x) for x in series(agc, "frequencyDeviation")],
                 color="#1f77b4", linewidth=2)
    axes[0].set_ylabel("Frequency (Hz)")
    axes[1].plot(time, series(agc, "guideVaneDeviation"), label="Guide vane")
    axes[1].plot(time, series(agc, "flowDeviation"), label="Water flow")
    axes[1].set_ylabel("Deviation (pu)")
    axes[1].legend()
    axes[2].plot(time, series(agc, "mechanicalPowerDeviation"), label="Mechanical power")
    axes[2].plot(time, series(agc, "electricalPowerDeviation"),
                 linestyle="--", label="Electrical load")
    axes[2].set(xlabel="Time (s)", ylabel="Power deviation (pu)")
    axes[2].legend()
    for ax in axes:
        ax.axvline(5.0, color="0.35", linestyle="--", linewidth=1.0)
        ax.grid(True, alpha=0.25)
    fig.suptitle("AGC component response")
    fig.tight_layout()
    fig.savefig(args.output_dir / "agc_component_response.svg")
    plt.close(fig)

    with (args.output_dir / "metrics.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["controller", "frequency_nadir_hz", "final_frequency_hz"])
        writer.writerows((label, f"{nadir:.6f}", f"{final:.6f}")
                         for label, nadir, final in metrics)


if __name__ == "__main__":
    main()
