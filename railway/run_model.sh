#!/usr/bin/env bash
set -euo pipefail
mkdir -p /workspace/run /workspace/results
cd /workspace/run
cat > run.mos <<'EOF'
loadModel(Modelica,{"4.0.0"});
getErrorString();
loadFile("/workspace/OpenHPL-repo/OpenHPL/package.mo","UTF-8",false);
getErrorString();
checkModel(OpenHPL.Examples.AGC_SMIB);
getErrorString();
simulate(OpenHPL.Examples.AGC_SMIB,startTime=0,stopTime=65,numberOfIntervals=3250,tolerance=1e-7,outputFormat="csv",variableFilter="time|frequency_Hz|mechanicalPower|electricalLoad|guideVane|flow|generator.f|governor.gate|governor.x_i|turbine.Wdot_s|turbine.Vdot|loadStep.y");
getErrorString();
EOF
echo "=== RUNNING OPENHPL AGC_SMIB WITHOUT JUPYTER OVERHEAD ==="
omc run.mos 2>&1 | tee /workspace/results/omc_agc.log
CSV=$(find /workspace/run -maxdepth 1 -name '*AGC_SMIB*_res.csv' | head -1)
if [ -z "$CSV" ]; then
  echo "ERROR: AGC_SMIB result CSV not created"
  exit 1
fi
cp "$CSV" /workspace/results/AGC_SMIB_res.csv
echo "RESULT_CSV=/workspace/results/AGC_SMIB_res.csv"
