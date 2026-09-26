within OpenHPLTest.NewTest.MultigenerationSystemWithAreaControl.Components;
model HydroGovernorArea
  "Aggregated hydro area with permanent droop governor and gate actuator"
  extends Modelica.Blocks.Icons.Block;

  parameter String areaName="Area";
  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Modelica.Units.SI.Power P_base=100e6;
  parameter Modelica.Units.SI.Time H=4;
  parameter Integer poles=12;
  parameter Modelica.Units.SI.Efficiency eta_e=0.99;
  parameter Real R=0.04 "Permanent droop";

  parameter Modelica.Units.SI.Height reservoirLevel=50;
  parameter Modelica.Units.SI.Position reservoirElevation=300;
  parameter Modelica.Units.SI.Height tailLevel=5;
  parameter Modelica.Units.SI.Height penstockHead=300;
  parameter Modelica.Units.SI.Length penstockLength=600;
  parameter Modelica.Units.SI.Diameter penstockDiameter=4;
  parameter Modelica.Units.SI.VolumeFlowRate Vdot_0=15;

  final parameter Modelica.Units.SI.AngularVelocity w_nom=
    4*Modelica.Constants.pi*f_nom/poles;

  Modelica.Blocks.Interfaces.RealInput P_demand(unit="W")
    annotation(Placement(transformation(extent={{-140,-60},{-100,-20}})));
  Modelica.Blocks.Interfaces.RealInput P_ref(unit="W")
    annotation(Placement(transformation(extent={{-140,20},{-100,60}})));
  Modelica.Blocks.Interfaces.RealOutput frequency(unit="Hz")
    annotation(Placement(transformation(extent={{100,60},{120,80}})));
  Modelica.Blocks.Interfaces.RealOutput electricalGeneration(unit="W")
    annotation(Placement(transformation(extent={{100,20},{120,40}})));
  Modelica.Blocks.Interfaces.RealOutput mechanicalPower(unit="W")
    annotation(Placement(transformation(extent={{100,-20},{120,0}})));
  Modelica.Blocks.Interfaces.RealOutput gateOpening
    annotation(Placement(transformation(extent={{100,-60},{120,-40}})));
  Modelica.Blocks.Interfaces.RealOutput waterFlow(unit="m3/s")
    annotation(Placement(transformation(extent={{100,-100},{120,-80}})));

  outer OpenHPL.Data data;

  OpenHPL.Waterway.Reservoir reservoir(
    h_0=reservoirLevel,
    constantLevel=true,
    fixElevation=true,
    z_0=reservoirElevation) annotation(Placement(transformation(origin={-118,30},extent={{-10,-10},{10,10}})));
  OpenHPL.Waterway.Pipe penstock(
    H=penstockHead,
    L=penstockLength,
    D_i=penstockDiameter,
    D_o=penstockDiameter,
    SteadyState=true) annotation(Placement(transformation(origin={-78,30},extent={{-10,-10},{10,10}})));
  OpenHPL.ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,
    H_n=345,
    Vdot_n=35,
    u_n=0.95,
    ConstEfficiency=true,
    eta_h=0.9,
    enable_P_out=true,
    enable_nomSpeed=false,
    fixed_iniSpeed=false,
    J=0,
    p=poles,
    Ploss=0,
    Pmax=2*P_base) annotation(Placement(transformation(origin={-28,30},extent={{-20,-20},{20,20}})));
  OpenHPL.Waterway.Reservoir tail(
    h_0=tailLevel,
    constantLevel=true) annotation(Placement(transformation(origin={22,30},extent={{-10,-10},{10,10}},rotation=180)));
  OpenHPL.ElectroMech.Generators.SimpleGen generator(
    useH=false,
    J=2*H*P_base/w_nom^2,
    p=poles,
    Ploss=0,
    Pmax=2*P_base,
    fixed_iniSpeed=true,
    f_0=1,
    enable_f=true,
    enable_w=true) annotation(Placement(transformation(origin={-28,-34},extent={{-15,-15},{15,15}})));
  OpenHPLTest.NewTest.Controllers.PermanentDroopGovernor governor(
    f_ref=f_nom,
    P_base=P_base,
    R=R) annotation(Placement(transformation(origin={98,92},extent={{-20,-20},{20,20}})));
  OpenHPLTest.NewTest.Controllers.GateActuator actuator annotation(Placement(transformation(origin={-58,100},extent={{-12,-12},{12,12}})));
  Modelica.Blocks.Math.Gain frequencyHz(k=f_nom) annotation(Placement(transformation(origin={10,-40},extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Math.Gain electricalToShaft(k=1/eta_e) annotation(Placement(transformation(origin={-78,-80},extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.RealExpression powerMeasurement(y=eta_e*turbine.P_out) annotation(Placement(transformation(origin={20,54},extent={{-10,-10},{10,10}})));

initial equation
  der(generator.inertia.w)=0;

equation
  connect(reservoir.o,penstock.i) annotation(Line(points={{-108,30},{-88,30}},color={28,108,200}));
  connect(penstock.o,turbine.i) annotation(Line(points={{-68,30},{-48,30}},color={28,108,200}));
  connect(turbine.o,tail.o) annotation(Line(points={{-8,30},{12,30}},color={28,108,200}));
  connect(turbine.flange,generator.flange) annotation(Line(points={{-28,30},{-28,-34}},color={0,0,0}));
  connect(P_demand,electricalToShaft.u) annotation(Line(points={{-120,-40},{-100,-40},{-100,-80},{-90,-80}},color={0,0,127}));
  connect(electricalToShaft.y,generator.Pload) annotation(Line(points={{-67,-80},{-28,-80},{-28,-16}},color={0,0,127}));
  connect(generator.f,frequencyHz.u) annotation(Line(points={{-11.5,-40},{-2,-40}},color={0,0,127}));
  connect(frequencyHz.y,governor.f) annotation(Line(points={{21,-40},{40,-40},{40,104},{74,104}},color={0,0,127}));
  connect(P_ref,governor.P_ref) annotation(Line(points={{-120,40},{50,40},{50,88},{74,88}},color={0,0,127}));
  connect(powerMeasurement.y,governor.P) annotation(Line(points={{31,54},{60,54},{60,96},{74,96}},color={0,0,127}));
  connect(governor.y,actuator.u) annotation(Line(points={{120,92},{148,92},{148,140},{-92,140},{-92,100},{-72.4,100}},color={0,0,127}));
  connect(actuator.y,turbine.u_t) annotation(Line(points={{-44.8,100},{-44,100},{-44,54}},color={0,0,127}));
  connect(actuator.y,governor.gate) annotation(Line(points={{-44.8,100},{-4,100},{-4,66},{64,66},{64,80},{74,80}},color={0,0,127}));

  frequency=frequencyHz.y;
  electricalGeneration=eta_e*turbine.P_out;
  mechanicalPower=turbine.P_out;
  gateOpening=actuator.y;
  waterFlow=turbine.Vdot;

  annotation(
    defaultComponentName="area",
    Diagram(coordinateSystem(extent={{-140,-110},{160,150}})),
    Documentation(info="<html><p>Reusable hydro area assembled from the same turbine, generator, permanent droop governor and gate actuator used in the existing NewTest studies.</p></html>"));
end HydroGovernorArea;