# Homotopy-assisted initialization in OpenHPL

## Purpose

OpenHPL contains nonlinear hydraulic and electromechanical equations that may be difficult to initialize as one coupled DAE system. This refactor uses the Modelica `homotopy(actual=..., simplified=...)` operator to provide a numerically easier initialization path without changing the physical model used during time simulation.

The design rule is:

```modelica
homotopy(
  actual     = fullPhysicalResidual,
  simplified = initializationResidual) = 0;
```

The simplified expression must preserve the equation structure needed to determine the same unknowns, but it should remove the strongest nonlinearities or discontinuous dependencies.

## Components refactored

### Waterway.Pipe

Actual model:

```text
F_f = DarcyFriction(v)
```

Simplified model:

```text
F_f = K_f,lin * v
```

The linear coefficient is computed from a reference flow based on `Vdot_0`. This retains a pressure-flow relationship during initialization while removing the nonlinear Darcy dependence.

### Waterway.SurgeTank

The actual model retains Darcy losses, fitting/orifice losses proportional to `v*abs(v)`, and the nonlinear air-cushion pressure relation.

For initialization:
- nonlinear hydraulic loss is introduced from a zero-loss relation;
- air-cushion pressure is introduced from the initial pressure `p_ac`.

The mass, momentum, gravity, pressure-force, and geometry equations remain present.

### ElectroMech.BaseClasses.BaseValve

Actual pressure-flow residual:

```text
dp * (Cv * opening^alpha)^2 - Vdot*abs(Vdot) = 0
```

Simplified residual:

```text
dp * (Cv * nominalOpening^alpha)^2 - Vdot*abs(Vdot_n) = 0
```

This is linear in pressure drop and flow for initialization.

### ElectroMech.Turbines.Francis

The mechanistic turbine geometry and Euler equations are preserved. Homotopy is introduced only in selected hydraulic relations:

1. Guide-vane pressure loss:
   full nonlinear loss -> zero-loss initialization relation.

2. Runner pressure/work balance:

```text
actual:
dp_r * max(Vdot,Vdot_eps)
+ 0.5*mdot*Vdot^2*(1/A0^2 - 1/A2^2)
- Wdot_t = 0

simplified:
dp_r * Vdot_n - Wdot_t = 0
```

This keeps pressure, flow and power coupled while removing the strongest nonlinear products during the first initialization stage.

## Components intentionally not changed

The governor limiter and rate limiter behavior remains unchanged. These blocks represent physical control constraints and should not be replaced by homotopy merely to remove events.

Likewise, homotopy should not be used to hide structural problems such as:
- too many initial equations;
- missing boundary conditions;
- singular connection topology;
- inconsistent start/fixed attributes;
- duplicated pressure or flow constraints.

Those problems should be corrected structurally.

## Expected solver workflow

A Modelica tool that supports global homotopy conceptually solves

```text
lambda = 0 : simplified initialization system
0 < lambda < 1 : continuation
lambda = 1 : complete OpenHPL nonlinear initialization system
```

After initialization, the simulation uses the `actual` expressions.

## Validation

For every modified component:

1. Simulate an existing example with `useHomotopy=true`.
2. Simulate the same model with `useHomotopy=false`.
3. Verify identical or numerically equivalent transient trajectories after initialization.
4. Compare initialization convergence and nonlinear iteration counts.
5. Test both nominal and difficult initial guesses.
6. Test zero/near-zero flow and reverse-flow cases where applicable.

Primary signals:
- pressure at component ports;
- mass/volume flow;
- surge-tank level;
- turbine pressure drop;
- turbine shaft power;
- generator speed/frequency.

## Next refactor targets

Recommended next targets are:
- `Waterway.Penstock`;
- `Waterway.Valve`;
- `Waterway.DraftTube`;
- `ElectroMech.Generators.SynchGen`;
- optional homotopy treatment of Francis servo geometry after a local analytic linearization is defined.

The preferred approach is component-level homotopy with physically interpretable simplified equations rather than one large system-level workaround.
