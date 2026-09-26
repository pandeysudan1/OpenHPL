# Controllers With Surge Tanks

This package collects `NewTest` examples where the hydraulic path includes a surge tank between the upstream intake and the penstock. The initial steady surge-tank water level used in these examples is `99.97713930270363 m`, obtained from the initialized isochronous-control operating point and reused as the common start level for the related controller variants.

Included controller examples:

- `IsochronousControlWithSurgeTank`
- `AGCControlWithSurgeTank`
- `PermanentDroopControlWithSurgeTank`
- `TransientDroopControlWithSurgeTank`
- `FCRControlWithSurgeTank`

The current report assets are stored in `report_data/` and include source CSV results plus response plots for the validated isochronous and AGC cases:

- `report_data/IsochronousControlWithSurgeTank_res.csv`
- `report_data/AGCControlWithSurgeTank_res.csv`
- `report_data/isochronous_response.png`
- `report_data/agc_response.png`

Summary metrics from the solved cases are in `summary.json`. Key values are:

- Isochronous final surge height: `100.1636737585737 m`
- Isochronous peak surge height: `100.2180635906453 m`
- Isochronous minimum frequency: `48.97364597499688 Hz`
- AGC final surge height: `99.97243533885145 m`
- AGC peak surge height: `100.2103590366684 m`
- AGC minimum frequency: `48.90836717657671 Hz`

The remaining controller models are included as examples in this package and can be simulated from the same package path when extended validation outputs are needed.