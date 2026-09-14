# AGC_Trollheim — OpenHPL active-power/frequency-control benchmark

## 1. Purpose

`OpenHPL.Examples.AGC_Trollheim` is a nonlinear hydropower load-frequency-control example assembled from OpenHPL components. It represents a Trollheim-inspired 150 MW plant benchmark and applies a 10% system-base load increase from 50% to 60% loading at `t = 5 s`.

The model is intended for controller and dynamic-model development. The Trollheim rating and hydraulic geometry are transferred from the existing `HydroSyncBridge.jl` Trollheim benchmark. They are **not claimed to be independently field-verified plant data**.

Simulation interval:

$$
0 \le t \le 65\;\mathrm{s}
$$

Load profile:

$$
P_L(t)=
\begin{cases}
0.50P_b=75\;\mathrm{MW}, & t<5\;\mathrm{s},\\
0.60P_b=90\;\mathrm{MW}, & t\ge5\;\mathrm{s}.
\end{cases}
$$

with

$$
P_b=150\;\mathrm{MW},\qquad f_0=50\;\mathrm{Hz}.
$$

---

## 2. Model architecture

```text
Upper reservoir
      |
      v
 Intake pipe
      |
      v
  Surge tank
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

 frequency pu
      ^
      |
 SimpleGovernorAGC
      |
      +---- guide-vane command ----> turbine.u_t
```

Hydraulic path:

$$
\text{Reservoir}\rightarrow\text{Intake}\rightarrow\text{SurgeTank}
\rightarrow\text{Penstock}\rightarrow\text{Turbine}
\rightarrow\text{Discharge}\rightarrow\text{Tailrace}.
$$

Electromechanical/control path:

$$
P_m\rightarrow\text{shaft/generator}\rightarrow f
\rightarrow\text{Governor+AGC}\rightarrow u_g\rightarrow P_m.
$$

---

## 3. Existing OpenHPL models reused

| Role | Existing OpenHPL model | Purpose |
|---|---|---|
| Upper/lower hydraulic boundaries | `OpenHPL.Waterway.Reservoir` | Constant-head/elevation boundary |
| Head-race tunnel | `OpenHPL.Waterway.Pipe` | Nonlinear water inertia and Darcy friction |
| Surge system | `OpenHPL.Waterway.SurgeTank` | Surge-level and surge-flow dynamics |
| Pressure shaft | `OpenHPL.Waterway.Pipe` | Penstock water-column dynamics |
| Turbine | `OpenHPL.ElectroMech.Turbines.Turbine` | Gate-dependent flow and hydraulic-to-mechanical power |
| Generator | `OpenHPL.ElectroMech.Generators.SimpleGen` | Rotor inertia and electrical loading |
| Grid/load equivalent | `OpenHPL.ElectroMech.PowerSystem.Grid` | Electrical-load torque and frequency coupling |
| Load disturbance | `Modelica.Blocks.Sources.Step` | 75 MW to 90 MW at 5 s |

The new AGC example reuses the component library rather than duplicating hydraulic or shaft models.

---

## 4. New model created for this workflow

### `SimpleGovernorAGC`

Location:

```text
OpenHPL/ElectroMech/PowerSystem/SimpleGovernorAGC.mo
```

This block was introduced for the AGC examples and contains:

- permanent primary droop,
- an integral secondary-control state,
- first-order guide-vane servomotor dynamics,
- gate saturation.

Its signals are:

```text
f_pu  ---> [frequency error] ---> [droop + AGC integral]
                                       |
                                       v
                                  saturation
                                       |
                                       v
                              first-order servo
                                       |
                                       v
                                     gate
```

The governing equations are

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
T_g\dot{u}=u_{sat}-u,
$$

$$
g=u.
$$

The current benchmark parameters are

$$
R=0.05,\qquad T_g=0.30\;\mathrm{s},\qquad K_i=1.5\;\mathrm{s}^{-1}.
$$

---

## 5. Connectors and causality

### Hydraulic connectors

OpenHPL hydraulic components use two-contact ports. At each connection, pressure/elevation compatibility and mass-flow continuity are enforced by Modelica connection equations.

Conceptually,

