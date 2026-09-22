within OpenHPL.ElectroMech.Turbines;
model PumpTurbine "Simple reversible pump-turbine model with mechanical connectors"
  extends BaseClasses.Power2Torque(f_0=data.f_0, power(y=Wdot_s));
  extends Interfaces.TurbineContacts;
  extends Interfaces.TwoContacts;
  extends Icons.Turbine;

  type OperatingMode = enumeration(
      Turbine "Generating mode",
      Pump "Pumping mode");

  parameter OperatingMode mode = OperatingMode.Turbine "Default operating mode"
    annotation (Dialog(group = "Operating mode"));
  parameter Boolean enable_modeInput = false
    "If checked, use Boolean input to switch between turbine and pump mode"
    annotation (choices(checkBox = true), Dialog(group = "Operating mode", tab = "I/O"));
  parameter SI.Height H_turbine_n = 100 "Nominal head in turbine mode"
    annotation (Dialog(group = "Nominal values"));
  parameter SI.VolumeFlowRate Vdot_turbine_n = 3 "Nominal volume flow rate in turbine mode"
    annotation (Dialog(group = "Nominal values"));
  parameter SI.Height H_pump_n = H_turbine_n "Nominal head rise in pump mode"
    annotation (Dialog(group = "Nominal values"));
  parameter SI.VolumeFlowRate Vdot_pump_n = Vdot_turbine_n "Nominal volume flow rate in pump mode"
    annotation (Dialog(group = "Nominal values"));
  parameter SI.PerUnit u_turbine_n = 1 "Nominal opening in turbine mode"
    annotation (Dialog(group = "Nominal values"));
  parameter SI.PerUnit u_pump_n = 1 "Nominal opening in pump mode"
    annotation (Dialog(group = "Nominal values"));
  parameter Real alpha = 1
    "Exponent of opening curve for both modes"
    annotation (Dialog(tab = "Advanced", group = "Opening law"));
  parameter Boolean ConstEfficiency = true
    "If checked the constant turbine efficiency eta_h is used, otherwise specify lookup table for turbine efficiency"
    annotation (Dialog(group = "Turbine efficiency"), choices(checkBox = true));
  parameter SI.Efficiency eta_h = 0.9 "Hydraulic efficiency in turbine mode"
    annotation (Dialog(group = "Turbine efficiency", enable = ConstEfficiency));
  replaceable parameter OpenHPL.Types.Efficiency VarEfficiency constrainedby OpenHPL.Types.Efficiency
    "Turbine efficiency lookup table as function of guide-vane opening"
    annotation (choicesAllMatching = true, Dialog(group = "Turbine efficiency", enable = not ConstEfficiency));
  parameter SI.Efficiency eta_p = 0.9 "Hydraulic efficiency in pump mode"
    annotation (Dialog(group = "Pump efficiency"));
  Modelica.Blocks.Interfaces.BooleanInput pumpMode_in = mode == OperatingMode.Pump
    "False = turbine mode, true = pump mode"
    annotation (Placement(transformation(origin = {-40, 120}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-40, 120}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Blocks.Math.Feedback lossCorrection
    annotation (Placement(transformation(extent = {{-50, 70}, {-30, 90}})));
  Modelica.Blocks.Tables.CombiTable1Dv efficiencyCurve(
    table = VarEfficiency.EffTable,
    smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative,
    extrapolation = Modelica.Blocks.Types.Extrapolation.LastTwoPoints)
    "Efficiency curve in turbine mode"
    annotation (Placement(transformation(origin = {-70, -70}, extent = {{-10, -10}, {10, 10}})));
  output Modelica.Units.SI.EnergyFlowRate Wdot_s
    "Shaft power, positive in turbine mode and negative in pump mode";

protected
  parameter Real C_v_turbine = Vdot_turbine_n / sqrt(H_turbine_n * data.g * data.rho) / u_turbine_n
    "Equivalent valve capacity in turbine mode";
  parameter Real C_v_pump = Vdot_pump_n / sqrt(H_pump_n * data.g * data.rho) / u_pump_n
    "Equivalent valve capacity in pump mode";
  constant Real epsilon = 5.0e-5 "Regularization constant";
  SI.Pressure dp "Pressure difference, inlet minus outlet";
  SI.MassFlowRate mdot "Mass flow rate";
  SI.VolumeFlowRate Vdot "Volume flow rate";
  SI.EnergyFlowRate Wdot_h "Hydraulic power transfer";
  SI.PerUnit opening "Limited guide-vane opening";
  SI.Efficiency eta_t "Effective turbine efficiency";
  Boolean pumpModeActive "Resolved operating mode";

equation
  i.mdot + o.mdot = 0;
  mdot = i.mdot;
  Vdot = mdot / data.rho;
  dp = i.p - o.p;
  o.elevation.z = i.elevation.z "Elevation propagation: no height change across pump-turbine";

  opening = min(1, max(0, u_t));
  efficiencyCurve.u[1] = opening;
  eta_t = if ConstEfficiency then eta_h else efficiencyCurve.y[1];
  pumpModeActive = pumpMode_in;

  if pumpModeActive then
    (-dp) * (C_v_pump * max(epsilon, opening ^ alpha)) ^ 2 = Vdot * abs(Vdot);
    Wdot_h = dp * Vdot;
    Wdot_s = Wdot_h / max(eta_p, epsilon);
  else
    dp * (C_v_turbine * max(epsilon, opening ^ alpha)) ^ 2 = Vdot * abs(Vdot);
    Wdot_h = dp * Vdot;
    Wdot_s = eta_t * Wdot_h;
  end if;

  connect(P_out, lossCorrection.y) annotation (Line(
      points = {{40, 110}, {40, 80}, {-31, 80}},
      color = {0, 0, 127},
      pattern = LinePattern.Dash));
  connect(lossCorrection.u1, power.y) annotation (Line(points = {{-48, 80}, {-88, 80}, {-88, 30}, {-81, 30}}, color = {0, 0, 127}));
  connect(frictionLoss.power, lossCorrection.u2) annotation (Line(points = {{-1, 12}, {-40, 12}, {-40, 72}}, color = {0, 0, 127}));
  annotation (
    preferredView = "info",
    Documentation(info = "<html>
<h4>Simple Pump-Turbine Model</h4>

<p>This reversible model represents a hydraulic unit that can either generate electrical
power as a turbine or consume electrical power as a pump. The model uses the standard
OpenHPL hydraulic connectors together with the mechanical shaft representation from
<code>Power2Torque</code>.</p>

<h5>Operating Modes</h5>
<ul>
  <li><strong>Turbine mode</strong>: the model behaves like a throttled turbine. A positive
      pressure drop from inlet to outlet drives a positive shaft power output.</li>
  <li><strong>Pump mode</strong>: the model adds head to the water. The outlet pressure becomes
      larger than the inlet pressure and the shaft power is negative, meaning that
      mechanical/electrical power is consumed.</li>
</ul>

<p>The default operating mode is selected by the parameter <code>mode</code>. The Boolean input
<code>pumpMode_in</code> is bound to this parameter by default, and an external connection can be used
to switch between modes during simulation. The parameter <code>enable_modeInput</code> only controls
the visual cue on the icon.</p>

<h5>Hydraulic Characteristic</h5>
<p>Both operating modes use a simple valve-like characteristic based on nominal head and
nominal discharge. Separate nominal values can be given for turbine and pump operation.
The guide-vane opening signal <code>u_t</code> is limited internally to the range [0,1].</p>

<h5>Efficiency</h5>
<p>In turbine mode the hydraulic efficiency can be constant or described by a lookup table
in the same way as the simple turbine model. In pump mode a constant hydraulic efficiency
<code>eta_p</code> is used.</p>
</html>"),
    Icon(graphics = {Text(
          visible = enable_P_out,
          extent = {{30, 100}, {50, 80}},
          textColor = {0, 0, 0},
          textString = "P"), Text(
          extent = {{-96, 100}, {-60, 80}},
          textColor = {0, 0, 0},
          textString = "Opening"), Text(
          visible = enable_modeInput,
          extent = {{-58, 100}, {-22, 80}},
          textColor = {0, 0, 0},
          textString = "Mode")}));
end PumpTurbine;
