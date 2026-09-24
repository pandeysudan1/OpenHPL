within OpenHPL.NewTest.Controllers;
block PermanentDroopGovernor "PI governor with permanent power-frequency droop"
  extends OpenHPL.NewTest.Icons.DroopGovernor;
  parameter Modelica.SIunits.Frequency f_ref(min=Modelica.Constants.small)=50;
  parameter Modelica.SIunits.Power P_base(min=Modelica.Constants.small)=100e6 "Power base shared by P and P_ref";
  parameter Real R(min=Modelica.Constants.small)=0.04 "Permanent droop: 0.04 means 4 percent";
  parameter Real Kp(min=0)=2 "Gain on combined per-unit speed/power error";
  parameter Real Ki(unit="1/s", min=Modelica.Constants.small)=0.1;
  parameter Modelica.SIunits.Time Tt(min=Modelica.Constants.small)=5 "Actuator tracking time";
  parameter Real yMin=0.01;
  parameter Real yMax=1;
  parameter Real x_start=0.45 "Initial integral-output guess";
  Modelica.Blocks.Interfaces.RealInput f(unit="Hz") annotation(Placement(transformation(extent={{-140,40},{-100,80}})));
  Modelica.Blocks.Interfaces.RealInput P(unit="W") "Measured turbine power on the chosen power base" annotation(Placement(transformation(extent={{-140,0},{-100,40}})));
  Modelica.Blocks.Interfaces.RealInput P_ref(unit="W") "Independent power reference at nominal frequency" annotation(Placement(transformation(extent={{-140,-40},{-100,0}})));
  Modelica.Blocks.Interfaces.RealInput gate "Actual actuator position for anti-windup" annotation(Placement(transformation(extent={{-140,-80},{-100,-40}})));
  Modelica.Blocks.Interfaces.RealOutput y annotation(Placement(transformation(extent={{100,-10},{120,10}})));
  Real e "Combined frequency and permanent-droop error";
  Real x(start=x_start, fixed=false) "Integral contribution, initialized by the enclosing plant";
  Real raw;
initial equation
  assert(R>0 and P_base>0 and f_ref>0 and Ki>0 and Tt>0, "Droop, bases, integral gain and tracking time must be positive");
  assert(yMax>yMin, "Governor limits must be ordered");
equation
  e=(f_ref-f)/f_ref - R*(P-P_ref)/P_base;
  raw=Kp*e+x;
  y=min(yMax,max(yMin,raw));
  der(x)=Ki*e+(gate-raw)/Tt;
end PermanentDroopGovernor;
