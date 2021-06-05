within OpenHPL.Controllers;
model DroopControllerPI "Droop controller model PI inside"
  extends OpenHPL.Icons.Governor;
  outer Constants Const "using standard class with constants";
  //// control parameters of the governor
  parameter Modelica.SIunits.Frequency f_ref = 50 "Reference frequency of the system" annotation (
    Dialog(group = "Controller parameter"));
  parameter Modelica.SIunits.Power P_r = 100e6 "Rated power of the generator" annotation (
    Dialog(group = "Controller parameter"));
  parameter Real D = 4 "Droop characteristics of the generator in percentage" annotation (
    Dialog(group = "Controller parameter"));
  parameter Real Kp = 0.003 "Kp value of PI controller" annotation (
    Dialog(group = "Controller parameter"));
  parameter Real Ti = 10 "Ti value of PI controller" annotation (
    Dialog(group = "Controller parameter"));
  Modelica.Blocks.Interfaces.RealInput P_sg
    annotation (Placement(transformation(extent={{-140,40},{-100,80}})));
  Modelica.Blocks.Interfaces.RealInput f_grid
    annotation (Placement(transformation(extent={{-140,-80},{-100,-40}})));
    Modelica.Blocks.Interfaces.RealOutput u_v
    "Turbine valve signal" annotation (
      Placement(visible=true, transformation(
        origin={110,0},
        extent={{-10,-10},{10,10}},
        rotation=0)));
        // variable
        Real P_dy_ref;
  Modelica.Blocks.Continuous.LimPID PIController(
    controllerType=Modelica.Blocks.Types.SimpleController.PI,
    k=Kp,
    Ti=Ti,
    yMax=1,
    yMin=0.01)
    annotation (Placement(transformation(extent={{-36,46},{-16,66}})));
  Modelica.Blocks.Sources.RealExpression PdyRef(y=P_dy_ref)
    annotation (Placement(transformation(extent={{-80,54},{-60,76}})));
  Modelica.Blocks.Sources.RealExpression PdyRef1(y=P_sg)
    annotation (Placement(transformation(extent={{-80,24},{-60,46}})));

equation
  P_dy_ref = -(P_r/1e6)/(D/100)*((f_grid-f_ref)/(f_ref))+P_sg;

  connect(PIController.u_s, PdyRef.y) annotation (Line(points={{-38,56},{-50,56},
          {-50,65},{-59,65}}, color={0,0,127}));
  connect(PIController.u_m, PdyRef1.y)
    annotation (Line(points={{-26,44},{-26,35},{-59,35}}, color={0,0,127}));
  connect(PIController.y, u_v) annotation (Line(points={{-15,56},{44,56},{44,0},
          {110,0}}, color={0,0,127}));
  annotation (
    Documentation(info="<html>
<p>This is a simple model of the governor that controls the guide vane oppening in the turbine based on the reference power production.</p>
<p><br><br>This is a simple model of a droop controller that determines the dynamic reference power to the PI controller for generating turbine valve signal for controlling the flow.</p>
<p>The model is taken from:&nbsp;<a href=\"Resources/Report/Generator_model.pdf\">Resources/Report/Generator_model.pdf</a></p>
</html>"));
end DroopControllerPI;
