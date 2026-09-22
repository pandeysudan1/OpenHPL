within OpenHPLTest.PumpTurbine;
model TestPumping "Basic pumping-mode test for the pump-turbine"
  extends Modelica.Icons.Example;

  OpenHPL.Waterway.Reservoir source(h_0 = 10, fixElevation = true, z_0 = 0) annotation (Placement(transformation(
        origin = {-80, 0},
        extent = {{-10, -10}, {10, 10}})));
  OpenHPL.Waterway.Pipe intake(H = 0.5, L = 100, D_i = 4) annotation (Placement(transformation(extent = {{-60, -10}, {-40, 10}})));
  Modelica.Blocks.Sources.Constant control(k = 1) annotation (Placement(transformation(origin = {-20, 50}, extent = {{-10, -10}, {10, 10}})));
  OpenHPL.ElectroMech.Turbines.PumpTurbine pumpTurbine(
    mode = OpenHPL.ElectroMech.Turbines.PumpTurbine.OperatingMode.Pump,
    enable_nomSpeed = true,
    H_pump_n = 90,
    Vdot_pump_n = 3,
    H_turbine_n = 80,
    Vdot_turbine_n = 3,
    eta_p = 0.88) annotation (Placement(transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}})));
  OpenHPL.Waterway.Pipe discharge(H = 0.5, L = 100, D_i = 4) annotation (Placement(transformation(extent = {{20, -10}, {40, 10}})));
  OpenHPL.Waterway.Reservoir sink(h_0 = 10, fixElevation = true, z_0 = 90) annotation (Placement(transformation(
        origin = {60, 0},
        extent = {{-10, 10}, {10, -10}},
        rotation = 180)));
  inner OpenHPL.Data data(Vdot_0 = 3)
                          annotation (Placement(transformation(
        origin = {-80, 80},
        extent = {{-10, -10}, {10, 10}})));
equation
  connect(source.o, intake.i) annotation (Line(points = {{-70, 0}, {-60, 0}}, color = {28, 108, 200}));
  connect(intake.o, pumpTurbine.i) annotation (Line(points = {{-40, 0}, {-10, 0}}, color = {28, 108, 200}));
  connect(pumpTurbine.o, discharge.i) annotation (Line(points = {{10, 0}, {20, 0}}, color = {28, 108, 200}));
  connect(discharge.o, sink.o) annotation (Line(points = {{40, 0}, {50, 0}}, color = {28, 108, 200}));
  connect(control.y, pumpTurbine.u_t) annotation (Line(points = {{-9, 50}, {0, 50}, {0, 12}}, color = {0, 0, 127}));
  annotation (experiment(StopTime = 200, StartTime = 0, Tolerance = 1e-06, Interval = 0.4));
end TestPumping;
