within OpenHPL.Examples.AGC_Trollheim_Surgetank;
block InitializedGovernorAGC
  "Droop plus integral AGC with anchored controller states for difficult hydraulic initialization"
  parameter Real R=0.50 "Permanent droop";
  parameter SI.Time T_g=0.30 "Guide-vane servo time constant";
  parameter Real K_i(unit="1/s")=0.10 "Integral gain";
  parameter SI.PerUnit f_ref=1 "Frequency reference";
  parameter SI.PerUnit u_bias=0.50 "Governor bias";
  parameter SI.PerUnit u_init=0.44634 "Known gate value near 75 MW operating point";
  parameter SI.PerUnit u_min=0.05;
  parameter SI.PerUnit u_max=1.0;

  Modelica.Blocks.Interfaces.RealInput f_pu;
  Modelica.Blocks.Interfaces.RealOutput gate;

  SI.PerUnit e_f;
  Real x_i(start=(u_init-u_bias)/K_i, fixed=true) "Anchored AGC integral state";
  SI.PerUnit u(start=u_init, fixed=true) "Anchored guide-vane state";
  SI.PerUnit u_cmd;
  SI.PerUnit u_sat;

equation
  e_f=f_ref-f_pu;
  der(x_i)=e_f;
  u_cmd=u_bias+e_f/R+K_i*x_i;
  u_sat=min(u_max,max(u_min,u_cmd));
  der(u)=(u_sat-u)/T_g;
  gate=u;

  annotation(Documentation(info="<html><p>Specialized initialization variant for the Trollheim surge-tank benchmark. The controller states are fixed to a known nearby operating point during initialization so global hydraulic homotopy cannot escape through an unphysical guide-vane solution. After t=0 the equations are identical to the simple droop-plus-integral AGC structure.</p></html>"));
end InitializedGovernorAGC;