$$
p_a=p_b,
$$

and

$$
\dot m_a+\dot m_b=0.
$$

The surge tank introduces an additional storage path so that the waterway may satisfy

$$
\dot V_{intake}=\dot V_{penstock}+\dot V_{surge}.
$$

### Mechanical shaft connector

The turbine, generator, and grid share a rotational flange. Shaft angular velocity is common while connector torques sum to zero:

$$
\omega_t=\omega_g=\omega_{grid},
$$

$$
\tau_t+\tau_g+\tau_{grid}=0.
$$

### Signal connectors

The controller loop is causal:

```text
generator.f  -> governor.f_pu
governor.gate -> turbine.u_t
loadStep.y   -> grid.Pload
```

---

## 6. Hydraulic equations

### Pipe momentum

The OpenHPL pipe model represents water-column momentum with nonlinear friction. In compact form,

$$
\frac{dM}{dt}=F_p+F_g-F_f+\dot M,
$$

with Darcy-Weisbach friction approximately

$$
F_f\propto f_D\,L\,\rho D\,v|v|.
$$

The corresponding hydraulic state is primarily the conduit flow rate.

### Surge tank

For a simple surge tank,

$$
\frac{dm}{dt}=\rho\dot V_s,
$$

$$
\frac{d(mv_s)}{dt}=F_p-F_g-F_f+\dot m v_s,
$$

and

$$
m=\rho A_s\frac{h_s}{\cos\theta}.
$$

Thus the surge level $h_s$ and surge flow are dynamic states.

### Turbine

The simple OpenHPL turbine computes hydraulic shaft power from

$$
P_m=\eta_h\,\Delta p_t\,\dot V_t.
$$

For this benchmark,

$$
\eta_h=0.90.
$$

The turbine's valve relation links gate opening, pressure drop, and flow, so the gate-to-power path is nonlinear.

---

## 7. Generator/grid frequency dynamics

The rotor dynamics follow angular momentum balance. A compact energy-form swing equation is

$$
J\omega\dot\omega=P_m-P_e-P_{loss}.
$$

Equivalently, in per-unit frequency form around nominal speed,

$$
2H\dot{\Delta f}_{pu}=\Delta P_m-\Delta P_e-D\Delta f_{pu}.
$$

The present Trollheim benchmark sets the explicit grid self-regulation terms to zero (`Lambda=0`, `mu=0`) so the response is dominated by turbine-governor and rotor dynamics.

Frequency is obtained from the generator per-unit speed:

$$
f=50\,f_{pu}.
$$

---

## 8. Trollheim benchmark parameter table

| Parameter | Value | Source/status |
|---|---:|---|
| Plant base power | 150 MW | transferred from `HydroSyncBridge.jl` Trollheim benchmark |
| Initial load | 75 MW | 50% loading |
| Final load | 90 MW | 60% loading |
| Load step time | 5 s | experiment definition |
| Nominal frequency | 50 Hz | Nordic nominal |
| Generator poles | 12 | transferred benchmark |
| Total rotor inertia `J_total` | `2e5 kg m^2` | transferred benchmark |
| Intake elevation drop | 20 m | transferred benchmark |
| Intake length | 500 m | transferred benchmark |
| Intake diameter | 6 m | transferred benchmark |
| Surge shaft height | 80 m | transferred benchmark |
| Surge shaft length | 80 m | transferred benchmark |
| Surge shaft diameter | 4 m | transferred benchmark |
| Penstock elevation drop | 300 m | transferred benchmark |
| Penstock length | 500 m | transferred benchmark |
| Penstock diameter | 4 m | transferred benchmark |
| Discharge elevation drop | 2 m | transferred benchmark |
| Discharge length | 600 m | transferred benchmark |
| Discharge diameter | 6 m | transferred benchmark |
| Turbine nominal head | 340 m | benchmark/derived nominal value |
| Turbine nominal flow | 50 m3/s | benchmark engineering value consistent with ~150 MW at ~340 m and 90% efficiency |
| Hydraulic efficiency | 0.90 | benchmark assumption |
| Droop | 5% | controller benchmark |
| Servo time constant | 0.30 s | controller benchmark |
| AGC integral gain | 1.5 1/s | controller benchmark |

