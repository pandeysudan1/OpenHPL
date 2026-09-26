within OpenHPLTest.NewTest.FCRPrequalification;
model FCRStepTest "FCR controller activation test using an imposed frequency step"
  extends Modelica.Icons.Example;

  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Modelica.Units.SI.Frequency df=-0.2;
  parameter Modelica.Units.SI.Time stepTime=20;

  FrequencyStepSignal testSignal(
    f0=f_nom,
    df=df,
    stepTime=stepTime) annotation(Placement(transformation(origin={-70,30},extent={{-15,-15},{15,15}})));

  OpenHPLTest.NewTest.Controllers.FCRGovernor fcr(
    f_ref=f_nom,
    Tm=0.10,
    deadband=0.00,
    Kf=0.50,
    y_bias=0.45,
    reserveUp=0.15,
    reserveDown=0.15) annotation(Placement(transformation(origin={-10,30},extent={{-15,-15},{15,15}})));

  OpenHPLTest.NewTest.Controllers.GateActuator actuator(
    y_start=0.45,
    openingRate=0.05,
    closingRate=0.05) annotation(Placement(transformation(origin={60,30},extent={{-15,-15},{15,15}})));

  FCRMetrics metrics(
    eventTime=stepTime,
    requestedReserve=min(0.15,max(-0.15,-0.50*df))) annotation(Placement(transformation(origin={0,-60},extent={{-15,-15},{15,15}})));

  output Modelica.Units.SI.Frequency frequencyInput;
  output Modelica.Units.SI.Frequency filteredFrequency;
  output Real requestedReserve;
  output Real deliveredReserve;
  output Real deliveryRatio;
  output Modelica.Units.SI.Time timeTo90;

equation
  connect(testSignal.f,fcr.f) annotation(Line(points={{-53.5,30},{-40,30},{-40,36},{-28,36}},color={0,0,127}));
  connect(fcr.y,actuator.u) annotation(Line(points={{6.5,30},{42,30}},color={0,0,127}));
  connect(actuator.y,fcr.gate) annotation(Line(points={{76.5,30},{85,30},{85,-10},{-40,-10},{-40,24},{-28,24}},color={0,0,127}));

  metrics.reserveDelivered = actuator.y - fcr.y_bias;
  metrics.frequency = testSignal.f;

  frequencyInput=testSignal.f;
  filteredFrequency=fcr.fFilt;
  requestedReserve=metrics.requestedReserve;
  deliveredReserve=metrics.reserveDelivered;
  deliveryRatio=metrics.deliveryRatio;
  timeTo90=metrics.timeTo90;

  annotation(
    experiment(StartTime=0,StopTime=80,Interval=0.02,Tolerance=1e-8),
    Documentation(info="<html>
<p>Controller-level prequalification harness. The plant is intentionally removed so
the FCR block and actuator can be tested independently before full hydro integration.</p>
<p>The imposed frequency step excites filtering, deadband, reserve saturation and
actuator-rate limits. Exposed metrics include reserve delivery ratio and time to 90%
of the requested reserve.</p>
<p>This is a generic engineering harness, not a claim of compliance with any specific
TSO product requirement.</p>
</html>"));
end FCRStepTest;
