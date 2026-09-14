# AGC_Trollheim — OpenHPL active-power/frequency-control benchmark

## 1. Purpose

`OpenHPL.Examples.AGC_Trollheim` is a nonlinear hydropower load-frequency-control benchmark built from OpenHPL components. It represents a **Trollheim-inspired 150 MW plant model** and applies a 10% system-base active-power load increase from 50% to 60% loading at `t = 5 s`.

The plant rating and hydraulic geometry are transferred from the user's existing `HydroSyncBridge.jl` Trollheim benchmark. They are **benchmark parameters, not independently field-verified Trollheim HPP data**.

$$
P_b=150\;\mathrm{MW},\qquad f_0=50\;\mathrm{Hz},\qquad 0\le t\le65\;\mathrm{s}.
$$

The load disturbance is

$$
P_L(t)=
\begin{cases}
0.50P_b=75\;\mathrm{MW}, & t<5\;\mathrm{s},\\[4pt]
0.60P_b=90\;\mathrm{MW}, & t\ge5\;\mathrm{s}.
\end{cases}
$$

---

## 2. Validated v1 architecture

```text
Upper reservoir
      |
      v
  Intake pipe
      |
      v
    Penstock
      |
      v
 Simple turbine ---- mechanical shaft ---- SimpleGen ---- Grid/load
      |
      v
 Discharge pipe
      |
      v
 Tail reservoir

 generator.f
      |
      v
 SimpleGovernorAGC
      |
      +----------------------------> turbine.u_t
```

Hydraulic path:

$$
\text{Reservoir}\rightarrow\text{Intake}\rightarrow\text{Penstock}
\rightarrow\text{Turbine}\rightarrow\text{Discharge}\rightarrow\text{Tailrace}.
$$

Electromechanical/control path:

$$
P_m\rightarrow\text{shaft/generator}\rightarrow f
\rightarrow\text{Governor+AGC}\rightarrow u_g\rightarrow P_m.
$$

A first higher-fidelity version also included `OpenHPL.Waterway.SurgeTank`. Its structural model was balanced, but OpenModelica could not robustly solve the coupled surge-flow/manifold initialization at `t=0`. The validated v1 benchmark therefore omits the surge tank rather than hiding an unresolved initialization problem. Section 12 documents that finding and the planned warm-start solution.

---

## 3. Existing OpenHPL models reused

| Role | Existing model | Function |
|---|---|---|
| Upper hydraulic boundary | `OpenHPL.Waterway.Reservoir` | Constant-head/elevation source |
| Intake | `OpenHPL.Waterway.Pipe` | Water-column inertia and Darcy friction |
| Penstock | `OpenHPL.Waterway.Pipe` | Nonlinear pressure/flow dynamics |
| Turbine | `OpenHPL.ElectroMech.Turbines.Turbine` | Gate-dependent flow and hydraulic-to-shaft power |
| Generator | `OpenHPL.ElectroMech.Generators.SimpleGen` | Rotor inertia and electrical loading |
| Grid/load equivalent | `OpenHPL.ElectroMech.PowerSystem.Grid` | Electrical load torque and common shaft frequency |
| Tail hydraulic boundary | `OpenHPL.Waterway.Reservoir` | Tailwater boundary |
| Disturbance | `Modelica.Blocks.Sources.Step` | 75 MW to 90 MW step at 5 s |

The example intentionally reuses OpenHPL's physical components rather than introducing duplicated hydraulic equations.

---

## 4. New model created for the AGC workflow

### `SimpleGovernorAGC`

Location:

```text
OpenHPL/ElectroMech/PowerSystem/SimpleGovernorAGC.mo
```

The block contains:

- permanent primary-frequency droop,
- an integral secondary-control state,
- gate-command saturation,
- a first-order guide-vane servomotor.

Signal path:

```text
f_pu ---> frequency error ---> droop + integral AGC ---> limiter ---> servo ---> gate
```

The equations are

$$
e_f=f_{ref}-f_{pu},
$$

$$
\dot{x}_i=e_f,
$$

$$
u_{cmd}=u_{bias}+\frac{e_f}{R}+K_i x_i,
$$

$$
u_{sat}=\operatorname{clip}(u_{cmd},u_{min},u_{max}),
$$

$$
T_g\dot u=u_{sat}-u,
$$

$$
g=u.
$$

For the final verified Trollheim run,

$$
\boxed{R=0.50},\qquad
\boxed{T_g=0.30\;\mathrm{s}},\qquad
\boxed{K_i=0.10\;\mathrm{s}^{-1}}.
$$

