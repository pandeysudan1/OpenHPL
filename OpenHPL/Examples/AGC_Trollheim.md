# AGC_Trollheim — OpenHPL active-power/frequency-control benchmark

## 1. Purpose

`OpenHPL.Examples.AGC_Trollheim` is a nonlinear hydropower load-frequency-control example assembled from OpenHPL components. It represents a Trollheim-inspired 150 MW benchmark and applies a 10% system-base load increase from 50% to 60% loading at `t = 5 s`.

The rating and hydraulic geometry are transferred from the user's existing `HydroSyncBridge.jl` Trollheim benchmark. They are **benchmark parameters, not independently field-verified Trollheim plant data**.

$$
P_b=150\;\mathrm{MW},\qquad f_0=50\;\mathrm{Hz},\qquad 0\le t\le65\;\mathrm{s}.
$$

$$
P_L(t)=
\begin{cases}
75\;\mathrm{MW}, & t<5\;\mathrm{s},\\
90\;\mathrm{MW}, & t\ge5\;\mathrm{s}.
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

 generator.f ---> SimpleGovernorAGC ---> turbine.u_t
```

Hydraulic path:

$$
\text{Reservoir}\rightarrow\text{Intake}\rightarrow\text{Penstock}\rightarrow
\text{Turbine}\rightarrow\text{Discharge}\rightarrow\text{Tailrace}.
$$

The first Trollheim implementation also included `OpenHPL.Waterway.SurgeTank`. `checkModel` remained structurally balanced, but the coupled nonlinear steady-state initialization failed in OpenModelica at `t=0`. The validated v1 benchmark therefore omits the surge tank rather than hiding an unresolved initialization problem. A surge-tank version is a planned next-fidelity model using a dedicated equilibrium/warm-start procedure.

---

## 3. Existing models reused

| Role | Model | Function |
|---|---|---|
| Upper/lower hydraulic boundaries | `OpenHPL.Waterway.Reservoir` | Constant-head/elevation boundaries |
| Intake | `OpenHPL.Waterway.Pipe` | Water-column inertia and Darcy friction |
| Penstock | `OpenHPL.Waterway.Pipe` | Nonlinear pressure/flow dynamics |
| Turbine | `OpenHPL.ElectroMech.Turbines.Turbine` | Gate-dependent flow and shaft power |
| Generator | `OpenHPL.ElectroMech.Generators.SimpleGen` | Rotor inertia and electrical power conversion |
| Grid/load | `OpenHPL.ElectroMech.PowerSystem.Grid` | Mechanical-grid/load equivalent |
| Load step | `Modelica.Blocks.Sources.Step` | 75 MW to 90 MW at 5 s |

New reusable control model:

```text
OpenHPL/ElectroMech/PowerSystem/SimpleGovernorAGC.mo
```

New examples:

```text
OpenHPL/Examples/AGC_SMIB.mo
OpenHPL/Examples/AGC_Trollheim.mo
```

---

## 4. Connectors

### Hydraulic

Across variable: pressure/elevation compatibility. Through variable: mass flow.

$$
p_a=p_b,
$$

$$
\dot m_a+\dot m_b=0.
$$

### Mechanical shaft

The turbine, generator, and grid share the rotational flange:

$$
\omega_t=\omega_g=\omega_{grid},
$$

$$
\tau_t+\tau_g+\tau_{grid}=0.
$$

### Signal connections

```text
generator.f    -> governor.f_pu
governor.gate  -> turbine.u_t
loadStep.y     -> grid.Pload
```

---

## 5. Core equations

### Pipe momentum

The OpenHPL conduit model follows momentum balance with nonlinear Darcy friction. A compact form is

$$
\frac{dM}{dt}=F_p+F_g-F_f+\dot M_{conv},
$$

with

$$
F_f\propto f_D L\rho D v|v|.
$$

### Turbine

The simple turbine shaft power is

$$
P_m=\eta_h\,\Delta p_t\,\dot V_t,
$$

with

$$
\eta_h=0.90.
$$

Gate position changes the turbine flow/pressure relation, so the gate-to-power path remains nonlinear.

### Rotor frequency dynamics

A compact energy balance is

$$
J\omega\dot\omega=P_m-P_e-P_{loss}.
$$

Around nominal frequency this is analogous to

$$
2H\dot{\Delta f}_{pu}=\Delta P_m-\Delta P_e-D\Delta f_{pu}.
$$

For this benchmark, the explicit grid self-regulation terms are set to zero:

```text
Lambda = 0
mu     = 0
```

### Governor + AGC

$$
e_f=f_{ref}-f_{pu},
$$

$$
\dot x_i=e_f,
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

Current control parameters:

$$
R=0.05,\qquad T_g=0.30\;\mathrm{s},\qquad K_i=1.5\;\mathrm{s}^{-1}.
$$

---

## 6. Benchmark parameters

| Parameter | Value | Status |
|---|---:|---|
| Plant base | 150 MW | transferred Trollheim benchmark |
| Initial load | 75 MW | 50% loading |
| Final load | 90 MW | 60% loading |
| Load step | 5 s | experiment |
| Frequency | 50 Hz | nominal |
| Poles | 12 | transferred benchmark |
| Total rotor inertia | `2e5 kg m^2` | transferred benchmark |
| Intake elevation drop | 20 m | transferred benchmark |
| Intake length | 500 m | transferred benchmark |
| Intake diameter | 6 m | transferred benchmark |
| Penstock elevation drop | 300 m | transferred benchmark |
| Penstock length | 500 m | transferred benchmark |
| Penstock diameter | 4 m | transferred benchmark |
| Discharge elevation drop | 2 m | transferred benchmark |
| Discharge length | 600 m | transferred benchmark |
| Discharge diameter | 6 m | transferred benchmark |
| Turbine nominal head | 340 m | benchmark value |
| Turbine nominal flow | 50 m3/s | benchmark value |
| Hydraulic efficiency | 0.90 | assumption |
| Droop | 5% | control benchmark |
| Servo time | 0.30 s | control benchmark |
| Integral gain | 1.5 1/s | control benchmark |

Nominal hydraulic consistency:

$$
P_m\approx\eta\rho gHQ
$$

$$
\approx0.90\times1000\times9.81\times340\times50
\approx150\;\mathrm{MW}.
$$

At 50% load, the expected flow is approximately 25 m3/s.

---

## 7. Initial conditions and well-posedness

Required pre-step equilibrium:

$$
f(0)=50\;\mathrm{Hz},
$$

$$
P_m(0)=P_e(0)=75\;\mathrm{MW},
$$

$$
\dot\omega(0)=0.
$$

OpenHPL is configured with steady-state hydraulic initialization and nominal frequency. In addition, the example explicitly imposes

```modelica
initial equation
  der(generator.inertia.w)=0;
