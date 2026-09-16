import os, base64, csv, hashlib, json, math, pathlib, subprocess, zlib
root = pathlib.Path(__file__).resolve().parents[1]
out = pathlib.Path("/tmp/openhpl-results")
out.mkdir(exist_ok=True)
mos = out / "run.mos"
mos.write_text('''
loadModel(Modelica, {"4.0.0"});
loadFile("''' + str(root / "OpenHPL/package.mo") + '''");
getErrorString();
checkModel(OpenHPL.Examples.SimpleTurbine);
getErrorString();
simulate(OpenHPL.Examples.SimpleTurbine, startTime=0, stopTime=1000, numberOfIntervals=1000, tolerance=1e-6, method="dassl", outputFormat="csv", fileNamePrefix="SimpleTurbine", variableFilter="time|control.y|turbine.Vdot|turbine.Wdot_s|turbine.dp|surgeTank.h");
getErrorString();
''')
version = subprocess.check_output(["omc", "--version"], text=True).strip()
sha = os.environ.get("RAILWAY_GIT_COMMIT_SHA", "unknown")
if (root / ".git").exists():
    sha = subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
run = subprocess.run(["omc", str(mos)], cwd=out, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=900)
print(run.stdout, flush=True)
(out / "solver.log").write_text(run.stdout)
if run.returncode:
    raise RuntimeError("OpenModelica process failed")
result = out / "SimpleTurbine_res.csv"
with result.open() as f:
    rows = list(csv.DictReader(f))
required = ["time", "control.y", "turbine.Vdot", "turbine.Wdot_s", "surgeTank.h"]
assert rows and all(k in rows[0] for k in required), "Missing simulation outputs"
assert abs(float(rows[-1]["time"]) - 1000) < 1e-6, "Simulation ended early"
assert all(math.isfinite(float(row[k])) for row in rows for k in required), "Nonfinite output"
summary = {"model": "OpenHPL.Examples.SimpleTurbine", "commit": sha, "compiler": version, "rows": len(rows), "final_time": float(rows[-1]["time"]), "ranges": {k: [min(float(r[k]) for r in rows), max(float(r[k]) for r in rows)] for k in required}}
print("SIMULATION_VALIDATED " + json.dumps(summary), flush=True)
raw = result.read_bytes()
encoded = base64.b64encode(zlib.compress(raw)).decode()
print("CSV_SHA256 " + hashlib.sha256(raw).hexdigest(), flush=True)
chunks = [encoded[i:i+2000] for i in range(0, len(encoded), 2000)]
for i, chunk in enumerate(chunks):
    print("CSV_CHUNK " + str(i) + "/" + str(len(chunks)) + " " + chunk, flush=True)
