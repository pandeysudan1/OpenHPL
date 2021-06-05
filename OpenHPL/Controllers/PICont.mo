within OpenHPL.Controllers;
model PICont "Droop controller model PI inside"
  extends OpenHPL.Icons.Governor;
  outer Constants Const "using standard class with constants";

  parameter Real Kp = 0.03 "Kp values for PI controllers" annotation (
   Dialog(group = "Controller parameter"));
  parameter Real Ti = 3 "Ti values for PI controllers" annotation (
    Dialog(group = "Controller parameter"));
  parameter Real uMax=1,uMin=0.01;
  Real x(start=0) "ng initial states for PI controller";

  Modelica.Blocks.Interfaces.RealInput u
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
  //Modelica.Blocks.Interfaces.RealVectorInput P_sg[ng]
   // annotation (Placement(transformation(extent={{-130,40},{-90,80}})));
  Modelica.Blocks.Interfaces.RealOutput y
    "Vector outputs for turbine valve signal"
    annotation (Placement(transformation(extent={{100,-20},{140,20}})));
equation


    der(x) = u/Ti;
    y = Kp*(x +u);
    //y = smooth(0,if u > uMax then uMax else if u < uMin then uMin else u);

  annotation (
    Documentation(info="<html>
<p>This is a simple model of the governor that controls the guide vane oppening in the turbine based on the reference power production.</p>
<p><br><br>This is a simple model of a droop controller that determines the dynamic reference power to the PI controller for generating turbine valve signal for controlling the flow.</p>
<p>The model is taken from:&nbsp;<a href=\"Resources/Report/Generator_model.pdf\">Resources/Report/Generator_model.pdf</a></p>
</html>"));
end PICont;
