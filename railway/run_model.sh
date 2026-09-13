#!/usr/bin/env bash
set -euo pipefail
mkdir -p /workspace/run /workspace/results
cd /workspace/run
cat > run.mos <<'EOF'
loadModel(Modelica,{"4.0.0"});
getErrorString();
loadFile("/workspace/OpenHPL-repo/OpenHPL/package.mo","UTF-8",false);
getErrorString();
checkModel(OpenHPL.Examples.SimpleTurbine);
getErrorString();
simulate(OpenHPL.Examples.SimpleTurbine,startTime=0,stopTime=1000,numberOfIntervals=500,tolerance=1e-6,outputFormat="csv",variableFilter="time|control.y|turbine.Wdot_s");
getErrorString();
EOF
echo "=== RUNNING OPENHPL WITHOUT JUPYTER OVERHEAD ==="
omc run.mos 2>&1 | tee /workspace/results/omc.log
CSV=$(find /workspace/run -maxdepth 1 -name '*SimpleTurbine*_res.csv' | head -1)
if [ -z "$CSV" ]; then
  echo "ERROR: SimpleTurbine result CSV not created"
  exit 1
fi
cp "$CSV" /workspace/results/SimpleTurbine_res.csv
echo "RESULT_CSV=/workspace/results/SimpleTurbine_res.csv"
