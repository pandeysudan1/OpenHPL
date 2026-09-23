within NewTest.Icons;
partial block GateActuator "Hydraulic piston and guide-vane actuator icon"
  extends NewTest.Icons.ControlBlock;
  annotation(Icon(graphics={
    Text(extent={{-78,87},{84,61}}, textString="SERVO", lineColor={18,112,105}, textStyle={TextStyle.Bold}),
    Rectangle(extent={{-63,36},{17,-12}}, radius=4, lineColor={18,112,105}, lineThickness=0.7, fillColor={216,240,233}, fillPattern=FillPattern.Solid),
    Rectangle(extent={{-20,33},{-10,-9}}, lineColor={18,112,105}, fillColor={18,112,105}, fillPattern=FillPattern.Solid),
    Line(points={{-10,12},{58,12}}, color={18,112,105}, thickness=1.4),
    Ellipse(extent={{53,17},{63,7}}, lineColor={18,112,105}, fillColor={245,249,252}, fillPattern=FillPattern.Solid),
    Line(points={{58,12},{70,-30}}, color={18,112,105}, thickness=1.0),
    Line(points={{50,-33},{80,-27}}, color={18,112,105}, thickness=1.4),
    Text(extent={{-76,-64},{84,-88}}, textString="GATE", lineColor={18,112,105}, textStyle={TextStyle.Bold})}));
end GateActuator;
