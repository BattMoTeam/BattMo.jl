


# Compute Cell KPIs {#Compute-Cell-KPIs}

BattMo implements several utilities to compute cell metrics, derived both from the cell parameter set and from simulation outputs. These metrics cover most of the points required by battery checklists published by reputable journals, namely the [Cell Press checklist](https://doi.org/10.1016/j.joule.2020.12.026) and the [ACS Energy Letter&#39;s checklist](https://doi.org/10.1021/acsenergylett.1c00870).

### Load parameter set and run simulation {#Load-parameter-set-and-run-simulation}

```julia
using BattMo, GLMakie


cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol);

output = solve(sim)
```


```
✔️ Validation of ModelSettings passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of CellParameters passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of CyclingProtocol passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of SimulationSettings passed: No issues found.
──────────────────────────────────────────────────
Jutul: Simulating 2 hours, 12 minutes as 163 report steps
╭────────────────┬───────────┬───────────────┬──────────╮
│ Iteration type │  Avg/step │  Avg/ministep │    Total │
│                │ 146 steps │ 146 ministeps │ (wasted) │
├────────────────┼───────────┼───────────────┼──────────┤
│ Newton         │   2.32877 │       2.32877 │  340 (0) │
│ Linearization  │   3.32877 │       3.32877 │  486 (0) │
│ Linear solver  │   2.32877 │       2.32877 │  340 (0) │
│ Precond apply  │       0.0 │           0.0 │    0 (0) │
╰────────────────┴───────────┴───────────────┴──────────╯
╭───────────────┬──────────┬────────────┬──────────╮
│ Timing type   │     Each │   Relative │    Total │
│               │       μs │ Percentage │       ms │
├───────────────┼──────────┼────────────┼──────────┤
│ Properties    │  37.1194 │     3.99 % │  12.6206 │
│ Equations     │ 156.5117 │    24.02 % │  76.0647 │
│ Assembly      │  68.6627 │    10.54 % │  33.3701 │
│ Linear solve  │ 272.9742 │    29.31 % │  92.8112 │
│ Linear setup  │   0.0000 │     0.00 % │   0.0000 │
│ Precond apply │   0.0000 │     0.00 % │   0.0000 │
│ Update        │  52.9611 │     5.69 % │  18.0068 │
│ Convergence   │ 143.0985 │    21.97 % │  69.5459 │
│ Input/Output  │  22.2118 │     1.02 % │   3.2429 │
│ Other         │  32.2287 │     3.46 % │  10.9577 │
├───────────────┼──────────┼────────────┼──────────┤
│ Total         │ 931.2351 │   100.00 % │ 316.6199 │
╰───────────────┴──────────┴────────────┴──────────╯
```


### Cell KPIs from the parameter set {#Cell-KPIs-from-the-parameter-set}

Some KPIs are directly computable from the cell parameter set. Here below we list the main KPIs we can compute with BattMo. For illustration, we create a Dictionary storing the values of the computations.

```julia
cell_kpis_from_set = Dict(
	"Positive Electrode Coating Mass" => compute_electrode_coating_mass(cell_parameters, "PositiveElectrode"),
	"Negative Electrode Coating Mass" => compute_electrode_coating_mass(cell_parameters, "NegativeElectrode"),
	"Separator Mass" => compute_separator_mass(cell_parameters),
	"Positive Electrode Current Collector Mass" => compute_current_collector_mass(cell_parameters, "PositiveElectrode"),
	"Negative Electrode Current Collector Mass" => compute_current_collector_mass(cell_parameters, "NegativeElectrode"),
	"Electrolyte Mass" => compute_electrolyte_mass(cell_parameters),
	"Cell Mass" => compute_cell_mass(cell_parameters),
	"Cell Volume" => compute_cell_volume(cell_parameters),
	"Positive Electrode Mass Loading" => compute_electrode_mass_loading(cell_parameters, "PositiveElectrode"),
	"Negative Electrode Mass Loading" => compute_electrode_mass_loading(cell_parameters, "NegativeElectrode"),
	"Cell Theoretical Capacity" => compute_cell_theoretical_capacity(cell_parameters),
	"Cell N:P Ratio" => compute_np_ratio(cell_parameters),
)
```


```
Dict{String, Float64} with 12 entries:
  "Positive Electrode Coating Mass"           => 0.0255595
  "Negative Electrode Current Collector Mass" => 0.0107662
  "Cell Theoretical Capacity"                 => 5.0912
  "Cell Volume"                               => 9.00538e-5
  "Positive Electrode Current Collector Mass" => 0.00451983
  "Negative Electrode Mass Loading"           => 0.144414
  "Separator Mass"                            => 0.000617901
  "Negative Electrode Coating Mass"           => 0.0148313
  "Electrolyte Mass"                          => 0.00644079
  "Cell Mass"                                 => 0.0627356
  "Cell N:P Ratio"                            => 0.913058
  "Positive Electrode Mass Loading"           => 0.248875
```


The functions to compute the cell mass and cell volume also offer an option to print the breakdown of masses without returning the total mass. The breakdown can be useful to verify the parameters are sensible, and to calculate a Bill of Materials (BOM)

```julia
compute_cell_mass(cell_parameters; print_breakdown = true);
```


```
		Component                 | Mass/kg |  Percentage
-------------------------------------------------------------
Cell                                 | 0.06274 |    100
Positive Electrode                   | 0.02556 |    40.7
Negative Electrode                   | 0.01483 |    23.6
Positive Electrode Current Collector | 0.00452 |    7.2
Negative Electrode Current Collector | 0.01077 |    17.2
Electrolyte                          | 0.00644 |    10.3
Separator                            | 0.00062 |    1.0
```


### Cell KPIs from simulation output {#Cell-KPIs-from-simulation-output}

Once we run a simulation we can access additional cell KPIs such as energy density, specific energy, mean power output, etc.

```julia
cell_kpis_from_output = Dict(
	"Discharge capacity" => compute_discharge_capacity(output),
	"Discharge energy" => compute_discharge_energy(output),
	"Energy density" => compute_discharge_energy(output) / compute_cell_volume(cell_parameters),
	"Specific energy" => compute_discharge_energy(output) / compute_cell_mass(cell_parameters),
)
```


```
Dict{String, Float64} with 4 entries:
  "Discharge capacity" => 4.98095
  "Specific energy"    => 1.02341e6
  "Discharge energy"   => 64204.0
  "Energy density"     => 7.12952e8
```


## Example full cycle {#Example-full-cycle}

When we run a protocol with a full or multiple cycles we can retrieve some extra KPIs from the output. Let&#39;s run a CCCV protocol.

```julia
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")
```


```
{
    "Protocol" => "CCCV"
    "UpperVoltageLimit" => 4.0
    "InitialControl" => "charging"
    "DRate" => 1.0
    "TotalNumberOfCycles" => 3
    "CRate" => 1.0
    "InitialStateOfCharge" => 0
    "CurrentChangeLimit" => 0.0001
    "VoltageChangeLimit" => 0.0001
    "InitialTemperature" => 298.15
    "Metadata" =>     {
        "Description" => "Parameter set for a constant current constant voltage cyling protocol."
        "Title" => "CCCV"
    }
    "LowerVoltageLimit" => 3.0
}
```


This protocol will run 3 cycles

```julia
sim = Simulation(model_setup, cell_parameters, cycling_protocol)

output = solve(sim)
```


```
✔️ Validation of CellParameters passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of CyclingProtocol passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of SimulationSettings passed: No issues found.
──────────────────────────────────────────────────
Jutul: Simulating 15 hours as 1080 report steps
╭────────────────┬───────────┬───────────────┬────────────╮
│ Iteration type │  Avg/step │  Avg/ministep │      Total │
│                │ 790 steps │ 846 ministeps │   (wasted) │
├────────────────┼───────────┼───────────────┼────────────┤
│ Newton         │   2.89494 │       2.70331 │ 2287 (585) │
│ Linearization  │   3.96582 │       3.70331 │ 3133 (624) │
│ Linear solver  │   2.89494 │       2.70331 │ 2287 (585) │
│ Precond apply  │       0.0 │           0.0 │      0 (0) │
╰────────────────┴───────────┴───────────────┴────────────╯
╭───────────────┬────────┬────────────┬────────╮
│ Timing type   │   Each │   Relative │  Total │
│               │     ms │ Percentage │      s │
├───────────────┼────────┼────────────┼────────┤
│ Properties    │ 0.0406 │     1.85 % │ 0.0928 │
│ Equations     │ 0.2845 │    17.75 % │ 0.8914 │
│ Assembly      │ 0.1257 │     7.84 % │ 0.3938 │
│ Linear solve  │ 0.2025 │     9.22 % │ 0.4632 │
│ Linear setup  │ 0.0000 │     0.00 % │ 0.0000 │
│ Precond apply │ 0.0000 │     0.00 % │ 0.0000 │
│ Update        │ 0.3711 │    16.89 % │ 0.8486 │
│ Convergence   │ 0.2329 │    14.52 % │ 0.7296 │
│ Input/Output  │ 0.0553 │     0.93 % │ 0.0468 │
│ Other         │ 0.6808 │    31.00 % │ 1.5570 │
├───────────────┼────────┼────────────┼────────┤
│ Total         │ 2.1964 │   100.00 % │ 5.0231 │
╰───────────────┴────────┴────────────┴────────╯
```


As our data represents multiple cycles now, we can choose for which cycle we&#39;d like to compute the KPI.

```julia
cell_kpis_from_output_cycle_0 = Dict(
	"Discharge capacity" => compute_discharge_capacity(output; cycle_number = 0),
	"Discharge energy" => compute_discharge_energy(output; cycle_number = 0),
	"Energy density" => compute_discharge_energy(output; cycle_number = 0) / compute_cell_volume(cell_parameters),
	"Specific energy" => compute_discharge_energy(output; cycle_number = 0) / compute_cell_mass(cell_parameters),
	"Charge capacity" => compute_charge_capacity(output; cycle_number = 0),
	"Charge energy" => compute_charge_energy(output; cycle_number = 0),
	"Round trip efficiency" => compute_round_trip_efficiency(output; cycle_number = 0),
)
```


```
Dict{String, Float64} with 7 entries:
  "Discharge capacity"    => 3.67642
  "Specific energy"       => 7.23787e5
  "Charge capacity"       => -4.29316
  "Charge energy"         => 59682.3
  "Round trip efficiency" => 0.775772
  "Discharge energy"      => 45407.2
  "Energy density"        => 5.04223e8
```


Or from the second cycle:

```julia
cell_kpis_from_output_cycle_1 = Dict(
	"Discharge capacity" => compute_discharge_capacity(output; cycle_number = 1),
	"Discharge energy" => compute_discharge_energy(output; cycle_number = 1),
	"Energy density" => compute_discharge_energy(output; cycle_number = 1) / compute_cell_volume(cell_parameters),
	"Specific energy" => compute_discharge_energy(output; cycle_number = 1) / compute_cell_mass(cell_parameters),
	"Charge capacity" => compute_charge_capacity(output; cycle_number = 1),
	"Charge energy" => compute_charge_energy(output; cycle_number = 1),
	"Round trip efficiency" => compute_round_trip_efficiency(output; cycle_number = 1),
)
```


```
Dict{String, Float64} with 7 entries:
  "Discharge capacity"    => 3.67642
  "Specific energy"       => 7.23788e5
  "Charge capacity"       => -3.69006
  "Charge energy"         => 52142.5
  "Round trip efficiency" => 0.887947
  "Discharge energy"      => 45407.2
  "Energy density"        => 5.04224e8
```


## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/8_compute_cell_kpis.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/8_compute_cell_kpis.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._
