# AGC_SMIB benchmark

`OpenHPL.Examples.AGC_SMIB` is a compact nonlinear hydropower load-frequency-control benchmark built on OpenHPL.

## Problem

A 2.5 MW hydro unit supplies an aggregate electrical load. The model is initialized at an exact steady state at 50 Hz and 50% loading (1.25 MW). At `t = 5 s`, load is stepped by +10 percentage points to 60% loading (1.50 MW). The simulation ends at 65 s.

## Architecture

Reservoir -> intake pipe -> penstock -> simple nonlinear turbine -> shaft/inertia -> simple generator -> aggregate grid/load.

Frequency is fed to `SimpleGovernorAGC`, which contains 5% primary droop, a first-order 0.3 s guide-vane servomotor, saturation, and a secondary integral term (`Ki = 1.5 1/s`).

The turbine uses the OpenHPL hydraulic equations, including nonlinear pressure-flow behavior and waterway dynamics. The electrical side is intentionally an aggregate electromechanical load model rather than a detailed dq synchronous-machine/infinite-bus network. This makes `AGC_SMIB` a first LFC/AGC milestone; a later benchmark can replace the electrical side with OpenIPSL synchronous-machine and infinite-bus components.

## Initialization

Hydraulic and governor states use steady-state initialization. The example additionally enforces zero generator rotor acceleration at initialization. This closes the missing torque-balance condition and gives, numerically, `Pm = PL = 1.25 MW` and `f = 50 Hz` before the step.

## Reduced comparison model

The Railway notebook compares the nonlinear OpenHPL response with a four-state benchmark:

- frequency deviation `df`
- guide-vane/governor state `dg`
- turbine mechanical-power state `dPm`
- AGC integral state `xi`

with

`2H d(df)/dt = dPm - dPL - D df`

`Tg d(dg)/dt = -df/R + Ki xi - dg`

`Tt d(dPm)/dt = dg - dPm`

`d(xi)/dt = -df`

For the present OpenHPL grid configuration, `D = 0` is used in the reduced benchmark to match `mu = 0` and `Lambda = 0` in the nonlinear model.

## Railway workflow

`railway/run_model.sh` checks and simulates the Modelica example with OpenModelica. `railway/notebooks/03_agc_smib.ipynb` reads the generated CSV, performs forensic checks, compares the reduced and nonlinear models, and creates frequency, power, guide-vane, and flow plots.

The intended development loop is:

1. formulate and sanity-check a reduced model in Python;
2. implement or modify the OpenHPL component model;
3. check structural balance with OpenModelica;
4. run the nonlinear model on Railway;
5. verify pre-disturbance steady state and post-disturbance physics;
6. compare reduced and nonlinear responses;
7. commit the validated changes to the `AGC_OpenHPL` branch.

## Current parameter status

The present benchmark uses parameters derived from the OpenHPL simple-turbine example and a 2.5 MW study base. It is **not yet a calibrated Trollheim power-plant model**. Trollheim-specific geometry, inertia, turbine characteristics, governor limits, and operating-point data should be introduced only when verified plant data are available.
