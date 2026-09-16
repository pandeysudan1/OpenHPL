within OpenHPL.Examples.TrollheimControlStudies;
model TwoAreaTieLineStudy
  "Two hydro areas coupled by a dynamic tie-line and controlled using ACE"
  Components.GuideVaneServo servo1;
  Components.WaterColumn waterway1;
  Components.Turbine turbine1;
  Components.ShaftGenerator shaft1(H=3.5);
  Components.GridLoad load1(stepSize=0.10);
  Components.TieLineAGC controller1(tieSign=1);

  Components.GuideVaneServo servo2;
  Components.WaterColumn waterway2(T_w=1.80);
  Components.Turbine turbine2(K_t=1.20);
  Components.ShaftGenerator shaft2(H=4.0);
  Components.GridLoad load2(stepSize=0.0);
  Components.TieLineAGC controller2(tieSign=-1);
  Components.TieLine tieLine(T_12=0.07);

  Modelica.Blocks.Interfaces.RealOutput frequencyDeviation1;
  Modelica.Blocks.Interfaces.RealOutput frequencyDeviation2;
  Modelica.Blocks.Interfaces.RealOutput tiePowerDeviation;
  Modelica.Blocks.Interfaces.RealOutput areaControlError1;
  Modelica.Blocks.Interfaces.RealOutput areaControlError2;
equation
  servo1.command = controller1.command;
  waterway1.guideVaneDeviation = servo1.guideVaneDeviation;
  turbine1.flowDeviation = waterway1.flowDeviation;
  shaft1.mechanicalPowerDeviation = turbine1.mechanicalPowerDeviation;
  shaft1.electricalPowerDeviation =
    load1.electricalPowerDeviation + tieLine.tiePowerDeviation;

  servo2.command = controller2.command;
  waterway2.guideVaneDeviation = servo2.guideVaneDeviation;
  turbine2.flowDeviation = waterway2.flowDeviation;
  shaft2.mechanicalPowerDeviation = turbine2.mechanicalPowerDeviation;
  shaft2.electricalPowerDeviation =
    load2.electricalPowerDeviation - tieLine.tiePowerDeviation;

  tieLine.frequencyDeviation1 = shaft1.frequencyDeviation;
  tieLine.frequencyDeviation2 = shaft2.frequencyDeviation;
  controller1.frequencyDeviation = shaft1.frequencyDeviation;
  controller1.tieLinePower = tieLine.tiePowerDeviation;
  controller2.frequencyDeviation = shaft2.frequencyDeviation;
  controller2.tieLinePower = tieLine.tiePowerDeviation;

  frequencyDeviation1 = shaft1.frequencyDeviation;
  frequencyDeviation2 = shaft2.frequencyDeviation;
  tiePowerDeviation = tieLine.tiePowerDeviation;
  areaControlError1 = controller1.areaControlError;
  areaControlError2 = controller2.areaControlError;
  annotation (experiment(StartTime=0, StopTime=120, Interval=0.05, Tolerance=1e-7));
end TwoAreaTieLineStudy;
