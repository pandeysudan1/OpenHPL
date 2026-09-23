"""Compile and verify the isochronous example. Requires omc, Python, matplotlib."""
import argparse
import csv
import json
import math
from pathlib import Path
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--build-dir", type=Path, default=HERE / "Results" / "build")
parser.add_argument("--skip-build", action="store_true", help="Use an already compiled iso_up executable")
args = parser.parse_args()
build = args.build_dir.resolve()
build.mkdir(parents=True, exist_ok=True)
results = HERE / "Results"
results.mkdir(exist_ok=True)

def run(command, log):
    proc = subprocess.run(command, cwd=build, capture_output=True, text=True)
    (build / log).write_text(proc.stdout + proc.stderr, encoding="utf-8")
    if proc.returncode:
        raise RuntimeError(f"Command failed; see {build / log}")
    return proc.stdout

if not args.skip_build:
    omc = shutil.which("omc")
    if not omc:
        raise RuntimeError("OpenModelica omc must be on PATH")
    package = (HERE.parent / "package.mo").as_posix()
    script = f'''loadModel(Modelica, {{"3.2.3"}});
loadFile("{package}");
getErrorString();
checkModel(OpenHPL.NewTest.IsochronousControl);
getErrorString();
simulate(OpenHPL.NewTest.IsochronousControl, stopTime=300, numberOfIntervals=3000, tolerance=1e-7, method="dassl", outputFormat="csv", fileNamePrefix="iso_up");
getErrorString();
'''
    (build / "run.mos").write_text(script, encoding="utf-8")
    log = run([omc, "run.mos"], "compile.log")
    if "simulation finished successfully" not in log.lower():
        raise RuntimeError(f"Translation/simulation failed; see {build / 'compile.log'}")

exe = build / ("iso_up.exe" if (build / "iso_up.exe").exists() else "iso_up")
cases = {
    "up": ("dP=5000000", 0.05),
    "down": ("dP=-5000000", 0.05),
    "hold": ("dP=0", 0.05),
    "rate": ("dP=5000000,actuator.openingRate=0.001,actuator.closingRate=0.001", 0.001),
}
series = {}
summary = {}
columns = ["time", "frequency", "mechanicalPower", "electricalDemand", "powerImbalance", "gateOpening", "waterFlow", "der(actuator.y)"]
for case, (override, rate_limit) in cases.items():
    run([str(exe), f"-r=iso_{case}_res.csv", f"-override={override}"], f"{case}.log")
    with (build / f"iso_{case}_res.csv").open() as stream:
        rows = [{k: float(r[k]) for k in columns} for r in csv.DictReader(stream)]
    assert rows and abs(rows[-1]["time"] - 300) < 1e-6, f"{case}: incomplete simulation"
    assert all(math.isfinite(v) for r in rows for v in r.values()), f"{case}: nonfinite result"
    before = [r for r in rows if r["time"] < 50]
    final = [r for r in rows if r["time"] >= 280]
    assert max(abs(r["frequency"] - 50) for r in before) < 1e-5, f"{case}: initial frequency drift"
    assert max(abs(r["powerImbalance"]) for r in before) < 100, f"{case}: initial power imbalance"
    assert max(abs(r["frequency"] - 50) for r in final) < 0.001, f"{case}: frequency not restored"
    assert max(abs(r["powerImbalance"]) for r in final) < 1000, f"{case}: power not balanced"
    assert all(0.01-1e-8 <= r["gateOpening"] <= 1+1e-8 for r in rows), f"{case}: gate position limit"
    assert max(abs(r["der(actuator.y)"]) for r in rows) <= rate_limit+1e-8, f"{case}: gate rate limit"
    if case == "up":
        assert min(r["frequency"] for r in rows) < 49.9
        assert rows[-1]["gateOpening"] > rows[0]["gateOpening"]
    if case == "down":
        assert max(r["frequency"] for r in rows) > 50.1
        assert rows[-1]["gateOpening"] < rows[0]["gateOpening"]
    if case == "hold":
        assert max(abs(r["frequency"]-50) for r in rows) < 1e-5
    if case == "rate":
        assert max(abs(r["der(actuator.y)"]) for r in rows) >= 0.999*rate_limit
    outside = [r["time"] for r in rows if r["time"] >= 50 and abs(r["frequency"]-50) > 0.01]
    summary[case] = {
        "frequency_min_Hz": min(r["frequency"] for r in rows),
        "frequency_max_Hz": max(r["frequency"] for r in rows),
        "frequency_final_Hz": rows[-1]["frequency"],
        "initial_gate_pu": rows[0]["gateOpening"],
        "final_gate_pu": rows[-1]["gateOpening"],
        "final_mechanical_power_MW": rows[-1]["mechanicalPower"]/1e6,
        "final_power_imbalance_W": rows[-1]["powerImbalance"],
        "maximum_gate_rate_pu_per_s": max(abs(r["der(actuator.y)"]) for r in rows),
        "last_time_outside_0_01_Hz_band_s": max(outside) if outside else None,
        "validation": "PASS",
    }
    with (results / f"{case}.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)
    series[case] = rows
(results / "validation.json").write_text(json.dumps(summary, indent=2)+"\n", encoding="utf-8")

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
fig, axes = plt.subplots(3, 2, figsize=(12, 9), sharex=True)
for col, case in enumerate(["up", "down"]):
    rows = series[case]
    t = [r["time"] for r in rows]
    axes[0,col].plot(t, [r["frequency"] for r in rows], color="#166a9b")
    axes[0,col].axhline(50, color="gray", linestyle="--", linewidth=1)
    axes[0,col].set_title("Load increase: 50 to 55 MW" if case == "up" else "Load decrease: 50 to 45 MW")
    axes[0,col].set_ylabel("Frequency (Hz)")
    axes[1,col].plot(t, [r["mechanicalPower"]/1e6 for r in rows], label="Turbine mechanical")
    axes[1,col].plot(t, [r["electricalDemand"]/1e6 for r in rows], label="Electrical demand", linestyle="--")
    axes[1,col].set_ylabel("Power (MW)")
    axes[1,col].legend(fontsize=8)
    axes[2,col].plot(t, [100*r["gateOpening"] for r in rows], color="#188060")
    axes[2,col].set_ylabel("Gate opening (%)")
    axes[2,col].set_xlabel("Time (s)")
    for ax in axes[:,col]:
        ax.axvline(50, color="gray", linestyle=":", linewidth=1)
        ax.grid(alpha=0.2)
        ax.set_xlim(0,300)
fig.suptitle("OpenHPL.NewTest.IsochronousControl — isolated hydro generator", fontsize=14)
fig.tight_layout()
fig.savefig(results / "isochronous_response.png", dpi=160)
print(json.dumps(summary, indent=2))
