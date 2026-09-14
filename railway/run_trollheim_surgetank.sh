#!/usr/bin/env bash
set -euo pipefail
mkdir -p /workspace/run /workspace/results
cd /workspace/run
cat > run_trollheim_surgetank.mos <<'EOF'
loadModel(Modelica,{"4.0.0"});
getErrorString();
loadFile("/workspace/OpenHPL-repo/OpenHPL/package.mo","UTF-8",false);
getErrorString();
checkModel(OpenHPL.Examples.AGC_Trollheim_Surgetank.TrollheimAGCSurgeTank);
getErrorString();
simulate(OpenHPL.Examples.AGC_Trollheim_Surgetank.TrollheimAGCSurgeTank,
  startTime=0,stopTime=65,numberOfIntervals=3250,tolerance=1e-7,outputFormat="csv",
  variableFilter="time|frequency_Hz|mechanicalPower|electricalLoad|guideVane|turbineFlow|surgeLevel|surgeFlow|generator.f|governor.gate|governor.x_i|turbine.Wdot_s|turbine.Vdot|loadStep.y|surgeTank.h|surgeTank.Vdot",
  simflags="-homotopyOnFirstTry -homMaxNewtonSteps=50 -homMaxTries=20");
getErrorString();
EOF

echo "=== RUNNING OPENHPL AGC_TROLLHEIM_SURGETANK ==="
omc run_trollheim_surgetank.mos 2>&1 | tee /workspace/results/omc_agc_trollheim_surgetank.log
CSV=$(find /workspace/run -maxdepth 1 -name '*TrollheimAGCSurgeTank*_res.csv' | head -1)
if [ -z "$CSV" ]; then
  echo "ERROR: surge-tank result CSV not created"
  exit 1
fi
cp "$CSV" /workspace/results/AGC_Trollheim_Surgetank_res.csv
python3 - <<'PY'
import pandas as pd
p='/workspace/results/AGC_Trollheim_Surgetank_res.csv'
df=pd.read_csv(p)
pre=df[df.time<5]; post=df[df.time>=5]
i=post.frequency_Hz.idxmin()
print('SURGE_PRE_f_range_Hz=',float(pre.frequency_Hz.max()-pre.frequency_Hz.min()))
print('SURGE_PRE_Pm_range_MW=',float((pre.mechanicalPower.max()-pre.mechanicalPower.min())/1e6))
print('SURGE_PRE_level_range_m=',float(pre.surgeLevel.max()-pre.surgeLevel.min()))
print('SURGE_NADIR_Hz=',float(df.loc[i,'frequency_Hz']))
print('SURGE_NADIR_time_s=',float(df.loc[i,'time']))
print('SURGE_FINAL_f_Hz=',float(df.iloc[-1].frequency_Hz))
print('SURGE_FINAL_Pm_MW=',float(df.iloc[-1].mechanicalPower/1e6))
print('SURGE_FINAL_level_m=',float(df.iloc[-1].surgeLevel))
print('SURGE_FINAL_flow_m3s=',float(df.iloc[-1].surgeFlow))
PY
