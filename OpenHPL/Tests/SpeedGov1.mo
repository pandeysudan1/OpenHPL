within OpenHPL.Tests;
model SpeedGov1 "SpeedGoverning"
  extends Modelica.Icons.Example;
  //Modelica.Blocks.Sources.Ramp load(duration = 1, height = -5e6, offset = 80e6, startTime = 600) annotation(
  //  Placement(visible = true, transformation(extent = {{-40, -6}, {-20, 14}}, rotation = 0)));
  //OpenHPL.HydroPower.Aggregate aggregate annotation(
  //  Placement(visible = true, transformation(extent = {{-4, -6}, {16, 14}}, rotation = 0)));
  Waterway.SurgeTank surgeTank(
    H=80,
    L=80,
    D=4,
    h_0=69.9)                              annotation (
    Placement(visible = true, transformation(origin={-28,28},    extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,
    C_v=3.7,
    H_n=370,
    V_dot_n=40,
    ConstEfficiency=false) annotation (Placement(visible=true, transformation(
        origin={34,22},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  Waterway.Pipe discharge(H=0.5, L=600)     annotation (
    Placement(visible = true, transformation(extent={{48,12},{68,32}},       rotation = 0)));
  Waterway.Reservoir reservoir(H_r=50)   annotation (
    Placement(visible = true, transformation(origin={-88,28},    extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Waterway.Reservoir tail(H_r=5, Input_level=false)     annotation (
    Placement(visible = true, transformation(origin={90,22},   extent = {{-10, 10}, {10, -10}}, rotation = 180)));
  Waterway.Pipe penstock(
    D_i=4,
    D_o=4,
    H=300,
    L=500,
    vertical=true)                                                              annotation (
    Placement(visible = true, transformation(origin={2,28},    extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Waterway.Pipe intake(
    H=20,
    L=4500,
    D_i=7)                     annotation (
    Placement(visible = true, transformation(extent={{-68,18},{-48,38}},      rotation = 0)));
  Modelica.Blocks.Sources.Ramp load(
    duration=0,
    height=0.1*130e6,
    offset=0.5*130e6,
    startTime=20) annotation (Placement(visible=true, transformation(
        origin={-22,-38},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  Modelica.Blocks.Continuous.LimPID PID(
    controllerType=Modelica.Blocks.Types.SimpleController.PI,
    k=0.005,
    Ti=10,
    Td=10,
    yMax=1,
    yMin=0.01) annotation (Placement(transformation(extent={{-18,70},{2,90}})));
  Modelica.Blocks.Sources.RealExpression f(y=gen.f)
    annotation (Placement(transformation(extent={{-58,48},{-38,68}})));
  Modelica.Blocks.Sources.RealExpression DeltaP(y=50)
    annotation (Placement(transformation(extent={{-56,78},{-36,98}})));
  ElectroMech.Generators.SimpleGen gen(J=10e5)
    annotation (Placement(transformation(extent={{24,-48},{44,-28}})));
  ElectroMech.Generators.SynchGen sgen(
    P_op=140e6,
    Q_op=130e6,
    Ra=0.03,
    Vs=20000,
    J=10e5) annotation (Placement(transformation(extent={{24,-16},{44,4}})));
  Modelica.Blocks.Sources.RealExpression Pg(y=sgen.Pe)
    annotation (Placement(transformation(extent={{-8,-30},{12,-10}})));
equation
//connect(turbine.P_out, aggregate.P_in) annotation(
//  Line(points = {{-3.8, 34}, {2, 34}, {2, 14}, {2, 14}}, color = {0, 0, 127}));
//connect(load.y, aggregate.u) annotation(
//  Line(points = {{-19, 4}, {-12.5, 4}, {-12.5, 4}, {-4, 4}}, color = {0, 0, 127}));
  connect(discharge.n,tail. n) annotation (
    Line(points={{68,22},{80,22}},    color = {28, 108, 200}));
  connect(reservoir.n,intake. p) annotation (
    Line(points={{-78,28},{-68,28}},      color = {28, 108, 200}));
  connect(turbine.n, discharge.p)
    annotation (Line(points={{44,22},{48,22}}, color={28,108,200}));
  connect(penstock.n, turbine.p) annotation (Line(points={{12,28},{16.95,28},{
          16.95,22},{24,22}}, color={28,108,200}));
  connect(intake.n,surgeTank. p) annotation (
    Line(points={{-48,28},{-38,28}},      color = {28, 108, 200}));
  connect(surgeTank.n,penstock. p) annotation (
    Line(points={{-18,28},{-8,28}},       color = {28, 108, 200}));
  connect(PID.u_m, f.y)
    annotation (Line(points={{-8,68},{-8,58},{-37,58}}, color={0,0,127}));
  connect(PID.u_s, DeltaP.y) annotation (Line(points={{-20,80},{-28,80},{-28,88},
          {-35,88}}, color={0,0,127}));
  connect(turbine.P_out, sgen.P_in)
    annotation (Line(points={{34,11},{34,6}}, color={0,0,127}));
  connect(PID.y, turbine.u_t)
    annotation (Line(points={{3,80},{34,80},{34,34}}, color={0,0,127}));
  connect(gen.P_in, Pg.y)
    annotation (Line(points={{34,-26},{34,-20},{13,-20}}, color={0,0,127}));
  connect(gen.u, load.y)
    annotation (Line(points={{24,-38},{-11,-38}}, color={0,0,127}));
  annotation (
    experiment(StartTime = -1000, StopTime = 1000, __Dymola_NumberOfIntervals = 10000, __Dymola_Algorithm = "Dassl"));
end SpeedGov1;
