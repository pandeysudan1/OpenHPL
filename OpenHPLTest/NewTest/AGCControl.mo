within OpenHPLTest.NewTest;
model AGCControl
  "Primary permanent droop plus secondary AGC frequency restoration"
  extends Modelica.Icons.Example;

  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Modelica.Units.SI.Power P_base=100e6;
  parameter Modelica.Units.SI.Power P_load0=50e6;
  parameter Modelica.Units.SI.Power dP=5e6;
  parameter Modelica.Units.SI.Time stepTime=50;
  parameter Modelica.Units.SI.Time H=4;
  parameter Integer poles=12;
  parameter Modelica.Units.SI.Efficiency eta_e=0.99 "Electrical output / shaft demand";
  parameter Real R=0.04 "Primary permanent droop";
  parameter Real Ki_AGC(unit="1/s")=0.02
    "Secondary integral gain";

  final parameter Modelica.Units.SI.AngularVelocity w_nom=
    4*Modelica.Constants.pi*f_nom/poles;

  inner OpenHPL.Data data(f_grid=f_nom, f_0=1, SteadyState=true, Vdot_0=15, rho=997, mu=0.89e-3, p_eps_input=0.0001) annotation(Placement(transformation(origin={-120,115},extent={{-10,-10},{10,10}},rotation=0)));

  OpenHPL.Waterway.Reservoir reservoir(h_0=50,constantLevel=true,fixElevation=true,z_0=300) annotation(Placement(transformation(origin={-120,30},extent={{-10,-10},{10,10}},rotation=0)));
  OpenHPL.Waterway.Pipe penstock(H=300,L=600,D_i=4,D_o=4,SteadyState=true) annotation(Placement(transformation(origin={-80,30},extent={{-10,-10},{10,10}},rotation=0)));
  OpenHPL.ElectroMech.Turbines.Turbine turbine(ValveCapacity=false,H_n=345,Vdot_n=35,u_n=0.95,ConstEfficiency=true,eta_h=0.9,enable_P_out=true,enable_nomSpeed=false,fixed_iniSpeed=false,J=0,p=poles,Ploss=0,Pmax=2*P_base) annotation(Placement(transformation(origin={-30,30},extent={{-20,-20},{20,20}},rotation=0)));
  OpenHPL.Waterway.Reservoir tail(h_0=5,constantLevel=true) annotation(Placement(transformation(origin={20,30},extent={{-10,-10},{10,10}},rotation=180)));
  OpenHPL.ElectroMech.Generators.SimpleGen generator(useH=false,J=2*H*P_base/w_nom^2,p=poles,Ploss=0,Pmax=2*P_base,fixed_iniSpeed=true,f_0=1,enable_f=true,enable_w=true) annotation(Placement(transformation(origin={-30,-35},extent={{-15,-15},{15,15}},rotation=0)));

  Modelica.Blocks.Sources.Step load(
    offset=P_load0,height=dP,startTime=stepTime) annotation(Placement(transformation(origin={-120,-80},extent={{-10,-10},{10,10}},rotation=0)));
  Modelica.Blocks.Sources.Constant schedule(k=P_load0) annotation(Placement(transformation(origin={20,-85},extent={{-10,-10},{10,10}},rotation=0)));
  Modelica.Blocks.Sources.RealExpression powerMeasurement(
    y=eta_e*turbine.P_out) annotation(Placement(transformation(origin={20,55},extent={{-10,-10},{10,10}},rotation=0)));

  Controllers.PermanentDroopGovernor governor(
    f_ref=f_nom,P_base=P_base,R=R) annotation(Placement(transformation(origin={100,90},extent={{-20,-20},{20,20}},rotation=0)));
  Controllers.SecondaryAGC agc(
    f_ref=f_nom,P_base=P_base,Ki=Ki_AGC) annotation(Placement(transformation(origin={100,-20},extent={{-16,-16},{16,16}},rotation=0)));
  Controllers.GateActuator actuator annotation(Placement(transformation(origin={-60,100},extent={{-12,-12},{12,12}},rotation=0)));

  output Modelica.Units.SI.Frequency frequency;
  output Modelica.Units.SI.Power primaryPowerReference;
  output Modelica.Units.SI.Power agcCorrection;
  output Real primaryDroopError;
  output Real agcFrequencyError;
  output Real gateOpening;
  output Modelica.Units.SI.Power mechanicalPower;
  output Modelica.Units.SI.Power electricalDemand;
  output Modelica.Units.SI.VolumeFlowRate waterFlow;

  output Modelica.Units.SI.Power powerImbalance=turbine.P_out-generator.Pload;
  output Modelica.Units.SI.Power electricalGeneration=eta_e*turbine.P_out "Electrical-equivalent turbine delivery; includes acceleration imbalance during transients";
  Modelica.Blocks.Math.Gain frequencyHz(k=f_nom) annotation(Placement(transformation(origin={10,-40},extent={{-10,-10},{10,10}},rotation=0)));
  Modelica.Blocks.Math.Gain electricalToShaft(k=1/eta_e) annotation(Placement(transformation(origin={-80,-80},extent={{-10,-10},{10,10}},rotation=0)));
