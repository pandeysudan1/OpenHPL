within OpenHPLTest.NewTest.FCRPrequalification;
model FCRSineTest "Controller-level sinusoidal FCR response test"
  extends Modelica.Icons.Example;

  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Modelica.Units.SI.Frequency amplitude=0.10;
  parameter Modelica.Units.SI.Frequency excitationFrequency=0.05;
  parameter Modelica.Units.SI.Time startTime=20;

  FrequencySineSignal testSignal(
    f0=f_nom,
    amplitude=amplitude,
    excitationFrequency=excitationFrequency,
    startTime=startTime) annotation(Placement(transformation(origin={-70,30},extent={{-15,-15},{15,15}})));

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

  output Modelica.Units.SI.Frequency frequencyInput;
  output Modelica.Units.SI.Frequency filteredFrequency;
  output Real reserveCommand;
  output Real deliveredReserve;
  output Real gateOpening;

equation
  connect(testSignal.f,fcr.f) annotation(Line(points={{-53.5,30},{-40,30},{-40,36},{-28,36}},color={0,0,127}));
  connect(fcr.y,actuator.u) annotation(Line(points={{6.5,30},{42,30}},color={0,0,127}));
  connect(actuator.y,fcr.gate) annotation(Line(points={{76.5,30},{85,30},{85,-10},{-40,-10},{-40,24},{-28,24}},color={0,0,127}));

  frequencyInput=testSignal.f;
  filteredFrequency=fcr.fFilt;
  reserveCommand=fcr.reserveLimited;
  deliveredReserve=actuator.y-fcr.y_bias;
  gateOpening=actuator.y;

  annotation(
    experiment(StartTime=0,StopTime=180,Interval=0.02,Tolerance=1e-8),
    Documentation(info="<html>
<p>Sinusoidal controller-level FCR test. Use this example to inspect attenuation,
phase lag, reserve saturation and gate-rate effects before adding plant dynamics.</p>
</html>"));
end FCRSineTest;