The approximate consistency check for nominal hydraulic power is

$$
P_h=\rho g H Q
$$

and shaft power is

$$
P_m=\eta_h\rho g H Q.
$$

For $H=340$ m, $Q=50$ m3/s and $\eta_h=0.90$,

$$
P_m\approx0.90\times1000\times9.81\times340\times50
\approx150\;\mathrm{MW}.
$$

---

## 9. Initial conditions and well-posed initialization

The required pre-disturbance condition is

$$
f(0)=50\;\mathrm{Hz},
$$

$$
P_m(0)=P_e(0)=75\;\mathrm{MW},
$$

$$
\dot\omega(0)=0,
$$

with all hydraulic storage states in steady state.

The model therefore uses

```modelica
inner OpenHPL.Data data(SteadyState=true, ...);
```

and explicitly adds

```modelica
initial equation
  der(generator.inertia.w)=0;
```

This last condition is important: fixing nominal rotor speed alone does not guarantee zero rotor acceleration. The torque/power balance must also be part of initialization.

The governor states use

$$
\dot{x}_i(0)=0,
$$

$$
\dot u(0)=0,
$$

so the nonlinear initialization problem solves the consistent gate bias/integrator value required to support the 75 MW operating point.

---

## 10. Disturbance sequence

### Before 5 s

The system should satisfy approximately

$$
P_m=P_L=75\;\mathrm{MW},\qquad f=50\;\mathrm{Hz}.
$$

### At 5 s

The electrical load jumps by

$$
\Delta P_L=15\;\mathrm{MW}=0.10\;pu.
$$

Initially the rotor supplies the deficit:

$$
J\omega\dot\omega<0.
$$

Therefore frequency falls, producing positive controller error

$$
e_f=f_{ref}-f>0.
$$

The governor increases guide-vane opening, water flow and turbine mechanical power.

### Long-term response

Primary droop arrests the initial frequency decline. Integral AGC then drives

$$
e_f\rightarrow0
$$

and hence

$$
f\rightarrow50\;\mathrm{Hz},\qquad P_m\rightarrow90\;\mathrm{MW}.
$$

---

## 11. Files in this workflow

```text
OpenHPL/
  ElectroMech/
    PowerSystem/
      SimpleGovernorAGC.mo        # new reusable controller block
  Examples/
    AGC_SMIB.mo                   # 2.5 MW generic validation benchmark
    AGC_Trollheim.mo              # 150 MW Trollheim-inspired benchmark
    AGC_Trollheim.md              # this design/verification document

railway/
  Dockerfile                      # OpenModelica/Jupyter environment
  run_model.sh                    # OMC simulation runner
  start.sh                        # simulation + notebook startup
  notebooks/
    03_agc_smib.ipynb             # reduced vs nonlinear comparison workflow
```

---

## 12. Validation checklist

The model is considered validated for this benchmark only if all of the following hold:

1. `checkModel(OpenHPL.Examples.AGC_Trollheim)` succeeds.
2. Equation and variable counts are balanced.
3. OpenModelica initialization converges.
4. The interval `0–5 s` remains stationary within numerical tolerance.
5. The load changes exactly from 75 MW to 90 MW at 5 s.
6. Frequency initially declines after the positive load step.
7. Governor gate and turbine power increase after the frequency decline.
8. AGC restores frequency close to 50 Hz by the end of the run.
9. Mechanical power approaches 90 MW in the final steady state.
10. Surge level and flow remain physically finite and continuous.

---

## 13. Interpretation and model scope

This example is an **aggregate electromechanical frequency-control model**. The electrical side does not yet contain a detailed synchronous-machine voltage model or the classical infinite-bus power-angle relation

$$
P_e=\frac{EV}{X}\sin\delta.
$$

A natural next extension is therefore

```text
AGC_Trollheim
   -> detailed synchronous generator
   -> infinite bus / OpenIPSL network
   -> ACE/tie-line AGC
   -> Nordic multi-machine study
```

The present example is the nonlinear hydraulic/control benchmark that should be kept as a simpler reference case while electrical-network fidelity is increased.
