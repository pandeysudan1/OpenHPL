within OpenHPLTest.NewTest.MultigenerationSystemWithAreaControl.Components;
block TieLineBiasAGC
  "Secondary controller integrating area control error"
  extends OpenHPLTest.NewTest.Icons.SecondaryAGC;

  parameter Modelica.Units.SI.Frequency f_ref(min=Modelica.Constants.small)=50;
  parameter Modelica.Units.SI.Power P_base(min=Modelica.Constants.small)=100e6;
  parameter Real Ki(unit="1/s", min=0)=0.003
    "Integral gain from ACE to per-unit power-reference shift";
  parameter Real B(unit="W/Hz", min=0)=200e6
    "Frequency-bias coefficient in MW/Hz form";
  parameter Modelica.Units.SI.Power P_tie_schedule=0;
  parameter Real dPMin=-0.30;
  parameter Real dPMax=0.30;
  parameter Real x_start=0;

  Modelica.Blocks.Interfaces.RealInput f(unit="Hz")
    annotation(Placement(transformation(extent={{-140,40},{-100,80}})));
  Modelica.Blocks.Interfaces.RealInput P_schedule(unit="W")
    annotation(Placement(transformation(extent={{-140,-10},{-100,30}})));
  Modelica.Blocks.Interfaces.RealInput P_tie(unit="W")
    annotation(Placement(transformation(extent={{-140,-80},{-100,-40}})));
  Modelica.Blocks.Interfaces.RealOutput P_ref(unit="W")
    annotation(Placement(transformation(extent={{100,20},{120,40}})));
  Modelica.Blocks.Interfaces.RealOutput ACE(unit="W")
    annotation(Placement(transformation(extent={{100,-40},{120,-20}})));

  Real x(start=x_start, fixed=false)
    "Per-unit AGC state";
  Real x_limited;

initial equation
  assert(dPMax>dPMin, "AGC limits must be ordered");

equation
  ACE=B*(f-f_ref) + (P_tie-P_tie_schedule);
  der(x)=-Ki*ACE/P_base;
  x_limited=min(dPMax,max(dPMin,x));
  P_ref=P_schedule + P_base*x_limited;

  annotation(Documentation(info="<html><p>Area-control-error AGC for a stylized two-area study. The sign convention follows positive export from the local area: if frequency falls below nominal or export drops below schedule, ACE becomes negative and the controller raises the local governor reference.</p></html>"));
end TieLineBiasAGC;