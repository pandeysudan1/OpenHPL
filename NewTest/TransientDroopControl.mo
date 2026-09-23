within NewTest;
model TransientDroopControl
  "Isolated hydro generator with permanent and transient droop"
  extends Modelica.Icons.Example;

  parameter Modelica.SIunits.Frequency f_nom=50;
  parameter Modelica.SIunits.Power P_base=100e6;
  parameter Modelica.SIunits.Power P_load0=50e6;
  parameter Modelica.SIunits.Power dP=5e6;
  parameter Modelica.SIunits.Time stepTime=50;
  parameter Modelica.SIunits.Time H=4;
  parameter Integer poles=12;
  parameter Real R=0.04 "Permanent droop";
  parameter Real Rt=0.10 "Transient-droop gain";
  parameter Modelica.SIunits.Time Tr=1.75 "Transient-droop time constant";

  final parameter Modelica.SIunits.AngularVelocity w_nom=
    4*Modelica.Constants.pi*f_nom/poles;

  inner OpenHPL.Constants Const(
    f=f_nom, Steady=true, eps=0.0001, V_0=15);

  OpenHPL.Waterway.Reservoir reservoir(H_r=50);
  OpenHPL.Waterway.Pipe penstock(
    H=300, L=600, D_i=4, D_o=4, SteadyState=true);
  OpenHPL.ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false, H_n=345, V_dot_n=35, u_n=0.95,
    ConstEfficiency=true, theta_h=0.9);
  OpenHPL.Waterway.Reservoir tail(H_r=5);
  OpenHPL.ElectroMech.Generators.SimpleGen generator(
    J=2*H*P_base/w_nom^2, p=poles, theta_e=0.99, k_b=0,
    SteadyState=false, w_0=w_nom);

  Modelica.Blocks.Sources.Step load(
    offset=P_load0, height=dP, startTime=stepTime);
  Modelica.Blocks.Sources.Constant powerReference(k=P_load0);
  Modelica.Blocks.Sources.RealExpression powerMeasurement(
    y=generator.theta_e*turbine.P_out);

  Controllers.TransientDroopGovernor governor(
    f_ref=f_nom, P_base=P_base, R=R, Rt=Rt, Tr=Tr);
  Controllers.GateActuator actuator;

  output Modelica.SIunits.Frequency frequency;
  output Modelica.SIunits.Frequency expectedFrequency
    "Final permanent-droop equilibrium reference";
  output Real transientDroopSignal;
  output Real governorError;
  output Modelica.SIunits.Power mechanicalPower;
  output Modelica.SIunits.Power electricalDemand;
  output Real gateOpening;
  output Modelica.SIunits.VolumeFlowRate waterFlow;

initial equation
  der(generator.w)=0
    "Solve initial gate and governor states from the plant equilibrium";
  assert(P_load0>0 and P_load0+dP>0,
    "Positive demand is required before and after the step");

equation
  connect(reservoir.n, penstock.p);
  connect(penstock.n, turbine.p);
  connect(turbine.n, tail.n);
  connect(turbine.P_out, generator.P_in);
  connect(load.y, generator.u);

  connect(generator.f, governor.f);
  connect(powerMeasurement.y, governor.P);
  connect(powerReference.y, governor.P_ref);
  connect(governor.y, actuator.u);
  connect(actuator.y, turbine.u_t);
  connect(actuator.y, governor.gate);

  frequency = generator.f;
  expectedFrequency =
    f_nom*(1 - R*(load.y-powerReference.y)/P_base);
  transientDroopSignal = governor.transientSignal;
  governorError = governor.e;
  mechanicalPower = turbine.P_out;
  electricalDemand = load.y;
  gateOpening = actuator.y;
  waterFlow = turbine.V_dot;

  annotation(
    experiment(StartTime=0, StopTime=300, Interval=0.1, Tolerance=1e-7),
    Documentation(info="<html>
<p>This example uses exactly the same hydro plant, disturbance convention,
measurement semantics and GateActuator as PermanentDroopControl.</p>
<p>The only controller change is the additional transient-droop washout state.
The transient signal becomes active while the gate moves and decays to zero,
so the final frequency approaches the same permanent-droop equilibrium.</p>
<p>Compare frequency, expectedFrequency, transientDroopSignal, governorError,
gateOpening, waterFlow and mechanicalPower against PermanentDroopControl.</p>
</html>"));
end TransientDroopControl;
