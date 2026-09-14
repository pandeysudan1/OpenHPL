within OpenHPL.Examples.AGC_Trollheim_Surgetank;
model TrollheimAGCSurgeTankWarmStart
  "Trollheim surge-tank AGC benchmark with dynamic preconditioning before t=0"
  extends Modelica.Icons.Example;

  parameter SI.Power P_base=150e6;
  parameter Integer p=12;
  parameter SI.MomentOfInertia J_total=2e5;
  final parameter SI.MomentOfInertia J_each=J_total/2;

  inner OpenHPL.Data data(
    SteadyState=false,
    f_grid=50,
    f_0=1,
    Vdot_0=25);

  OpenHPL.Waterway.Reservoir reservoir(
    h_0=50,
    fixElevation=true,
    z_0=322);

  OpenHPL.Waterway.Pipe intake(
    H=20,L=500,D_i=6,D_o=6,
    SteadyState=false,Vdot_0=25);

  HomotopySurgeTank surgeTank(
    H=80,L=80,D=4,
    h_0=50,Vdot_0=0,
    SteadyState=false);

  OpenHPL.Waterway.Pipe penstock(
    H=300,L=500,D_i=4,D_o=4,
    SteadyState=false,Vdot_0=25);

  OpenHPL.ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,H_n=340,Vdot_n=50,u_n=1,
    ConstEfficiency=true,eta_h=0.90,Pmax=P_base,
    J=J_each,p=p,enable_nomSpeed=false,enable_P_out=true);

  OpenHPL.Waterway.Pipe discharge(
    H=2,L=600,D_i=6,D_o=6,
    SteadyState=false,Vdot_0=25);

  OpenHPL.Waterway.Reservoir tail(h_0=5);

  OpenHPL.ElectroMech.Generators.SimpleGen generator(
    Pmax=P_base,J=J_each,p=p,Ploss=0,enable_f=true);

  OpenHPL.ElectroMech.PowerSystem.Grid grid(
    Pgrid=P_base,useLambda=true,Lambda=0,mu=0,J=1,p=p,enable_f=true);

  OpenHPL.ElectroMech.PowerSystem.SimpleGovernorAGC governor(
    R=0.50,T_g=0.30,K_i=0.10,
    u_bias=0.50,u_min=0.05,u_max=1.0);

  Modelica.Blocks.Sources.Step loadStep(
    offset=0.50*P_base,
    height=0.10*P_base,
    startTime=5);
  Modelica.Blocks.Sources.Constant zeroPower(k=0);

  output SI.Frequency frequency_Hz;
  output SI.Power mechanicalPower;
  output SI.Power electricalLoad;
  output SI.PerUnit guideVane;
  output SI.VolumeFlowRate turbineFlow;
  output SI.Height surgeLevel;
  output SI.VolumeFlowRate surgeFlow;

equation
  connect(reservoir.o,intake.i);
  connect(intake.o,surgeTank.i);
  connect(surgeTank.o,penstock.i);
  connect(penstock.o,turbine.i);
  connect(turbine.o,discharge.i);
  connect(discharge.o,tail.o);

  connect(turbine.flange,generator.flange);
  connect(generator.flange,grid.flange);
  connect(zeroPower.y,generator.Pload);
  connect(loadStep.y,grid.Pload);
  connect(generator.f,governor.f_pu);
  connect(governor.gate,turbine.u_t);

  frequency_Hz=data.f_grid*generator.f;
  mechanicalPower=turbine.Wdot_s;
  electricalLoad=loadStep.y;
  guideVane=governor.gate;
  turbineFlow=turbine.Vdot;
  surgeLevel=surgeTank.h;
  surgeFlow=surgeTank.Vdot;

  annotation(
    experiment(StartTime=-300,StopTime=65,Tolerance=1e-7,Interval=0.05),
    Documentation(info="<html>
<h4>Dynamic warm-start variant</h4>
<p>The model starts at t=-300 s from explicit hydraulic guesses. No steady-state derivative constraints are imposed on the waterway. The controller and nonlinear waterway are allowed to converge dynamically under the 75 MW load before the visible experiment begins at t=0. The load still steps to 90 MW at t=5 s.</p>
<p>This approach is intended as a robust fallback when the direct algebraic steady-state initialization and global homotopy path are difficult to solve.</p>
</html>"));
end TrollheimAGCSurgeTankWarmStart;
