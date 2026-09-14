#!/usr/bin/env bash
set -euo pipefail
mkdir -p /workspace/results /workspace/run
echo "=== OpenHPL AGC Railway startup ==="
omc --version
chmod +x /workspace/OpenHPL-repo/railway/run_model.sh
/workspace/OpenHPL-repo/railway/run_model.sh
echo "=== OPENHPL AGC SIMULATION FINISHED ==="
echo "Executing AGC comparison notebook..."
jupyter nbconvert --to notebook --execute /workspace/OpenHPL-repo/railway/notebooks/03_agc_smib.ipynb \
  --output /workspace/results/03_agc_smib.executed.ipynb \
  --ExecutePreprocessor.timeout=600
echo "=== AGC NOTEBOOK EXECUTED ==="
python3 - <<'PY'
import json, pathlib
p=pathlib.Path('/workspace/results/03_agc_smib.executed.ipynb')
nb=json.loads(p.read_text())
for cell in nb.get('cells',[]):
    for out in cell.get('outputs',[]):
        if out.get('output_type')=='stream':
            print(''.join(out.get('text',[])), end='')
PY
echo "=== STARTING JUPYTER ==="
exec jupyter lab --allow-root --ip=0.0.0.0 --port="${PORT:-8888}" --no-browser \
  --IdentityProvider.token="${JUPYTER_TOKEN:?JUPYTER_TOKEN must be set}" \
  --ServerApp.password="" --ServerApp.root_dir=/workspace
