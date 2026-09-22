within OpenHPLTest.PumpTurbine;
model TestGenerating "Basic generating-mode test for the pump-turbine"
  extends OpenHPL.Examples.SimplePumpTurbine(
    pumpTurbine(
      mode = OpenHPL.ElectroMech.Turbines.PumpTurbine.OperatingMode.Turbine,
      enable_nomSpeed = true,
      H_turbine_n = 80,
      Vdot_turbine_n = 3));

  annotation (experiment(StopTime = 1000, StartTime = 0, Tolerance = 1e-06, Interval = 2));
end TestGenerating;
