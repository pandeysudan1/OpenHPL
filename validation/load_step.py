"""Run NewTest examples with OpenModelica and plot measured CSV results.

Requires omc on PATH, Python, numpy and matplotlib.
Run from any directory: python validation/load_step.py
"""
import argparse
import csv
import json
import hashlib
from pathlib import Path
import subprocess

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
CASES = {
    'IsochronousControl': 300,
    'PermanentDroopControl': 300,
    'TransientDroopControl': 300,
    'AGCControl': 8000,
    'FCRControl': 300,
    'FCRPrequalification.FCRComparison': 300,
    'FCRPrequalification.HydraulicFCRTest': 300,
    'FCRPrequalification.FCRStepTest': 80,
    'FCRPrequalification.FCRSineTest': 180,
}


def read_csv(path):
    with path.open() as stream:
        rows = list(csv.DictReader(stream))
    return {k: np.array([float(row[k]) for row in rows]) for k in rows[0]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reuse', type=Path, help='Analyze existing simulation CSVs')
    args = parser.parse_args()
    output = ROOT / 'validation' / 'results'
    output.mkdir(parents=True, exist_ok=True)
    build = args.reuse.resolve() if args.reuse else output / 'build'
    build.mkdir(parents=True, exist_ok=True)
    if not args.reuse:
        lines = ['loadModel(Modelica, {"4.0.0"});',
                 f'loadFile({json.dumps((ROOT / "OpenHPL/package.mo").as_posix())});',
                 f'loadFile({json.dumps((ROOT / "OpenHPLTest/package.mo").as_posix())});',
                 'getErrorString();']
        for model, stop in CASES.items():
            short = model.split('.')[-1]
            lines += [f'checkModel(OpenHPLTest.NewTest.{model});',
                      f'simulate(OpenHPLTest.NewTest.{model}, stopTime={stop}, '
                      f'numberOfIntervals={min(stop*10,8000)}, tolerance=1e-7, '
                      f'method="dassl", outputFormat="csv", fileNamePrefix="{short}");',
                      'getErrorString();']
        (build / 'run.mos').write_text('\n'.join(lines), encoding='utf-8')
        result = subprocess.run(['omc', 'run.mos'], cwd=build, capture_output=True, text=True)
        (output / 'simulation.log').write_text(result.stdout + result.stderr, encoding='utf-8')
        if result.returncode or result.stdout.count('The simulation finished successfully.') != len(CASES):
            raise RuntimeError('Simulation failed; see results/simulation.log')

    data, summary = {}, {}
    for model, stop in CASES.items():
        short = model.split('.')[-1]
        path = build / (short + '_res.csv')
        if short == 'IsochronousControl' and not path.exists():
            path = build / 'iso_res.csv'
        d = data[short] = read_csv(path)
        assert abs(d['time'][-1] - stop) < 1e-5, short
        assert all(np.isfinite(v).all() for v in d.values()), short
        item = {'stop_s': stop}
        if 'frequency' in d:
            f, gate, t = d['frequency'], d['actuator.y'], d['time']
            assert max(abs(f[t < 50] - 50)) < 1e-4, short + ' startup'
            assert gate.min() >= .01-1e-6 and gate.max() <= 1+1e-6, short
            dt = np.diff(t)
            rates = np.diff(gate)[dt > 1e-8] / dt[dt > 1e-8]
            assert max(abs(rates)) < .0501, short + ' gate rate'
            assert abs(d['powerImbalance'][-1]) < 1000, short + ' power balance'
            if short in ['PermanentDroopControl', 'TransientDroopControl']:
                assert abs(f[-1] - 49.9) < 1e-4, short
            if short in ['IsochronousControl', 'AGCControl']:
                assert abs(f[-1] - 50) < .001, short
            item.update(final_Hz=float(f[-1]), minimum_Hz=float(f.min()),
                        final_gate=float(gate[-1]), max_gate_rate_per_s=float(max(abs(rates))),
                        final_shaft_imbalance_W=float(d['powerImbalance'][-1]))
        elif short == 'FCRStepTest':
            assert abs(d['deliveredReserve'][-1] - .1) < 1e-5
            item.update(final_gate_reserve=float(d['deliveredReserve'][-1]),
                        time_to_90_s=float(d['timeTo90'][-1]))
        summary[short] = item
    (output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    # Keep the compact archives consumed by the research report in sync with this run.
    for short, d in data.items():
        keys = [k for k in ['time', 'frequency', 'frequencyInput', 'actuator.y',
                           'load.y', 'electricalGeneration', 'powerImbalance',
                           'deliveredReserve', 'reserveCommand'] if k in d]
        with (output / (short + '.csv')).open('w', newline='') as stream:
            writer = csv.writer(stream)
            writer.writerow(keys)
            writer.writerows(zip(*(d[k] for k in keys)))
    if not args.reuse:
        manifest = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes().replace(b'\r\n', b'\n')).hexdigest()
                    for p in (ROOT / 'OpenHPLTest/NewTest').rglob('*.mo')}
        (output / 'source_sha256.json').write_text(json.dumps(manifest, indent=2) + '\n')

    fig, axes = plt.subplots(2, 2, figsize=(13, 8), constrained_layout=True)
    names = ['IsochronousControl', 'PermanentDroopControl', 'TransientDroopControl', 'FCRControl']
    labels = ['Isochronous', 'Permanent droop', 'Transient droop', 'FCR']
    for name, label in zip(names, labels):
        d = data[name]
        axes[0, 0].plot(d['time'], d['frequency'], label=label)
        axes[1, 0].plot(d['time'], d['actuator.y'], label=label)
    d = data['IsochronousControl']
    axes[0, 1].plot(d['time'], d['load.y']/1e6, '--', label='Electrical demand')
    axes[0, 1].plot(d['time'], d['electricalGeneration']/1e6, label='0.99 × turbine power')
    d = data['AGCControl']
    axes[1, 1].plot(d['time']/60, d['frequency'], color='tab:purple', label='AGC + permanent droop')
    specs = [('Primary frequency response', 'Time (s)', 'Frequency (Hz)'),
             ('Isochronous power response', 'Time (s)', 'Power (MW)'),
             ('Gate response', 'Time (s)', 'Gate opening (pu)'),
             ('Secondary frequency recovery', 'Time (min)', 'Frequency (Hz)')]
    for ax, (title, xlabel, ylabel) in zip(axes.flat, specs):
        ax.set(title=title, xlabel=xlabel, ylabel=ylabel)
        ax.grid(alpha=.25)
        ax.legend(fontsize=8)
    fig.suptitle('OpenHPLTest.NewTest — 50 → 55 MW load step at 50 s', fontsize=16)
    fig.savefig(output / 'load_step.png', dpi=170)
    plt.close(fig)
    print(json.dumps(summary, indent=2))
    print('All checks passed. Results:', output)


if __name__ == '__main__':
    main()
