within OpenHPLTest.NewTest.ControllersWithSurgeTanks;
model AGCControlWithSurgeTank
  "Primary permanent droop plus AGC with surge-tank hydraulics"
  extends Modelica.Icons.Example;

  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Modelica.Units.SI.Power P_base=100e6;
  parameter Modelica.Units.SI.Power P_load0=50e6;
  parameter Modelica.Units.SI.Power dP=5e6;
  parameter Modelica.Units.SI.Time stepTime=50;
  parameter Modelica.Units.SI.Time H=4;
  parameter Integer poles=12;
  parameter Modelica.Units.SI.Efficiency eta_e=0.99;
  parameter Real R=0.04;
  parameter Real Ki_AGC(unit="1/s")=0.02;
  parameter Modelica.Units.SI.Height surgeTankSteadyHeight=99.97713930270363
    "Steady surge-tank water level solved from the initialized isochronous case";
  parameter Modelica.Units.SI.Height surgeTankRise=120;
  parameter Modelica.Units.SI.Diameter surgeTankDiameter=6;

  final parameter Modelica.Units.SI.AngularVelocity w_nom=
    4*Modelica.Constants.pi*f_nom/poles;

  inner OpenHPL.Data data(
    f_grid=f_nom,
    f_0=1,
    SteadyState=true,
    Vdot_0=15,
    rho=997,
    mu=0.89e-3,
    p_eps_input=0.0001) annotation(Placement(transformation(origin={-120,115},extent={{-10,-10},{10,10}},rotation=0)));

  OpenHPL.Waterway.Reservoir reservoir(h_0=50,constantLevel=true,fixElevation=true,z_0=300) annotation(Placement(transformation(origin={-120,30},extent={{-10,-10},{10,10}},rotation=0)));
  OpenHPL.Waterway.Pipe intake(H=50,L=100,D_i=4,D_o=4,SteadyState=true) annotation(Placement(transformation(origin={-100,30},extent={{-10,-10},{10,10}},rotation=0)));
  OpenHPL.Waterway.SurgeTank surgeTank(
    H=surgeTankRise,
    L=surgeTankRise,
    D=surgeTankDiameter,
    SteadyState=true,
    h_0=surgeTankSteadyHeight) annotation(Placement(transformation(origin={-80,30},extent={{-10,-10},{10,10}},rotation=0)));
  OpenHPL.Waterway.Pipe penstock(H=250,L=500,D_i=4,D_o=4,SteadyState=true) annotation(Placement(transformation(origin={-40,30},extent={{-10,-10},{10,10}},rotation=0)));
  OpenHPL.ElectroMech.Turbines.Turbine turbine(ValveCapacity=false,H_n=345,Vdot_n=35,u_n=0.95,ConstEfficiency=true,eta_h=0.9,enable_P_out=true,enable_nomSpeed=false,fixed_iniSpeed=false,J=0,p=poles,Ploss=0,Pmax=2*P_base) annotation(Placement(transformation(origin={10,30},extent={{-20,-20},{20,20}},rotation=0)));
  OpenHPL.Waterway.Reservoir tail(h_0=5,constantLevel=true) annotation(Placement(transformation(origin={60,30},extent={{-10,-10},{10,10}},rotation=180)));
  OpenHPL.ElectroMech.Generators.SimpleGen generator(useH=false,J=2*H*P_base/w_nom^2,p=poles,Ploss=0,Pmax=2*P_base,fixed_iniSpeed=true,f_0=1,enable_f=true,enable_w=true) annotation(Placement(transformation(origin={10,-35},extent={{-15,-15},{15,15}},rotation=0)));

  Modelica.Blocks.Sources.Step load(offset=P_load0,height=dP,startTime=stepTime) annotation(Placement(transformation(origin={-120,-80},extent={{-10,-10},{10,10}},rotation=0)));
  Modelica.Blocks.Sources.Constant schedule(k=P_load0) annotation(Placement(transformation(origin={20,-85},extent={{-10,-10},{10,10}},rotation=0)));
  Modelica.Blocks.Sources.RealExpression powerMeasurement(y=eta_e*turbine.P_out) annotation(Placement(transformation(origin={20,55},extent={{-10,-10},{10,10}},rotation=0)));

  OpenHPLTest.NewTest.Controllers.PermanentDroopGovernor governor(f_ref=f_nom,P_base=P_base,R=R) annotation(Placement(transformation(origin={100,90},extent={{-20,-20},{20,20}},rotation=0)));
  OpenHPLTest.NewTest.Controllers.SecondaryAGC agc(f_ref=f_nom,P_base=P_base,Ki=Ki_AGC) annotation(Placement(transformation(origin={100,-20},extent={{-16,-16},{16,16}},rotation=0)));
  OpenHPLTest.NewTest.Controllers.GateActuator actuator annotation(Placement(transformation(origin={-20,100},extent={{-12,-12},{12,12}},rotation=0)));

  output Modelica.Units.SI.Frequency frequency;
  output Modelica.Units.SI.Power primaryPowerReference;
  output Modelica.Units.SI.Power agcCorrection;
  output Real primaryDroopError;
  output Real agcFrequencyError;
  output Real gateOpening;
  output Modelica.Units.SI.Power mechanicalPower;
  output Modelica.Units.SI.Power electricalDemand;
  output Modelica.Units.SI.VolumeFlowRate waterFlow;
  output Modelica.Units.SI.Height surgeTankHeight;
  output Modelica.Units.SI.VolumeFlowRate surgeTankFlow;

  output Modelica.Units.SI.Power powerImbalance=turbine.P_out-generator.Pload;
  output Modelica.Units.SI.Power electricalGeneration=eta_e*turbine.P_out;
  Modelica.Blocks.Math.Gain frequencyHz(k=f_nom) annotation(Placement(transformation(origin={50,-40},extent={{-10,-10},{10,10}},rotation=0)));
  Modelica.Blocks.Math.Gain electricalToShaft(k=1/eta_e) annotation(Placement(transformation(origin={-80,-80},extent={{-10,-10},{10,10}},rotation=0)));
