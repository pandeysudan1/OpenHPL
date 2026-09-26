within OpenHPLTest.NewTest.MultigenerationSystemWithAreaControl;
model NorwayNO1NO2AreaControl
  "Stylized two-area NO1-NO2 hydro study with primary droop and tie-line-bias AGC"
  extends Modelica.Icons.Example;

  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Modelica.Units.SI.Time stepTime=200;
  parameter Real scaleToNorway=0.05
    "Per-unit study scale used to keep the hydraulic plant near the validated NewTest operating range";
  parameter Modelica.Units.SI.Power P_load_NO1=53e6
    "Scaled NO1 net demand before disturbance";
  parameter Modelica.Units.SI.Power P_load_NO2=52e6
    "Scaled NO2 net demand before disturbance";
  parameter Modelica.Units.SI.Power dP_NO1=6e6
    "Scaled extra load applied in NO1";
  parameter Modelica.Units.SI.Power P_tie_schedule=-8e6
    "Scheduled export from NO1 to NO2; negative means NO1 imports from NO2";
  parameter Real T12(unit="W/rad")=18e6
    "Scaled synchronizing strength for the NO1-NO2 corridor";
  parameter Real B_NO1(unit="W/Hz")=22e6;
  parameter Real B_NO2(unit="W/Hz")=26e6;
  parameter Real Ki_AGC(unit="1/s")=0.0025;

  final parameter Modelica.Units.SI.Power P_schedule_NO1=P_load_NO1 + P_tie_schedule;
  final parameter Modelica.Units.SI.Power P_schedule_NO2=P_load_NO2 - P_tie_schedule;

  Modelica.Blocks.Sources.Step loadNO1(
    offset=P_load_NO1,
    height=dP_NO1,
    startTime=stepTime) annotation(Placement(transformation(origin={-140,80},extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.Constant loadNO2(k=P_load_NO2) annotation(Placement(transformation(origin={-140,-20},extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.Constant scheduleNO1(k=P_schedule_NO1) annotation(Placement(transformation(origin={-10,140},extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.Constant scheduleNO2(k=P_schedule_NO2) annotation(Placement(transformation(origin={-10,-140},extent={{-10,-10},{10,10}})));

  Components.ReducedHydroArea no1(
    areaName="NO1",
    P_base=90e6,
    H=4.0,
    R=0.05,
    Tw=4.5,
    D=1.1) annotation(Placement(transformation(origin={-10,70},extent={{-50,-50},{50,50}})));
  Components.ReducedHydroArea no2(
    areaName="NO2",
    P_base=120e6,
    H=4.8,
    R=0.04,
    Tw=5.5,
    D=1.3) annotation(Placement(transformation(origin={-10,-70},extent={{-50,-50},{50,50}})));
  Components.TieLinePower tieLine(
    f_nom=f_nom,
    T12=T12,
    P_schedule=P_tie_schedule) annotation(Placement(transformation(origin={114,0},extent={{-18,-18},{18,18}})));
  Components.TieLineBiasAGC agcNO1(
    f_ref=f_nom,
    P_base=no1.P_base,
    Ki=Ki_AGC,
    B=B_NO1,
    P_tie_schedule=P_tie_schedule) annotation(Placement(transformation(origin={114,72},extent={{-18,-18},{18,18}})));
  Components.TieLineBiasAGC agcNO2(
    f_ref=f_nom,
    P_base=no2.P_base,
    Ki=Ki_AGC,
    B=B_NO2,
    P_tie_schedule=-P_tie_schedule) annotation(Placement(transformation(origin={116,-96},extent={{-18,-18},{18,18}})));
  Modelica.Blocks.Math.Add demandNO1(k2=1) annotation(Placement(transformation(origin={-70,70},extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Math.Add demandNO2(k2=1) annotation(Placement(transformation(origin={-70,-70},extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Math.Gain reverseTie(k=-1) annotation(Placement(transformation(origin={72,-72},extent={{-10,-10},{10,10}})));

  output Modelica.Units.SI.Frequency fNO1=no1.frequency;
  output Modelica.Units.SI.Frequency fNO2=no2.frequency;
  output Modelica.Units.SI.Power PtieNO1toNO2=tieLine.P12;
  output Modelica.Units.SI.Power ACENO1=agcNO1.ACE;
  output Modelica.Units.SI.Power ACENO2=agcNO2.ACE;
  output Modelica.Units.SI.Power PrefNO1=agcNO1.P_ref;
  output Modelica.Units.SI.Power PrefNO2=agcNO2.P_ref;
  output Modelica.Units.SI.Power generationNO1=no1.electricalGeneration;
  output Modelica.Units.SI.Power generationNO2=no2.electricalGeneration;
  output Real gateNO1=no1.gateOpening;
  output Real gateNO2=no2.gateOpening;

initial equation
  no1.w_pu=1;
  no2.w_pu=1;
  no1.Pm=P_schedule_NO1;
  no2.Pm=P_schedule_NO2;
  agcNO1.x=0;
  agcNO2.x=0;

equation
  connect(loadNO1.y,demandNO1.u1) annotation(Line(points={{-129,80},{-100,80},{-100,76},{-82,76}},color={0,0,127}));
  connect(tieLine.P12,demandNO1.u2) annotation(Line(points={{133.8,0},{150,0},{150,52},{-100,52},{-100,64},{-82,64}},color={0,0,127}));
  connect(demandNO1.y,no1.P_demand) annotation(Line(points={{-59,70},{-38,70}},color={0,0,127}));
  connect(loadNO2.y,demandNO2.u1) annotation(Line(points={{-129,-20},{-108,-20},{-108,-64},{-82,-64}},color={0,0,127}));
  connect(tieLine.P12,reverseTie.u) annotation(Line(points={{133.8,0},{150,0},{150,-72},{84,-72}},color={0,0,127}));
  connect(reverseTie.y,demandNO2.u2) annotation(Line(points={{61,-72},{-82,-72}},color={0,0,127}));
  connect(demandNO2.y,no2.P_demand) annotation(Line(points={{-59,-70},{-38,-70}},color={0,0,127}));

  connect(scheduleNO1.y,agcNO1.P_schedule) annotation(Line(points={{1,140},{60,140},{60,72},{92.4,72}},color={0,0,127}));
  connect(scheduleNO2.y,agcNO2.P_schedule) annotation(Line(points={{1,-140},{60,-140},{60,-94},{94,-94}},color={0,0,127}));
  connect(no1.frequency,agcNO1.f) annotation(Line(points={{42,80},{66,80},{66,79.2},{92.4,79.2}},color={0,0,127}));
  connect(no2.frequency,agcNO2.f) annotation(Line(points={{42,-60},{66,-60},{66,-85},{94,-85}},color={0,0,127}));
  connect(tieLine.P12,agcNO1.P_tie) annotation(Line(points={{133.8,0},{150,0},{150,64.8},{135.6,64.8}},color={0,0,127}));
  connect(reverseTie.y,agcNO2.P_tie) annotation(Line(points={{61,-72},{61, -107}, {94, -107}},color={0,0,127}));
  connect(agcNO1.P_ref,no1.P_ref) annotation(Line(points={{133.8,79.2},{150,79.2},{150,118},{-60,118},{-60,90},{-38,90}},color={0,0,127}));
  connect(agcNO2.P_ref,no2.P_ref) annotation(Line(points={{136,-91},{136,-118},{-60,-118},{-60,-50},{-38,-50}},color={0,0,127}));

  connect(no1.frequency,tieLine.f1) annotation(Line(points={{42,80},{78,80},{78,7.2},{92.4,7.2}},color={0,0,127}));
  connect(no2.frequency,tieLine.f2) annotation(Line(points={{42,-60},{78,-60},{78,-7.2},{92.4,-7.2}},color={0,0,127}));

  annotation(
    Diagram(coordinateSystem(extent={{-160,-160},{170,160}})),
    experiment(StartTime=0,StopTime=4000,Interval=1,Tolerance=1e-7),
    Documentation(info="<html><p>Stylized two-area load-frequency-control study inspired by the NO1 and NO2 Norwegian bidding zones within a Nordic-style synchronous system.</p><p>The electrical side is intentionally reduced-order: each area uses the validated NewTest hydro governor stack, while a linearized tie-line and tie-line-bias AGC reproduce the standard primary-plus-secondary control mechanism used in Nordic load-frequency studies.</p><p>The benchmark is scaled down to remain compatible with the present single-unit hydro plant parametrization while preserving the operational story: NO1 starts as a net-importing area, receives an extra load step at t=200 s, and shares the transient response with hydro-rich NO2 before AGC restores frequency and interchange toward schedule.</p></html>"));
end NorwayNO1NO2AreaControl;
