within OpenHPL.NewTest;
model PermanentDroopControl "Isolated hydro generator: permanent frequency offset after a load step"
  extends Modelica.Icons.Example;
  parameter Modelica.SIunits.Frequency f_nom=50;
  parameter Modelica.SIunits.Power P_base=100e6;
  parameter Modelica.SIunits.Power P_load0=50e6;
  parameter Modelica.SIunits.Power dP=5e6 "Positive for load increase; negative for decrease";
  parameter Modelica.SIunits.Time stepTime=50;
  parameter Modelica.SIunits.Time H=4 "Generator inertia constant on P_base";
  parameter Integer poles=12;
  parameter Real R(min=Modelica.Constants.small)=0.04 "Permanent droop, per unit (0.04 = 4 percent)";
  final parameter Modelica.SIunits.AngularVelocity w_nom=4*Modelica.Constants.pi*f_nom/poles;
  inner OpenHPL.Constants Const(f=f_nom, Steady=true, eps=0.0001, V_0=15) annotation(Placement(transformation(extent={{-100,76},{-80,96}})));
  OpenHPL.Waterway.Reservoir reservoir(H_r=50) annotation(Placement(transformation(origin = {-2, -26}, extent = {{-100, 20}, {-80, 40}})));
  OpenHPL.Waterway.Pipe penstock(H=300,L=600,D_i=4,D_o=4,SteadyState=true) annotation(Placement(transformation(origin = {-2, -26}, extent = {{-60, 20}, {-40, 40}})));
  OpenHPL.ElectroMech.Turbines.Turbine turbine(ValveCapacity=false,H_n=345,V_dot_n=35,u_n=0.95,ConstEfficiency=true,theta_h=0.9) annotation(Placement(transformation(origin = {-2, -26}, extent = {{-20, 20}, {0, 40}})));
  OpenHPL.Waterway.Reservoir tail(H_r=5) annotation(Placement(transformation(origin={38,4},extent={{-10,10},{10,-10}},rotation=180)));
  OpenHPL.ElectroMech.Generators.SimpleGen generator(J=2*H*P_base/w_nom^2,p=poles,theta_e=0.99,k_b=0,SteadyState=false,w_0=w_nom) annotation(Placement(transformation(origin = {-2, -26}, extent = {{-20, -30}, {0, -10}})));
  Modelica.Blocks.Sources.Step load(offset=P_load0,height=dP,startTime=stepTime) annotation(Placement(transformation(origin = {-2, -26}, extent = {{-80, -30}, {-60, -10}})));
  Controllers.PermanentDroopGovernor governor(f_ref=f_nom,P_base=P_base,R=R) annotation(Placement(transformation(extent={{34,-100},{74,-60}})));
  Modelica.Blocks.Sources.Constant powerReference(k=P_load0) annotation(Placement(transformation(extent={{-80,-118},{-60,-98}})));
  Modelica.Blocks.Sources.RealExpression powerMeasurement(y=generator.theta_e*turbine.P_out) annotation(Placement(transformation(extent={{-80,-84},{-60,-64}})));
  Controllers.GateActuator actuator annotation(Placement(transformation(origin = {24, -98.4}, extent = {{-48, 158.4}, {0, 206.4}})));
  output Modelica.SIunits.Frequency frequency;
  output Modelica.SIunits.Frequency expectedFrequency "Unsaturated equilibrium prediction for the current constant-power load";
  output Real droopResidual "Combined frequency and power error";
  output Modelica.SIunits.Power mechanicalPower;
  output Modelica.SIunits.Power electricalDemand;
  output Modelica.SIunits.Power powerImbalance;
  output Real gateOpening;
  output Modelica.SIunits.VolumeFlowRate waterFlow;
initial equation
  der(generator.w)=0 "Solve initial gate/integrator from mechanical-electrical balance";
  assert(P_load0>0 and P_load0+dP>0, "This example requires positive demand before and after the step");
equation
  connect(reservoir.n,penstock.p) annotation(Line(points={{-82,4},{-62,4}},color={28,108,200}));
  connect(penstock.n,turbine.p) annotation(Line(points={{-42,4},{-22,4}},color={28,108,200}));
  connect(turbine.n,tail.n) annotation(Line(points={{-2,4},{28,4}},color={28,108,200}));
  connect(turbine.P_out,generator.P_in) annotation(Line(points={{-12,-7},{-12,-34}},color={0,0,127}));
  connect(load.y,generator.u) annotation(Line(points={{-61,-46},{-22,-46}},color={0,0,127}));
  connect(generator.f,governor.f) annotation(Line(points={{-1,-46},{14,-46},{14,-68},{30,-68}},color={0,0,127}));
  connect(governor.y,actuator.u) annotation(Line(points={{76,-80},{94,-80},{94,96},{-40,96},{-40,84},{-29,84}},color={0,0,127}));
  connect(actuator.y,turbine.u_t) annotation(Line(points={{26,84},{26,52},{-12,52},{-12,16}},color={0,0,127}));
  connect(actuator.y,governor.gate) annotation(Line(points={{26,84},{86,84},{86,-130},{20,-130},{20,-92},{30,-92}},color={0,0,127}));
  connect(powerMeasurement.y,governor.P) annotation(Line(points={{-59,-74},{-4,-74},{-4,-76},{30,-76}},color={0,0,127}));
  connect(powerReference.y,governor.P_ref) annotation(Line(points={{-59,-108},{6,-108},{6,-84},{30,-84}},color={0,0,127}));
  frequency=generator.f;
  expectedFrequency=f_nom*(1-R*(load.y-powerReference.y)/P_base);
  droopResidual=governor.e;
  mechanicalPower=turbine.P_out;
  electricalDemand=load.y;
  powerImbalance=mechanicalPower-generator.W_g-generator.W_fa;
  gateOpening=actuator.y;
  waterFlow=turbine.V_dot;
  annotation(experiment(StartTime=0,StopTime=300,Interval=0.1,Tolerance=1e-7),
    Diagram(coordinateSystem(extent={{-110,-140},{110,120}})),
    Documentation(info="<html><p>One isolated hydro generator starts at 50 MW and 50 Hz. At 50 s, demand increases by 5 MW. With R=0.04 and P_base=100 MW, the predicted final frequency is 49.90 Hz. Set dP=-5e6 for 50.10 Hz, or R=0.05 for 49.875 Hz after the positive load step.</p><p>The governor receives actual turbine mechanical power multiplied by generator efficiency, on the same electrical-equivalent base as the fixed 50 MW power reference. Its PI acts on combined frequency and power error; it does not integrate frequency error alone. There is no secondary frequency restoration or AGC.</p><p>The physical plant and balanced initialization follow IsochronousControl: rigid water-column inertia and friction, constant hydraulic efficiency, rotor energy balance and a limited gate servo. Demand is constant power and has no frequency damping. Under these assumptions the unsaturated equilibrium is f=f_nom*(1-R*dP/P_base). expectedFrequency is an algebraic reference for that final equilibrium, not a prediction of the transient.</p><p>Plot frequency and expectedFrequency, mechanicalPower, electricalDemand, gateOpening, waterFlow and droopResidual. At equilibrium mechanicalPower=electricalDemand/0.99. Initialization solves the gate opening and integral contribution from zero acceleration at nominal speed.</p><p>Conceptual reference: P. Kundur, Power System Stability and Control, active-power/frequency control and turbine governing. Parameters are illustrative, not a reproduced textbook benchmark. The power-feedback formulation makes the permanent droop explicit and provides a power-reference input for future AGC.</p></html>"));
end PermanentDroopControl;