initial equation
  der(generator.inertia.w)=0;
  agc.x=0;
  assert(P_load0>0 and P_load0 + dP>0,
    "Positive demand is required before and after the step");

equation
  connect(reservoir.o,intake.i) annotation(Line(points={{-110,30},{-110,30}},color={28,108,200}));
  connect(intake.o,surgeTank.i) annotation(Line(points={{-90,30},{-90,30}},color={28,108,200}));
  connect(surgeTank.o,penstock.i) annotation(Line(points={{-70,30},{-50,30}},color={28,108,200}));
  connect(penstock.o,turbine.i) annotation(Line(points={{-30,30},{-10,30}},color={28,108,200}));
  connect(turbine.o,tail.o) annotation(Line(points={{30,30},{50,30}},color={28,108,200}));
  connect(turbine.flange,generator.flange) annotation(Line(points={{10,30},{10,-35}},color={0,0,0}));
  connect(load.y,electricalToShaft.u) annotation(Line(points={{-109,-80},{-92,-80}},color={0,0,127}));
  connect(electricalToShaft.y,generator.Pload) annotation(Line(points={{-69,-80},{10,-80},{10,-17}},color={0,0,127}));
  connect(generator.f,frequencyHz.u) annotation(Line(points={{26.5,-41},{38,-41},{38,-40}},color={0,0,127}));

  connect(frequencyHz.y,governor.f) annotation(Line(points={{61,-40},{76,-40},{76,102}},color={0,0,127}));
  connect(frequencyHz.y,agc.f) annotation(Line(points={{61,-40},{66,-40},{66,-13.6},{80.8,-13.6}},color={0,0,127}));
  connect(schedule.y,agc.P_schedule) annotation(Line(points={{31,-85},{70,-85},{70,-26.4},{80.8,-26.4}},color={0,0,127}));
  connect(agc.P_ref,governor.P_ref) annotation(Line(points={{117.6,-20},{150,-20},{150,45},{50,45},{50,86},{76,86}},color={0,0,127}));
  connect(powerMeasurement.y,governor.P) annotation(Line(points={{31,55},{60,55},{60,94},{76,94}},color={0,0,127}));

  connect(governor.y,actuator.u) annotation(Line(points={{122,90},{150,90},{150,140},{-55,140},{-55,100},{-34.4,100}},color={0,0,127}));
  connect(actuator.y,turbine.u_t) annotation(Line(points={{-6.8,100},{-6,100},{-6,54}},color={0,0,127}));
  connect(actuator.y,governor.gate) annotation(Line(points={{-6.8,100},{34,100},{34,78},{76,78}},color={0,0,127}));

  frequency=frequencyHz.y;
  primaryPowerReference=agc.P_ref;
  agcCorrection=agc.P_ref-schedule.y;
  primaryDroopError=governor.e;
  agcFrequencyError=agc.e_f;
  gateOpening=actuator.y;
  mechanicalPower=turbine.P_out;
  electricalDemand=load.y;
  waterFlow=turbine.Vdot;
  surgeTankHeight=surgeTank.h;
  surgeTankFlow=surgeTank.Vdot;

  annotation(
    Diagram(coordinateSystem(extent={{-150,-120},{175,155}})),
    experiment(StartTime=0,StopTime=8000,Interval=1,Tolerance=1e-7),
    Documentation(info="<html><p>AGC benchmark with an explicit surge tank between the upstream reservoir and the penstock.</p></html>"));
end AGCControlWithSurgeTank;