within OpenHPL.NewTest.Icons;
partial block ControlBlock "Shared frame for power-system control icons"
  annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={
    Rectangle(extent={{-100,100},{100,-100}}, radius=12, lineColor={28,70,100}, lineThickness=0.5, fillColor={245,249,252}, fillPattern=FillPattern.Solid),
    Rectangle(extent={{-100,100},{-88,-100}}, radius=4, lineColor={28,108,160}, fillColor={28,108,160}, fillPattern=FillPattern.Solid),
    Text(extent={{-150,142},{150,108}}, textString="%name", lineColor={28,70,100})}),
    Documentation(info="<html><p>Reusable vector frame for future power-system controllers. Extend this class and add a distinctive central symbol and a short caption. Keep symbols inside +/-80 and leave connector locations clear. Blue denotes regulation; teal denotes actuation. Graphics are native Modelica primitives and need no external image files.</p></html>"));
end ControlBlock;
