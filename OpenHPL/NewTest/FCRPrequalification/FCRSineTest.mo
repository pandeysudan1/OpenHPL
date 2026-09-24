within OpenHPL.NewTest.FCRPrequalification;
model FCRSineTest "Controller-level sinusoidal FCR response test"
  extends Modelica.Icons.Example;

  parameter Modelica.SIunits.Frequency f_nom=50;
  parameter Modelica.SIunits.Frequency amplitude=0.10;
  parameter Modelica.SIunits.Frequency excitationFrequency=0.05;
  parameter Modelica.SIunits.Time startTime=20;

  FrequencySineSignal testSignal(
    f0=f_nom,
    amplitude=amplitude,
    excitationFrequency=excitationFrequency,
    startTime=startTime);

  OpenHPL.NewTest.Controllers.FCRGovernor fcr(
    f_ref=f_nom,
    Tm=0.10,
    deadband=0.00,
    Kf=0.50,
    y_bias=0.45,
    reserveUp=0.15,
    reserveDown=0.15);

  OpenHPL.NewTest.Controllers.GateActuator actuator(
    y_start=0.45,
    openingRate=0.05,
    closingRate=0.05);

  output Modelica.SIunits.Frequency frequencyInput;
  output Modelica.SIunits.Frequency filteredFrequency;
  output Real reserveCommand;
  output Real deliveredReserve;
  output Real gateOpening;

equation
  connect(testSignal.f,fcr.f);
  connect(fcr.y,actuator.u);
  connect(actuator.y,fcr.gate);

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
