within OpenHPL.Examples.TrollheimControlStudies;
model IsochronousStudy
  "PI speed control: frequency returns to 50 Hz"
  extends BasePlant;
  Components.IsochronousPI controller;
equation
  controller.frequencyDeviation = frequencyDeviation;
  controlSignal = controller.command;
  annotation (experiment(StartTime=0, StopTime=60, Interval=0.05, Tolerance=1e-7));
end IsochronousStudy;
