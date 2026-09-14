#!/usr/bin/env bash
set -u
mkdir -p /workspace/run /workspace/results
cd /workspace/run

rm -f *TrollheimAGCSurgeTank*_res.csv \
      /workspace/results/AGC_Trollheim_Surgetank_direct_res.csv \
      /workspace/results/AGC_Trollheim_Surgetank_WarmStart_res.csv

cat > run_trollheim_surgetank_direct.mos <<'EOF'
loadModel(Modelica,{"4.0.0"});
getErrorString();
loadFile("/workspace/OpenHPL-repo/OpenHPL/package.mo","UTF-8",false);
getErrorString();
checkModel(OpenHPL.Examples.AGC_Trollheim_Surgetank.TrollheimAGCSurgeTank);
getErrorString();
simulate(OpenHPL.Examples.AGC_Trollheim_Surgetank.TrollheimAGCSurgeTank,
  startTime=0,stopTime=65,numberOfIntervals=3250,tolerance=1e-7,outputFormat="csv",
  variableFilter="time|frequency_Hz|mechanicalPower|electricalLoad|guideVane|turbineFlow|surgeLevel|surgeFlow|generator.f|governor.gate|governor.x_i|turbine.Wdot_s|turbine.Vdot|loadStep.y|surgeTank.h|surgeTank.Vdot",
  simflags="-homotopyOnFirstTry -homMaxNewtonSteps=50 -homMaxTries=20 -lv=LOG_INIT,LOG_NLS");
getErrorString();
EOF

echo "=== DIRECT HOMOTOPY INITIALIZATION TEST ==="
omc run_trollheim_surgetank_direct.mos 2>&1 | tee /workspace/results/omc_agc_trollheim_surgetank_direct.log || true
DIRECT_CSV=$(find /workspace/run -maxdepth 1 -name '*TrollheimAGCSurgeTank_res.csv' -type f -size +0c | head -1)
DIRECT_OK=0
if [ -n "$DIRECT_CSV" ]; then
  cp "$DIRECT_CSV" /workspace/results/AGC_Trollheim_Surgetank_direct_res.csv
  DIRECT_OK=$(python3 - <<'PY'
import pandas as pd
try:
    df=pd.read_csv('/workspace/results/AGC_Trollheim_Surgetank_direct_res.csv')
    print(1 if len(df)>10 and float(df.time.max())>=64.99 else 0)
except Exception:
    print(0)
PY
)
fi

if [ "$DIRECT_OK" = "1" ]; then
  echo "DIRECT_HOMOTOPY_RESULT=PASS"
  python3 - <<'PY'
import pandas as pd
p='/workspace/results/AGC_Trollheim_Surgetank_direct_res.csv'
df=pd.read_csv(p)
pre=df[df.time<5]; post=df[df.time>=5]; i=post.frequency_Hz.idxmin()
print('DIRECT_PRE_f_range_Hz=',float(pre.frequency_Hz.max()-pre.frequency_Hz.min()))
print('DIRECT_PRE_Pm_range_MW=',float((pre.mechanicalPower.max()-pre.mechanicalPower.min())/1e6))
print('DIRECT_PRE_level_range_m=',float(pre.surgeLevel.max()-pre.surgeLevel.min()))
print('DIRECT_PRE_surgeFlow_range_m3s=',float(pre.surgeFlow.max()-pre.surgeFlow.min()))
print('DIRECT_NADIR_Hz=',float(df.loc[i,'frequency_Hz']))
print('DIRECT_NADIR_time_s=',float(df.loc[i,'time']))
print('DIRECT_FINAL_f_Hz=',float(df.iloc[-1].frequency_Hz))
print('DIRECT_FINAL_Pm_MW=',float(df.iloc[-1].mechanicalPower/1e6))
print('DIRECT_FINAL_level_m=',float(df.iloc[-1].surgeLevel))
print('DIRECT_FINAL_surgeFlow_m3s=',float(df.iloc[-1].surgeFlow))
PY
else
  echo "DIRECT_HOMOTOPY_RESULT=FAIL"
fi

rm -f *TrollheimAGCSurgeTankWarmStart*_res.csv
cat > run_trollheim_surgetank_warm.mos <<'EOF'
loadModel(Modelica,{"4.0.0"});
getErrorString();
loadFile("/workspace/OpenHPL-repo/OpenHPL/package.mo","UTF-8",false);
getErrorString();
checkModel(OpenHPL.Examples.AGC_Trollheim_Surgetank.TrollheimAGCSurgeTankWarmStart);
getErrorString();
simulate(OpenHPL.Examples.AGC_Trollheim_Surgetank.TrollheimAGCSurgeTankWarmStart,
  startTime=-300,stopTime=65,numberOfIntervals=7300,tolerance=1e-7,outputFormat="csv",
  variableFilter="time|frequency_Hz|mechanicalPower|electricalLoad|guideVane|turbineFlow|surgeLevel|surgeFlow|generator.f|governor.gate|governor.x_i|turbine.Wdot_s|turbine.Vdot|loadStep.y|surgeTank.h|surgeTank.Vdot");
getErrorString();
EOF

echo "=== DYNAMIC WARM-START TEST ==="
omc run_trollheim_surgetank_warm.mos 2>&1 | tee /workspace/results/omc_agc_trollheim_surgetank_warm.log || true
WARM_CSV=$(find /workspace/run -maxdepth 1 -name '*TrollheimAGCSurgeTankWarmStart*_res.csv' -type f -size +0c | head -1)
if [ -z "$WARM_CSV" ]; then
  echo "WARM_START_RESULT=FAIL"
  exit 1
fi
cp "$WARM_CSV" /workspace/results/AGC_Trollheim_Surgetank_WarmStart_res.csv

echo "WARM_START_RESULT=PASS"
python3 - <<'PY'
import pandas as pd
p='/workspace/results/AGC_Trollheim_Surgetank_WarmStart_res.csv'
df=pd.read_csv(p)
vis=df[df.time>=0].copy(); pre=vis[(vis.time>=0)&(vis.time<5)]; post=vis[vis.time>=5]
i=post.frequency_Hz.idxmin()
print('WARM_PRE_f_range_Hz=',float(pre.frequency_Hz.max()-pre.frequency_Hz.min()))
print('WARM_PRE_Pm_range_MW=',float((pre.mechanicalPower.max()-pre.mechanicalPower.min())/1e6))
print('WARM_PRE_level_range_m=',float(pre.surgeLevel.max()-pre.surgeLevel.min()))
print('WARM_PRE_surgeFlow_range_m3s=',float(pre.surgeFlow.max()-pre.surgeFlow.min()))
print('WARM_NADIR_Hz=',float(df.loc[i,'frequency_Hz']))
print('WARM_NADIR_time_s=',float(df.loc[i,'time']))
print('WARM_FINAL_f_Hz=',float(vis.iloc[-1].frequency_Hz))
print('WARM_FINAL_Pm_MW=',float(vis.iloc[-1].mechanicalPower/1e6))
print('WARM_FINAL_level_m=',float(vis.iloc[-1].surgeLevel))
print('WARM_FINAL_surgeFlow_m3s=',float(vis.iloc[-1].surgeFlow))
PY
