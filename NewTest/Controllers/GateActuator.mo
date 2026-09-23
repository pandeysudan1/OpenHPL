within NewTest.Controllers;
block GateActuator "Gate servo with position and opening/closing rate limits"
  extends NewTest.Icons.GateActuator;
  parameter Modelica.SIunits.Time T(min=Modelica.Constants.small)=0.5;
  parameter Real yMin=0.01 "Positive minimum avoids the turbine's zero-gate singularity";
  parameter Real yMax=1;
  parameter Real openingRate(unit="1/s", min=Modelica.Constants.small)=0.05;
  parameter Real closingRate(unit="1/s", min=Modelica.Constants.small)=0.05;
  parameter Real y_start=0.6 "Initial guess; equilibrium is solved during initialization";
  Modelica.Blocks.Interfaces.RealInput u annotation(Placement(transformation(extent={{-140,-20},{-100,20}})));
  Modelica.Blocks.Interfaces.RealOutput y(start=y_start, fixed=false) annotation(Placement(transformation(extent={{100,-10},{120,10}})));
  Real target(start=y_start);
initial equation
  assert(yMax>yMin, "Gate limits must be ordered");
  y=target;
equation
  target=min(yMax,max(yMin,u));
  der(y)=min(openingRate,max(-closingRate,(target-y)/T));
  annotation(Documentation(info="<html><p>First-order gate servo. The target is position-limited and the gate derivative is rate-limited. Initialization solves a stationary gate position. Connect the actual gate position to the governor tracking input.</p></html>"));
end GateActuator;
