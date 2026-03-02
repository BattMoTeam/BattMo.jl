# Bolay Composition Calibration

Run:

```bash
julia --project=. examples/Experimental/bolay_calibrtation/bolay_calibration.jl
```

What it does:

- Loads `examples/Experimental/jsoninputs/bolay_cell_parameters.json`
- Uses `examples/Experimental/resources/bolay_discharge_data.csv` as the target
- Calibrates:
  - Active material / binder / conductive additive mass fractions
  - Active material / binder / conductive additive densities
  - Coating effective density
  for both electrodes
- Writes calibrated parameters to:
  - `examples/Experimental/bolay_calibrtation/bolay_cell_parameters_calibrated.json`

Notes:

- The target data is capacity-voltage, while `VoltageCalibration` uses time-voltage.
  The script converts capacity to time assuming constant discharge current at `0.3 A`.
- Mass fractions are calibrated independently; the optimizer does not enforce that
  the three fractions sum to exactly `1.0`.
