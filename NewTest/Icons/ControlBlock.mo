within NewTest.Icons;
partial block ControlBlock "Shared frame for power-system control icons"
  annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={
    Rectangle(extent={{-100,100},{100,-100}}, radius=12, lineColor={28,70,100}, lineThickness=0.5, fillColor={245,249,252}, fillPattern=FillPattern.Solid),
    Rectangle(extent={{-100,100},{-88,-100}}, radius=4, lineColor={28,108,160}, fillColor={28,108,160}, fillPattern=FillPattern.Solid),
    Text(extent={{-150,142},{150,108}}, textString="%name", lineColor={28,70,100})}));
end ControlBlock;
