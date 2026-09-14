within OpenHPL.Examples;
model AGC_Trollheim "Trollheim HPP AGC benchmark: 75 MW to 90 MW load step at t=5 s"
  extends Modelica.Icons.Example;

  parameter SI.Power P_base=150e6 "Plant power base";
  parameter Integer p=12 "Generator pole count";
  parameter SI.MomentOfInertia J_total=2e5 "Transferred Trollheim rotor inertia benchmark";
  final parameter SI.MomentOfInertia J_each=J_total/2
    "Split equally between turbine and generator inertias";

  inner OpenHPL.Data data(
    SteadyState=true,
    f_grid=50,
    f_0=1,
    Vdot_0=25) annotation (Placement(transformation(extent={{-96,78},{-76,98}})));

  OpenHPL.Waterway.Reservoir reservoir(
    h_0=50,
    fixElevation=true,
    z_0=322) annotation (Placement(transformation(extent={{-96,20},{-76,40}})));

  OpenHPL.Waterway.Pipe intake(
    H=20,
    L=500,
    D_i=6,
    D_o=6) annotation (Placement(transformation(extent={{-70,20},{-50,40}})));

  OpenHPL.Waterway.SurgeTank surgeTank(
    H=80,
    L=80,
    D=4,
    h_0=50,
    Vdot_0=0,
    SteadyState=false) annotation (Placement(transformation(extent={{-46,46},{-26,66}})));

  OpenHPL.Waterway.Pipe penstock(
    H=300,
    L=500,
    D_i=4,
    D_o=4) annotation (Placement(transformation(extent={{-42,20},{-22,40}})));

  OpenHPL.ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,
    H_n=340,
    Vdot_n=50,
    u_n=1,
    ConstEfficiency=true,
    eta_h=0.90,
    Pmax=P_base,
    J=J_each,
    p=p,
    enable_nomSpeed=false,
    enable_P_out=true) annotation (Placement(transformation(extent={{-12,10},{8,30}})));

  OpenHPL.Waterway.Pipe discharge(
    H=2,
    L=600,
    D_i=6,
    D_o=6) annotation (Placement(transformation(extent={{18,0},{38,20}})));

  OpenHPL.Waterway.Reservoir tail(
    h_0=5) annotation (Placement(transformation(origin={58,10},extent={{-10,10},{10,-10}},rotation=180)));

  OpenHPL.ElectroMech.Generators.SimpleGen generator(
    Pmax=P_base,
    J=J_each,
    p=p,
    Ploss=0,
    enable_f=true) annotation (Placement(transformation(extent={{-4,-28},{16,-8}})));

  OpenHPL.ElectroMech.PowerSystem.Grid grid(
    Pgrid=P_base,
    useLambda=true,
    Lambda=0,
    mu=0,
    J=1,
    p=p,
    enable_f=true) annotation (Placement(transformation(extent={{28,-28},{48,-8}})));

  OpenHPL.ElectroMech.PowerSystem.SimpleGovernorAGC governor(
    R=0.05,
    T_g=0.30,
    K_i=1.5,
    u_bias=0.50,
    u_min=0.05,
    u_max=1.0) annotation (Placement(transformation(extent={{-24,52},{-4,72}})));

  Modelica.Blocks.Sources.Step loadStep(
    offset=0.50*P_base,
    height=0.10*P_base,
    startTime=5) annotation (Placement(transformation(extent={{50,48},{70,68}})));
  Modelica.Blocks.Sources.Constant zeroPower(k=0) annotation (Placement(transformation(extent={{-4,-60},{16,-40}})));

  output SI.Frequency frequency_Hz "Generator/grid frequency";
  output SI.Power mechanicalPower "Turbine shaft power";
  output SI.Power electricalLoad "Applied electrical load";
  output SI.PerUnit guideVane "Guide-vane opening";
  output SI.VolumeFlowRate turbineFlow "Turbine flow";
  output SI.Height surgeLevel "Surge-tank water level";

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

  frequency_Hz = data.f_grid*generator.f;
  mechanicalPower = turbine.Wdot_s;
  electricalLoad = loadStep.y;
  guideVane = governor.gate;
  turbineFlow = turbine.Vdot;
  surgeLevel = surgeTank.h;

initial equation
  der(generator.inertia.w)=0;

  annotation (
    experiment(StartTime=0, StopTime=65, Tolerance=1e-7, Interval=0.02),
    Documentation(info="<html><h4>AGC_Trollheim</h4><p>OpenHPL benchmark derived from the Trollheim parameter set used in the user's HydroSyncBridge.jl work. Initial loading is 75 MW (50% of 150 MW). At t=5 s the load increases by 15 MW to 90 MW (60%). The nonlinear hydraulic path includes intake, surge tank, penstock, turbine and discharge. A simple generator, mechanical grid equivalent and droop-plus-integral AGC governor close the frequency-control loop.</p><p>The hydraulic geometry and machine rating are transferred benchmark values and should not be interpreted as independently field-verified Trollheim plant data. The surge tank uses seeded initialization (h=50 m, Vdot=0) to avoid the nonlinear steady-state algebraic loop; the 0-5 s forensic drift is used to judge and tune consistency.</p></html>"));
end AGC_Trollheim;
