within OpenHPLTest.NewTest;
model FCRControl
  "Hydro frequency-containment response with filtered deadbanded reserve activation"
  extends Modelica.Icons.Example;

  parameter Modelica.Units.SI.Frequency f_nom=50;
  parameter Modelica.Units.SI.Power P_base=100e6;
  parameter Modelica.Units.SI.Power P_load0=50e6;
  parameter Modelica.Units.SI.Power dP=5e6;
  parameter Modelica.Units.SI.Time stepTime=50;
  parameter Modelica.Units.SI.Time H=4;
  parameter Integer poles=12;
  parameter Real gateBias(start=0.45,fixed=false) "Gate bias solved from initial power balance";
  parameter Modelica.Units.SI.Efficiency eta_e=0.99 "Electrical output / shaft demand";

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

  Controllers.FCRGovernor fcr(
    f_ref=f_nom,
    Tm=0.10,
    deadband=0.00,
    Kf=0.20,
    y_bias=gateBias,
    reserveUp=0.15,
    reserveDown=0.15) annotation(Placement(transformation(origin={100,90},extent={{-20,-20},{20,20}},rotation=0)));

  Controllers.GateActuator actuator(
    openingRate=0.05,
    closingRate=0.05,
    y_start=0.451827) annotation(Placement(transformation(origin={-60,100},extent={{-12,-12},{12,12}},rotation=0)));

  output Modelica.Units.SI.Frequency frequency;
  output Modelica.Units.SI.Frequency filteredFrequency;
  output Modelica.Units.SI.Frequency frequencyDeviation;
  output Real fcrReserveCommand;
  output Real fcrReserveLimited;
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
    "Solve initial plant equilibrium";
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

  connect(frequencyHz.y,fcr.f) annotation(Line(points={{21,-40},{40,-40},{40,100},{76,100}},color={0,0,127}));
  connect(fcr.y,actuator.u) annotation(Line(points={{122,90},{150,90},{150,140},{-95,140},{-95,100},{-74.4,100}},color={0,0,127}));
  connect(actuator.y,fcr.gate) annotation(Line(points={{-46.8,100},{-4,100},{-4,65},{64,65},{64,80},{76,80}},color={0,0,127}));
  connect(actuator.y,turbine.u_t) annotation(Line(points={{-46.8,100},{-46,100},{-46,54}},color={0,0,127}));

  frequency=frequencyHz.y;
  filteredFrequency=fcr.fFilt;
  frequencyDeviation=fcr.df;
  fcrReserveCommand=fcr.reserveCommand;
  fcrReserveLimited=fcr.reserveLimited;
  gateOpening=actuator.y;
  mechanicalPower=turbine.P_out;
  electricalDemand=load.y;
  waterFlow=turbine.Vdot;

  annotation(
    Diagram(coordinateSystem(extent={{-150,-120},{175,155}})),
    experiment(StartTime=0,StopTime=180,Interval=0.05,Tolerance=1e-7),
    Documentation(info="<html>
<p>This example reuses the same OpenHPL hydro plant and GateActuator used by the
other NewTest controller studies.</p>
<p>At t=50 s the electrical demand increases by 5 MW. The FCRGovernor filters
frequency, applies a parameterized deadband, converts the active frequency deviation
to a fast reserve command, and limits upward/downward activation before commanding
the gate actuator.</p>
<p>Plot frequency, filteredFrequency, frequencyDeviation, fcrReserveCommand,
fcrReserveLimited, gateOpening, mechanicalPower and waterFlow.</p>
<p>This is a generic FCR dynamics example. Product-specific prequalification
criteria should be implemented as a separate test layer around this reusable block.</p>
</html>"));
end FCRControl;
