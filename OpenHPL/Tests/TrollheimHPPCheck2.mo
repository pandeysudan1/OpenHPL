within OpenHPL.Tests;
model TrollheimHPPCheck2
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
    Placement(visible = true, transformation(origin={-126,118},  extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ElectroMech.Turbines.Turbine turbine1(
    ValveCapacity=false,
    C_v=3.7,
    H_n=370,
    V_dot_n=15,
    ConstEfficiency=false) annotation (Placement(visible=true, transformation(
        origin={-64,110},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  Waterway.Pipe discharge(H=0.5, L=600)     annotation (
    Placement(visible = true, transformation(extent={{-46,78},{-26,98}},     rotation = 0)));
  Waterway.Reservoir reservoir(H_r=50)   annotation (
    Placement(visible = true, transformation(origin={-186,118},  extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Waterway.Reservoir tail(H_r=5, Input_level=false)     annotation (
    Placement(visible = true, transformation(origin={-6,88},   extent = {{-10, 10}, {10, -10}}, rotation = 180)));
  Waterway.Pipe penstock(
    D_i=4,
    D_o=4,
    H=300,
    L=500,
    vertical=true)                                                              annotation (
    Placement(visible = true, transformation(origin={-96,118}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Waterway.Pipe intake(
    H=20,
    L=4500,
    D_i=7)                     annotation (
    Placement(visible = true, transformation(extent={{-166,108},{-146,128}},  rotation = 0)));
  Modelica.Blocks.Sources.Ramp load(
    duration=10,
    height=0.3*130e6,
    offset=0.2*130e6,
    startTime=10) annotation (Placement(visible=true, transformation(
        origin={10,130},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  ElectroMech.Turbines.Turbine turbine2(
    ValveCapacity=false,
    C_v=3.7,
    H_n=370,
    V_dot_n=20,
    ConstEfficiency=false) annotation (Placement(visible=true, transformation(
        origin={-96,78},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  Modelica.Blocks.Sources.RealExpression Pg1(y=sgen1.Pe)
    annotation (Placement(transformation(extent={{-78,24},{-50,48}})));
  Modelica.Blocks.Sources.RealExpression Pg2(y=sgen2.Pe)
    annotation (Placement(transformation(extent={{-76,4},{-48,26}})));
  ElectroMech.Generators.SynchGen sgen1(
    P_op=130e6,
    Q_op=120e6,                         J=5e5)
    annotation (Placement(transformation(extent={{-74,56},{-54,76}})));
  ElectroMech.Generators.SynchGen sgen2(
    P_op=130e6,
    Q_op=120e6,                         J=5e5)
    annotation (Placement(transformation(extent={{-106,36},{-86,56}})));
  Modelica.Blocks.Sources.RealExpression realExpression5(y=gen.f)
    annotation (Placement(transformation(extent={{-246,154},{-226,174}})));
  Modelica.Blocks.Routing.DeMultiplex demux(n=2)
    annotation (Placement(transformation(extent={{-156,154},{-136,174}})));
  Controllers.DroopControllerPI2 droopControllerPI2_1(
    D={4,4},
    Kp={0.03,0.03},
    Ti={100,115})
    annotation (Placement(transformation(extent={{-202,154},{-182,174}})));
  Modelica.Blocks.Math.Add3 add3_1
    annotation (Placement(transformation(extent={{-16,14},{4,34}})));
  Modelica.Blocks.Sources.Ramp load1(
    duration=10,
    height=0,
    offset=0,
    startTime=100)
                  annotation (Placement(visible=true, transformation(
        origin={-58,-12},
        extent={{-10,-10},{10,10}},
        rotation=0)));
  ElectroMech.Generators.SimpleGen2 gen(J=1000e5)
    annotation (Placement(transformation(extent={{34,44},{54,64}})));
equation
//connect(turbine.P_out, aggregate.P_in) annotation(
//  Line(points = {{-3.8, 34}, {2, 34}, {2, 14}, {2, 14}}, color = {0, 0, 127}));
//connect(load.y, aggregate.u) annotation(
//  Line(points = {{-19, 4}, {-12.5, 4}, {-12.5, 4}, {-4, 4}}, color = {0, 0, 127}));
  connect(discharge.n,tail. n) annotation (
    Line(points={{-26,88},{-16,88}},  color = {28, 108, 200}));
  connect(reservoir.n,intake. p) annotation (
    Line(points={{-176,118},{-166,118}},  color = {28, 108, 200}));
  connect(turbine1.n, discharge.p) annotation (Line(points={{-54,110},{-52,110},
          {-52,88},{-46,88}}, color={28,108,200}));
  connect(penstock.n, turbine1.p) annotation (Line(points={{-86,118},{-81.05,
          118},{-81.05,110},{-74,110}},   color={28,108,200}));
  connect(intake.n,surgeTank. p) annotation (
    Line(points={{-146,118},{-136,118}},  color = {28, 108, 200}));
  connect(surgeTank.n,penstock. p) annotation (
    Line(points={{-116,118},{-106,118}},  color = {28, 108, 200}));
  connect(turbine2.p, turbine1.p) annotation (Line(points={{-106,78},{-110,78},
          {-110,98},{-80,98},{-80,110},{-74,110}},    color={28,108,200}));
  connect(turbine2.n, discharge.p) annotation (Line(points={{-86,78},{-76,78},{
          -76,88},{-46,88}},   color={28,108,200}));
  connect(turbine2.P_out, sgen2.P_in)
    annotation (Line(points={{-96,67},{-96,58}},   color={0,0,127}));
  connect(turbine1.P_out, sgen1.P_in)
    annotation (Line(points={{-64,99},{-64,78}},   color={0,0,127}));
  connect(turbine1.u_t, demux.y[1]) annotation (Line(points={{-64,122},{-64,
          167.5},{-136,167.5}},            color={0,0,127}));
  connect(turbine2.u_t, demux.y[2]) annotation (Line(points={{-96,90},{-96,
          160.5},{-136,160.5}},       color={0,0,127}));
  connect(realExpression5.y, droopControllerPI2_1.f_grid) annotation (Line(
        points={{-225,164},{-204,164}},                       color={0,0,127}));
  connect(demux.u, droopControllerPI2_1.uv) annotation (Line(points={{-158,164},
          {-181,164}},                       color={0,0,127}));
  connect(Pg2.y, add3_1.u2) annotation (Line(points={{-46.6,15},{-34,15},{-34,
          24},{-18,24}}, color={0,0,127}));
  connect(Pg1.y, add3_1.u1) annotation (Line(points={{-48.6,36},{-32,36},{-32,
          32},{-18,32}}, color={0,0,127}));
  connect(add3_1.u3, load1.y) annotation (Line(points={{-18,16},{-32,16},{-32,
          -12},{-47,-12}},
                     color={0,0,127}));
  connect(add3_1.y, gen.P_in) annotation (Line(points={{5,24},{24,24},{24,66},{
          44,66}},   color={0,0,127}));
  connect(gen.u, load.y) annotation (Line(points={{34,54},{28,54},{28,130},{21,
          130}},     color={0,0,127}));
  annotation (
    experiment(StartTime = -1000, StopTime = 1000, __Dymola_NumberOfIntervals = 10000, __Dymola_Algorithm = "Dassl"),
    Diagram(coordinateSystem(extent={{-260,-100},{200,200}})),
    Icon(coordinateSystem(extent={{-260,-100},{200,200}})));
end TrollheimHPPCheck2;
