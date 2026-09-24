within OpenHPL.NewTest.FCRPrequalification;
block FrequencyRampSignal "Frequency ramp test signal"
  parameter Modelica.SIunits.Frequency f0=50;
  parameter Modelica.SIunits.Frequency df=-0.2 "Total frequency change";
  parameter Modelica.SIunits.Time startTime=20;
  parameter Modelica.SIunits.Time duration(min=Modelica.Constants.small)=20;
  Modelica.Blocks.Interfaces.RealOutput f(unit="Hz");
protected
  Real tau;
equation
  tau = min(1,max(0,(time-startTime)/duration));
  f = f0 + df*tau;
end FrequencyRampSignal;
