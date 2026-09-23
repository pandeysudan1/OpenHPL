within NewTest.Controllers;
block TransientDroopGovernor "PI governor with permanent and transient droop"
  extends NewTest.Icons.TransientDroopGovernor;

  parameter Modelica.SIunits.Frequency f_ref(min=Modelica.Constants.small)=50;
  parameter Modelica.SIunits.Power P_base(min=Modelica.Constants.small)=100e6
    "Power base shared by P and P_ref";
  parameter Real R(min=0)=0.04 "Permanent droop";
  parameter Real Rt(min=0)=0.10 "Transient-droop gain";
  parameter Modelica.SIunits.Time Tr(min=Modelica.Constants.small)=1.75
    "Transient-droop washout time constant";
  parameter Real Kp(min=0)=2 "Gain on combined governing error";
  parameter Real Ki(unit="1/s", min=0)=0.1 "Integral gain";
  parameter Modelica.SIunits.Time Tt(min=Modelica.Constants.small)=5
    "Actuator-tracking anti-windup time";
  parameter Real yMin=0.01;
  parameter Real yMax=1;
  parameter Real x_start=0.45 "Initial integral-output guess";
  parameter Real z_start=0.45 "Initial filtered-gate guess";

  Modelica.Blocks.Interfaces.RealInput f(unit="Hz")
    annotation(Placement(transformation(extent={{-140,50},{-100,90}})));
  Modelica.Blocks.Interfaces.RealInput P(unit="W")
    annotation(Placement(transformation(extent={{-140,10},{-100,50}})));
  Modelica.Blocks.Interfaces.RealInput P_ref(unit="W")
    annotation(Placement(transformation(extent={{-140,-30},{-100,10}})));
  Modelica.Blocks.Interfaces.RealInput gate "Actual actuator position"
    annotation(Placement(transformation(extent={{-140,-80},{-100,-40}})));
  Modelica.Blocks.Interfaces.RealOutput y
    annotation(Placement(transformation(extent={{100,-10},{120,10}})));

  Real frequencyError;
  Real powerError;
  Real z(start=z_start, fixed=false) "Low-pass gate state";
  Real transientSignal "Washout contribution Rt*(gate-z)";
  Real e "Combined governing error";
  Real x(start=x_start, fixed=false) "Integral contribution";
  Real raw;

initial equation
  assert(yMax > yMin, "Governor limits must be ordered");
  assert(Tr > 0 and Tt > 0 and P_base > 0 and f_ref > 0,
    "Time constants and bases must be positive");
  z = gate "No artificial transient-droop kick at initialization";

equation
  frequencyError = (f_ref - f)/f_ref;
  powerError = (P - P_ref)/P_base;

  der(z) = (gate - z)/Tr;
  transientSignal = Rt*(gate - z);

  e = frequencyError - R*powerError - transientSignal;

  raw = Kp*e + x;
  y = min(yMax, max(yMin, raw));
  der(x) = Ki*e + (gate - raw)/Tt;

  annotation(Documentation(info="<html>
<p>Hydro governor with permanent droop and a transient-droop washout term.</p>
<p>The dynamic term is generated from the actual gate:
Tr*der(z)=gate-z and transientSignal=Rt*(gate-z).
It is active during gate motion and decays to zero at steady state.</p>
<p>The governing error is
e=(f_ref-f)/f_ref - R*(P-P_ref)/P_base - transientSignal.
Therefore the final equilibrium retains the permanent-droop characteristic,
while transient droop modifies the short-term response.</p>
<p>The structure follows the transient-droop idea already used by the OpenHPL
Governor model, but keeps the NewTest reusable-controller semantics and actuator
tracking anti-windup.</p>
</html>"));
end TransientDroopGovernor;
