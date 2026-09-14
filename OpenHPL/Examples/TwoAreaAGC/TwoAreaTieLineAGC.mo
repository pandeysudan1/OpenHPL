within OpenHPL.Examples.TwoAreaAGC;
model TwoAreaTieLineAGC
  "Two synchronous hydro areas with 5+3 Trollheim-like units and tie-line ACE control"
  extends Modelica.Icons.Example;

  parameter Integer n1=5 "Hydro units in Area 1";
  parameter Integer n2=3 "Hydro units in Area 2";
  parameter SI.Power P_unit=150e6 "Rated power of each Trollheim-like unit";
  parameter Integer p=12 "Generator pole count";
  parameter SI.MomentOfInertia J_total=2e5 "Rotor inertia per unit benchmark";
  final parameter SI.MomentOfInertia J_each=J_total/2;
  final parameter SI.Power Pbase1=n1*P_unit;
  final parameter SI.Power Pbase2=n2*P_unit;

  parameter Real K_tie(unit="W/rad")=25e6
    "Synchronizing coefficient of the AC tie line";
  parameter Real B1=20 "Area-1 frequency bias in pu ACE / pu frequency";
  parameter Real B2=20 "Area-2 frequency bias in pu ACE / pu frequency";
  parameter SI.Power dP1=30e6 "Area-1 load increase at t=5 s";

  block TieLineGovernor
    "Primary droop plus distributed secondary ACE integral control"
    parameter Real R=0.50 "Droop [pu frequency / pu gate]";
    parameter SI.Time T_g=0.30 "Guide-vane servomotor time constant";
    parameter Real K_i(unit="1/s")=0.12 "ACE integral gain";
    parameter Real alpha=1 "Area participation factor";
    parameter SI.PerUnit u_bias=0.50;
    parameter SI.PerUnit u_min=0.05;
    parameter SI.PerUnit u_max=1.0;
    Modelica.Blocks.Interfaces.RealInput f_pu;
    Modelica.Blocks.Interfaces.RealInput ace_pu;
    Modelica.Blocks.Interfaces.RealOutput gate;
    SI.PerUnit e_f;
    Real x_ace(start=0, fixed=false);
    SI.PerUnit u(start=u_bias, fixed=false);
    SI.PerUnit u_cmd;
    SI.PerUnit u_sat;
  initial equation
    der(x_ace)=0;
    der(u)=0;
  equation
    e_f=1-f_pu;
    der(x_ace)=-ace_pu;
    u_cmd=u_bias + e_f/R + alpha*K_i*x_ace;
    u_sat=min(u_max,max(u_min,u_cmd));
    der(u)=(u_sat-u)/T_g;
    gate=u;
  end TieLineGovernor;

  inner OpenHPL.Data data(SteadyState=true,f_grid=50,f_0=1,Vdot_0=25);

  OpenHPL.Waterway.Reservoir reservoir1[n1](each h_0=50,each fixElevation=true,each z_0=322);
  OpenHPL.Waterway.Pipe intake1[n1](each H=20,each L=500,each D_i=6,each D_o=6);
  OpenHPL.Waterway.Pipe penstock1[n1](each H=300,each L=500,each D_i=4,each D_o=4);
  OpenHPL.ElectroMech.Turbines.Turbine turbine1[n1](each ValveCapacity=false,each H_n=340,each Vdot_n=50,each u_n=1,each ConstEfficiency=true,each eta_h=0.90,each Pmax=P_unit,each J=J_each,each p=p,each enable_nomSpeed=false,each enable_P_out=true);
  OpenHPL.Waterway.Pipe discharge1[n1](each H=2,each L=600,each D_i=6,each D_o=6);
  OpenHPL.Waterway.Reservoir tail1[n1](each h_0=5);
  OpenHPL.ElectroMech.Generators.SimpleGen generator1[n1](each Pmax=P_unit,each J=J_each,each p=p,each Ploss=0,each enable_f=true);
  TieLineGovernor governor1[n1](each R=0.50,each T_g=0.30,each K_i=0.12,each alpha=1.0/n1);

  OpenHPL.Waterway.Reservoir reservoir2[n2](each h_0=50,each fixElevation=true,each z_0=322);
  OpenHPL.Waterway.Pipe intake2[n2](each H=20,each L=500,each D_i=6,each D_o=6);
  OpenHPL.Waterway.Pipe penstock2[n2](each H=300,each L=500,each D_i=4,each D_o=4);
  OpenHPL.ElectroMech.Turbines.Turbine turbine2[n2](each ValveCapacity=false,each H_n=340,each Vdot_n=50,each u_n=1,each ConstEfficiency=true,each eta_h=0.90,each Pmax=P_unit,each J=J_each,each p=p,each enable_nomSpeed=false,each enable_P_out=true);
  OpenHPL.Waterway.Pipe discharge2[n2](each H=2,each L=600,each D_i=6,each D_o=6);
  OpenHPL.Waterway.Reservoir tail2[n2](each h_0=5);
  OpenHPL.ElectroMech.Generators.SimpleGen generator2[n2](each Pmax=P_unit,each J=J_each,each p=p,each Ploss=0,each enable_f=true);
  TieLineGovernor governor2[n2](each R=0.50,each T_g=0.30,each K_i=0.12,each alpha=1.0/n2);

  OpenHPL.ElectroMech.PowerSystem.Grid grid1(Pgrid=Pbase1,useLambda=true,Lambda=0,mu=0,J=1,p=p,enable_f=true);
  OpenHPL.ElectroMech.PowerSystem.Grid grid2(Pgrid=Pbase2,useLambda=true,Lambda=0,mu=0,J=1,p=p,enable_f=true);

  Modelica.Blocks.Sources.Step localLoad1(offset=0.50*Pbase1,height=dP1,startTime=5);
  Modelica.Blocks.Sources.Constant localLoad2(k=0.50*Pbase2);
  Modelica.Blocks.Sources.Constant zeroPower(k=0);
  Modelica.Blocks.Sources.RealExpression area1Load(y=localLoad1.y + P_tie);
  Modelica.Blocks.Sources.RealExpression area2Load(y=localLoad2.y - P_tie);

  Real delta12(start=0,fixed=true) "Area-1 minus Area-2 electrical angle [rad]";
  SI.Power P_tie "Tie-line power, positive Area 1 -> Area 2";
  SI.Frequency frequency1_Hz;
  SI.Frequency frequency2_Hz;
  Real df1_pu;
  Real df2_pu;
  Real Ptie_pu1;
  Real Ptie_pu2;
  Real ACE1_pu;
  Real ACE2_pu;
  Real gate1_mean;
  Real gate2_mean;
  Real mechanical1_MW;
  Real mechanical2_MW;
  Real localLoad1_MW;
  Real localLoad2_MW;
  Real P_tie_MW;

