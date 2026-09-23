# Permanent droop control

In OMEdit, load `OpenHPL/package.mo`, open
`OpenHPL.NewTest.PermanentDroopControl`, and simulate 0 to 300 s. Plot
`frequency` and `expectedFrequency` together. The load changes at 50 s.
The example has a dedicated droop-curve governor icon and the existing servo icon.

## What changes from isochronous control

An isochronous governor restores 50 Hz after a load change. This permanent-droop
governor allows a steady frequency offset while it balances generation and load.
The new `Controllers.PermanentDroopGovernor` has separate frequency, power,
power-reference, and actual-gate inputs. Its equations are:

```text
e = (f_ref - f)/f_ref - R*(P - P_ref)/P_base
raw = Kp*e + x
y = clip(raw, yMin, yMax)
der(x) = Ki*e + (actualGate - raw)/Tt
```

The PI integrator removes the combined frequency/power error. It does not remove
frequency error by itself. At an unsaturated stationary operating point,
actualGate=raw and e=0, giving:

```text
f = f_ref * (1 - R*(P - P_ref)/P_base)
```

R is a fraction: use `0.04` for 4%, not `4`. Four-percent droop means a 4% change
in nominal frequency per 1 pu change in power on the specified power base; it does
not mean the frequency drops 4% for every load step.

The example holds P_ref at the starting 50 MW electrical demand. The power
measurement is turbine shaft power multiplied by generator efficiency (0.99),
so it is on an electrical-equivalent base. It is not the imposed demand signal.
Both P inputs and P_base use W. With bearing losses disabled, equilibrium makes
this measurement equal to electrical demand. Thus:

```text
Delta f = -f_nom * R * dP / P_base
        = -50 * 0.04 * 5e6 / 100e6
        = -0.1 Hz
```

The controller characteristic is 50 MW/Hz in magnitude for these settings.
The example models a constant-power load without frequency damping. Saturation,
frequency-sensitive loads, losses on a different power base, or varying P_ref
would require their corresponding equilibrium calculation. expectedFrequency
is the equilibrium reference for the present load, not the transient trajectory.

## Physical plant and initialization

This uses the same hydraulic and generator parameters as IsochronousControl:
reservoir, 600 m rigid penstock with water inertia and friction, turbine with
constant efficiency, dynamic SimpleGen, and gate position/rate limits. Initial
frequency is 50 Hz; zero rotor acceleration, stationary flow and stationary gate
solve the initial gate and integral contribution. Initial gate is about 0.451827.

Default governor gains are Kp=2 and Ki=0.1 1/s, with 5 s actuator tracking. The
servo has a 0.5 s time constant and limits of 0.01..1 and +/-0.05 pu/s. Gains and
plant data are illustrative; they are not optimized for a real installation.
The positive load step has a transient minimum near 48.905 Hz before recovering
to 49.900 Hz. Successful droop verification is not an operational performance
certification. No protection, voltage dynamics or elastic water hammer is modeled.

The existing `OpenHPL.Controllers.DroopControllerPI` is not reused because its
measured-power term cancels, leaving integral action on frequency error alone.
The new controller explicitly retains the independent power-reference and
power-feedback terms. The existing GateActuator and icon frame are reused.

## Verified cases

OpenModelica 1.26.0 with MSL 3.2.3: model check passes with 91 equations and
91 variables. Five simulations pass:

| Test | Predicted frequency | Simulated frequency at 300 s |
| --- | --- | --- |
| +5 MW, R=4%, 100 MW base | 49.900 Hz | 49.89999980 Hz |
| -5 MW, R=4%, 100 MW base | 50.100 Hz | 50.10000038 Hz |
| No load change | 50.000 Hz | 50.00000000 Hz |
| +5 MW, R=5%, 100 MW base | 49.875 Hz | 49.87500040 Hz |
| +5 MW, R=4%, 200 MW base | 49.950 Hz | 49.94999962 Hz |

The 200 MW case checks per-unit scaling. Because H is held at 4 s, increasing
P_base also increases generator inertia; this case does not isolate dynamic
effects of the power base alone. All final power-balance residuals are under 2 W.
Both 4% load-step cases settle within 0.01 Hz of their respective final frequency
about 82 s after the disturbance. The governor's combined error tends to zero
while the frequency error stays nonzero.

Run the reproducible checks with Python, matplotlib and omc on PATH:

```powershell
python path/to/OpenHPL/NewTest/validate_droop.py
```

The script compiles under `Results/Droop/build` and exports five compact CSVs,
`Results/Droop/validation.json`, and `Results/Droop/permanent_droop_response.png`.
Checks include equilibrium before the step, finite and complete results, expected
frequency within 0.001 Hz throughout the final 20 s, power balance within 1000 W,
combined-error residual below 1e-5 pu, gate bounds/rates, and response direction.
The installed parent library emits the same unavailable-OpenIPSL notification as
the isochronous example; this model does not instantiate OpenIPSL components.

## References and next steps

Conceptual reference: P. Kundur, *Power System Stability and Control*, active
power/frequency control and turbine governing. This is an electronic power-feedback
implementation, not mechanical gate-position droop or an exact textbook case.
Also see [NERC's Primary Frequency Control guideline](https://www.nerc.com/globalassets/who-we-are/standing-committees/rstc/rs/primary_frequency_control_reliability_guideline_v_4.0_clean_v3---dr.pdf)
for the droop characteristic and its interpretation.

The independent P_ref input is ready for a future secondary AGC controller.
Multiple-generator load sharing will require a common dynamic electrical system;
it is not demonstrated by this single-generator case.
