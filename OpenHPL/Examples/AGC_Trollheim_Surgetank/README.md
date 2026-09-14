# AGC_Trollheim_Surgetank

## 1. Purpose

`OpenHPL.Examples.AGC_Trollheim_Surgetank` extends the validated Trollheim AGC benchmark by inserting a surge tank between the intake and penstock.

The validated model is:

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
 Simple turbine ---- shaft ---- SimpleGen ---- Grid / load
      |
      v
 Discharge pipe
      |
      v
 Tail reservoir

 generator.f ---> Governor + AGC ---> turbine.u_t
```

The experiment is

$$
P_b = 150\;\mathrm{MW},\qquad f_0=50\;\mathrm{Hz},
$$

with

$$
P_L(t)=
\begin{cases}
75\;\mathrm{MW}, & t<5\;\mathrm{s},\\
90\;\mathrm{MW}, & t\ge5\;\mathrm{s}.
\end{cases}
$$

The plant parameters are transferred benchmark values from the user's Trollheim/HydroSyncBridge work. They are not independently field-verified Trollheim plant data.

---

## 2. Why the original surge-tank initialization failed

The first surge-tank model was structurally balanced, but OpenModelica failed during initialization.

The important discovery was that this was **not simply a matter of increasing the number of Newton iterations**.

The original formulation mixed several steady-state constraints such as

$$
\dot m_{pipe}=0,
$$

with nonlinear surge-tank momentum equations and free governor/shaft states in one global initialization problem.

OpenModelica could follow the global homotopy path toward

$$
\lambda=1,
$$

but the final state could still violate one of the separately imposed derivative conditions.

Examples observed during debugging included

$$
\dot m_{surge}\ne 0
$$

and later

$$
\dot m_{penstock}\ne 0.
$$

This showed that the continuation algorithm itself was working, while the initialization formulation was inconsistent or poorly conditioned.

---

## 3. Modelica homotopy strategy

Modelica defines

```modelica
homotopy(actual = ..., simplified = ...)
```

so that the initialization solver can start from a simpler system and continuously move toward the true nonlinear equations.

Conceptually,

$$
F(x,\lambda)=0,
$$

where

$$
F(x,0)=F_{simplified}(x)
$$

and

$$
F(x,1)=F_{actual}(x).
$$

For the surge tank, the nonlinear branch momentum/friction relation was given a simpler initialization form so OpenModelica could use global homotopy.

The final validated case still benefits from OpenModelica homotopy: initialization completed successfully using **3 homotopy steps**.

---

## 4. The key fix: transfer a known equilibrium

Rather than asking the global nonlinear solver to discover every initial state simultaneously, the already validated no-surge Trollheim model was used to obtain the exact 75 MW hydraulic operating point.

Railway/OpenModelica gave

$$
Q_0 = 23.178260892\;\mathrm{m^3/s},
$$

$$
u_{g,0}=0.446339858,
$$

and the intake/penstock junction pressure

$$
p_j = 685962.295\;\mathrm{Pa}.
$$

OpenHPL uses gauge pressure with

$$
p_a=0,
$$

$$
\rho=999.65\;\mathrm{kg/m^3},
$$

so the physically consistent steady surge level is

$$
h_{s,0}=\frac{p_j-p_a}{\rho g}.
$$

Numerically,

$$
\boxed{h_{s,0}=69.973178\;\mathrm m}.
$$

At steady state the surge branch must carry essentially zero flow:

$$
\boxed{Q_{s,0}=0}.
$$

Therefore the initialized hydraulic state is

$$
\boxed{
Q_{intake,0}=Q_{penstock,0}=Q_{turbine,0}=23.178260892\;\mathrm{m^3/s}
}
$$

with

$$
\boxed{Q_{surge,0}=0}.
$$

This equilibrium transfer was the decisive step.

---

## 5. Models in this package

### `HomotopySurgeTank.mo`

Surge-tank variant with an explicit simplified nonlinear initialization relation for Modelica homotopy studies.

### `InitializedGovernorAGC.mo`

Governor/AGC variant that anchors the gate near the already known operating point during initialization. This prevents the global nonlinear solver from escaping through unrealistic gate values.

### `TrollheimAGCSurgeTank.mo`

Direct global-homotopy development model.

### `TrollheimAGCSurgeTankWarmStart.mo`

Dynamic preconditioning experiment. It runs a long pre-disturbance interval before the 5 s load step. This model demonstrated that simple dynamic warm-up alone may require a much longer settling interval because the surge mode is lightly damped.

### `TrollheimAGCSurgeTankInitialized.mo`

**Validated benchmark.** This model uses the equilibrium transferred from the no-surge Trollheim case.

---

## 6. Main equations

### Pipe momentum

A compact conduit equation is

$$
L\frac{d\dot m}{dt}
=
A\left(p_i+\rho gH-p_o\right)-F_f,
$$

where the friction term is nonlinear in flow.

### Surge-tank mass balance

For surge-tank cross-sectional area $A_s$,

$$
A_s\frac{dh_s}{dt}=Q_s.
$$

Thus at hydraulic steady state,

$$
Q_s=0
\quad\Rightarrow\quad
\frac{dh_s}{dt}=0.
$$

### Surge branch momentum

A compact representation is

$$
L_s\rho\frac{dQ_s}{dt}
=
A_s\left(p_j-p_a-\rho gh_s\right)-F_{f,s}(Q_s).
$$

At steady state and zero branch flow,

$$
p_j-p_a=\rho gh_s.
$$

### Turbine power

$$
P_m=\eta_h\,\Delta p_t\,Q_t.
$$

### Rotor dynamics

$$
J\omega\dot\omega=P_m-P_e-P_{loss}.
$$

### Governor and AGC

$$
e_f=f_{ref}-f_{pu},
$$

$$
\dot x_i=e_f,
$$

$$
u_{cmd}=u_{bias}+\frac{e_f}{R}+K_ix_i,
$$

$$
T_g\dot u=u_{sat}-u.
$$

The Trollheim benchmark uses the conservative stable tuning

$$
R=0.50,\qquad T_g=0.30\;\mathrm{s},\qquad K_i=0.10\;\mathrm{s^{-1}}.
$$

---

## 7. Structural verification

OpenModelica reports for the validated surge-tank case:

```text
299 equations
299 variables
192 trivial equations
```

Therefore

$$
\boxed{N_{eq}=N_{var}=299}.
$$

The model initializes successfully with **3 homotopy steps** and completes the full 0–65 s DASSL simulation.

---

## 8. Pre-disturbance validation

The 0–5 s interval is effectively steady.

Measured Railway ranges are:

$$
\Delta f_{0-5s}=1.0930\times10^{-4}\;\mathrm{Hz},
$$

$$
\Delta P_{m,0-5s}=3.3213\times10^{-4}\;\mathrm{MW},
$$

$$
\Delta h_{s,0-5s}=3.2226\times10^{-4}\;\mathrm m,
$$

$$
\Delta Q_{s,0-5s}=2.3286\times10^{-3}\;\mathrm{m^3/s}.
$$

At $t=0$,

| Quantity | Value |
|---|---:|
| Frequency | 50.000000 Hz |
| Turbine power | 75.000000 MW |
| Guide vane | 0.44633986 pu |
| Turbine flow | 23.17826089 m3/s |
| Surge level | 69.97317801 m |
| Surge flow | 0.00000000 m3/s |

This verifies a well-posed initial equilibrium.

---

## 9. 75 MW → 90 MW response

At $t=5$ s the electrical load increases by

$$
\Delta P_L=15\;\mathrm{MW}=0.10\;pu.
$$

Selected nonlinear OpenHPL/Railway samples are:

| Time [s] | Frequency [Hz] | Turbine power [MW] | Gate [pu] | Turbine flow [m3/s] | Surge level [m] | Surge flow [m3/s] |
|---:|---:|---:|---:|---:|---:|---:|
| 0.0 | 50.000000 | 75.000000 | 0.446340 | 23.178261 | 69.973178 | 0.000000 |
| 5.0 | 49.999890 | 74.999685 | 0.446344 | 23.178381 | 69.972852 | -0.002346 |
| 5.1 | 49.862195 | 74.783720 | 0.447167 | 23.184568 | 69.972823 | -0.007136 |
| 5.5 | 49.279204 | 73.865466 | 0.461094 | 23.566218 | 69.969268 | -0.297588 |
| 6.0 | 48.566767 | 76.091924 | 0.488197 | 24.724438 | 69.941134 | -1.175974 |
| 7.0 | 47.655898 | 84.874782 | 0.535364 | 27.267311 | 69.768373 | -3.067733 |
| 10.0 | 48.030915 | 92.247478 | 0.546059 | 28.407148 | 68.893665 | -3.124241 |
| 20.0 | 48.861108 | 90.771368 | 0.541753 | 28.106081 | 69.011621 | 3.174126 |
| 40.0 | 49.624892 | 90.069094 | 0.536269 | 27.843925 | 70.115559 | -3.979999 |
| 65.0 | 49.981886 | 90.074933 | 0.533357 | 27.743629 | 71.677443 | 1.004791 |

Frequency nadir:

$$
\boxed{f_{nadir}=47.492993\;\mathrm{Hz}}
$$

at

$$
\boxed{t_{nadir}=7.72\;\mathrm{s}}.
$$

At 65 s,

$$
\boxed{f(65)=49.981886\;\mathrm{Hz}},
$$

$$
\boxed{P_m(65)=90.074933\;\mathrm{MW}},
$$

$$
\boxed{h_s(65)=71.677443\;\mathrm m},
$$

$$
\boxed{Q_s(65)=1.004791\;\mathrm{m^3/s}}.
$$

The surge mode is still visible at 65 s, which is physically meaningful and distinct from an initialization error.

---

## 10. Comparison with the no-surge benchmark

The previously validated no-surge model gave

$$
f_{nadir,no\ surge}=47.305580\;\mathrm{Hz}.
$$

The surge-tank model gives

$$
f_{nadir,surge}=47.492993\;\mathrm{Hz}.
$$

Therefore the modeled surge tank improves the nadir by approximately

$$
\boxed{\Delta f_{nadir}=0.187414\;\mathrm{Hz}}.
$$

At 65 s:

| Model | Frequency [Hz] | Turbine power [MW] |
|---|---:|---:|
| No surge tank | 49.903676 | 90.056713 |
| With surge tank | 49.981886 | 90.074933 |

The surge tank changes both the short-term hydraulic energy exchange and the longer-period waterway mode.

---

## 11. Main modeling lesson

The decisive improvement was not simply increasing the homotopy iteration limit.

The robust sequence was:

```text
validated no-surge equilibrium
        |
        v
