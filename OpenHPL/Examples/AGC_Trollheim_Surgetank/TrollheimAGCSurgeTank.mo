within OpenHPL.Examples.AGC_Trollheim_Surgetank;
model TrollheimAGCSurgeTank "Trollheim AGC benchmark with homotopy-assisted surge tank"
  extends Modelica.Icons.Example;

  parameter SI.Power P_base=150e6 "Plant power base";
  parameter Integer p=12 "Generator pole count";
  parameter SI.MomentOfInertia J_total=2e5 "Transferred Trollheim rotor inertia benchmark";
  final parameter SI.MomentOfInertia J_each=J_total/2;

  inner OpenHPL.Data data(SteadyState=true,f_grid=50,f_0=1,Vdot_0=25);
  OpenHPL.Waterway.Reservoir reservoir(h_0=50,fixElevation=true,z_0=322);
  OpenHPL.Waterway.Pipe intake(H=20,L=500,D_i=6,D_o=6,SteadyState=true);
  HomotopySurgeTank surgeTank(H=80,L=80,D=4,h_0=50,Vdot_0=0,Vdot_hom=1,SteadyState=true);
  OpenHPL.Waterway.Pipe penstock(H=300,L=500,D_i=4,D_o=4,SteadyState=true);
  OpenHPL.ElectroMech.Turbines.Turbine turbine(
    ValveCapacity=false,H_n=340,Vdot_n=50,u_n=1,
    ConstEfficiency=true,eta_h=0.90,Pmax=P_base,J=J_each,p=p,
    enable_nomSpeed=false,enable_P_out=true);
  OpenHPL.Waterway.Pipe discharge(H=2,L=600,D_i=6,D_o=6,SteadyState=true);
  OpenHPL.Waterway.Reservoir tail(h_0=5);
  OpenHPL.ElectroMech.Generators.SimpleGen generator(
    Pmax=P_base,J=J_each,p=p,Ploss=0,enable_f=true,
    fixed_iniSpeed=false);
  OpenHPL.ElectroMech.PowerSystem.Grid grid(
    Pgrid=P_base,useLambda=true,Lambda=0,mu=0,J=1,p=p,enable_f=true,
    fixed_iniSpeed=true);

  InitializedGovernorAGC governor(
    R=0.50,
    T_g=0.30,
    K_i=0.10,
    u_bias=0.50,
    u_init=0.44634,
    u_min=0.05,
    u_max=1.0);

  Modelica.Blocks.Sources.Step loadStep(offset=0.50*P_base,height=0.10*P_base,startTime=5);
  Modelica.Blocks.Sources.Constant zeroPower(k=0);

  output SI.Frequency frequency_Hz "Generator/grid frequency";
  output SI.Power mechanicalPower "Turbine shaft power";
  output SI.Power electricalLoad "Applied electrical load";
  output SI.PerUnit guideVane "Guide-vane opening";
  output SI.VolumeFlowRate turbineFlow "Turbine flow";
  output SI.Height surgeLevel "Surge-tank level";
  output SI.VolumeFlowRate surgeFlow "Surge-branch flow";

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

initial equation
  der(generator.inertia.w)=0;

  annotation(
    experiment(StartTime=0,StopTime=65,Tolerance=1e-7,Interval=0.02),
    Documentation(info="<html><h4>AGC Trollheim with surge tank</h4><p>The surge-tank momentum equation uses Modelica homotopy(). The AGC controller is anchored to a nearby 75 MW operating point and exactly one mechanically connected unit (the Grid model) fixes the initial shaft speed to nominal, as intended by OpenHPL Power2Torque.fixed_iniSpeed. The generator derivative condition then enforces initial torque balance. The load changes from 75 MW to 90 MW at t=5 s.</p></html>"));
end TrollheimAGCSurgeTank;
