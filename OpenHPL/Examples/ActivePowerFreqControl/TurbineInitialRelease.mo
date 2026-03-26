within OpenHPL.Examples.ActivePowerFreqControl;
model TurbineInitialRelease "Starter turbine-only model for APFC studies"
  extends OpenHPL.Examples.SimpleTurbine;
  annotation (experiment(StopTime=1000), Documentation(info="<html>
<p>Baseline turbine model used as the first APFC study step.</p>
<p>This model is intentionally minimal and aligned with the initial simple turbine workflow.</p>
<p>Next step: connect governor and generator dynamics incrementally.</p>
</html>"));
end TurbineInitialRelease;
