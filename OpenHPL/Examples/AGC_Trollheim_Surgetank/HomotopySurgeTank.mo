within OpenHPL.Examples.AGC_Trollheim_Surgetank;
model HomotopySurgeTank "Simple surge tank with homotopy-assisted steady-state initialization"
  outer OpenHPL.Data data "Using standard data set";
  extends OpenHPL.Interfaces.TwoContacts;
  extends OpenHPL.Types.FrictionSpec(final D_h=D);

  parameter SI.Height H=80 "Vertical component of surge shaft length";
  parameter SI.Length L=80 "Surge shaft length";
  parameter SI.Diameter D=4 "Surge shaft diameter";
  parameter Boolean SteadyState=data.SteadyState "Use steady-state initialization";
  parameter SI.Height h_0=50 "Initial water level above surge inlet";
  parameter SI.VolumeFlowRate Vdot_0=0 "Start guess for surge flow";
  parameter SI.VolumeFlowRate Vdot_hom=1
    "Reference surge flow used to linearize friction in the simplified homotopy system";

  SI.Height h(start=h_0, fixed=false) "Surge water height";
  SI.VolumeFlowRate Vdot(start=Vdot_0, fixed=false) "Surge branch volume flow";
  SI.Velocity v "Surge water velocity";
  SI.MassFlowRate mdot "Surge mass flow";
  SI.Mass m "Water mass";
  SI.Momentum M "Water momentum";
  SI.Force F_p "Pressure force";
  SI.Force F_g "Gravity force";
  SI.Force F_f_actual "Nonlinear Darcy friction";
  SI.Force F_f_linear "Linearized friction for homotopy start system";
  SI.Pressure p_b "Bottom/manifold pressure";

protected
  parameter SI.Area A=(C.pi*D^2)/4 "Cross-sectional area";
  parameter Real cos_theta=H/L "Slope ratio";
  parameter SI.Velocity v_hom=
    if abs(Vdot_hom)/A > 1e-4 then abs(Vdot_hom)/A else 1e-4
    "Velocity used for linear-friction slope";
  parameter Real k_fric(unit="kg/s")=
    abs(OpenHPL.Functions.DarcyFriction.Friction(v_hom,D,L,data.rho,data.mu,p_eps))/v_hom
    "Linear friction slope matched to nonlinear friction at v_hom";
  SI.Length l=h/cos_theta "Water-column length";

initial equation
  if SteadyState then
    // A steady open surge tank has no net branch flow. Stating this directly is
    // more robust than imposing der(m)=0 through a derivative alias.
    Vdot=0;
    // The remaining surge level is solved from the steady momentum balance.
    der(M)=0;
  else
    h=h_0;
    Vdot=Vdot_0;
  end if;

equation
  assert(h>=0,"Surge-tank water level must be non-negative",AssertionLevel.error);

  p_b=i.p;
  i.p=o.p;

  v=Vdot/A;
  mdot=data.rho*Vdot;
  mdot=i.mdot+o.mdot;

  m=data.rho*A*l;
  M=m*v;
  der(m)=mdot;

  F_p=(p_b-data.p_a)*A;
  F_g=m*data.g*cos_theta;
  F_f_actual=OpenHPL.Functions.DarcyFriction.Friction(v,D,l,data.rho,data.mu,p_eps);
  F_f_linear=k_fric*v;

  // lambda=0: hydrostatic pressure balance plus linear damping.
  // lambda=1: full nonlinear momentum balance, including convective momentum and Darcy friction.
  der(M)=homotopy(
    actual=mdot*v + F_p - F_f_actual - F_g,
    simplified=F_p - F_f_linear - F_g);

  o.elevation.z=i.elevation.z;

  annotation(Documentation(info="<html>
<h4>Homotopy-assisted surge tank</h4>
<p>This benchmark-local component leaves the base OpenHPL SurgeTank unchanged.</p>
<p>During steady-state initialization the physical surge condition is imposed directly as Vdot=0, while der(M)=0 lets the solver determine the equilibrium water level. This avoids the derivative-alias inconsistency observed when der(m)=0 was used as an initialization equation.</p>
<p>The nonlinear momentum equation is wrapped in Modelica homotopy(). At lambda=0 the solver sees hydrostatic balance with linearized friction; at lambda=1 the complete nonlinear momentum equation is recovered.</p>
</html>"));
end HomotopySurgeTank;
