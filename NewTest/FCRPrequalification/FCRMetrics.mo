within NewTest.FCRPrequalification;
block FCRMetrics "Compact metrics for an FCR activation test"
  parameter Modelica.SIunits.Time eventTime=20;
  parameter Real requestedReserve=0.1 "Requested reserve increment in pu gate";
  parameter Modelica.SIunits.Time measurementWindow=30;
  Modelica.Blocks.Interfaces.RealInput reserveDelivered;
  Modelica.Blocks.Interfaces.RealInput frequency(unit="Hz");

  output Real deliveryRatio;
  output Real reserveError;
  output Real peakDelivered(start=0, fixed=true);
  output Modelica.SIunits.Frequency minFrequency(start=1e9, fixed=true);
  output Modelica.SIunits.Time timeTo90(start=-1, fixed=true);

protected
  Real target90;
equation
  target90 = 0.9*requestedReserve;
  deliveryRatio =
    if abs(requestedReserve) > Modelica.Constants.small
    then reserveDelivered/requestedReserve
    else 0;
  reserveError = requestedReserve - reserveDelivered;

  when reserveDelivered > pre(peakDelivered) then
    peakDelivered = reserveDelivered;
  end when;

  when frequency < pre(minFrequency) then
    minFrequency = frequency;
  end when;

  when {time >= eventTime and pre(timeTo90) < 0 and reserveDelivered >= target90} then
    timeTo90 = time - eventTime;
  end when;
end FCRMetrics;
