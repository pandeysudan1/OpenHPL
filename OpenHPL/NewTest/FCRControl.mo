within OpenHPL.NewTest;
model FCRControl
  "Hydro frequency-containment response with filtered deadbanded reserve activation"
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

  Controllers.FCRGovernor fcr(
    f_ref=f_nom,
    Tm=0.10,
    deadband=0.00,
    Kf=0.20,
    y_bias=0.451827,
    reserveUp=0.15,
    reserveDown=0.15);

  Controllers.GateActuator actuator(
    openingRate=0.05,
    closingRate=0.05,
    y_start=0.451827);

  output Modelica.SIunits.Frequency frequency;
  output Modelica.SIunits.Frequency filteredFrequency;
  output Modelica.SIunits.Frequency frequencyDeviation;
  output Real fcrReserveCommand;
  output Real fcrReserveLimited;
  output Real gateOpening;
  output Modelica.SIunits.Power mechanicalPower;
  output Modelica.SIunits.Power electricalDemand;
  output Modelica.SIunits.VolumeFlowRate waterFlow;

initial equation
  der(generator.w)=0
    "Solve initial plant equilibrium";
  assert(P_load0>0 and P_load0+dP>0,
    "Positive demand is required before and after the step");

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

  frequency=generator.f;
  filteredFrequency=fcr.fFilt;
  frequencyDeviation=fcr.df;
  fcrReserveCommand=fcr.reserveCommand;
  fcrReserveLimited=fcr.reserveLimited;
  gateOpening=actuator.y;
  mechanicalPower=turbine.P_out;
  electricalDemand=load.y;
  waterFlow=turbine.V_dot;

  annotation(
    experiment(StartTime=0,StopTime=180,Interval=0.05,Tolerance=1e-7),
    Documentation(info="<html>
<p>This example reuses the same OpenHPL hydro plant and GateActuator used by the
other NewTest controller studies.</p>
<p>At t=50 s the electrical demand increases by 5 MW. The FCRGovernor filters
frequency, applies a parameterized deadband, converts the active frequency deviation
to a fast reserve command, and limits upward/downward activation before commanding
the gate actuator.</p>
<p>Plot frequency, filteredFrequency, frequencyDeviation, fcrReserveCommand,
fcrReserveLimited, gateOpening, mechanicalPower and waterFlow.</p>
<p>This is a generic FCR dynamics example. Product-specific prequalification
criteria should be implemented as a separate test layer around this reusable block.</p>
</html>"));
end FCRControl;