initial equation
  der(generator1[1].inertia.w)=0;
  der(generator2[1].inertia.w)=0;

equation
  for i in 1:n1 loop
    connect(reservoir1[i].o,intake1[i].i);
    connect(intake1[i].o,penstock1[i].i);
    connect(penstock1[i].o,turbine1[i].i);
    connect(turbine1[i].o,discharge1[i].i);
    connect(discharge1[i].o,tail1[i].o);
    connect(turbine1[i].flange,generator1[i].flange);
    connect(generator1[i].flange,grid1.flange);
    connect(zeroPower.y,generator1[i].Pload);
    connect(generator1[i].f,governor1[i].f_pu);
    governor1[i].ace_pu=ACE1_pu;
    connect(governor1[i].gate,turbine1[i].u_t);
  end for;

  for i in 1:n2 loop
    connect(reservoir2[i].o,intake2[i].i);
    connect(intake2[i].o,penstock2[i].i);
    connect(penstock2[i].o,turbine2[i].i);
    connect(turbine2[i].o,discharge2[i].i);
    connect(discharge2[i].o,tail2[i].o);
    connect(turbine2[i].flange,generator2[i].flange);
    connect(generator2[i].flange,grid2.flange);
    connect(zeroPower.y,generator2[i].Pload);
    connect(generator2[i].f,governor2[i].f_pu);
    governor2[i].ace_pu=ACE2_pu;
    connect(governor2[i].gate,turbine2[i].u_t);
  end for;

  connect(area1Load.y,grid1.Pload);
  connect(area2Load.y,grid2.Pload);

  frequency1_Hz=data.f_grid*generator1[1].f;
  frequency2_Hz=data.f_grid*generator2[1].f;
  df1_pu=generator1[1].f-1;
  df2_pu=generator2[1].f-1;

  der(delta12)=2*Modelica.Constants.pi*(frequency1_Hz-frequency2_Hz);
  P_tie=K_tie*delta12;
  Ptie_pu1=P_tie/Pbase1;
  Ptie_pu2=P_tie/Pbase2;
  ACE1_pu=B1*df1_pu + Ptie_pu1;
  ACE2_pu=B2*df2_pu - Ptie_pu2;

  gate1_mean=sum(governor1.gate)/n1;
  gate2_mean=sum(governor2.gate)/n2;
  mechanical1_MW=sum(turbine1.Wdot_s)/1e6;
  mechanical2_MW=sum(turbine2.Wdot_s)/1e6;
  localLoad1_MW=localLoad1.y/1e6;
  localLoad2_MW=localLoad2.y/1e6;
  P_tie_MW=P_tie/1e6;

  annotation(experiment(StartTime=0,StopTime=80,Tolerance=1e-7,Interval=0.02),
    Documentation(info="<html><h4>TwoAreaTieLineAGC</h4><p>Two coherent hydro control areas are formed from five and three Trollheim-like nonlinear hydropower units. A 30 MW step is applied in Area 1 at t=5 s. The AC tie line is represented by P12=K12(delta1-delta2), with angle difference obtained from the integral of area frequency difference. Each area's distributed secondary controller integrates ACE = B*Delta f +/- Delta Ptie so that both frequency and scheduled tie-line exchange are restored.</p></html>"));
end TwoAreaTieLineAGC;
