"""Compile and verify the permanent-droop example. Requires omc, Python, matplotlib."""
import argparse
import csv
import json
import math
from pathlib import Path
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--build-dir", type=Path, default=HERE / "Results" / "Droop" / "build")
parser.add_argument("--skip-build", action="store_true", help="Use an already compiled droop executable")
args = parser.parse_args()
build = args.build_dir.resolve()
build.mkdir(parents=True, exist_ok=True)
results = HERE / "Results" / "Droop"
results.mkdir(parents=True, exist_ok=True)

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
checkModel(OpenHPL.NewTest.PermanentDroopControl);
getErrorString();
simulate(OpenHPL.NewTest.PermanentDroopControl, stopTime=300, numberOfIntervals=3000, tolerance=1e-7, method="dassl", outputFormat="csv", fileNamePrefix="droop");
getErrorString();
'''
    (build / "run.mos").write_text(script, encoding="utf-8")
    log = run([omc, "run.mos"], "compile.log")
    if "simulation finished successfully" not in log.lower():
        raise RuntimeError(f"Translation/simulation failed; see {build / 'compile.log'}")

exe = build / ("droop.exe" if (build / "droop.exe").exists() else "droop")
cases = {
    "up_4pct": ("dP=5000000,R=0.04", 49.9),
    "down_4pct": ("dP=-5000000,R=0.04", 50.1),
    "hold": ("dP=0,R=0.04", 50.0),
    "up_5pct": ("dP=5000000,R=0.05", 49.875),
    "up_double_base": ("dP=5000000,R=0.04,P_base=200000000", 49.95),
}
series = {}
summary = {}
columns = ["time", "frequency", "mechanicalPower", "electricalDemand", "powerImbalance", "gateOpening", "waterFlow", "der(actuator.y)", "expectedFrequency", "droopResidual"]
for case, (override, expected) in cases.items():
    run([str(exe), f"-r=droop_{case}_res.csv", f"-override={override}"], f"{case}.log")
    with (build / f"droop_{case}_res.csv").open() as stream:
        rows = [{k: float(r[k]) for k in columns} for r in csv.DictReader(stream)]
    assert rows and abs(rows[-1]["time"] - 300) < 1e-6, f"{case}: incomplete simulation"
    assert all(math.isfinite(v) for r in rows for v in r.values()), f"{case}: nonfinite result"
    before = [r for r in rows if r["time"] < 50]
    final = [r for r in rows if r["time"] >= 280]
    assert max(abs(r["frequency"] - 50) for r in before) < 1e-5, f"{case}: initial frequency drift"
    assert max(abs(r["powerImbalance"]) for r in before) < 100, f"{case}: initial power imbalance"
    assert max(abs(r["frequency"] - expected) for r in final) < 0.001, f"{case}: steady frequency does not match the analytic droop prediction"
    assert max(abs(r["powerImbalance"]) for r in final) < 1000, f"{case}: power not balanced"
    assert all(0.01-1e-8 <= r["gateOpening"] <= 1+1e-8 for r in rows), f"{case}: gate position limit"
    assert max(abs(r["der(actuator.y)"]) for r in rows) <= 0.05+1e-8, f"{case}: gate rate limit"
    assert max(abs(r["expectedFrequency"]-expected) for r in final) < 1e-9
    assert max(abs(r["droopResidual"]) for r in final) < 1e-5
    if case.startswith("up"):
        assert min(r["frequency"] for r in rows) < expected
        assert rows[-1]["gateOpening"] > rows[0]["gateOpening"]
    if case == "down_4pct":
        assert max(r["frequency"] for r in rows) > expected
        assert rows[-1]["gateOpening"] < rows[0]["gateOpening"]
    if case == "hold":
        assert max(abs(r["frequency"]-50) for r in rows) < 1e-5
    outside = [r["time"] for r in rows if r["time"] >= 50 and abs(r["frequency"]-expected) > 0.01]
    summary[case] = {
        "expected_frequency_Hz": expected,
        "final_droop_residual_pu": rows[-1]["droopResidual"],
        "frequency_min_Hz": min(r["frequency"] for r in rows),
        "frequency_max_Hz": max(r["frequency"] for r in rows),
        "frequency_final_Hz": rows[-1]["frequency"],
        "initial_gate_pu": rows[0]["gateOpening"],
        "final_gate_pu": rows[-1]["gateOpening"],
        "final_mechanical_power_MW": rows[-1]["mechanicalPower"]/1e6,
        "final_power_imbalance_W": rows[-1]["powerImbalance"],
        "maximum_gate_rate_pu_per_s": max(abs(r["der(actuator.y)"]) for r in rows),
        "last_time_outside_0_01_Hz_of_equilibrium_s": max(outside) if outside else None,
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
fig, axes = plt.subplots(2, 2, figsize=(12, 8))
for case, label in [("up_4pct", "+5 MW, R=4%"), ("down_4pct", "-5 MW, R=4%"), ("up_5pct", "+5 MW, R=5%")]:
    rows = series[case]
    t = [r["time"] for r in rows]
    axes[0,0].plot(t, [r["frequency"] for r in rows], label=label)
    axes[0,1].plot(t, [r["frequency"] for r in rows], label=label)
    axes[1,0].plot(t, [100*r["gateOpening"] for r in rows], label=label)
axes[0,0].set_ylabel("Frequency (Hz)")
axes[0,0].set_title("Load step at 50 s")
axes[0,1].set_ylabel("Frequency (Hz)")
axes[0,1].set_title("Permanent steady-state offsets")
axes[0,1].set_xlim(150,300)
axes[0,1].set_ylim(49.85,50.125)
axes[1,0].set_ylabel("Gate opening (%)")
axes[1,0].set_title("Guide-vane response")
for R in [0.04,0.05]:
    powers = [40,45,50,55,60]
    axes[1,1].plot(powers,[50*(1-R*(v-50)/100) for v in powers],label=f"R={100*R:.0f}%")
for case in ["up_4pct","down_4pct","up_5pct"]:
    r=series[case][-1]
    axes[1,1].plot(r["electricalDemand"]/1e6,r["frequency"],"ko",markersize=5)
axes[1,1].set_title("Droop characteristic; dots are simulations")
axes[1,1].set_ylabel("Steady frequency (Hz)")
axes[1,1].set_xlabel("Electrical power (MW)")
for ax in [axes[0,0],axes[0,1],axes[1,0]]:
    ax.set_xlabel("Time (s)")
    if ax is not axes[0,1]:
        ax.set_xlim(0,300)
        ax.axvline(50,color="gray",linestyle=":",linewidth=1)
for ax in axes.flat:
    ax.grid(alpha=0.2)
    ax.legend(fontsize=8)
fig.suptitle("OpenHPL permanent droop control | 50 Hz, 100 MW base",fontsize=14)
fig.tight_layout()
fig.savefig(results / "permanent_droop_response.png",dpi=160)
print(json.dumps(summary,indent=2))

