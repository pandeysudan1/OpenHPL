within OpenHPLTest.NewTest.MultigenerationSystemWithAreaControl.Components;
block TieLinePower
  "Linearized tie-line power exchange between two coherent areas"
  extends OpenHPLTest.NewTest.Icons.ControlBlock;

  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Real T12(unit="W/rad", min=0)=300e6
    "Synchronizing coefficient relating angle separation to transfer power";
  parameter Modelica.Units.SI.Power P_schedule=0
    "Scheduled export from area 1 to area 2";

  Modelica.Blocks.Interfaces.RealInput f1(unit="Hz")
    annotation(Placement(transformation(extent={{-140,40},{-100,80}})));
  Modelica.Blocks.Interfaces.RealInput f2(unit="Hz")
    annotation(Placement(transformation(extent={{-140,-80},{-100,-40}})));
  Modelica.Blocks.Interfaces.RealOutput P12(unit="W")
    "Positive means export from area 1 to area 2"
    annotation(Placement(transformation(extent={{100,-10},{120,10}})));

  Real dP_tie(start=0, fixed=false)
    "Deviation around the scheduled transfer";

initial equation
  dP_tie=0;

equation
  der(dP_tie)=2*Modelica.Constants.pi*T12*((f1-f_nom) - (f2-f_nom));
  P12=P_schedule + dP_tie;

  annotation(Icon(graphics={
    Text(extent={{-70,78},{74,50}}, textString="TIE", lineColor={28,108,160}, textStyle={TextStyle.Bold}),
    Line(points={{-60,0},{58,0}}, color={18,112,105}, thickness=1.2),
    Polygon(points={{58,0},{34,12},{34,-12},{58,0}}, lineColor={18,112,105}, fillColor={18,112,105}, fillPattern=FillPattern.Solid),
    Text(extent={{-86,-58},{88,-86}}, textString="P12", lineColor={28,108,160}, textStyle={TextStyle.Bold})}),
    Documentation(info="<html><p>Stylized two-area tie-line model. The state tracks deviation from the scheduled transfer using the classic small-signal relationship d(Delta P_tie)/dt = 2*pi*T12*(Delta f1 - Delta f2).</p></html>"));
end TieLinePower;