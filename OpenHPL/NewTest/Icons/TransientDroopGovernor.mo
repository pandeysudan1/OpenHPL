within OpenHPL.NewTest.Icons;
partial block TransientDroopGovernor "Permanent plus transient droop governor icon"
  extends OpenHPL.NewTest.Icons.ControlBlock;
  annotation(Icon(graphics={
    Text(extent={{-78,87},{84,61}}, textString="GOV", lineColor={28,108,160},
      textStyle={TextStyle.Bold}),
    Line(points={{-56,38},{-56,-38},{64,-38}}, color={28,70,100},
      thickness=0.5, arrow={Arrow.None,Arrow.Filled}),
    Line(points={{-44,28},{48,-24}}, color={28,108,160}, thickness=1.1),
    Line(points={{-42,20},{-18,4},{2,18},{22,2},{46,-14}},
      color={18,112,105}, thickness=0.9),
    Text(extent={{-82,-60},{84,-88}}, textString="TRANSIENT DROOP",
      lineColor={28,108,160}, textStyle={TextStyle.Bold})}));
end TransientDroopGovernor;
