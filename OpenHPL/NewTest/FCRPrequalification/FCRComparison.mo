within OpenHPL.NewTest.FCRPrequalification;
model FCRComparison
  "Side-by-side FCR command, actuator delivery, and nonlinear hydraulic power response"
  extends Modelica.Icons.Example;

  parameter Modelica.SIunits.Frequency f_nom=50;
  parameter Modelica.SIunits.Power P_base=100e6;
  parameter Modelica.SIunits.Power P_load0=50e6;
  parameter Modelica.SIunits.Power dP=5e6;
  parameter Modelica.SIunits.Time stepTime=50;
  parameter Modelica.SIunits.Time H=4;
  parameter Integer poles=12;

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

  OpenHPL.NewTest.Controllers.FCRGovernor fcr(
    f_ref=f_nom,
    Tm=0.10,
    deadband=0.00,
    Kf=0.20,
    y_bias=0.451827,
    reserveUp=0.15,
    reserveDown=0.15);

  OpenHPL.NewTest.Controllers.GateActuator actuator(
    y_start=0.451827,
    openingRate=0.05,
    closingRate=0.05);

  FCRComparisonMetrics metrics(powerBase=P_base);

  output Modelica.SIunits.Frequency frequency;
  output Real commandedReserve;
  output Real deliveredGateReserve;
  output Modelica.SIunits.Power incrementalMechanicalPower;
  output Real normalizedMechanicalPower;
  output Real gateTrackingError;
  output Real gateTrackingRatio;
  output Real powerToCommandRatio;
  output Modelica.SIunits.VolumeFlowRate waterFlow;
  output Real gateOpening;

initial equation
  der(generator.w)=0;

equation
  connect(reservoir.n,penstock.p);
  connect(penstock.n,turbine.p);
  connect(turbine.n,tail.n);
  connect(turbine.P_out,generator.P_in);
  connect(load.y,generator.u);

  connect(generator.f,fcr.f);
  connect(fcr.y,actuator.u);
  connect(actuator.y,fcr.gate);
  connect(actuator.y,turbine.u_t);

  metrics.commandedReserve=fcr.reserveLimited;
  metrics.deliveredGateReserve=actuator.y-fcr.y_bias;
  metrics.incrementalMechanicalPower=turbine.P_out-P_load0/0.99;

  frequency=generator.f;
  commandedReserve=metrics.commandedReserve;
  deliveredGateReserve=metrics.deliveredGateReserve;
  incrementalMechanicalPower=metrics.incrementalMechanicalPower;
  normalizedMechanicalPower=metrics.normalizedMechanicalPower;
  gateTrackingError=metrics.gateTrackingError;
  gateTrackingRatio=metrics.gateTrackingRatio;
  powerToCommandRatio=metrics.powerToCommandRatio;
  waterFlow=turbine.V_dot;
  gateOpening=actuator.y;

  annotation(
    experiment(StartTime=0,StopTime=180,Interval=0.05,Tolerance=1e-7),
    Documentation(info="<html>
<p>Comparison milestone for the NewTest FCR workflow.</p>
<p>Plot commandedReserve, deliveredGateReserve and normalizedMechanicalPower on the
same axis. Their separation visualizes controller dynamics, actuator constraints,
and nonlinear hydraulic delivery.</p>
<p>Also inspect gateTrackingError, gateTrackingRatio and powerToCommandRatio.
These are instantaneous diagnostic ratios, not frequency-response estimates.</p>
</html>"));
end FCRComparison;
