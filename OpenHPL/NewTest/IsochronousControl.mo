within OpenHPL.NewTest;
model IsochronousControl "Isolated hydro generator: frequency restoration after a load step"
  extends Modelica.Icons.Example;
  parameter Modelica.SIunits.Frequency f_nom=50;
  parameter Modelica.SIunits.Power P_base=100e6;
  parameter Modelica.SIunits.Power P_load0=50e6;
  parameter Modelica.SIunits.Power dP=5e6 "Positive for load increase; negative for decrease";
  parameter Modelica.SIunits.Time stepTime=50;
  parameter Modelica.SIunits.Time H=4 "Generator inertia constant on P_base";
  parameter Integer poles=12;
  final parameter Modelica.SIunits.AngularVelocity w_nom=4*Modelica.Constants.pi*f_nom/poles;
  inner OpenHPL.Constants Const(f=f_nom, Steady=true, eps=0.0001, V_0=15) annotation(Placement(transformation(extent={{-100,76},{-80,96}})));
  OpenHPL.Waterway.Reservoir reservoir(H_r=50) annotation(Placement(transformation(extent={{-100,20},{-80,40}})));
  OpenHPL.Waterway.Pipe penstock(H=300,L=600,D_i=4,D_o=4,SteadyState=true) annotation(Placement(transformation(extent={{-60,20},{-40,40}})));
  OpenHPL.ElectroMech.Turbines.Turbine turbine(ValveCapacity=false,H_n=345,V_dot_n=35,u_n=0.95,ConstEfficiency=true,theta_h=0.9) annotation(Placement(transformation(extent={{-20,20},{0,40}})));
  OpenHPL.Waterway.Reservoir tail(H_r=5) annotation(Placement(transformation(origin={40,30},extent={{-10,10},{10,-10}},rotation=180)));
  OpenHPL.ElectroMech.Generators.SimpleGen generator(J=2*H*P_base/w_nom^2,p=poles,theta_e=0.99,k_b=0,SteadyState=false,w_0=w_nom) annotation(Placement(transformation(extent={{-20,-30},{0,-10}})));
  Modelica.Blocks.Sources.Step load(offset=P_load0,height=dP,startTime=stepTime) annotation(Placement(transformation(extent={{-80,-30},{-60,-10}})));
  Controllers.IsochronousGovernor governor(f_ref=f_nom) annotation(Placement(transformation(extent={{40,-70},{60,-50}})));
  Controllers.GateActuator actuator annotation(Placement(transformation(extent={{-20,66},{0,86}})));
  output Modelica.SIunits.Frequency frequency;
  output Modelica.SIunits.Power mechanicalPower;
  output Modelica.SIunits.Power electricalDemand;
  output Modelica.SIunits.Power powerImbalance;
  output Real gateOpening;
  output Modelica.SIunits.VolumeFlowRate waterFlow;
initial equation
  der(generator.w)=0 "Solve initial gate/integrator from mechanical-electrical balance";
  assert(P_load0>0 and P_load0+dP>0, "This example requires positive demand before and after the step");
equation
  connect(reservoir.n,penstock.p) annotation(Line(points={{-80,30},{-60,30}},color={28,108,200}));
  connect(penstock.n,turbine.p) annotation(Line(points={{-40,30},{-20,30}},color={28,108,200}));
  connect(turbine.n,tail.n) annotation(Line(points={{0,30},{30,30}},color={28,108,200}));
  connect(turbine.P_out,generator.P_in) annotation(Line(points={{-10,19},{-10,-8}},color={0,0,127}));
  connect(load.y,generator.u) annotation(Line(points={{-59,-20},{-20,-20}},color={0,0,127}));
  connect(generator.f,governor.f) annotation(Line(points={{1,-20},{20,-20},{20,-56},{38,-56}},color={0,0,127}));
  connect(governor.y,actuator.u) annotation(Line(points={{61,-60},{80,-60},{80,96},{-40,96},{-40,76},{-22,76}},color={0,0,127}));
  connect(actuator.y,turbine.u_t) annotation(Line(points={{1,76},{14,76},{14,52},{-10,52},{-10,42}},color={0,0,127}));
  connect(actuator.y,governor.gate) annotation(Line(points={{1,76},{68,76},{68,-40},{26,-40},{26,-64},{38,-64}},color={0,0,127}));
  frequency=generator.f;
  mechanicalPower=turbine.P_out;
  electricalDemand=load.y;
  powerImbalance=mechanicalPower-generator.W_g-generator.W_fa;
  gateOpening=actuator.y;
  waterFlow=turbine.V_dot;
  annotation(experiment(StartTime=0,StopTime=300,Interval=0.1,Tolerance=1e-7),
    Diagram(coordinateSystem(extent={{-110,-100},{110,110}})),
    Documentation(info="<html><p>One isolated hydro generator supplies a 50 MW demand. At 50 s the load increases by 5 MW. A PI speed governor restores 50 Hz through a position- and rate-limited gate servo. Set dP=-5e6 for a separate load-decrease experiment.</p><p>The OpenHPL pipe retains water-column inertia and friction; the turbine uses constant hydraulic efficiency. SimpleGen supplies rotor energy dynamics, with electrical efficiency 0.99 and bearing losses disabled. This is an active-power/frequency demonstration, not a voltage or electromagnetic transient model.</p><p>Initialization fixes nominal speed, stationary water flow and gate, and zero rotor acceleration. The initial gate opening and PI integral contribution are solved, rather than guessed as fixed values.</p><p>Plot frequency, mechanicalPower, electricalDemand, gateOpening, waterFlow and powerImbalance. Mechanical power includes the generator conversion loss, so its final value is electricalDemand/0.99.</p><p>Conceptual reference: P. Kundur, Power System Stability and Control, turbine governing and active-power/frequency control. Plant data and control gains are illustrative, not textbook benchmark data. This governor has no permanent droop and is intended for one frequency-controlling islanded unit.</p></html>"));
end IsochronousControl;
