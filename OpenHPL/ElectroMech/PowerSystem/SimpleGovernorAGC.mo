within OpenHPL.ElectroMech.PowerSystem;
block SimpleGovernorAGC "Primary droop governor with secondary integral frequency restoration"
  parameter Real R=0.05 "Permanent droop [pu frequency / pu gate]";
  parameter SI.Time T_g=0.3 "Guide-vane servomotor time constant";
  parameter Real K_i(unit="1/s")=1.5 "Secondary integral gain";
  parameter SI.PerUnit f_ref=1 "Frequency reference";
  parameter SI.PerUnit u_bias=0.5 "Nominal guide-vane bias";
  parameter SI.PerUnit u_min=0.05 "Minimum guide-vane opening";
  parameter SI.PerUnit u_max=1.0 "Maximum guide-vane opening";

  Modelica.Blocks.Interfaces.RealInput f_pu "Measured unit/grid frequency [pu]";
  Modelica.Blocks.Interfaces.RealOutput gate "Guide-vane command [pu]";

  SI.PerUnit e_f "Frequency error f_ref-f";
  Real x_i(start=0, fixed=false) "AGC integral state";
  SI.PerUnit u(start=u_bias, fixed=false) "Servomotor / guide-vane state";
  SI.PerUnit u_cmd "Unsaturated governor + AGC command";
  SI.PerUnit u_sat "Saturated command";

initial equation
  der(x_i)=0;
  der(u)=0;

equation
  e_f = f_ref - f_pu;
  der(x_i) = e_f;
  u_cmd = u_bias + e_f/R + K_i*x_i;
  u_sat = min(u_max, max(u_min, u_cmd));
  der(u) = (u_sat-u)/T_g;
  gate = u;

  annotation (Documentation(info="<html><p>Minimal LFC/AGC governor for examples. Primary response is 5% droop by default. The integral state restores nominal frequency after a sustained load step. The integral and gate states are left free during initialization and constrained by zero derivatives, allowing the complete hydro-mechanical model to solve a consistent pre-disturbance operating point.</p></html>"));
end SimpleGovernorAGC;
