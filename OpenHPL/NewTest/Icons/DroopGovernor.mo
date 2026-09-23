within OpenHPL.NewTest.Icons;
partial block DroopGovernor "Permanent-droop governor with power-frequency slope"
  extends OpenHPL.NewTest.Icons.ControlBlock;
  annotation(Icon(graphics={
    Text(extent={{-78,87},{84,61}},textString="GOV",lineColor={28,108,160},textStyle={TextStyle.Bold}),
    Line(points={{-52,43},{-52,-42},{62,-42}},color={28,70,100},thickness=0.5,arrow={Arrow.None,Arrow.Filled}),
    Line(points={{-52,-42},{-52,48}},color={28,70,100},thickness=0.5,arrow={Arrow.None,Arrow.Filled}),
    Line(points={{-40,33},{49,-25}},color={28,108,160},thickness=1.2),
    Ellipse(extent={{-1,12},{9,2}},lineColor={18,112,105},fillColor={18,112,105},fillPattern=FillPattern.Solid),
    Text(extent={{-82,57},{-57,34}},textString="f",lineColor={28,70,100}),
    Text(extent={{57,-22},{82,-45}},textString="P",lineColor={28,70,100}),
    Text(extent={{-76,-65},{84,-90}},textString="DROOP",lineColor={28,108,160},textStyle={TextStyle.Bold})}));
end DroopGovernor;
