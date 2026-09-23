within NewTest.FCRPrequalification;
block FCRComparisonMetrics
  "Compare commanded reserve, actuator delivery, and hydraulic power delivery"
  parameter Real gateBase(min=Modelica.Constants.small)=1
    "Gate normalization base";
  parameter Modelica.SIunits.Power powerBase(min=Modelica.Constants.small)=100e6
    "Power normalization base";

  Modelica.Blocks.Interfaces.RealInput commandedReserve;
  Modelica.Blocks.Interfaces.RealInput deliveredGateReserve;
  Modelica.Blocks.Interfaces.RealInput incrementalMechanicalPower(unit="W");

  output Real gateTrackingError;
  output Real gateTrackingRatio;
  output Real normalizedMechanicalPower;
  output Real powerToCommandRatio;

equation
  gateTrackingError = commandedReserve - deliveredGateReserve;
  gateTrackingRatio =
    if abs(commandedReserve) > Modelica.Constants.small
    then deliveredGateReserve/commandedReserve
    else 0;

  normalizedMechanicalPower = incrementalMechanicalPower/powerBase;

  powerToCommandRatio =
    if abs(commandedReserve) > Modelica.Constants.small
    then normalizedMechanicalPower/commandedReserve
    else 0;

  annotation(Documentation(info="<html>
<p>Compact comparison block for FCR studies. It separates controller-command error,
gate-delivery error, and normalized mechanical-power delivery.</p>
<p>This block is intentionally algebraic. Dynamic gain/phase estimation over a
frequency sweep should be computed from exported time-series data.</p>
</html>"));
end FCRComparisonMetrics;
