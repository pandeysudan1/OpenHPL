within OpenHPL.ElectroMech.Generators;
model SimpleGen2 "Model of a simple generator"
  outer Constants Const "Using standard class with constants";
  import Modelica.Constants.pi;
  extends OpenHPL.Icons.Generator;
  //// geometrical parameters of the agreggate
  parameter Modelica.SIunits.MomentOfInertia J = 5e5 "Moment of inertia of the generator";
  //// variables
  Modelica.SIunits.Frequency f(start = 50) "Frequency";
  Modelica.SIunits.EnergyFlowRate Pm "Shaft power";
  Modelica.SIunits.EnergyFlowRate Pe = u  "Electrical power";
  //// conectors
  Modelica.Blocks.Interfaces.RealInput u "Electrical demand"    annotation (
    Placement(visible = true, transformation(extent={{-140,-20},{-100,20}},     rotation = 0), iconTransformation(extent = {{-120, -20}, {-80, 20}}, rotation = 0)));
  Modelica.Blocks.Interfaces.RealInput P_in = Pm "Input of mechanical power" annotation (
    Placement(visible = true, transformation(origin={3.55271e-15,120},
                                                                  extent={{-20,-20},{20,20}},      rotation = 270)));


equation
  der(f) = 1/(4*pi*pi*f*J)*(Pm-Pe)
  annotation (
    Documentation(info="<html><p>Simple model of an ideal generator with friction.</p>
<p>This model has inputs as electric power available on the grid and the turbine shaft power.
This model based on the angular momentum balance, which depends on the turbine shaft power,
 the friction loss in the aggregate rotation and the power taken up by the generator.</p>
<p align=\"center\">
<img src=\"modelica://OpenHPL/Resources/Images/simplegen.png\">
</p>
</html>"));
end SimpleGen2;