The large permanent droop value is deliberate in this benchmark. The transferred inertia and long waterway produce strong inverse-response dynamics, so the much more aggressive `AGC_SMIB` gains are not stable when copied directly to the Trollheim-scale model.

---

## 5. Connectors and component coupling

### 5.1 Hydraulic connectors

OpenHPL hydraulic components use across/through variables. At a hydraulic connection, pressure compatibility and mass continuity are enforced through Modelica connection equations. Conceptually,

$$
p_a=p_b,
$$

and

$$
\dot m_a+\dot m_b=0.
$$

Thus the whole waterway forms one coupled nonlinear hydraulic DAE rather than a chain of independent transfer functions.

### 5.2 Mechanical connector

The turbine, generator and grid are connected through rotational flanges. At the ideal common shaft,

$$
\omega_t=\omega_g=\omega_{grid},
$$

while connector torques balance:

$$
\tau_t+\tau_g+\tau_{grid}=0.
$$

### 5.3 Control-signal connectors

```text
generator.f    -> governor.f_pu
governor.gate  -> turbine.u_t
loadStep.y     -> grid.Pload
```

The hydraulic/mechanical side is acausal through physical connectors; the governor path is causal signal flow.

---

## 6. Core physical equations

### 6.1 Waterway momentum

The OpenHPL pipe model represents water-column momentum with nonlinear friction. In compact form,

$$
\frac{dM}{dt}=F_p+F_g-F_f+F_{conv},
$$

with Darcy-Weisbach friction approximately proportional to

$$
F_f\propto f_D\,L\,\rho D\,v|v|.
$$

The important point for AGC studies is that flow cannot change instantaneously. Water inertia therefore creates a dynamic gate-to-power path.

### 6.2 Turbine power

The simple OpenHPL turbine computes shaft power as

$$
P_m=\eta_h\,\Delta p_t\,\dot V_t,
$$

where

$$
\eta_h=0.90.
$$

Gate opening modifies the nonlinear flow/pressure relation. Consequently, opening the guide vane does not imply an instantaneous proportional rise in shaft power. The Railway simulations show the expected hydro inverse response immediately after the disturbance.

### 6.3 Rotor dynamics

The mechanical energy balance is

$$
J\omega\dot\omega=P_m-P_e-P_{loss}.
$$

Around nominal frequency this is analogous to the swing equation

$$
2H\dot{\Delta f}_{pu}=\Delta P_m-\Delta P_e-D\Delta f_{pu}.
$$

For this benchmark the explicit load-frequency terms are disabled:

```text
Lambda = 0
mu     = 0
```

so the response primarily exposes rotor inertia, waterway dynamics and governor/AGC action.

Frequency output is

$$
f=50 f_{pu}.
$$

---

## 7. Benchmark parameter table

| Parameter | Value | Source/status |
|---|---:|---|
| Plant power base | 150 MW | transferred Trollheim benchmark |
| Initial load | 75 MW | 50% loading |
| Final load | 90 MW | 60% loading |
| Load step time | 5 s | benchmark definition |
| Nominal frequency | 50 Hz | Nordic nominal |
| Generator poles | 12 | transferred benchmark |
| Total rotor inertia `J_total` | `2e5 kg m^2` | transferred benchmark |
| Turbine inertia used | `1e5 kg m^2` | one half of total |
| Generator inertia used | `1e5 kg m^2` | one half of total |
| Intake elevation drop | 20 m | transferred benchmark |
| Intake length | 500 m | transferred benchmark |
| Intake diameter | 6 m | transferred benchmark |
| Penstock elevation drop | 300 m | transferred benchmark |
| Penstock length | 500 m | transferred benchmark |
| Penstock diameter | 4 m | transferred benchmark |
| Discharge elevation drop | 2 m | transferred benchmark |
| Discharge length | 600 m | transferred benchmark |
| Discharge diameter | 6 m | transferred benchmark |
| Turbine nominal head | 340 m | benchmark engineering value |
| Turbine nominal flow | 50 m3/s | benchmark engineering value |
| Hydraulic efficiency | 0.90 | benchmark assumption |
| Initial flow guess | 25 m3/s | 50% operating-point guess |
| Permanent droop `R` | 0.50 | nonlinear-tuning result |
| Servo time constant `T_g` | 0.30 s | controller benchmark |
| Integral gain `K_i` | 0.10 1/s | nonlinear-tuning result |
| Gate limits | 0.05–1.00 pu | controller constraint |

A nominal consistency check is

$$
P_m\approx\eta\rho gHQ,
$$

and therefore

$$
P_m\approx
0.90\times1000\times9.81\times340\times50
\approx150\;\mathrm{MW}.
$$

The solved 50% operating point has a turbine flow of approximately

