within OpenHPL.NewTest.Controllers;
block IsochronousGovernor "PI speed control with actuator-tracking anti-windup"
  extends Modelica.Blocks.Icons.Block;
  parameter Modelica.SIunits.Frequency f_ref(min=Modelica.Constants.small)=50;
  parameter Real Kp(min=0)=2 "Gain on per-unit frequency error";
  parameter Real Ki(unit="1/s", min=0)=0.1 "Integral gain on per-unit frequency error";
  parameter Modelica.SIunits.Time Tt(min=Modelica.Constants.small)=5 "Actuator tracking time";
  parameter Real yMin=0.01;
  parameter Real yMax=1;
  parameter Real x_start=0.6 "Initial integral-output guess";
  Modelica.Blocks.Interfaces.RealInput f(unit="Hz") annotation(Placement(transformation(extent={{-140,20},{-100,60}})));
  Modelica.Blocks.Interfaces.RealInput gate "Actual actuator position" annotation(Placement(transformation(extent={{-140,-60},{-100,-20}})));
  Modelica.Blocks.Interfaces.RealOutput y annotation(Placement(transformation(extent={{100,-10},{120,10}})));
  Real e "Per-unit frequency error";
  Real x(start=x_start, fixed=false) "Integral contribution, solved from plant equilibrium initially";
  Real raw;
initial equation
  assert(yMax>yMin, "Governor limits must be ordered");
equation
  e=(f_ref-f)/f_ref;
  raw=Kp*e+x;
  y=min(yMax,max(yMin,raw));
  der(x)=Ki*e+(gate-raw)/Tt;
  annotation(Documentation(info="<html><p>Isochronous PI governor without permanent droop. Actual gate tracking limits windup during both position and rate saturation. The enclosing plant must supply an initial equilibrium condition to determine x, or set x(fixed=true) for a specified initial integral contribution.</p><p>Frequency input is Hz; internal error and gate position are per unit. Gains are illustrative and must be retuned for other waterways and inertias.</p></html>"));
end IsochronousGovernor;
