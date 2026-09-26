within OpenHPLTest.NewTest.FCRPrequalification;
block FrequencyRampSignal "Frequency ramp test signal"
  parameter Modelica.Units.SI.Frequency f0=50;
  parameter Modelica.Units.SI.Frequency df=-0.2 "Total frequency change";
  parameter Modelica.Units.SI.Time startTime=20;
  parameter Modelica.Units.SI.Time duration(min=Modelica.Constants.small)=20;
  Modelica.Blocks.Interfaces.RealOutput f(unit="Hz");
protected
  Real tau;
equation
  tau = min(1,max(0,(time-startTime)/duration));
  f = f0 + df*tau;
end FrequencyRampSignal;
