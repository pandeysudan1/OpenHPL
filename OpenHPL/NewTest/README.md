# Isochronous control in OpenHPL

Open `OpenHPL/package.mo` in OMEdit, then select
`OpenHPL.NewTest.IsochronousControl`. Simulate from 0 to 300 s with DASSL,
tolerance 1e-7 and output interval 0.1 s (already set in the experiment annotation).
Use Modelica Standard Library 3.2.3, as requested by this version of OpenHPL.

## First experiment

The isolated generator supplies 50 MW at 50 Hz. At 50 s demand increases to
55 MW. The PI governor measures frequency, commands a gate servo, and restores
nominal frequency by increasing turbine power. Set `dP=-5e6` for the independent
load-decrease experiment, or `dP=0` for the equilibrium check.

Plot `frequency`, `mechanicalPower`, `electricalDemand`, `gateOpening`,
`waterFlow`, and `powerImbalance`. Power is in W, frequency in Hz, flow in m3/s,
and gate opening is a fraction. The output `powerImbalance` includes the generator
conversion loss; at equilibrium turbine power equals electrical demand / 0.99.

## Components and equations

- Existing OpenHPL Reservoir, Pipe, Turbine and SimpleGen provide the physical plant.
- `Controllers.IsochronousGovernor` implements e=(f_ref-f)/f_ref,
  raw=Kp*e+x, y=clip(raw), and der(x)=Ki*e+(actualGate-raw)/Tt.
- `Controllers.GateActuator` implements a first-order servo with gate-position
  limits and separate opening/closing rate limits. The governor tracks the actual
  gate to limit integral windup during saturation and rate limiting.
- Defaults: Kp=2, Ki=0.1 1/s, tracking time 5 s, servo time 0.5 s,
  gate range 0.01..1, and rates 0.05 pu/s in each direction.
- The generator has H=4 s on a 100 MW base and 12 poles. Its mechanical inertia
  is calculated from J=2*H*P_base/w_nom^2; electrical frequency is not shaft speed.
- The penstock is 600 m long, 4 m in diameter, with 300 m elevation drop.
  Reservoir and tailwater levels provide a gross head of 345 m. Pipe friction
  and water inertia remain active. Turbine hydraulic efficiency is 0.9.

The initial conditions impose nominal speed, zero rotor acceleration, stationary
water flow and a stationary gate. Initial gate opening and governor integral
contribution are solved from that operating point (approximately 0.451827).
The actuator uses y=target at initialization, avoiding a flat, rate-limited
initialization residual. Controller start values are guesses, not fixed gate settings.
A different plant or initial demand must still have a physically feasible equilibrium.
For standalone reuse of the governor, provide an initialization condition in the
plant or fix its integral state explicitly, as explained in the Modelica documentation.
Keep the governor and actuator position limits consistent when changing them.

The existing `DroopControllerPI` was not used: its measured power cancels from
its error signal, leaving a frequency-error PI loop. The new block makes the
isochronous behavior, units, initialization and actuator tracking explicit.
Existing controller and plant source files were not modified. The library's
root `package.order` was extended with `NewTest`.

## Verified results

Validated with OpenModelica 1.26.0 and Modelica 3.2.3. Model equation check:
85 equations and 85 variables. All four simulations complete successfully.

| Case | Frequency extreme | Frequency at 300 s | Final gate |
| --- | --- | --- | --- |
| +5 MW | 48.97185 Hz minimum | 49.99999943 Hz | 0.497070 |
| -5 MW | 51.01605 Hz maximum | 50.00000037 Hz | 0.406599 |
| No step | 50 Hz throughout | 50 Hz | 0.451827 |
| +5 MW, deliberately slow 0.001 pu/s gate | 42.11432 Hz minimum | 50.00003772 Hz | 0.497069 |

Both normal load-step cases remain within 0.01 Hz of nominal after approximately
132 s simulation time, about 82 s after the disturbance. Final power-balance
residual is below 1 W for both cases. The slow-gate case intentionally illustrates
poor transient frequency performance; its numerical PASS verifies limits and
recovery, not acceptable operational performance. No underfrequency protection
is modeled. These illustrative gains are not an optimized plant tuning.

Automated checks require frequency within 0.001 Hz and power imbalance within
1000 W throughout the final 20 s; stationary pre-disturbance operation; finite,
complete results; correct response direction; gate position and rate bounds;
and actual rate-limit activation in the slow-actuator experiment.

From any directory, run (Python, matplotlib and `omc` on PATH required):

```powershell
python path/to/OpenHPL/NewTest/validate.py
```

The script compiles the model under `Results/build`, runs all four cases, and
writes compact CSVs, `Results/validation.json` and `Results/isochronous_response.png`.
Use `--build-dir PATH` to choose a different compilation directory. The
`--skip-build` option is only for checking an executable already built from the
current model sources.

OpenModelica reports that the parent library's declared OpenIPSL 2.0.0-dev is
unavailable. This example does not instantiate OpenIPSL models and was successfully
translated and simulated without it. OpenModelica also reports using compatible
4.1.0 Complex and ModelicaServices packages with MSL 3.2.3 in this installation.

## Scope and reference

Conceptual reference: P. Kundur, *Power System Stability and Control*, turbine
governing and active-power/frequency control. The plant data and controller gains
are illustrative OpenHPL demonstration values, not a reproduced Kundur benchmark.

This model represents one isolated, frequency-controlling hydro unit. It has
no permanent droop, tie-line, AGC, voltage control, surge tank, elastic water-hammer
model or detailed electromagnetic generator dynamics. The simple turbine does
not include runner-speed dependence. Later droop and AGC examples should build
on this verified case with explicitly different control laws and network models.
