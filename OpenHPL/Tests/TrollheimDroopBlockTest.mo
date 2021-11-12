within OpenHPL.Tests;
model TrollheimDroopBlockTest
  "This is parallel operation of hydro powers for droop control mechanism."
  extends Modelica.Icons.Example;
  //Modelica.Blocks.Sources.Ramp load(duration = 1, height = -5e6, offset = 80e6, startTime = 600) annotation(
  //  Placement(visible = true, transformation(extent = {{-40, -6}, {-20, 14}}, rotation = 0)));
  //OpenHPL.HydroPower.Aggregate aggregate annotation(
  //  Placement(visible = true, transformation(extent = {{-4, -6}, {16, 14}}, rotation = 0)));
  Waterway.SurgeTank surgeTank(
    H=80,
    L=80,
    D=4,                       h_0 = 69.9) annotation (
    Placement(visible = true, transformation(origin = {-30, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,
    C_v=3.7,
    H_n=370,
    V_dot_n=40,
    ConstEfficiency=false) annotation (Placement(visible=true, transformation(
        origin={30,10},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  Waterway.Pipe discharge(H = 0.5, L = 600) annotation (
    Placement(visible = true, transformation(extent = {{50, -10}, {70, 10}}, rotation = 0)));
  Waterway.Reservoir reservoir(H_r=50)   annotation (
    Placement(visible = true, transformation(origin = {-90, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Waterway.Reservoir tail(H_r = 5, Input_level = false) annotation (
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, 10}, {10, -10}}, rotation = 180)));
  Waterway.Pipe penstock(
    D_i=4,
    D_o=4,
    H=300,
    L=500,                                                     vertical = true) annotation (
    Placement(visible = true, transformation(origin = {0, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Waterway.Pipe intake(
    H=20,
    L=4500,
    D_i=7)                     annotation (
    Placement(visible = true, transformation(extent = {{-70, 20}, {-50, 40}}, rotation = 0)));
  Modelica.Blocks.Sources.Ramp load(
    duration=0,
    height=0.5*50e6,
    offset=50e6,
    startTime=20) annotation (Placement(visible=true, transformation(
        origin={-30,-30},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  ElectroMech.Generators.SimpleGen gen(
    J=10e5,
    theta_e=1,
    k_b=0) annotation (Placement(transformation(extent={{20,-40},{40,-20}})));
  Modelica.Blocks.Sources.RealExpression DeltaP1(y=gen.f)
    annotation (Placement(transformation(extent={{-90,76},{-70,96}})));
  Controllers.PICont pICont
    annotation (Placement(transformation(extent={{-18,66},{2,86}})));
equation
//connect(turbine.P_out, aggregate.P_in) annotation(
//  Line(points = {{-3.8, 34}, {2, 34}, {2, 14}, {2, 14}}, color = {0, 0, 127}));
//connect(load.y, aggregate.u) annotation(
//  Line(points = {{-19, 4}, {-12.5, 4}, {-12.5, 4}, {-4, 4}}, color = {0, 0, 127}));
  connect(discharge.n, tail.n) annotation (
    Line(points = {{70, 0}, {80, 0}}, color = {28, 108, 200}));
  connect(reservoir.n, intake.p) annotation (
    Line(points = {{-80, 30}, {-70, 30}}, color = {28, 108, 200}));
  connect(turbine.n, discharge.p) annotation (Line(points={{40,10},{44,10},{44,
          0},{50,0}}, color={28,108,200}));
  connect(penstock.n, turbine.p) annotation (Line(points={{10,30},{14.95,30},{
          14.95,10},{20,10}}, color={28,108,200}));
  connect(intake.n, surgeTank.p) annotation (
    Line(points = {{-50, 30}, {-40, 30}}, color = {28, 108, 200}));
  connect(surgeTank.n, penstock.p) annotation (
    Line(points = {{-20, 30}, {-10, 30}}, color = {28, 108, 200}));
  connect(turbine.P_out, gen.P_in)
    annotation (Line(points={{30,-1},{30,-18}}, color={0,0,127}));
  connect(load.y, gen.u)
    annotation (Line(points={{-19,-30},{20,-30}}, color={0,0,127}));
  connect(DeltaP1.y, pICont.u) annotation (Line(points={{-69,86},{-44,86},{-44,
          76},{-20,76}}, color={0,0,127}));
  connect(turbine.u_t, pICont.y) annotation (Line(points={{30,22},{18,22},{18,
          76},{4,76}}, color={0,0,127}));
  annotation (
    experiment(StartTime = -1000, StopTime = 1000, __Dymola_NumberOfIntervals = 10000, __Dymola_Algorithm = "Dassl"));
end TrollheimDroopBlockTest;
