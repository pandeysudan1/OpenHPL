within NewTest.FCRPrequalification;
model FCRStepTest "FCR controller activation test using an imposed frequency step"
  extends Modelica.Icons.Example;

  parameter Modelica.SIunits.Frequency f_nom=50;
  parameter Modelica.SIunits.Frequency df=-0.2;
  parameter Modelica.SIunits.Time stepTime=20;

  FrequencyStepSignal testSignal(
    f0=f_nom,
    df=df,
    stepTime=stepTime);

  NewTest.Controllers.FCRGovernor fcr(
    f_ref=f_nom,
    Tm=0.10,
    deadband=0.00,
    Kf=0.50,
    y_bias=0.45,
    reserveUp=0.15,
    reserveDown=0.15);

  NewTest.Controllers.GateActuator actuator(
    y_start=0.45,
    openingRate=0.05,
    closingRate=0.05);

  FCRMetrics metrics(
    eventTime=stepTime,
    requestedReserve=min(0.15,max(-0.15,-0.50*df)));

  output Modelica.SIunits.Frequency frequencyInput;
  output Modelica.SIunits.Frequency filteredFrequency;
  output Real requestedReserve;
  output Real deliveredReserve;
  output Real deliveryRatio;
  output Modelica.SIunits.Time timeTo90;

equation
  connect(testSignal.f,fcr.f);
  connect(fcr.y,actuator.u);
  connect(actuator.y,fcr.gate);

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
