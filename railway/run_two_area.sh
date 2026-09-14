#!/usr/bin/env bash
set -euo pipefail

ROOT=/workspace/OpenHPL-repo
RUN=/workspace/run/two-area
OUT=/workspace/results/two-area
mkdir -p "$RUN" "$OUT"
cd "$RUN"

cat > simulate_two_area.mos <<'MOS'
loadModel(Modelica, {"4.0.0"});
loadFile("/workspace/OpenHPL-repo/OpenHPL/package.mo");
getErrorString();
checkModel(OpenHPL.Examples.TwoAreaAGC.TwoAreaTieLineAGC);
getErrorString();
simulate(OpenHPL.Examples.TwoAreaAGC.TwoAreaTieLineAGC,
  startTime=0, stopTime=80, numberOfIntervals=4000,
  tolerance=1e-7, method="dassl", outputFormat="csv",
  fileNamePrefix="TwoAreaTieLineAGC");
getErrorString();
MOS

omc simulate_two_area.mos | tee "$OUT/omc.log"
test -f TwoAreaTieLineAGC_res.csv
cp TwoAreaTieLineAGC_res.csv "$OUT/TwoAreaTieLineAGC_res.csv"
python3 "$ROOT/railway/plot_two_area.py" "$OUT/TwoAreaTieLineAGC_res.csv" "$OUT"

printf '\n=== TWO AREA SUMMARY ===\n'
cat "$OUT/summary.txt"
printf '\nServing validated results on port %s\n' "${PORT:-8080}"
exec python3 -m http.server "${PORT:-8080}" --directory /workspace/results
