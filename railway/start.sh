#!/usr/bin/env bash
set -euo pipefail
mkdir -p /workspace/results /workspace/run
echo "=== OpenHPL Railway startup ==="
omc --version
chmod +x /workspace/OpenHPL-repo/railway/run_model.sh
/workspace/OpenHPL-repo/railway/run_model.sh
echo "=== OPENHPL SIMULATION FINISHED ==="
echo "Executing notebook for analysis and plot..."
jupyter nbconvert --to notebook --execute /workspace/OpenHPL-repo/railway/notebooks/02_simple_turbine.ipynb \
  --output /workspace/results/02_simple_turbine.executed.ipynb \
  --ExecutePreprocessor.timeout=600
echo "=== NOTEBOOK EXECUTED ==="
python3 - <<'PY'
import json, pathlib
p=pathlib.Path('/workspace/results/02_simple_turbine.executed.ipynb')
nb=json.loads(p.read_text())
for cell in nb.get('cells',[]):
    for out in cell.get('outputs',[]):
        if out.get('output_type')=='stream':
            print(''.join(out.get('text',[])), end='')
PY
echo "=== STARTING JUPYTER ==="
exec jupyter lab --ip=0.0.0.0 --port="${PORT:-8888}" --no-browser \
  --ServerApp.token="${JUPYTER_TOKEN:-}" --ServerApp.password="" \
  --ServerApp.allow_origin="*" --ServerApp.root_dir=/workspace
