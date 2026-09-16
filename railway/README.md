# SimpleTurbine baseline

Runs the unmodified `OpenHPL.Examples.SimpleTurbine` with OpenModelica 1.27.0 and Modelica 4.0.0. This is a hydraulic baseline, not an FCR qualification or generator-frequency test.

- Duration: 0–1000 s; output interval: 1 s; DASSL tolerance: 1e-6.
- Guide-vane command: 1.0 until 500 s, ramp to 0.1 by 530 s.
- Outputs: flow, turbine power, pressure drop, surge-tank level and command.
- Initial conditions are those in the library example; initial transients may occur.

Run `python3 railway/run_simple_turbine.py` in a Linux environment with OpenModelica, Modelica 4.0.0, Git and Python 3. Results are written to `/tmp/openhpl-results`. The script checks required columns, finite numbers and completion at 1000 s. It logs the source commit, compiler version, summary and compressed CSV chunks with a SHA-256 checksum for retrieval from Railway. These checks establish numerical completion, not physical validation against plant measurements.

Cloud run status and results will be recorded after execution. The service uses restart policy NEVER to avoid automatic repeat simulations.
