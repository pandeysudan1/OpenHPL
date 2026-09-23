within NewTest.Icons;
partial block FCRGovernor "Fast frequency-containment controller icon"
  extends NewTest.Icons.ControlBlock;
  annotation(Icon(graphics={
    Text(extent={{-80,86},{84,58}}, textString="FCR",
      lineColor={28,108,160}, textStyle={TextStyle.Bold}),
    Ellipse(extent={{-54,42},{-10,-2}}, lineColor={28,108,160},
      fillColor={225,238,249}, fillPattern=FillPattern.Solid),
    Text(extent={{-48,32},{-16,7}}, textString="Hz",
      lineColor={28,70,100}),
    Line(points={{-10,20},{18,20},{18,40},{44,40},{44,8},{68,8}},
      color={18,112,105}, thickness=1.1,
      arrow={Arrow.None,Arrow.Filled}),
    Line(points={{16,-8},{28,-20},{40,-8},{52,-20}},
      color={28,108,160}, thickness=0.9),
    Text(extent={{-84,-60},{84,-88}}, textString="FAST RESERVE",
      lineColor={28,108,160}, textStyle={TextStyle.Bold})}));
end FCRGovernor;
