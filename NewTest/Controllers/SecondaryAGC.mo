within NewTest.Controllers;
block SecondaryAGC
  "Secondary frequency controller that adjusts the governor power reference"
  extends NewTest.Icons.SecondaryAGC;

  parameter Modelica.SIunits.Frequency f_ref(min=Modelica.Constants.small)=50;
  parameter Modelica.SIunits.Power P_base(min=Modelica.Constants.small)=100e6;
  parameter Real Ki(unit="1/s", min=0)=0.02
    "Integral gain from per-unit frequency error to per-unit power-reference shift";
  parameter Real dPMin=-0.30
    "Minimum AGC power-reference shift on P_base";
  parameter Real dPMax=0.30
    "Maximum AGC power-reference shift on P_base";
  parameter Real x_start=0
    "Initial per-unit AGC power-reference shift";

  Modelica.Blocks.Interfaces.RealInput f(unit="Hz")
    annotation(Placement(transformation(extent={{-140,20},{-100,60}})));
  Modelica.Blocks.Interfaces.RealInput P_schedule(unit="W")
    "Scheduled power before AGC correction"
    annotation(Placement(transformation(extent={{-140,-60},{-100,-20}})));
  Modelica.Blocks.Interfaces.RealOutput P_ref(unit="W")
    "Power reference supplied to the primary governor"
    annotation(Placement(transformation(extent={{100,-10},{120,10}})));

  Real e_f "Per-unit frequency error";
  Real x(start=x_start, fixed=false)
    "Per-unit secondary-control state";
  Real x_limited;

initial equation
  assert(dPMax>dPMin, "AGC limits must be ordered");

equation
  e_f=(f_ref-f)/f_ref;
  der(x)=Ki*e_f;
  x_limited=min(dPMax,max(dPMin,x));
  P_ref=P_schedule + P_base*x_limited;

  annotation(Documentation(info="<html>
<p>Secondary frequency-control block. It does not replace the primary hydro governor.
Instead it slowly shifts the governor power reference.</p>
<p>e_f=(f_ref-f)/f_ref, der(x)=Ki*e_f, and
P_ref=P_schedule+P_base*clip(x).</p>
<p>Connect P_ref to PermanentDroopGovernor.P_ref or
TransientDroopGovernor.P_ref. This keeps primary and secondary control
architecturally separate and allows the same droop governor to be reused
with or without AGC.</p>
</html>"));
end SecondaryAGC;
