#!/usr/bin/env bash
set -u
mkdir -p /workspace/run /workspace/results
cd /workspace/run
rm -f *TrollheimAGCSurgeTankInitialized*_res.csv /workspace/results/AGC_Trollheim_Surgetank_Initialized_res.csv

cat > run_trollheim_surgetank_initialized.mos <<'EOF'
loadModel(Modelica,{"4.0.0"});
getErrorString();
loadFile("/workspace/OpenHPL-repo/OpenHPL/package.mo","UTF-8",false);
getErrorString();
checkModel(OpenHPL.Examples.AGC_Trollheim_Surgetank.TrollheimAGCSurgeTankInitialized);
getErrorString();
simulate(OpenHPL.Examples.AGC_Trollheim_Surgetank.TrollheimAGCSurgeTankInitialized,
  startTime=0,stopTime=65,numberOfIntervals=3250,tolerance=1e-7,outputFormat="csv",
  variableFilter="time|frequency_Hz|mechanicalPower|electricalLoad|guideVane|turbineFlow|surgeLevel|surgeFlow|generator.f|governor.gate|turbine.Wdot_s|turbine.Vdot|loadStep.y|surgeTank.h|surgeTank.Vdot");
getErrorString();
EOF

echo "=== EQUILIBRIUM-SEEDED SURGETANK TEST ==="
omc run_trollheim_surgetank_initialized.mos 2>&1 | tee /workspace/results/omc_agc_trollheim_surgetank_initialized.log || true
CSV=$(find /workspace/run -maxdepth 1 -name '*TrollheimAGCSurgeTankInitialized*_res.csv' -type f -size +0c | head -1)
if [ -z "$CSV" ]; then echo "INITIALIZED_SURGE_RESULT=FAIL"; exit 1; fi
cp "$CSV" /workspace/results/AGC_Trollheim_Surgetank_Initialized_res.csv
python3 - <<'PY'
import pandas as pd
p='/workspace/results/AGC_Trollheim_Surgetank_Initialized_res.csv'
df=pd.read_csv(p)
if len(df)<10 or df.time.max()<64.99:
    print('INITIALIZED_SURGE_RESULT=FAIL'); raise SystemExit(1)
pre=df[df.time<5]; post=df[df.time>=5]; i=post.frequency_Hz.idxmin()
print('INITIALIZED_SURGE_RESULT=PASS')
print('SURGE_PRE_f_range_Hz=',float(pre.frequency_Hz.max()-pre.frequency_Hz.min()))
print('SURGE_PRE_Pm_range_MW=',float((pre.mechanicalPower.max()-pre.mechanicalPower.min())/1e6))
print('SURGE_PRE_level_range_m=',float(pre.surgeLevel.max()-pre.surgeLevel.min()))
print('SURGE_PRE_flow_range_m3s=',float(pre.surgeFlow.max()-pre.surgeFlow.min()))
print('SURGE_NADIR_Hz=',float(df.loc[i,'frequency_Hz']))
print('SURGE_NADIR_time_s=',float(df.loc[i,'time']))
print('SURGE_FINAL_f_Hz=',float(df.iloc[-1].frequency_Hz))
print('SURGE_FINAL_Pm_MW=',float(df.iloc[-1].mechanicalPower/1e6))
print('SURGE_FINAL_level_m=',float(df.iloc[-1].surgeLevel))
print('SURGE_FINAL_flow_m3s=',float(df.iloc[-1].surgeFlow))
for ts in [0,1,4.9,5,5.1,5.5,6,7,10,20,40,65]:
    j=(df.time-ts).abs().idxmin(); r=df.loc[j]
    print(f"SURGE_SAMPLE,{r.time:.2f},{r.frequency_Hz:.8f},{r.mechanicalPower/1e6:.8f},{r.guideVane:.8f},{r.turbineFlow:.8f},{r.surgeLevel:.8f},{r.surgeFlow:.8f}")
PY
