within OpenHPL.Examples.TrollheimControlStudies;
model DroopStudy
  "Primary control with 5 percent droop and nonzero steady-state frequency error"
  extends BasePlant;
  Components.DroopController controller;
equation
  controller.frequencyDeviation = frequencyDeviation;
  controlSignal = controller.command;
  annotation (experiment(StartTime=0, StopTime=60, Interval=0.05, Tolerance=1e-7));
end DroopStudy;
