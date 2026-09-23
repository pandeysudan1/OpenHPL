within NewTest.Icons;
partial block Governor "Frequency dial and feedback governor icon"
  extends NewTest.Icons.ControlBlock;
  annotation(Icon(graphics={
    Text(extent={{-78,87},{84,61}}, textString="GOV", lineColor={28,108,160}, textStyle={TextStyle.Bold}),
    Ellipse(extent={{-43,54},{49,-38}}, lineColor={28,108,160}, lineThickness=0.7, fillColor={225,238,249}, fillPattern=FillPattern.Solid),
    Line(points={{3,8},{23,29}}, color={18,112,105}, thickness=1.1),
    Text(extent={{-21,0},{27,-24}}, textString="Hz", lineColor={28,70,100}),
    Text(extent={{-76,-66},{84,-90}}, textString="ISO / PI", lineColor={28,108,160}, textStyle={TextStyle.Bold})}));
end Governor;
