within OpenHPL.Examples.AGC_Trollheim_Surgetank;
model TrollheimAGCSurgeTankInitialized
  "Trollheim AGC with surge tank seeded from validated 75 MW hydraulic equilibrium"
  extends Modelica.Icons.Example;

  parameter SI.Power P_base=150e6;
  parameter Integer p=12;
  parameter SI.MomentOfInertia J_total=2e5;
  final parameter SI.MomentOfInertia J_each=J_total/2;

  // Equilibrium values transferred from the validated no-surge Trollheim case.
  parameter SI.VolumeFlowRate Q_eq=23.17826089221624;
  parameter SI.Height h_s_eq=69.9731780052749;
  parameter SI.PerUnit gate_eq=0.4463398576231575;

  inner OpenHPL.Data data(
    SteadyState=false,
    f_grid=50,
    f_0=1,
    Vdot_0=Q_eq);

  OpenHPL.Waterway.Reservoir reservoir(
    h_0=50,
    fixElevation=true,
    z_0=322);

  OpenHPL.Waterway.Pipe intake(
    H=20,L=500,D_i=6,D_o=6,
    SteadyState=false,Vdot_0=Q_eq);

  HomotopySurgeTank surgeTank(
    H=80,L=80,D=4,
    h_0=h_s_eq,Vdot_0=0,
    SteadyState=false);

  OpenHPL.Waterway.Pipe penstock(
    H=300,L=500,D_i=4,D_o=4,
    SteadyState=false,Vdot_0=Q_eq);

  OpenHPL.ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,H_n=340,Vdot_n=50,u_n=1,
    ConstEfficiency=true,eta_h=0.90,Pmax=P_base,
    J=J_each,p=p,enable_nomSpeed=false,enable_P_out=true);

  OpenHPL.Waterway.Pipe discharge(
    H=2,L=600,D_i=6,D_o=6,
    SteadyState=false,Vdot_0=Q_eq);

  OpenHPL.Waterway.Reservoir tail(h_0=5);

  OpenHPL.ElectroMech.Generators.SimpleGen generator(
    Pmax=P_base,J=J_each,p=p,Ploss=0,enable_f=true,
    fixed_iniSpeed=false);

  OpenHPL.ElectroMech.PowerSystem.Grid grid(
    Pgrid=P_base,useLambda=true,Lambda=0,mu=0,J=1,p=p,enable_f=true,
    fixed_iniSpeed=true);

  InitializedGovernorAGC governor(
    R=0.50,T_g=0.30,K_i=0.10,
    u_bias=0.50,u_init=gate_eq,
    u_min=0.05,u_max=1.0);

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
    experiment(StartTime=0,StopTime=65,Tolerance=1e-7,Interval=0.02),
    Documentation(info="<html>
<h4>Equilibrium-seeded Trollheim surge-tank AGC</h4>
<p>This model avoids asking the global initialization solver to discover the complete hydraulic/electromechanical operating point. Instead, it transfers the validated 75 MW operating point from the no-surge Trollheim benchmark.</p>
<p>The junction pressure in the validated case is 685962.295 Pa. With OpenHPL gauge pressure p_a=0, rho=999.65 kg/m3 and g=9.80665 m/s2, the corresponding hydrostatic surge level is 69.973178 m. The mainline flow is 23.1782609 m3/s and the gate is 0.446339858 pu.</p>
<p>At zero surge flow the inserted surge tank should not alter the mainline equilibrium. The 75 to 90 MW load step remains at t=5 s.</p>
</html>"));
end TrollheimAGCSurgeTankInitialized;
