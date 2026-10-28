# BPX parameter sets

[BPX (Battery Parameter eXchange)](https://bpxstandard.com) is an open standard for exchanging the parameters of physics-based lithium-ion battery models. A BPX file is a JSON file that contains the parameters of a Doyle-Fuller-Newman (DFN) model, or of one of its reduced forms (SPMe, SPM), together with the operating conditions of the cell and, optionally, measured validation data.

BattMo can read BPX files into [`CellParameters`](@ref), a [`CyclingProtocol`](@ref) or a complete [`FullSimulationInput`](@ref), and write BattMo cell parameters to BPX files. This page describes how to use the BPX support, how the parameters are converted between the BPX and BattMo models, and which parts of the BPX standard are not, or only approximately, supported.

BattMo supports BPX version 1.1.1. Files in the older 0.x format are converted to the 1.x layout when they are read.

## Reading a BPX file

```julia
using BattMo

cell_parameters = load_cell_parameters(; from_bpx_file_path = "nmc_pouch_cell_BPX.json")
```

The converted parameters are an ordinary [`CellParameters`](@ref) instance, which you can inspect and modify, and use in a [`Simulation`](@ref).

The BPX operating conditions (voltage cut-offs, initial state-of-charge and temperatures) are not cell parameters in BattMo; they belong to the [`CyclingProtocol`](@ref) (see [Operating conditions](@ref bpx_protocol)). `load_cycling_protocol` reads them from the BPX file:

```julia
cycling_protocol = load_cycling_protocol(; from_bpx_file_path = "nmc_pouch_cell_BPX.json")

sim = Simulation(LithiumIonBattery(), cell_parameters, cycling_protocol)
output = solve(sim)
```

BPX does not define a cycling experiment, so this protocol is a constant current discharge with `DRate = 1`, which you can change. With the `experiment` option, the current of one of the experiments in the `Validation` section of the file is used instead, so that the simulation can be compared with the validation data (see [Validation experiments](@ref bpx_validation_experiments)).

`load_full_simulation_input` reads the cell parameters and the cycling protocol at once, and adds the default BattMo P2D model, simulation and solver settings. The findings of both conversions are reported together:

```julia
simulation_input = load_full_simulation_input(;
    from_bpx_file_path = "nmc_pouch_cell_BPX.json",
    bpx_options = (experiment = "1C discharge",),
)
output = run_simulation(simulation_input)
```

!!! note "C-rates"
    The current of a `DRate` or `CRate` protocol is relative to the theoretical capacity that BattMo computes from the cell parameters (`compute_cell_theoretical_capacity`), not to the BPX `"Nominal cell capacity [A.h]"`. For the NMC example cell, the theoretical capacity is 13.19 Ah while the nominal capacity is 12.5 Ah. For a given current, set the rate to the current divided by the theoretical capacity, or use the `experiment` option, which prescribes the current in ampere.

The [BPX example](@ref "Simulating a BPX parameter set and comparing with its validation data") simulates the validation experiments of the NMC example cell and compares them with the data.

### Options

The BPX import takes the following options. With [`load_cell_parameters`](@ref), [`load_cycling_protocol`](@ref) and [`load_full_simulation_input`](@ref) they are passed as a named tuple `bpx_options`; they are keyword arguments of the corresponding functions of the `BattMo.BPX` module (see [Functions](@ref bpx_functions)).

| Option | Default | Used by | Description |
|:--|:--|:--|:--|
| `validate` | `true` | all | Check the file against the BPX schema and for internal consistency. |
| `strict` | `false` | all | Raise an error, instead of a warning, when the file does not conform to the BPX schema. Inconsistent data (see [Validation](@ref bpx_validation)) only gives a warning, as in the Python BPX package. |
| `cell_case` | `nothing` | cell parameters, full input | The cell format (`Cell.Case`, e.g. `"Pouch"` or `"Cylindrical"`). BPX does not specify it, so by default it is inferred from the title and description of the file. |
| `experiment` | `nothing` | cycling protocol, full input | The name of an experiment in the `Validation` section (e.g. `"1C discharge"`) whose current is used for the cycling protocol. By default, a constant current discharge with `DRate = 1` is set up. |

```julia
cell_parameters = load_cell_parameters(;
    from_bpx_file_path = "nmc_pouch_cell_BPX.json",
    bpx_options = (strict = true, cell_case = "Pouch"),
)
```

## Writing a BPX file

```julia
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

write_bpx("chen_2020_BPX.json", cell_parameters; cycling_protocol)
```

[`write_bpx`](@ref) writes a BPX 1.1.1 file for the DFN model; `BattMo.BPX.convert_to_bpx` returns the same data as a dictionary. The voltage cut-offs, which BPX requires, and the initial state of the cell are taken from the cycling protocol. Without a cycling protocol they are left out and the file does not conform to the BPX standard. The exported file is validated like an imported one, and the same `validate` and `strict` options apply.

A parameter set that was read from BPX is written to an equivalent BPX parameter set: reading the written file gives the same BattMo parameters. For other parameter sets, see [Export](@ref bpx_export) for what can and cannot be represented in BPX.

## [The conversion report](@id bpx_report)

Every import and export collects its findings and reports them in two messages:

- **A warning** with the findings that change the simulation results or need your attention:

  | Category | Meaning |
  |:--|:--|
  | Violations of the BPX standard | The data does not conform to the BPX schema, or a function string uses operations that BPX does not allow. All violations are listed, with their location in the file. |
  | Inconsistencies within the BPX data | The data conforms to the schema but is not self-consistent (see [Validation](@ref bpx_validation)). |
  | BPX features that BattMo does not support | Parts of the parameter set that are ignored, e.g. OCP hysteresis or a degradation state. |
  | Differences between the BPX and BattMo models | The BattMo model differs from the BPX model, e.g. the thermal model, so that simulations do not reproduce BPX. |
  | Keys that are not part of the BPX standard | Ignored keys (reported as schema violations when the file is validated). |
  | Parameters that could not be determined | BattMo parameters for which the BPX data is missing. They are set to `0.0` and must be set before simulating; the validation of the simulation input flags the ones the selected model needs. |
  | Operating conditions that the BPX input does not give | Cycling protocol entries set to a default value, e.g. the constant current discharge with `DRate = 1`, or an initial state of charge that the file does not give. |

- **An info message** with the documented choices of the conversion: the [approximations](@ref bpx_approximations) made, parameters without a counterpart, the operating conditions with their [`CyclingProtocol`](@ref) entries (when reading cell parameters only), and notes (e.g. that a legacy file was converted, that the cell format was inferred, or which validation experiment the cycling protocol uses).

For example, reading the NMC pouch cell example of the BPX standard gives a warning that the voltage given by its OCPs at the stoichiometry limits (4.2018 V) exceeds its upper cut-off voltage (4.2 V), and that thermal simulations do not reproduce the BPX thermal model.

## [Validation](@id bpx_validation)

### The BPX schema

Files are validated against the JSON schema of the official [BPX Python package](https://github.com/FaradayInstitution/BPX) (version 1.1.1). The schema is not written by the BattMo developers: it is generated, unmodified, from that package (copyright (c) 2022 University of Oxford, MIT license) and bundled with BattMo in `src/input/bpx_schema/`, together with its license and a README that describes how it was generated and how to update it for a new BPX release.

The schema fixes the name of every parameter, and every name includes its unit (e.g. `"Particle radius [m]"`). A parameter given in another unit (e.g. `"Particle radius [um]"`) is therefore not a BPX parameter: it is reported as a violation and ignored, and its values are not converted.

For the declared model (`"DFN"`, `"SPMe"`, `"SPM"` or `"Partial"`), the schema checks that all required parameters are present, that no other parameters are given, and that every value has the right type: a number, a function string, or a table with `"x"` and `"y"` arrays.

### Function strings

BPX functions are strings in Python syntax with the independent variable `x` and the operations `*`, `/`, `-`, `+`, `**`, `exp` and `tanh`. BattMo checks that function strings only use these operations; other operations are reported as violations. For the checks below, function strings are evaluated by BattMo itself, which only evaluates these operations, so a BPX file cannot run code.

### Consistency checks

As the Python BPX package does, BattMo checks that

- the voltage window given by the OCPs at the stoichiometry limits lies within the voltage cut-offs, with a tolerance of 1 mV:
  ```math
  U_\mathrm{p}(\theta_\mathrm{p}^\mathrm{min}) - U_\mathrm{n}(\theta_\mathrm{n}^\mathrm{max}) \le V_\mathrm{max}, \qquad
  U_\mathrm{p}(\theta_\mathrm{p}^\mathrm{max}) - U_\mathrm{n}(\theta_\mathrm{n}^\mathrm{min}) \ge V_\mathrm{min},
  ```
  with the OCPs at the reference temperature;
- the initial state-of-charge lies between 0 and 1;
- the active material volume fraction ``b R / 3`` does not exceed the solid volume fraction ``1 - \varepsilon`` of an electrode (see below);
- the sign of the current of each validation experiment matches the BPX convention, in which a positive current charges the cell. For experiments that only charge or only discharge, the current must match the change of the voltage (a discharge lowers the voltage by more than 10 mV, a charge raises it) and, when the name of the experiment contains "discharge" or "charge", the type of experiment. Experiments that both charge and discharge are not checked.

These findings are warnings, also in strict mode.

### BPX versions

BPX 1.0 moved the initial conditions and the ambient temperature from the `"Parameterisation"` section to a new `"State"` section. Files in the 0.x format, recognized by their `Header.BPX` version, are converted to the 1.x layout before they are validated and converted, in the same way as the Python BPX package does (BattMo's conversion is adapted from it). The only difference is that the lumped thermal conductivity of 0.x files, which BPX 1.x no longer has, is kept in the `"User-defined"` section, because BattMo uses it.

A file that declares a BPX version newer than 1.1.1 is read with the 1.1.1 schema: parameters introduced in later versions are reported and ignored.

## Parameter conversion

### Cell

| BPX | BattMo | Conversion |
|:--|:--|:--|
| `Electrode area [m2]` ``A`` | `Cell.ElectrodeGeometricSurfaceArea` | unchanged (area of a single electrode layer) |
| `Number of electrode pairs connected in parallel to make a cell` ``N_\mathrm{p}`` | `Cell.NumberOfLayersInParallel` | unchanged, with `DoubleCoatedElectrodes = false`, so that the total electrode area used by the simulation is ``A N_\mathrm{p}`` (see [Approximations](@ref bpx_approximations)) |
| `Nominal cell capacity [A.h]` | `Cell.NominalCapacity` | unchanged |
| `External surface area [m2]` | `Cell.DeviceSurfaceArea` | unchanged (not used by the BattMo thermal model) |
| `Reference temperature [K]` | `Cell.ReferenceTemperature` | unchanged; 298.15 K when absent |
| `Density [kg.m-3]` | `Density` of every component | lumped density used for all components |
| `Specific heat capacity [J.K-1.kg-1]` | `SpecificHeatCapacity` of every component | unchanged |
| `Volume [m3]` | – | not used (see [Thermal model](@ref bpx_thermal)) |
| `Lower/Upper voltage cut-off [V]` | `CyclingProtocol` | reported, see [Operating conditions](@ref bpx_protocol) |

### Electrodes

For the negative (``k = \mathrm{n}``) and positive (``k = \mathrm{p}``) electrode:

| BPX | BattMo | Conversion |
|:--|:--|:--|
| `Thickness [m]` | `Coating.Thickness` | unchanged |
| `Porosity` ``\varepsilon`` | `Coating.EffectiveDensity` | ``\rho (1 - \varepsilon)``, so that the solid volume fraction is ``1 - \varepsilon`` |
| `Transport efficiency` ``\mathcal{B}`` | `Coating.BruggemanCoefficient` ``\beta`` | ``\beta = \ln \mathcal{B} / \ln \varepsilon``, from ``\mathcal{B} = \varepsilon^\beta`` |
| `Conductivity [S.m-1]` ``\sigma`` (effective) | `ElectronicConductivity` (intrinsic) of all solid components | ``\sigma / (1 - \varepsilon)^\beta`` |
| `Surface area per unit volume [m-1]` ``b`` | `ActiveMaterial.VolumetricSurfaceArea` | unchanged |
| `Particle radius [m]` ``R`` | `ActiveMaterial.ParticleRadius` | unchanged |
| ``b``, ``R``, ``\varepsilon`` | `ActiveMaterial.MassFraction`, `Binder.MassFraction` | ``\frac{b R / 3}{1 - \varepsilon}`` and the rest of the solid |
| `Maximum concentration [mol.m-3]` | `ActiveMaterial.MaximumConcentration` | unchanged |
| `Minimum/Maximum stoichiometry` | `StoichiometricCoefficientAtSOC0/SOC100` | negative electrode: minimum at SOC 0, maximum at SOC 100; positive electrode: maximum at SOC 0, minimum at SOC 100 |
| `OCP [V]`, `Entropic change coefficient [V.K-1]`, `Diffusivity [m2.s-1]` | `OpenCircuitPotential`, `EntropyChange`, `DiffusionCoefficient` | function strings: `x` → `(c / cmax)`, `**` → `^`; numbers and tables unchanged |
| `Reaction rate constant [mol.m-2.s-1]` ``K`` | `ActiveMaterial.ReactionRateConstant` ``k_0`` | ``k_0 = K / (c^\mathrm{max} \sqrt{c_\mathrm{e0}})`` |
| `Diffusivity activation energy [J.mol-1]` | `ActivationEnergyOfDiffusion` | unchanged |
| `Reaction rate constant activation energy [J.mol-1]` | `ActivationEnergyOfReaction` | unchanged |
| – | `NumberOfElectronsTransfered`, `ChargeTransferCoefficient` | 1 and 0.5: BPX assumes a single-electron reaction with symmetric Butler-Volmer kinetics |

**Exchange current density.** BPX writes the exchange current density as
```math
j_0 = F K \sqrt{\frac{c_\mathrm{e}}{c_\mathrm{e0}} \, \theta (1 - \theta)}, \qquad \theta = \frac{c}{c^\mathrm{max}},
```
with ``c_\mathrm{e0}`` the initial electrolyte concentration, while BattMo uses
```math
j_0 = n F k_0 \sqrt{c_\mathrm{e} \, c \, (c^\mathrm{max} - c)}.
```
Both are equal for ``k_0 = K / (c^\mathrm{max} \sqrt{c_\mathrm{e0}})`` and ``n = 1``.

**Active material volume fraction.** BPX defines the active material volume fraction of an electrode as ``\Phi = b R / 3`` (spherical particles), which sets the capacity of the electrode. It is in general smaller than the solid volume fraction ``1 - \varepsilon``. BattMo computes the active material volume fraction from the mass fractions and densities of the coating components, so the active material mass fraction is set to ``\Phi / (1 - \varepsilon)`` (all components have the same density) and the rest of the solid is assigned to the binder.

**Effective conductivity.** BPX gives the effective conductivity of the porous electrode, while BattMo computes it as ``(1 - \varepsilon)^\beta`` times the volume-weighted intrinsic conductivity of the solid components. All solid components get the same intrinsic conductivity, so the effective conductivity is reproduced exactly.

### Separator

| BPX | BattMo | Conversion |
|:--|:--|:--|
| `Thickness [m]` | `Separator.Thickness` | unchanged |
| `Porosity` | `Separator.Porosity` | unchanged |
| `Transport efficiency` | `Separator.BruggemanCoefficient` | ``\ln \mathcal{B} / \ln \varepsilon`` |

### Electrolyte

| BPX | BattMo | Conversion |
|:--|:--|:--|
| `Initial electrolyte concentration [mol.m-3]` (in `State`) | `Electrolyte.Concentration` | unchanged |
| `Cation transference number` | `Electrolyte.TransferenceNumber` | unchanged |
| `Conductivity [S.m-1]`, `Diffusivity [m2.s-1]` | `IonicConductivity`, `DiffusionCoefficient` | function strings: `x` → `c`, `**` → `^`; activation energies folded in (see below) |
| `Conductivity/Diffusivity activation energy [J.mol-1]` | – | folded into the functions |
| – | `ChargeNumber` | 1 (BPX assumes a monovalent electrolyte) |

BattMo has no activation energies for the electrolyte, but evaluates the electrolyte functions of concentration and temperature. The BPX Arrhenius relation is therefore written into the function strings:
```math
\sigma_\mathrm{e}(c, T) = \sigma_\mathrm{e,ref}(c) \exp\left(\frac{E_{\sigma_\mathrm{e}}}{R}\left(\frac{1}{T_\mathrm{ref}} - \frac{1}{T}\right)\right),
```
which is exact. Tabulated electrolyte data cannot carry this factor; an activation energy given with a table is reported and ignored.

### Temperature dependence

The BPX reference temperature sets `Cell.ReferenceTemperature`, which BattMo uses as the reference temperature of the Arrhenius relations of the electrode diffusivity and reaction rate constant and of the entropic correction of the OCP,
```math
U(\theta, T) = U_\mathrm{ref}(\theta) + (T - T_\mathrm{ref}) \frac{\mathrm{d}U}{\mathrm{d}T}(\theta),
```
as in BPX. See [Temperature dependence](@ref) for the BattMo model.

### Tabulated data

BPX tables (`{"x": [...], "y": [...]}`) are passed to BattMo unchanged: BattMo evaluates tabulated electrode functions at the stoichiometry ``c / c^\mathrm{max}`` and tabulated electrolyte functions at the concentration, which are the BPX variables `x`.

### [Operating conditions](@id bpx_protocol)

| BPX | `CyclingProtocol` |
|:--|:--|
| `Cell` → `Lower voltage cut-off [V]` | `LowerVoltageLimit` |
| `Cell` → `Upper voltage cut-off [V]` | `UpperVoltageLimit` |
| `State` → `Initial conditions` → `Initial state-of-charge` | `InitialStateOfCharge` |
| `State` → `Initial conditions` → `Initial temperature [K]` | `InitialTemperature` |
| `State` → `Thermal environment` → `Ambient temperature [K]` | `AmbientTemperature` |

`load_cycling_protocol` and `load_full_simulation_input` set these entries. Values that the file does not give are set to a default and reported: the initial state of charge to 1 for a protocol that starts with a discharge and 0 for one that starts with a charge, the initial temperature to the temperature at the start of the validation experiment or to 298.15 K, and the ambient temperature to the initial temperature. When only the cell parameters are read, the values are listed in the conversion report.

BPX does not define a cycling experiment. Without the `experiment` option, the protocol is a constant current discharge (`"Protocol" = "CC"`) with `DRate = 1`.

### [Validation experiments](@id bpx_validation_experiments)

The `Validation` section of a BPX file contains experiments with the time, current, voltage and, optionally, temperature. With `experiment`, the current of that experiment is prescribed with the `InputCurrentSeries` protocol:

| BPX experiment | `CyclingProtocol` |
|:--|:--|
| `Time [s]` | `Times`, shifted to start at 0 s; the simulation uses these times as time steps |
| `Current [A]` | `Currents`, with the opposite sign: BPX uses a positive current for charging, BattMo for discharging |
| `Temperature [K]` | `InitialTemperature`, only when `State` does not give it |

The voltage cut-offs of the file still apply. The voltage and temperature data are not used by the conversion; the [BPX example](@ref "Simulating a BPX parameter set and comparing with its validation data") shows how to compare a simulation with them.

## [Approximations](@id bpx_approximations)

The following choices do not change the simulated electrochemistry. The component densities and the inactive solid are reported in the info message of every import.

- **Component densities.** BPX gives one lumped density for the whole cell. It is used as the density of all components (active material, inactive solid, electrolyte and separator), so cell masses and gravimetric quantities, such as the specific energy, are approximate.
- **Inactive solid.** BPX does not describe the binder and conductive additive. The solid that is not active material is lumped into the binder and the conductive additive has zero mass.
- **Electrode pairs.** BPX describes the cell as ``N_\mathrm{p}`` electrode pairs of area ``A``, each with one negative coating, a separator and one positive coating, so that the current density is ``I / (A N_\mathrm{p})``. They are imported as ``N_\mathrm{p}`` single coated layers (`DoubleCoatedElectrodes = false`), which gives the same total electrode area ``A N_\mathrm{p}`` and the same coating, separator and electrolyte volumes. BPX does not say whether the real cell uses double coated electrodes, so the number of current collectors implied by the layer layout may differ from the real cell; current collectors are not part of BPX.

## Differences between the BPX and BattMo models

### [Thermal model](@id bpx_thermal)

BPX uses a lumped thermal model for the whole cell,
```math
\rho c_\mathrm{p} \frac{\mathrm{d}T}{\mathrm{d}t} = \frac{A N_\mathrm{p}}{\mathcal{V}} \int_0^L \dot{Q} \, \mathrm{d}x - h_\mathrm{ext} \frac{\mathcal{A}}{\mathcal{V}} (T - T_\mathrm{amb}),
```
where ``\mathcal{V}`` is the volume of the whole cell (including current collectors, tabs and casing), ``\mathcal{A}`` its external surface area and ``h_\mathrm{ext}`` the heat transfer coefficient.

The BattMo thermal model resolves the temperature in the simulated domain, which for a BPX cell is the electrode stack of volume ``A N_\mathrm{p} (L_\mathrm{n} + L_\mathrm{s} + L_\mathrm{p})``, and cools it through the faces of the simulation grid with `Cell.SurfaceHeatTransferCoefficient`. Hence:

- the heat capacity is computed for the stack volume instead of the cell volume ``\mathcal{V}`` (for the NMC example cell, 57 % of ``\mathcal{V}``);
- the cell volume, the external surface area and the heat transfer coefficient of BPX are not used;
- BPX 1.x has no thermal conductivity, so the BattMo `ThermalConductivity` parameters are undetermined (for 0.x files, the lumped thermal conductivity is used).

Thermal simulations therefore do not reproduce BPX. Isothermal simulations are unaffected. The import reports this difference whenever the file contains thermal parameters.

### Reduced models

BPX files for the SPMe or SPM model are converted as they are, but BattMo simulates the full P2D (DFN) model with them, so the results differ from an SPMe or SPM simulation. An SPM parameter set has no electrolyte and transport parameters; the corresponding BattMo parameters are reported as undetermined.

## Unsupported BPX features

| Feature | Behaviour |
|:--|:--|
| Blended electrodes (`"Particle"` node with several particle types) | Error: BattMo models a single active material per electrode. |
| OCP hysteresis (`OCP (lithiation) [V]`, `OCP (delithiation) [V]`, `OCP hysteresis decay constant`, initial hysteresis states) | Reported and ignored; the equilibrium `OCP [V]` is used. |
| Degradation state (`LAM`, `LLI`) | A non-zero degradation state is reported and ignored; the parameters of the unaged reference cell are used. |
| `Validation` data | The current of an experiment can be used for the cycling protocol (`experiment` option); the voltage and temperature data are not used. |
| `User-defined` parameters | Reported and not interpreted, except the lumped thermal conductivity of converted 0.x files. |

## [Export](@id bpx_export)

The export applies the inverse of the conversions above. In addition:

- ``A`` is `Cell.ElectrodeGeometricSurfaceArea` and ``N_\mathrm{p}`` is the number of facing electrode pairs (`compute_number_of_electrode_pairs`): `NumberOfLayersInParallel` for single coated electrodes, and ``2 N_\mathrm{layers} - 1`` for double coated electrodes, plus one if the stack is closed off with a negative electrode. The coating layout itself is not exported.
- The lumped density and specific heat capacity are computed from the coatings, electrolyte and separator, and the volume ``A N_\mathrm{p} L`` from the stack thickness ``L``; current collectors and casing are not included.
- Electrode functions of `c` and `cmax` are rewritten as functions of the stoichiometry `x`; electrolyte functions with an Arrhenius factor written by the import are split again into a function and an activation energy.

The following cannot be represented in BPX and is reported:

- functions given as Julia functions (`FunctionName`) and functions that depend on temperature (BPX functions depend on a single variable; temperature dependence is given by activation energies and the entropic change coefficient);
- a non-constant reaction rate constant;
- parameters without a BPX counterpart, such as current collectors, the SEI layer and the cell geometry;
- an active material volume fraction that differs from ``b R / 3``: the BPX model then has a different electrode capacity than the BattMo model;
- reactions with more than one electron or an asymmetric charge transfer coefficient, and electrolytes that are not monovalent.

## Possible improvements

The following parts of the BPX standard are not supported, or could be supported better:

- **Thermal model.** The lumped BPX thermal model could be reproduced in a 1D simulation by scaling the component densities by ``\mathcal{V} / (A N_\mathrm{p} L)`` and setting `SurfaceHeatTransferCoefficient` to ``h_\mathrm{ext} \mathcal{A}`` divided by the cooled area of the simulation grid.
- **Validation data.** The voltage curves of the `Validation` section could be used directly for calibration, and the experiments could be split into constant current and rest steps instead of a sampled current series.
- **Degradation state.** LAM and LLI could be supported by scaling the surface area per unit volume and recomputing the stoichiometry limits from the voltage cut-offs (BPX equations 16–17).
- **Blended electrodes and OCP hysteresis** require extensions of the BattMo models.
- **Updating to new BPX versions** requires regenerating the bundled schema (see `src/input/bpx_schema/README.md`) and, when new parameters are introduced, extending the conversion.

## [Functions](@id bpx_functions)

```@docs
write_bpx
BattMo.BPX.load_from_bpx_file
BattMo.BPX.parse_bpx_to_cell_parameters
BattMo.BPX.load_cycling_protocol_from_bpx_file
BattMo.BPX.parse_bpx_to_cycling_protocol
BattMo.BPX.load_full_simulation_input_from_bpx_file
BattMo.BPX.parse_bpx_to_full_simulation_input
BattMo.BPX.convert_to_bpx
```
