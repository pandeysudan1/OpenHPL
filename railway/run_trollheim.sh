#!/usr/bin/env bash
set -euo pipefail
mkdir -p /workspace/run /workspace/results
cd /workspace/run
cat > run_trollheim.mos <<'EOF'
loadModel(Modelica,{"4.0.0"});
getErrorString();
loadFile("/workspace/OpenHPL-repo/OpenHPL/package.mo","UTF-8",false);
getErrorString();
checkModel(OpenHPL.Examples.AGC_Trollheim);
getErrorString();
simulate(OpenHPL.Examples.AGC_Trollheim,startTime=0,stopTime=65,numberOfIntervals=3250,tolerance=1e-7,outputFormat="csv",variableFilter="time|frequency_Hz|mechanicalPower|electricalLoad|guideVane|turbineFlow|generator.f|governor.gate|governor.x_i|turbine.Wdot_s|turbine.Vdot|loadStep.y");
getErrorString();
EOF

echo "=== RUNNING OPENHPL AGC_TROLLHEIM ==="
omc run_trollheim.mos 2>&1 | tee /workspace/results/omc_agc_trollheim.log
CSV=$(find /workspace/run -maxdepth 1 -name '*AGC_Trollheim*_res.csv' | head -1)
if [ -z "$CSV" ]; then
  echo "ERROR: AGC_Trollheim result CSV not created"
  exit 1
fi
cp "$CSV" /workspace/results/AGC_Trollheim_res.csv

echo "=== TROLLHEIM FORENSIC CHECK ==="
python3 - <<'PY'
import pandas as pd
p='/workspace/results/AGC_Trollheim_res.csv'
df=pd.read_csv(p)
print('Columns:',df.columns.tolist())
f='frequency_Hz'; pm='mechanicalPower'; pl='electricalLoad'; g='guideVane'; q='turbineFlow'
pre=df[df.time<5]; post=df[df.time>=5]
print('PRE_f_range_Hz=',float(pre[f].max()-pre[f].min()))
print('PRE_Pm_range_MW=',float((pre[pm].max()-pre[pm].min())/1e6))
print('PRE_mean_Pm_MW=',float(pre[pm].mean()/1e6))
print('PRE_mean_PL_MW=',float(pre[pl].mean()/1e6))
i=post[f].idxmin()
print('NADIR_Hz=',float(df.loc[i,f]))
print('NADIR_time_s=',float(df.loc[i,'time']))
print('FINAL_f_Hz=',float(df.iloc[-1][f]))
print('FINAL_Pm_MW=',float(df.iloc[-1][pm]/1e6))
print('FINAL_PL_MW=',float(df.iloc[-1][pl]/1e6))
print('FINAL_gate_pu=',float(df.iloc[-1][g]))
print('FINAL_flow_m3s=',float(df.iloc[-1][q]))
print('TROLLHEIM_DATA_START')
for ts in [0,1,4.9,5,5.1,5.2,5.5,6,7,10,20,40,65]:
    j=(df.time-ts).abs().idxmin(); r=df.loc[j]
    print(f"{r['time']:.2f},{r[f]:.9f},{r[pm]/1e6:.9f},{r[pl]/1e6:.9f},{r[g]:.9f},{r[q]:.9f}")
print('TROLLHEIM_DATA_END')
PY

echo "RESULT_CSV=/workspace/results/AGC_Trollheim_res.csv"
