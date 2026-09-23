within NewTest.FCRPrequalification;
block FrequencyStepSignal "Frequency test signal with pre-disturbance hold and one step"
  parameter Modelica.SIunits.Frequency f0=50 "Initial frequency";
  parameter Modelica.SIunits.Frequency df=-0.2 "Applied frequency step";
  parameter Modelica.SIunits.Time stepTime=20;
  Modelica.Blocks.Interfaces.RealOutput f(unit="Hz");
equation
  f = if time < stepTime then f0 else f0 + df;
end FrequencyStepSignal;
