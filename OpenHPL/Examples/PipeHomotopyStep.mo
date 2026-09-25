within OpenHPL.Examples;
model PipeHomotopyStep "Small pipe step-response example for homotopy CI"
  extends Modelica.Icons.Example;

  inner OpenHPL.Data data(SteadyState=false, Vdot_0=0.5);

  Modelica.Blocks.Sources.Step flowStep(height=0.2, offset=0.5, startTime=5)
    "Commanded flow: 0.5 -> 0.7 m3/s at t=5 s";

  OpenHPL.Waterway.VolumeFlowSource source(
    useInput=true,
    useFilter=true,
    T_f=0.25,
    fixElevation=true,
    z_0=0);

  OpenHPL.Waterway.Pipe pipe(
    H=0,
    L=500,
    D_i=0.8,
    D_o=0.8,
    SteadyState=false,
    Vdot_0=0.5,
    useInitialFlow=false,
    useHomotopy=true);

  OpenHPL.Waterway.Reservoir downstream(
    h_0=10,
    constantLevel=true,
    fixElevation=false);

equation
  connect(flowStep.y, source.outFlow);
  connect(source.o, pipe.i);
  connect(pipe.o, downstream.o);

  annotation(experiment(StartTime=0, StopTime=20, Tolerance=1e-6, Interval=0.02));
end PipeHomotopyStep;