$$
\dot V_t(0)=23.1783\;\mathrm{m^3/s}.
$$

---

## 8. Initial conditions and well-posedness

The required pre-disturbance equilibrium is

$$
f(0)=50\;\mathrm{Hz},
$$

$$
P_m(0)=P_e(0)=75\;\mathrm{MW},
$$

$$
\dot\omega(0)=0.
$$

The model uses steady-state hydraulic initialization through `OpenHPL.Data` and explicitly imposes

```modelica
initial equation
  der(generator.inertia.w)=0;
```

This condition is important. Specifying nominal initial speed alone does not guarantee a stationary operating point: a nonzero shaft-torque imbalance can still cause immediate rotor acceleration.

The governor's steady initialization implies

$$
\dot{x}_i(0)=0,
$$

$$
\dot u(0)=0,
$$

so the nonlinear initialization problem determines the consistent gate and AGC integrator state.

### Verified pre-step values

| Quantity | `t = 0 s` | `t = 4.9 s` |
|---|---:|---:|
| Frequency | 50.000000 Hz | 49.999832 Hz |
| Turbine power | 75.000000 MW | 74.999564 MW |
| Electrical load | 75.000000 MW | 75.000000 MW |
| Gate | 0.446340 pu | 0.446347 pu |
| Turbine flow | 23.178261 m3/s | 23.178451 m3/s |

For the whole `0–5 s` interval, Railway measured

$$
\max(f)-\min(f)=1.71\times10^{-4}\;\mathrm{Hz},
$$

and

$$
\max(P_m)-\min(P_m)=5.02\times10^{-4}\;\mathrm{MW}.
$$

This verifies the intended steady pre-disturbance operating condition to numerical tolerance.

---

## 9. Disturbance response

At `t = 5 s`,

$$
\Delta P_L=15\;\mathrm{MW}=0.10\;pu.
$$

Initially,

$$
P_m<P_e,
$$

so

$$
\dot\omega<0,
$$

and frequency falls. The governor responds by opening the guide vane. Because of water inertia, mechanical power initially changes more slowly than the gate command.

Selected nonlinear OpenHPL/Railway values are:

| Time [s] | Frequency [Hz] | Turbine power [MW] | Load [MW] | Gate [pu] | Flow [m3/s] |
|---:|---:|---:|---:|---:|---:|
| 5.00 | 49.999829 | 74.999570 | 75 | 0.446347 | 23.178459 |
| 5.10 | 49.862109 | 74.774325 | 90 | 0.447170 | 23.183691 |
| 5.20 | 49.720748 | 74.339199 | 90 | 0.449350 | 23.213759 |
| 5.50 | 49.273102 | 73.471254 | 90 | 0.461169 | 23.526786 |
| 6.00 | 48.526262 | 75.065923 | 90 | 0.489047 | 24.641352 |
| 7.00 | 47.503292 | 83.909308 | 90 | 0.540325 | 27.331062 |
| 10.00 | 48.111616 | 93.467307 | 90 | 0.545280 | 28.504703 |
| 20.00 | 48.895138 | 90.620646 | 90 | 0.539511 | 28.012977 |
| 40.00 | 49.627165 | 90.220357 | 90 | 0.537179 | 27.891007 |
| 65.00 | 49.903676 | 90.056713 | 90 | 0.536310 | 27.844067 |

Frequency nadir:

$$
\boxed{f_{nadir}=47.30558\;\mathrm{Hz}}
$$

at

$$
\boxed{t_{nadir}=7.70\;\mathrm{s}}.
$$

End-of-run values:

$$
\boxed{f(65)=49.90368\;\mathrm{Hz}},
$$

$$
\boxed{P_m(65)=90.05671\;\mathrm{MW}},
$$

$$
\boxed{u_g(65)=0.53631},
$$

$$
\boxed{\dot V_t(65)=27.84407\;\mathrm{m^3/s}}.
$$

Thus the model is stable and secondary control is restoring nominal frequency; the remaining 0.096 Hz error at 65 s is consistent with deliberately slow integral action. A longer simulation approaches the nominal equilibrium further.

The deep nadir should **not** be interpreted as a prediction of actual Trollheim grid frequency. This benchmark isolates a single low-inertia plant against an aggregate load and intentionally omits the much larger Nordic synchronous-area inertia and frequency response.

---

## 10. Forensic governor tuning

Copying the small `AGC_SMIB` gains directly to the Trollheim-scale case did not work. This is an important modeling result.

Approximate transferred inertia constant:

$$
H\approx\frac{\tfrac12J\omega_m^2}{P_b}\approx1.83\;\mathrm{s}.
$$

An approximate water starting time obtained from the transferred waterways and initial flow is around