initial equation
  der(generator.inertia.w)=0
    "Solve initial hydraulic/electromechanical equilibrium";
  agc.x=0
    "Start secondary controller from the scheduled operating point";
  assert(P_load0>0 and P_load0+dP>0,
    "Positive demand is required before and after the step");

equation
  connect(reservoir.o,penstock.i) annotation(Line(points={{-110,30},{-90,30}},color={28,108,200}));
  connect(penstock.o,turbine.i) annotation(Line(points={{-70,30},{-50,30}},color={28,108,200}));
  connect(turbine.o,tail.o) annotation(Line(points={{-10,30},{10,30}},color={28,108,200}));
  connect(turbine.flange,generator.flange) annotation(Line(points={{-30,30},{-30,-35}},color={0,0,0}));
  connect(load.y,electricalToShaft.u) annotation(Line(points={{-109,-80},{-92,-80}},color={0,0,127}));
  connect(electricalToShaft.y,generator.Pload) annotation(Line(points={{-69,-80},{-30,-80},{-30,-17}},color={0,0,127}));
  connect(generator.f,frequencyHz.u) annotation(Line(points={{-13.5,-41},{-6,-41},{-6,-40},{-2,-40}},color={0,0,127}));

  connect(frequencyHz.y,governor.f) annotation(Line(points={{21,-40},{40,-40},{40,102},{76,102}},color={0,0,127}));
  connect(frequencyHz.y,agc.f) annotation(Line(points={{21,-40},{60,-40},{60,-13.6},{80.8,-13.6}},color={0,0,127}));
  connect(schedule.y,agc.P_schedule) annotation(Line(points={{31,-85},{70,-85},{70,-26.4},{80.8,-26.4}},color={0,0,127}));
  connect(agc.P_ref,governor.P_ref) annotation(Line(points={{117.6,-20},{150,-20},{150,45},{50,45},{50,86},{76,86}},color={0,0,127}));
  connect(powerMeasurement.y,governor.P) annotation(Line(points={{31,55},{60,55},{60,94},{76,94}},color={0,0,127}));

  connect(governor.y,actuator.u) annotation(Line(points={{122,90},{150,90},{150,140},{-95,140},{-95,100},{-74.4,100}},color={0,0,127}));
  connect(actuator.y,turbine.u_t) annotation(Line(points={{-46.8,100},{-46,100},{-46,54}},color={0,0,127}));
  connect(actuator.y,governor.gate) annotation(Line(points={{-46.8,100},{-4,100},{-4,65},{64,65},{64,78},{76,78}},color={0,0,127}));

  frequency=frequencyHz.y;
  primaryPowerReference=agc.P_ref;
  agcCorrection=agc.P_ref-schedule.y;
  primaryDroopError=governor.e;
  agcFrequencyError=agc.e_f;
  gateOpening=actuator.y;
  mechanicalPower=turbine.P_out;
  electricalDemand=load.y;
  waterFlow=turbine.Vdot;

  annotation(
    Diagram(coordinateSystem(extent={{-150,-120},{175,155}})),
    experiment(StartTime=0,StopTime=8000,Interval=1,Tolerance=1e-7),
    Documentation(info="<html>
<p>This example reuses the existing PermanentDroopGovernor and GateActuator.
The new SecondaryAGC block slowly adjusts P_ref after the primary droop response.</p>
<p>Sequence after the +5 MW load step: inertia arrests the initial imbalance;
permanent droop increases gate opening and leaves a frequency offset; AGC then
integrates the remaining frequency error and shifts P_ref until frequency returns
toward 50 Hz.</p>
<p>Compare this model directly with PermanentDroopControl. Plot frequency,
primaryPowerReference, agcCorrection, primaryDroopError, agcFrequencyError,
gateOpening, mechanicalPower and waterFlow.</p>
</html>"));
end AGCControl;
