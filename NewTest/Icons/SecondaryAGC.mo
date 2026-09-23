within NewTest.Icons;
partial block SecondaryAGC "Secondary frequency-control / AGC icon"
  extends NewTest.Icons.ControlBlock;
  annotation(Icon(graphics={
    Text(extent={{-80,86},{84,58}}, textString="AGC",
      lineColor={28,108,160}, textStyle={TextStyle.Bold}),
    Ellipse(extent={{-54,42},{-10,-2}}, lineColor={28,108,160},
      fillColor={225,238,249}, fillPattern=FillPattern.Solid),
    Text(extent={{-48,32},{-16,7}}, textString="Hz",
      lineColor={28,70,100}),
    Line(points={{-10,20},{14,20},{14,42},{42,42},{42,8},{66,8}},
      color={18,112,105}, thickness=1.0,
      arrow={Arrow.None,Arrow.Filled}),
    Text(extent={{6,-4},{62,-30}}, textString="P_ref",
      lineColor={18,112,105}),
    Text(extent={{-84,-60},{84,-88}}, textString="SECONDARY",
      lineColor={28,108,160}, textStyle={TextStyle.Bold})}));
end SecondaryAGC;
