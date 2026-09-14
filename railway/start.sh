#!/usr/bin/env bash
set -euo pipefail
mkdir -p /workspace/results /workspace/run
echo "=== OpenHPL Trollheim AGC Railway startup ==="
omc --version
chmod +x /workspace/OpenHPL-repo/railway/run_trollheim.sh
chmod +x /workspace/OpenHPL-repo/railway/run_trollheim_surgetank.sh
/workspace/OpenHPL-repo/railway/run_trollheim.sh
echo "=== BASE TROLLHEIM AGC SIMULATION FINISHED ==="
/workspace/OpenHPL-repo/railway/run_trollheim_surgetank.sh
echo "=== SURGETANK TROLLHEIM AGC SIMULATION FINISHED ==="
echo "=== STARTING JUPYTER ==="
exec jupyter lab --allow-root --ip=0.0.0.0 --port="${PORT:-8888}" --no-browser \
  --IdentityProvider.token="${JUPYTER_TOKEN:?JUPYTER_TOKEN must be set}" \
  --ServerApp.password="" --ServerApp.root_dir=/workspace
