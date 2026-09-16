within OpenHPL.Examples.TrollheimControlStudies;
partial model BasePlant
  "Reservoir operating point, waterway, turbine, shaft-generator and grid load"
  parameter Real nominalFrequency(unit="Hz")=50;
  parameter Real initialPower=0.50 "Operating power in pu";
  Modelica.Blocks.Interfaces.RealInput controlSignal;
  Modelica.Blocks.Interfaces.RealOutput frequencyDeviation;
  Modelica.Blocks.Interfaces.RealOutput guideVaneDeviation;
  Modelica.Blocks.Interfaces.RealOutput flowDeviation;
  Modelica.Blocks.Interfaces.RealOutput mechanicalPowerDeviation;
  Modelica.Blocks.Interfaces.RealOutput electricalPowerDeviation;

  Components.GuideVaneServo servo;
  Components.WaterColumn waterway;
  Components.Turbine turbine;
  Components.ShaftGenerator shaftGenerator;
  Components.GridLoad gridLoad;
equation
  servo.command = controlSignal;
  waterway.guideVaneDeviation = servo.guideVaneDeviation;
  turbine.flowDeviation = waterway.flowDeviation;
  shaftGenerator.mechanicalPowerDeviation = turbine.mechanicalPowerDeviation;
  shaftGenerator.electricalPowerDeviation = gridLoad.electricalPowerDeviation;

  guideVaneDeviation = servo.guideVaneDeviation;
  flowDeviation = waterway.flowDeviation;
  mechanicalPowerDeviation = turbine.mechanicalPowerDeviation;
  electricalPowerDeviation = gridLoad.electricalPowerDeviation;
  frequencyDeviation = shaftGenerator.frequencyDeviation;
end BasePlant;
