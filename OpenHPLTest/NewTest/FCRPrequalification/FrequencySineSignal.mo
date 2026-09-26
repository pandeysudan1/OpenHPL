within OpenHPLTest.NewTest.FCRPrequalification;
block FrequencySineSignal "Sinusoidal frequency test signal"
  parameter Modelica.Units.SI.Frequency f0=50;
  parameter Modelica.Units.SI.Frequency amplitude=0.10;
  parameter Modelica.Units.SI.Frequency excitationFrequency=0.05
    "Excitation frequency in Hz";
  parameter Modelica.Units.SI.Time startTime=20;
  Modelica.Blocks.Interfaces.RealOutput f(unit="Hz") annotation(Placement(transformation(extent={{100,-10},{120,10}})));
equation
  f = if time < startTime then f0
      else f0 + amplitude*sin(2*Modelica.Constants.pi*excitationFrequency*(time-startTime));
end FrequencySineSignal;