extract Q0, gate0 and junction pressure
        |
        v
compute surge level from hydrostatics
        |
        v
set Qsurge,0 = 0
        |
        v
initialize detailed surge model
        |
        v
Modelica/OpenModelica homotopy
        |
        v
full nonlinear 0...65 s simulation
```

Mathematically,

$$
(Q_0,u_0,p_j)
\rightarrow
\left(h_{s,0}=\frac{p_j-p_a}{\rho g},\;Q_{s,0}=0\right)
\rightarrow
x_0^{consistent}.
$$

This makes homotopy a continuation tool around a physically meaningful equilibrium instead of asking the solver to invent the complete plant operating point.

---

## 12. Railway validation workflow

```text
GitHub: AGC_OpenHPL
        |
        v
Docker / OpenModelica 1.27
        |
        v
checkModel(...TrollheimAGCSurgeTankInitialized)
        |
        v
299 equations = 299 variables
        |
        v
3 homotopy initialization steps
        |
        v
DASSL 0...65 s
        |
        v
CSV forensic checks
```

The Railway run accepts the case only if the trajectory actually reaches 65 s; an initialization-only CSV is not counted as success.

---

## 13. Next studies

The validated surge-tank model can now be used for:

1. direct no-surge vs surge-tank AGC comparison;
2. surge-tank natural-frequency and damping estimation;
3. Bode/Nyquist linearization around the 75 MW operating point;
4. transient-droop hydro governor design;
5. FCR tuning with gate-rate and waterway constraints;
6. detailed synchronous generator / infinite-bus replacement;
7. OpenIPSL and Nordic multi-machine integration.
