within OpenHPLTest.NewTest.FCRPrequalification;
block FrequencyStepSignal "Frequency test signal with pre-disturbance hold and one step"
  parameter Modelica.Units.SI.Frequency f0=50 "Initial frequency";
  parameter Modelica.Units.SI.Frequency df=-0.2 "Applied frequency step";
  parameter Modelica.Units.SI.Time stepTime=20;
  Modelica.Blocks.Interfaces.RealOutput f(unit="Hz") annotation(Placement(transformation(extent={{100,-10},{120,10}})));
equation
  f = if time < stepTime then f0 else f0 + df;
end FrequencyStepSignal;
