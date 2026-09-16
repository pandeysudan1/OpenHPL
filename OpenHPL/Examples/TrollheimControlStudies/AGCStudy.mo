within OpenHPL.Examples.TrollheimControlStudies;
model AGCStudy
  "Primary droop plus secondary integral control"
  extends BasePlant;
  Components.AGCController controller;
equation
  controller.frequencyDeviation = frequencyDeviation;
  controlSignal = controller.command;
  annotation (experiment(StartTime=0, StopTime=60, Interval=0.05, Tolerance=1e-7));
end AGCStudy;
