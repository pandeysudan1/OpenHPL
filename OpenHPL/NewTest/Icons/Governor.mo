within OpenHPL.NewTest.Icons;
partial block Governor "Frequency dial and feedback governor icon"
  extends OpenHPL.NewTest.Icons.ControlBlock;
  annotation(Icon(graphics={
    Text(extent={{-78,87},{84,61}}, textString="GOV", lineColor={28,108,160}, textStyle={TextStyle.Bold}),
    Ellipse(extent={{-43,54},{49,-38}}, lineColor={28,108,160}, lineThickness=0.7, fillColor={225,238,249}, fillPattern=FillPattern.Solid),
    Line(points={{3,45},{3,35}}, color={28,108,160}, thickness=0.7),
    Line(points={{-27,32},{-20,25}}, color={28,108,160}, thickness=0.7),
    Line(points={{33,32},{26,25}}, color={28,108,160}, thickness=0.7),
    Line(points={{-34,8},{-24,8}}, color={28,108,160}, thickness=0.7),
    Line(points={{40,8},{30,8}}, color={28,108,160}, thickness=0.7),
    Line(points={{3,8},{23,29}}, color={18,112,105}, thickness=1.1),
    Ellipse(extent={{-2,13},{8,3}}, lineColor={18,112,105}, fillColor={18,112,105}, fillPattern=FillPattern.Solid),
    Text(extent={{-21,0},{27,-24}}, textString="Hz", lineColor={28,70,100}),
    Line(points={{62,24},{74,24},{74,-52},{-62,-52},{-62,8},{-48,8}}, color={28,108,160}, thickness=0.6, arrow={Arrow.None,Arrow.Filled}),
    Text(extent={{-76,-66},{84,-90}}, textString="ISO / PI", lineColor={28,108,160}, textStyle={TextStyle.Bold})}));
end Governor;
