within OpenHPL.NewTest.Icons;
partial block DroopGovernor "Permanent-droop governor with power-frequency slope"
  extends OpenHPL.NewTest.Icons.ControlBlock;
  annotation(Icon(graphics={
    Text(extent={{-78,87},{84,61}},textString="GOV",lineColor={28,108,160},textStyle={TextStyle.Bold}),
    Line(points={{-52,43},{-52,-42},{62,-42}},color={28,70,100},thickness=0.5,arrow={Arrow.None,Arrow.Filled}),
    Line(points={{-40,33},{49,-25}},color={28,108,160},thickness=1.2),
    Text(extent={{-76,-65},{84,-90}},textString="DROOP",lineColor={28,108,160},textStyle={TextStyle.Bold})}));
end DroopGovernor;
