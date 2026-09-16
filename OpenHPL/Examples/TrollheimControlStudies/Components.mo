within OpenHPL.Examples.TrollheimControlStudies;
package Components "Equation-based component models"
  extends Modelica.Icons.Package;

  block GuideVaneServo
    parameter Real T_g(unit="s")=0.25 "Servo time constant";
    parameter Real y_max=0.35 "Maximum guide-vane deviation";
    Modelica.Blocks.Interfaces.RealInput command;
    Modelica.Blocks.Interfaces.RealOutput guideVaneDeviation;
  protected
    Real y(start=0, fixed=true);
  equation
    T_g*der(y) = max(-y_max, min(y_max, command)) - y;
    guideVaneDeviation = y;
  end GuideVaneServo;

  block WaterColumn
    parameter Real T_w(unit="s")=1.50 "Water starting time";
    parameter Real k_q=0.35 "Nonlinear hydraulic-loss coefficient";
    Modelica.Blocks.Interfaces.RealInput guideVaneDeviation;
    Modelica.Blocks.Interfaces.RealOutput flowDeviation;
  protected
    Real q(start=0, fixed=true);
  equation
    T_w*der(q) = guideVaneDeviation - q - k_q*q*abs(q);
    flowDeviation = q;
  end WaterColumn;

  block Turbine
    parameter Real K_t=1.30 "Flow-to-mechanical-power gain";
    parameter Real alpha=0.12 "Nonlinear turbine coefficient";
    Modelica.Blocks.Interfaces.RealInput flowDeviation;
    Modelica.Blocks.Interfaces.RealOutput mechanicalPowerDeviation;
  equation
    mechanicalPowerDeviation =
      K_t*flowDeviation*(1 - alpha*flowDeviation);
  end Turbine;

  block ShaftGenerator
    parameter Real H(unit="s")=3.50 "Inertia constant";
    parameter Real D=1.00 "Load-damping coefficient";
    Modelica.Blocks.Interfaces.RealInput mechanicalPowerDeviation;
    Modelica.Blocks.Interfaces.RealInput electricalPowerDeviation;
    Modelica.Blocks.Interfaces.RealOutput frequencyDeviation;
  protected
    Real f(start=0, fixed=true);
  equation
    2*H*der(f) =
      mechanicalPowerDeviation - electricalPowerDeviation - D*f;
    frequencyDeviation = f;
  end ShaftGenerator;

  block GridLoad
    parameter Real stepTime(unit="s")=5;
    parameter Real stepSize=0.10 "Load increase in pu";
    Modelica.Blocks.Interfaces.RealOutput electricalPowerDeviation;
  equation
    electricalPowerDeviation = if time >= stepTime then stepSize else 0;
  end GridLoad;

  block IsochronousPI
    parameter Real K_p=4.0;
    parameter Real K_i=0.80;
    Modelica.Blocks.Interfaces.RealInput frequencyDeviation;
    Modelica.Blocks.Interfaces.RealOutput command;
  protected
    Real integralError(start=0, fixed=true);
  equation
    der(integralError) = -frequencyDeviation;
    command = -K_p*frequencyDeviation + K_i*integralError;
  end IsochronousPI;

  block DroopController
    parameter Real R=0.05 "5 percent permanent droop";
    Modelica.Blocks.Interfaces.RealInput frequencyDeviation;
    Modelica.Blocks.Interfaces.RealOutput command;
  equation
    command = -frequencyDeviation/R;
  end DroopController;

  block AGCController
    parameter Real R=0.05 "Primary droop";
    parameter Real B=1.0 "Frequency-bias factor";
    parameter Real K_i=0.80 "Secondary integral gain";
    Modelica.Blocks.Interfaces.RealInput frequencyDeviation;
    Modelica.Blocks.Interfaces.RealOutput command;
  protected
    Real secondaryCommand(start=0, fixed=true);
  equation
    der(secondaryCommand) = -K_i*B*frequencyDeviation;
    command = -frequencyDeviation/R + secondaryCommand;
  end AGCController;

  block TieLine
    parameter Real T_12=0.07 "Synchronizing coefficient";
    Modelica.Blocks.Interfaces.RealInput frequencyDeviation1;
    Modelica.Blocks.Interfaces.RealInput frequencyDeviation2;
    Modelica.Blocks.Interfaces.RealOutput tiePowerDeviation;
  protected
    Real pTie(start=0, fixed=true);
  equation
    der(pTie) = 2*Modelica.Constants.pi*T_12*
      (frequencyDeviation1 - frequencyDeviation2);
    tiePowerDeviation = pTie;
  end TieLine;

  block TieLineAGC
    parameter Real R=0.05 "Primary droop";
    parameter Real B=1.0 "Frequency-bias factor";
    parameter Real K_i=0.80 "Secondary integral gain";
    parameter Real tieSign=1.0 "Positive for export, negative for import";
    Modelica.Blocks.Interfaces.RealInput frequencyDeviation;
    Modelica.Blocks.Interfaces.RealInput tieLinePower;
    Modelica.Blocks.Interfaces.RealOutput command;
    Modelica.Blocks.Interfaces.RealOutput areaControlError;
  protected
    Real secondaryCommand(start=0, fixed=true);
  equation
    areaControlError = B*frequencyDeviation + tieSign*tieLinePower;
    der(secondaryCommand) = -K_i*areaControlError;
    command = -frequencyDeviation/R + secondaryCommand;
  end TieLineAGC;
end Components;
