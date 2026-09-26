within OpenHPLTest.NewTest.MultigenerationSystemWithAreaControl.Components;
model ReducedHydroArea
  "Reduced-order aggregated hydro area for multi-area frequency-control studies"
  extends Modelica.Blocks.Icons.Block;

  parameter String areaName="Area";
  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Modelica.Units.SI.Power P_base=100e6;
  parameter Real R=0.04 "Permanent droop";
  parameter Modelica.Units.SI.Time H=4 "Equivalent inertia constant";
  parameter Modelica.Units.SI.Time Tw=4 "Hydro power lag";
  parameter Real D=1.0 "Load damping in pu power per pu frequency";
  parameter Real gateToPowerGain=1.0
    "Per-unit mechanical power produced by a fully open gate";

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

  OpenHPLTest.NewTest.Controllers.PermanentDroopGovernor governor(
    f_ref=f_nom,
    P_base=P_base,
    R=R,
    x_start=0.5) annotation(Placement(transformation(origin={52,62},extent={{-20,-20},{20,20}})));
  OpenHPLTest.NewTest.Controllers.GateActuator actuator(
    y_start=0.5,
    openingRate=0.05,
    closingRate=0.05) annotation(Placement(transformation(origin={-30,70},extent={{-12,-12},{12,12}})));

  Real w_pu(start=1, fixed=false) "Per-unit frequency state";
  Modelica.Units.SI.Power Pm(start=0.5*P_base, fixed=false)
    "Equivalent mechanical power";

initial equation
  der(w_pu)=0;
  der(Pm)=0;

equation
  connect(P_ref,governor.P_ref) annotation(Line(points={{-120,40},{-10,40},{-10,58},{28,58}},color={0,0,127}));
  connect(governor.y,actuator.u) annotation(Line(points={{74,62},{90,62},{90,98},{-60,98},{-60,70},{-44.4,70}},color={0,0,127}));
  connect(actuator.y,governor.gate) annotation(Line(points={{-16.8,70},{6,70},{6,50},{28,50}},color={0,0,127}));

  governor.f=frequency;
  governor.P=Pm;
  der(Pm)=(P_base*gateToPowerGain*actuator.y - Pm)/Tw;
  2*H*der(w_pu)=(Pm - P_demand)/P_base - D*(w_pu - 1);

  frequency=f_nom*w_pu;
  mechanicalPower=Pm;
  electricalGeneration=Pm;
  gateOpening=actuator.y;

  annotation(
    defaultComponentName="area",
    Diagram(coordinateSystem(extent={{-140,-110},{120,120}})),
    Documentation(info="<html><p>Reduced-order hydro area for multi-area load-frequency-control studies. The electrical side is an aggregate swing equation, and the hydro side is a first-order gate-to-power lag driven by the existing permanent droop governor and gate actuator blocks from NewTest.</p></html>"));
end ReducedHydroArea;