# Multigeneration System With Area Control

This package studies a stylized two-area hydro generation problem inspired by the Norwegian NO1 and NO2 bidding zones inside a Nordic-style synchronous system. The problem is to understand how a hydro-dominated exporting area and a more load-heavy importing area share a sudden disturbance through primary droop and then restore scheduled interchange through secondary area control. The current benchmark applies a `+6 MW` load increase in the NO1 area at `t = 200 s` while NO1 starts with a scheduled `8 MW` import from NO2.

The repository does not currently contain a validated Nordic 44 transmission model, tie-line parameter set for NO1-NO2, or a reusable multi-area network package. For that reason, the study is implemented as a reduced-order control benchmark rather than a full EMT or transient-stability network model. It reuses the existing `PermanentDroopGovernor` and `GateActuator` blocks from `NewTest`, adds a linearized tie-line-power block and tie-line-bias AGC block, and wraps each area in a reduced-order hydro aggregate. A more detailed `HydroGovernorArea` wrapper is also included as an exploratory path for future extension back toward the full OpenHPL hydraulic plant.

The current result is a realistic control study rather than a claim of exact Nordic 44 calibration. From the generated summary, both areas start at `50 Hz`, NO1 falls to `49.3969 Hz`, NO2 falls to `49.4093 Hz`, and both recover to `49.9995 Hz` by the end of the run. The scheduled tie-line transfer starts at `-8 MW`, reaches a transient minimum of `-14.8354 MW`, and returns to `-7.9963 MW`, showing that AGC nearly restores the planned interchange. Final aggregate generation settles near `51.00 MW` for NO1 and `59.99 MW` for NO2.

Included models:

- `Components/ReducedHydroArea.mo`
- `Components/HydroGovernorArea.mo`
- `Components/TieLinePower.mo`
- `Components/TieLineBiasAGC.mo`
- `NorwayNO1NO2AreaControl.mo`

Generated study assets:

- `report_data/NorwayNO1NO2AreaControl_res.csv`
- `report_data/summary.json`
- `report_data/no1_no2_area_response.png`
- `report_data/no1_no2_generation_and_agc.png`