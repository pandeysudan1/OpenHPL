within OpenHPL.NewTest;
model AGCControl
  "Primary permanent droop plus secondary AGC frequency restoration"
  extends Modelica.Icons.Example;

  parameter Modelica.SIunits.Frequency f_nom=50;
  parameter Modelica.SIunits.Power P_base=100e6;
  parameter Modelica.SIunits.Power P_load0=50e6;
  parameter Modelica.SIunits.Power dP=5e6;
  parameter Modelica.SIunits.Time stepTime=50;
  parameter Modelica.SIunits.Time H=4;
  parameter Integer poles=12;
  parameter Real R=0.04 "Primary permanent droop";
  parameter Real Ki_AGC(unit="1/s")=0.02
    "Secondary integral gain";

  final parameter Modelica.SIunits.AngularVelocity w_nom=
    4*Modelica.Constants.pi*f_nom/poles;

  inner OpenHPL.Constants Const(
    f=f_nom, Steady=true, eps=0.0001, V_0=15);

  OpenHPL.Waterway.Reservoir reservoir(H_r=50);
  OpenHPL.Waterway.Pipe penstock(
    H=300,L=600,D_i=4,D_o=4,SteadyState=true);
  OpenHPL.ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,H_n=345,V_dot_n=35,u_n=0.95,
    ConstEfficiency=true,theta_h=0.9);
  OpenHPL.Waterway.Reservoir tail(H_r=5);
  OpenHPL.ElectroMech.Generators.SimpleGen generator(
    J=2*H*P_base/w_nom^2,p=poles,theta_e=0.99,k_b=0,
    SteadyState=false,w_0=w_nom);

  Modelica.Blocks.Sources.Step load(
    offset=P_load0,height=dP,startTime=stepTime);
  Modelica.Blocks.Sources.Constant schedule(k=P_load0);
  Modelica.Blocks.Sources.RealExpression powerMeasurement(
    y=generator.theta_e*turbine.P_out);

  Controllers.PermanentDroopGovernor governor(
    f_ref=f_nom,P_base=P_base,R=R);
  Controllers.SecondaryAGC agc(
    f_ref=f_nom,P_base=P_base,Ki=Ki_AGC);
  Controllers.GateActuator actuator;

  output Modelica.SIunits.Frequency frequency;
  output Modelica.SIunits.Power primaryPowerReference;
  output Modelica.SIunits.Power agcCorrection;
  output Real primaryDroopError;
  output Real agcFrequencyError;
  output Real gateOpening;
  output Modelica.SIunits.Power mechanicalPower;
  output Modelica.SIunits.Power electricalDemand;
  output Modelica.SIunits.VolumeFlowRate waterFlow;

initial equation
  der(generator.w)=0
    "Solve initial hydraulic/electromechanical equilibrium";
  agc.x=0
    "Start secondary controller from the scheduled operating point";
  assert(P_load0>0 and P_load0+dP>0,
    "Positive demand is required before and after the step");

equation
  connect(reservoir.n,penstock.p);
  connect(penstock.n,turbine.p);
  connect(turbine.n,tail.n);
  connect(turbine.P_out,generator.P_in);
  connect(load.y,generator.u);

  connect(generator.f,governor.f);
  connect(generator.f,agc.f);
  connect(schedule.y,agc.P_schedule);
  connect(agc.P_ref,governor.P_ref);
  connect(powerMeasurement.y,governor.P);

  connect(governor.y,actuator.u);
  connect(actuator.y,turbine.u_t);
  connect(actuator.y,governor.gate);

  frequency=generator.f;
  primaryPowerReference=agc.P_ref;
  agcCorrection=agc.P_ref-schedule.y;
  primaryDroopError=governor.e;
  agcFrequencyError=agc.e_f;
  gateOpening=actuator.y;
  mechanicalPower=turbine.P_out;
  electricalDemand=load.y;
  waterFlow=turbine.V_dot;

  annotation(
    experiment(StartTime=0,StopTime=500,Interval=0.1,Tolerance=1e-7),
    Documentation(info="<html>
<p>This example reuses the existing PermanentDroopGovernor and GateActuator.
The new SecondaryAGC block slowly adjusts P_ref after the primary droop response.</p>
<p>Sequence after the +5 MW load step: inertia arrests the initial imbalance;
permanent droop increases gate opening and leaves a frequency offset; AGC then
integrates the remaining frequency error and shifts P_ref until frequency returns
toward 50 Hz.</p>
<p>Compare this model directly with PermanentDroopControl. Plot frequency,
primaryPowerReference, agcCorrection, primaryDroopError, agcFrequencyError,
gateOpening, mechanicalPower and waterFlow.</p>
</html>"));
end AGCControl;
