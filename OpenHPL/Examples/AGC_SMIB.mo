within OpenHPL.Examples;
model AGC_SMIB "Hydropower LFC/AGC benchmark: 50% to 60% load step at t=5 s"
  extends Modelica.Icons.Example;

  parameter SI.Power P_base=2.5e6 "System/turbine power base";
  parameter Integer p=12 "Generator/turbine pole count";
  parameter SI.Time H_total=3.0 "Target combined turbine-generator inertia constant";
  final parameter SI.Frequency f_mech=data.f_grid/(p/2);
  final parameter SI.AngularVelocity w_mech=2*Modelica.Constants.pi*f_mech;
  final parameter SI.MomentOfInertia J_each=H_total*P_base/(w_mech*w_mech)
    "Half of J_total = 2 H_total P_base / w^2";

  inner OpenHPL.Data data(
    SteadyState=true,
    f_grid=50,
    f_0=1,
    Vdot_0=1.5) annotation (Placement(transformation(extent={{-96,78},{-76,98}})));

  OpenHPL.Waterway.Reservoir reservoir(
    h_0=10,
    fixElevation=true,
    z_0=100) annotation (Placement(transformation(extent={{-96,20},{-76,40}})));
  OpenHPL.Waterway.Pipe intake(
    H=10,
    L=50,
    D_i=5) annotation (Placement(transformation(extent={{-70,20},{-50,40}})));
  OpenHPL.Waterway.Pipe penstock(
    H=80,
    L=200,
    D_i=3,
    D_o=3) annotation (Placement(transformation(extent={{-42,20},{-22,40}})));
  OpenHPL.ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,
    H_n=80,
    Vdot_n=3,
    u_n=1,
    ConstEfficiency=true,
    eta_h=0.9,
    Pmax=P_base,
    J=J_each,
    p=p,
    enable_nomSpeed=false,
    enable_P_out=true) annotation (Placement(transformation(extent={{-12,10},{8,30}})));
  OpenHPL.Waterway.Pipe discharge(
    H=0.5,
    L=600,
    D_i=5) annotation (Placement(transformation(extent={{18,0},{38,20}})));
  OpenHPL.Waterway.Reservoir tail(h_0=5) annotation (Placement(transformation(
    origin={58,10}, extent={{-10,10},{10,-10}}, rotation=180)));

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
    T_g=0.3,
    K_i=1.5,
    u_bias=0.5,
    u_min=0.05,
    u_max=1.0) annotation (Placement(transformation(extent={{-24,52},{-4,72}})));

  Modelica.Blocks.Sources.Step loadStep(
    offset=0.50*P_base,
    height=0.10*P_base,
    startTime=5) annotation (Placement(transformation(extent={{50,48},{70,68}})));
  Modelica.Blocks.Sources.Constant zeroPower(k=0) annotation (Placement(transformation(extent={{-4,-60},{16,-40}})));

  output SI.Frequency frequency_Hz "System frequency";
  output SI.Power mechanicalPower "Turbine shaft power";
  output SI.Power electricalLoad "Applied electrical load";
  output SI.PerUnit guideVane "Guide-vane opening";
  output SI.VolumeFlowRate turbineFlow "Turbine volumetric flow";

initial equation
  der(generator.inertia.w)=0 "Enforce exact electromechanical steady state before the load step";

equation
  connect(reservoir.o,intake.i);
  connect(intake.o,penstock.i);
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

  annotation (
    experiment(StartTime=0, StopTime=65, Tolerance=1e-7, Interval=0.02),
    Documentation(info="<html><h4>AGC_SMIB benchmark</h4><p>A compact single-machine aggregate-bus frequency-control problem using the nonlinear OpenHPL waterway and turbine equations. The initial operating point is solved as a steady state at 50% loading (1.25 MW on a 2.5 MW base). At t=5 s the electrical load is stepped to 60% (1.50 MW). The governor provides 5% primary droop and an integral secondary term. The Grid block is configured with Lambda=0 so it acts as a simple electrical load torque and measurement bus; the turbine and generator supply the rotating inertia. This is the first AGC/SMIB milestone and intentionally avoids detailed electromagnetic/network transients.</p></html>"));
end AGC_SMIB;
