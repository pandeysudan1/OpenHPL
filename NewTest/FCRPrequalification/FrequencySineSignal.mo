within NewTest.FCRPrequalification;
block FrequencySineSignal "Sinusoidal frequency test signal"
  parameter Modelica.SIunits.Frequency f0=50;
  parameter Modelica.SIunits.Frequency amplitude=0.10;
  parameter Modelica.SIunits.Frequency excitationFrequency=0.05
    "Excitation frequency in Hz";
  parameter Modelica.SIunits.Time startTime=20;
  Modelica.Blocks.Interfaces.RealOutput f(unit="Hz");
equation
  f = if time < startTime then f0
      else f0 + amplitude*sin(2*Modelica.Constants.pi*excitationFrequency*(time-startTime));
end FrequencySineSignal;
