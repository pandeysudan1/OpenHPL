within NewTest.Controllers;
block FCRGovernor
  "Fast frequency-containment governor with filtering, deadband and reserve limits"
  extends NewTest.Icons.FCRGovernor;

  parameter Modelica.SIunits.Frequency f_ref(min=Modelica.Constants.small)=50;
  parameter Modelica.SIunits.Time Tm(min=Modelica.Constants.small)=0.10
    "Frequency measurement/filter time constant";
  parameter Modelica.SIunits.Frequency deadband(min=0)=0.00
    "Symmetric frequency deadband";
  parameter Real Kf(unit="1/Hz", min=0)=1.0
    "Gate-command gain per Hz outside the deadband";
  parameter Real y_bias=0.45 "Nominal gate command at nominal frequency";
  parameter Real reserveUp(min=0)=0.20
    "Maximum upward FCR gate increment";
  parameter Real reserveDown(min=0)=0.20
    "Maximum downward FCR gate decrement";
  parameter Modelica.SIunits.Time Tt(min=Modelica.Constants.small)=1.0
    "Actuator tracking time for anti-windup";
  parameter Real yMin=0.01;
  parameter Real yMax=1.0;

  Modelica.Blocks.Interfaces.RealInput f(unit="Hz")
    annotation(Placement(transformation(extent={{-140,30},{-100,70}})));
  Modelica.Blocks.Interfaces.RealInput gate
    "Actual actuator position for tracking"
    annotation(Placement(transformation(extent={{-140,-70},{-100,-30}})));
  Modelica.Blocks.Interfaces.RealOutput y
    annotation(Placement(transformation(extent={{100,-10},{120,10}})));

  Real fFilt(start=f_ref, fixed=true) "Filtered frequency";
  Real df "Filtered frequency deviation, Hz";
  Real dfActive "Frequency deviation outside deadband";
  Real reserveCommand "Unsaturated incremental FCR command";
  Real reserveLimited "Reserve-limited incremental FCR command";
  Real raw "Command before position saturation";
  Real trackingCorrection;

equation
  der(fFilt)=(f-fFilt)/Tm;
  df=fFilt-f_ref;

  dfActive=
    if df > deadband then df-deadband
    elseif df < -deadband then df+deadband
    else 0;

  reserveCommand=-Kf*dfActive;
  reserveLimited=min(reserveUp,max(-reserveDown,reserveCommand));

  raw=y_bias+reserveLimited;
  y=min(yMax,max(yMin,raw));

  trackingCorrection=(gate-y)/Tt;

  annotation(Documentation(info="<html>
<p>Fast frequency-containment controller intended for reusable hydro FCR studies.</p>
<p>The signal path is: measured frequency -> first-order filter -> symmetric deadband
-> proportional frequency response -> up/down reserve limitation -> gate command.</p>
<p>For underfrequency, df&lt;0 and the reserve command is positive. For overfrequency,
the command is negative. The block is deliberately parameterized and does not encode
a specific TSO product definition.</p>
<p>The actual gate input is exposed for consistent actuator-tracking semantics and
future anti-windup/rate-limited extensions.</p>
</html>"));
end FCRGovernor;