$$
T_w\approx0.55\;\mathrm{s}.
$$

A classical reduced hydro turbine approximation is

$$
G_h(s)=\frac{1-T_ws}{1+\tfrac12T_ws},
$$

which explicitly contains the hydro non-minimum-phase zero. This explains why aggressive gate action can initially reduce mechanical power.

### Tuning trail

| `R` | `K_i` [1/s] | Nonlinear result |
|---:|---:|---|
| 0.05 | 1.50 | unstable/poorly damped; gate saturation; nadir ≈43.25 Hz |
| 0.20 | 0.15 | still long-period oscillatory; unacceptable |
| 0.50 | 0.05 | stable baseline; `f(65)≈49.50 Hz` |
| **0.50** | **0.10** | **selected v1 tuning; stable; `f(65)=49.904 Hz`** |

The purpose of this tuning is not to claim optimal plant control. It establishes a numerically stable and physically interpretable benchmark for subsequent FCR/AGC controller-design work.

---

## 11. Railway/OpenModelica verification

Execution chain:

```text
GitHub: AGC_OpenHPL
       |
       v
railway/Dockerfile
       |
       v
OpenModelica 1.27.0
       |
       v
checkModel(OpenHPL.Examples.AGC_Trollheim)
       |
       v
DASSL simulation, 0...65 s
       |
       v
AGC_Trollheim_res.csv
       |
       v
Python forensic checks / Jupyter
```

Runner:

```text
railway/run_trollheim.sh
```

Verified OpenModelica structural result:

```text
279 equations
279 variables
183 trivial equations
```

Initialization finished successfully using **3 homotopy steps**, and the DASSL simulation completed successfully.

OpenModelica still reports generic mixed initialization-specification warnings inherited from the component hierarchy (`not fully specified` / `over specified`). They do not prevent initialization or integration in this benchmark, but they remain a cleanup item for the library.

---

## 12. Surge-tank forensic finding

A higher-fidelity variant was built as

```text
Reservoir -> Intake -> SurgeTank -> Penstock -> Turbine
```

and passed structural checking with

```text
314 equations
314 variables
```

However, OpenModelica could not robustly solve the coupled nonlinear initialization system at `t=0`. The failing nonlinear loop involves the surge branch and manifold pressure/flow equilibrium. Switching the surge tank from formal steady-state initialization to a simple seeded level/zero-flow initialization did not solve the global initialization problem.

This result is retained as part of the model-development record. The planned solution is a two-stage warm-start procedure:

1. solve or simulate the hydraulic subsystem to an equilibrium,
2. extract conduit flows, surge level, gate position and shaft speed,
3. use those values as consistent initial states/guesses for the 65 s AGC disturbance case.

That approach is consistent with the warm-up workflow already used in the user's `HydroSyncBridge.jl` Trollheim simulations.

---

## 13. Files created/used

```text
OpenHPL/
  ElectroMech/
    PowerSystem/
      SimpleGovernorAGC.mo

  Examples/
    AGC_SMIB.mo
    AGC_Trollheim.mo
    AGC_Trollheim.md
    package.order

railway/
  Dockerfile
  start.sh
  run_model.sh
  run_trollheim.sh
  notebooks/
    03_agc_smib.ipynb
```

---

## 14. Validation checklist

| Check | Status |
|---|---|
| `checkModel(AGC_Trollheim)` | PASS |
| equations = variables | PASS, 279 = 279 |
| OpenModelica initialization | PASS |
| homotopy initialization | PASS, 3 steps |
| 0–5 s steady operating point | PASS |
| load 75 → 90 MW at 5 s | PASS |
| frequency initially falls | PASS |
| guide vane opens | PASS |
| turbine flow rises | PASS |
| turbine power approaches 90 MW | PASS |
| sustained instability eliminated | PASS |
| frequency recovery toward 50 Hz | PASS, 49.904 Hz at 65 s |
| surge-tank version | NOT YET — requires warm start |

---

## 15. Scope and next development steps

The current grid is an aggregate electromechanical load equivalent. It is not yet the classical electrical SMIB model

$$
P_e=\frac{EV}{X}\sin\delta.
$$

The recommended development path is

```text
AGC_Trollheim v1 (this benchmark)
        |
        +--> warm-started surge-tank waterway
        |
        +--> transient-droop / lead-lag hydro governor
        |
        +--> detailed synchronous generator
        |
        +--> infinite bus / OpenIPSL network
        |
        +--> ACE + tie-line AGC
        |
        +--> Nordic multi-machine study
```

This v1 model should remain in the repository as the simple nonlinear reference case while higher electrical and hydraulic fidelity is added.