```

This condition is essential. Fixing initial speed alone does not guarantee zero rotor acceleration; the initial shaft torque balance must also hold.

The governor uses

$$
\dot x_i(0)=0,\qquad \dot u(0)=0,
$$

allowing the nonlinear initialization solve to determine the gate/integrator operating point needed for 75 MW.

---

## 8. Disturbance physics

At 5 s,

$$
\Delta P_L=15\;\mathrm{MW}=0.10\;pu.
$$

Immediately after the step,

$$
P_m<P_e,
$$

so

$$
\dot\omega<0,
$$

and frequency drops. Positive frequency error opens the guide vane, increasing turbine flow and mechanical power.

Primary droop arrests the frequency decrease. Integral AGC then drives

$$
e_f\rightarrow0,
$$

so ideally

$$
f\rightarrow50\;\mathrm{Hz},\qquad P_m\rightarrow90\;\mathrm{MW}.
$$

---

## 9. Railway/OpenModelica validation workflow

```text
GitHub branch AGC_OpenHPL
        |
        v
railway/Dockerfile
        |
        v
OpenModelica 1.27
        |
        v
checkModel(OpenHPL.Examples.AGC_Trollheim)
        |
        v
simulate 0...65 s with DASSL
        |
        v
CSV forensic checks
        |
        +--> 0...5 s steady-state check
        +--> frequency nadir
        +--> final frequency
        +--> final turbine power
        +--> gate and flow response
```

Runner:

```text
railway/run_trollheim.sh
```

---

## 10. Validation criteria

A run is accepted only when:

1. `checkModel(OpenHPL.Examples.AGC_Trollheim)` succeeds.
2. Equation and variable counts match.
3. OpenModelica initialization converges.
4. Frequency and turbine power remain effectively constant from 0 to 5 s.
5. The load changes from 75 MW to 90 MW at 5 s.
6. Frequency initially falls.
7. Gate, flow and mechanical power respond in the expected direction.
8. AGC restores frequency close to 50 Hz.
9. Mechanical power converges close to 90 MW.

---

## 11. Surge-tank forensic finding

A higher-fidelity version using

```text
Reservoir -> Intake -> SurgeTank -> Penstock -> Turbine
```

was also constructed. Its structural check passed with a balanced equation/variable count, but OpenModelica could not robustly solve the coupled nonlinear initialization system at `t=0`, including the surge-flow/manifold algebraic loop. Changing the surge level seed alone did not resolve it.

This is therefore recorded as a model-development result, not discarded. The proper next step is a two-stage procedure:

1. warm-start or solve the hydraulic equilibrium separately,
2. use the solved surge level, conduit flows, gate, and shaft speed as fixed/consistent initial guesses for the dynamic AGC run.

This is analogous to the warm-up strategy already used in the user's `HydroSyncBridge.jl` Trollheim simulations.

---

## 12. Scope and next step

The present model is an aggregate electromechanical frequency-control benchmark. It does not yet contain the classical synchronous-machine/infinite-bus relation

$$
P_e=\frac{EV}{X}\sin\delta.
$$

Development path:

```text
validated AGC_Trollheim v1
    -> warm-started surge-tank model
    -> detailed synchronous generator
    -> infinite bus / OpenIPSL network
    -> ACE and tie-line AGC
    -> Nordic multi-machine study
```
