#!/usr/bin/env python3
import json, os, sys
import pandas as pd
import matplotlib.pyplot as plt

csv_path, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
df = pd.read_csv(csv_path)

def col(name):
    if name in df.columns:
        return df[name]
    matches = [c for c in df.columns if c.strip('"') == name]
    if matches:
        return df[matches[0]]
    raise KeyError(f"Missing {name}; available={list(df.columns)[:40]}")

t = col('time')
f1 = col('frequency1_Hz')
f2 = col('frequency2_Hz')
pt = col('P_tie_MW')
g1 = col('gate1_mean')
g2 = col('gate2_mean')
p1 = col('mechanical1_MW')
p2 = col('mechanical2_MW')
ace1 = col('ACE1_pu')
ace2 = col('ACE2_pu')
mask = t >= 5.0

metrics = {
    'frequency1_nadir_Hz': float(f1[mask].min()),
    'frequency2_nadir_Hz': float(f2[mask].min()),
    'frequency1_peak_Hz': float(f1[mask].max()),
    'frequency2_peak_Hz': float(f2[mask].max()),
    'peak_abs_tie_line_MW': float(pt[mask].abs().max()),
    'final_frequency1_Hz': float(f1.iloc[-1]),
    'final_frequency2_Hz': float(f2.iloc[-1]),
    'final_tie_line_MW': float(pt.iloc[-1]),
    'final_ACE1_pu': float(ace1.iloc[-1]),
    'final_ACE2_pu': float(ace2.iloc[-1]),
    'final_gate1_mean_pu': float(g1.iloc[-1]),
    'final_gate2_mean_pu': float(g2.iloc[-1]),
    'final_mechanical1_MW': float(p1.iloc[-1]),
    'final_mechanical2_MW': float(p2.iloc[-1]),
}

with open(os.path.join(out, 'summary.json'), 'w') as f:
    json.dump(metrics, f, indent=2)
with open(os.path.join(out, 'summary.txt'), 'w') as f:
    for k, v in metrics.items():
        f.write(f'{k}: {v:.6f}\n')

plt.figure(figsize=(9,5))
plt.plot(t, f1, label='Area 1 frequency')
plt.plot(t, f2, label='Area 2 frequency')
plt.axvline(5, linestyle='--', linewidth=1, label='30 MW step')
plt.axhline(50, linestyle=':', linewidth=1)
plt.xlabel('Time [s]'); plt.ylabel('Frequency [Hz]'); plt.grid(True, alpha=.3); plt.legend(); plt.tight_layout()
plt.savefig(os.path.join(out, 'frequency_response.svg'))
plt.close()

plt.figure(figsize=(9,5))
plt.plot(t, pt, label='P12: Area 1 -> Area 2')
plt.axvline(5, linestyle='--', linewidth=1)
plt.axhline(0, linestyle=':', linewidth=1)
plt.xlabel('Time [s]'); plt.ylabel('Tie-line power [MW]'); plt.grid(True, alpha=.3); plt.legend(); plt.tight_layout()
plt.savefig(os.path.join(out, 'tie_line_power.svg'))
plt.close()

plt.figure(figsize=(9,5))
plt.plot(t, g1, label='Area 1 mean gate')
plt.plot(t, g2, label='Area 2 mean gate')
plt.xlabel('Time [s]'); plt.ylabel('Mean guide-vane opening [pu]'); plt.grid(True, alpha=.3); plt.legend(); plt.tight_layout()
plt.savefig(os.path.join(out, 'governor_response.svg'))
plt.close()

plt.figure(figsize=(9,5))
plt.plot(t, p1, label='Area 1 hydro mechanical power')
plt.plot(t, p2, label='Area 2 hydro mechanical power')
plt.xlabel('Time [s]'); plt.ylabel('Mechanical power [MW]'); plt.grid(True, alpha=.3); plt.legend(); plt.tight_layout()
plt.savefig(os.path.join(out, 'hydro_power_response.svg'))
plt.close()
