within OpenHPL.Tests;
model SpeedGov2
  "This is parallel operation of hydro powers for droop control mechanism."
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
  ElectroMech.Turbines.Turbine turbine1(
    ValveCapacity=false,
    C_v=3.7,
    H_n=370,
    V_dot_n=20,
    ConstEfficiency=false) annotation (Placement(visible=true, transformation(
        origin={34,22},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  Waterway.Pipe discharge(H=0.5, L=600)     annotation (
    Placement(visible = true, transformation(extent={{52,-12},{72,8}},       rotation = 0)));
  Waterway.Reservoir reservoir(H_r=50)   annotation (
    Placement(visible = true, transformation(origin={-88,28},    extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Waterway.Reservoir tail(H_r=5, Input_level=false)     annotation (
    Placement(visible = true, transformation(origin={92,-2},   extent = {{-10, 10}, {10, -10}}, rotation = 180)));
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
    height=0.1*50e6,
    offset=50e6,
    startTime=20) annotation (Placement(visible=true, transformation(
        origin={-70,-70},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  Modelica.Blocks.Continuous.LimPID PID1(
    controllerType=Modelica.Blocks.Types.SimpleController.PI,
    k=0.02,
    Ti=10,
    yMax=1,
    yMin=0.01) annotation (Placement(transformation(extent={{-18,70},{2,90}})));
  Modelica.Blocks.Sources.RealExpression fgrid1(y=gen.f)
    annotation (Placement(transformation(extent={{-58,48},{-38,68}})));
  Modelica.Blocks.Sources.RealExpression fref1(y=50)
    annotation (Placement(transformation(extent={{-56,78},{-36,98}})));
  ElectroMech.Generators.SimpleGen gen(J=10e5)
    annotation (Placement(transformation(extent={{-24,-98},{-4,-78}})));
  Modelica.Blocks.Math.Add add
    annotation (Placement(transformation(extent={{66,-60},{86,-40}})));
  ElectroMech.Turbines.Turbine turbine2(
    ValveCapacity=false,
    C_v=3.7,
    H_n=370,
    V_dot_n=20,
    ConstEfficiency=false) annotation (Placement(visible=true, transformation(
        origin={12,-12},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  Modelica.Blocks.Sources.RealExpression fgrid2(y=gen.f)
    annotation (Placement(transformation(extent={{-86,-42},{-66,-22}})));
  Modelica.Blocks.Continuous.LimPID PID2(
    controllerType=Modelica.Blocks.Types.SimpleController.PI,
    k=0.01,
    Ti=10,
    yMax=1,
    yMin=0.01)
    annotation (Placement(transformation(extent={{-48,-24},{-28,-4}})));
  Modelica.Blocks.Sources.RealExpression fref2(y=50)
    annotation (Placement(transformation(extent={{-86,-16},{-66,4}})));
  Modelica.Blocks.Sources.RealExpression Pg1(y=sgen1.Pe)
    annotation (Placement(transformation(extent={{20,-62},{40,-42}})));
  Modelica.Blocks.Sources.RealExpression Pg2(y=sgen2.Pe)
    annotation (Placement(transformation(extent={{20,-76},{40,-56}})));
  ElectroMech.Generators.SynchGen sgen1(J=5e5)
    annotation (Placement(transformation(extent={{24,-34},{44,-14}})));
  ElectroMech.Generators.SynchGen sgen2(J=5e5)
    annotation (Placement(transformation(extent={{-8,-54},{12,-34}})));
equation
//connect(turbine.P_out, aggregate.P_in) annotation(
//  Line(points = {{-3.8, 34}, {2, 34}, {2, 14}, {2, 14}}, color = {0, 0, 127}));
//connect(load.y, aggregate.u) annotation(
//  Line(points = {{-19, 4}, {-12.5, 4}, {-12.5, 4}, {-4, 4}}, color = {0, 0, 127}));
  connect(discharge.n,tail. n) annotation (
    Line(points={{72,-2},{82,-2}},    color = {28, 108, 200}));
  connect(reservoir.n,intake. p) annotation (
    Line(points={{-78,28},{-68,28}},      color = {28, 108, 200}));
  connect(turbine1.n, discharge.p) annotation (Line(points={{44,22},{46,22},{46,
          -2},{52,-2}}, color={28,108,200}));
  connect(penstock.n, turbine1.p) annotation (Line(points={{12,28},{16.95,28},{
          16.95,22},{24,22}}, color={28,108,200}));
  connect(intake.n,surgeTank. p) annotation (
    Line(points={{-48,28},{-38,28}},      color = {28, 108, 200}));
  connect(surgeTank.n,penstock. p) annotation (
    Line(points={{-18,28},{-8,28}},       color = {28, 108, 200}));
  connect(PID1.u_m, fgrid1.y)
    annotation (Line(points={{-8,68},{-8,58},{-37,58}}, color={0,0,127}));
  connect(PID1.u_s, fref1.y) annotation (Line(points={{-20,80},{-28,80},{-28,88},
          {-35,88}}, color={0,0,127}));
  connect(load.y, gen.u) annotation (Line(points={{-59,-70},{-40,-70},{-40,-88},
          {-24,-88}}, color={0,0,127}));
  connect(add.y, gen.P_in) annotation (Line(points={{87,-50},{92,-50},{92,-76},
          {-14,-76}}, color={0,0,127}));
  connect(turbine2.p, turbine1.p) annotation (Line(points={{2,-12},{-4,-12},{-4,
          8},{26,8},{26,22},{24,22}},     color={28,108,200}));
  connect(turbine2.n, discharge.p) annotation (Line(points={{22,-12},{22,-2},{
          52,-2}},         color={28,108,200}));
  connect(PID2.u_s, fref2.y) annotation (Line(points={{-50,-14},{-58,-14},{-58,
          -6},{-65,-6}}, color={0,0,127}));
  connect(fgrid2.y, PID2.u_m)
    annotation (Line(points={{-65,-32},{-38,-32},{-38,-26}}, color={0,0,127}));
  connect(PID2.y, turbine2.u_t) annotation (Line(points={{-27,-14},{-12,-14},{
          -12,0},{12,0}},color={0,0,127}));
  connect(add.u1, Pg1.y) annotation (Line(points={{64,-44},{52,-44},{52,-52},{
          41,-52}}, color={0,0,127}));
  connect(add.u2, Pg2.y) annotation (Line(points={{64,-56},{52,-56},{52,-66},{
          41,-66}}, color={0,0,127}));
  connect(turbine2.P_out, sgen2.P_in)
    annotation (Line(points={{12,-23},{12,-28},{2,-28},{2,-32}},
                                               color={0,0,127}));
  connect(turbine1.P_out, sgen1.P_in)
    annotation (Line(points={{34,11},{34,-12}},color={0,0,127}));
  connect(turbine1.u_t, PID1.y)
    annotation (Line(points={{34,34},{34,80},{3,80}}, color={0,0,127}));
  annotation (
    experiment(StartTime = -1000, StopTime = 1000, __Dymola_NumberOfIntervals = 10000, __Dymola_Algorithm = "Dassl"));
end SpeedGov2;
