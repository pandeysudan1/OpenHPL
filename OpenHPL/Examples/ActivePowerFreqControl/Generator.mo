within OpenHPL.Examples.ActivePowerFreqControl;
model Generator "Starter generator-only model for APFC studies"
  extends OpenHPL.Examples.PowerSystemSimple;
  annotation (experiment(StopTime=20), Documentation(info="<html>
<p>Baseline generator-grid dynamics model for APFC studies.</p>
<p>Use this model to tune inertia, damping, and grid frequency response before full hydro coupling.</p>
</html>"));
end Generator;
