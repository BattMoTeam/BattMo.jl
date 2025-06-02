


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


```ansi
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
│[1m Iteration type [0m│[1m  Avg/step [0m│[1m  Avg/ministep [0m│[1m    Total [0m│
│[1m                [0m│[90m 146 steps [0m│[90m 146 ministeps [0m│[90m (wasted) [0m│
├────────────────┼───────────┼───────────────┼──────────┤
│[1m Newton         [0m│   2.32877 │       2.32877 │  340 (0) │
│[1m Linearization  [0m│   3.32877 │       3.32877 │  486 (0) │
│[1m Linear solver  [0m│   2.32877 │       2.32877 │  340 (0) │
│[1m Precond apply  [0m│       0.0 │           0.0 │    0 (0) │
╰────────────────┴───────────┴───────────────┴──────────╯
╭───────────────┬──────────┬────────────┬──────────╮
│[1m Timing type   [0m│[1m     Each [0m│[1m   Relative [0m│[1m    Total [0m│
│[1m               [0m│[90m       μs [0m│[90m Percentage [0m│[90m       ms [0m│
├───────────────┼──────────┼────────────┼──────────┤
│[1m Properties    [0m│  34.7643 │     4.33 % │  11.8199 │
│[1m Equations     [0m│ 149.7960 │    26.65 % │  72.8009 │
│[1m Assembly      [0m│  62.3949 │    11.10 % │  30.3239 │
│[1m Linear solve  [0m│ 291.5813 │    36.29 % │  99.1376 │
│[1m Linear setup  [0m│   0.0000 │     0.00 % │   0.0000 │
│[1m Precond apply [0m│   0.0000 │     0.00 % │   0.0000 │
│[1m Update        [0m│  46.6683 │     5.81 % │  15.8672 │
│[1m Convergence   [0m│  61.7459 │    10.98 % │  30.0085 │
│[1m Input/Output  [0m│  21.2410 │     1.14 % │   3.1012 │
│[1m Other         [0m│  29.8622 │     3.72 % │  10.1531 │
├───────────────┼──────────┼────────────┼──────────┤
│[1m Total         [0m│ 803.5658 │   100.00 % │ 273.2124 │
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


```ansi
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


```ansi
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


```ansi
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


```ansi
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


```ansi
✔️ Validation of CellParameters passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of CyclingProtocol passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of SimulationSettings passed: No issues found.
──────────────────────────────────────────────────
Jutul: Simulating 15 hours as 1080 report steps
╭────────────────┬───────────┬───────────────┬────────────╮
│[1m Iteration type [0m│[1m  Avg/step [0m│[1m  Avg/ministep [0m│[1m      Total [0m│
│[1m                [0m│[90m 790 steps [0m│[90m 846 ministeps [0m│[90m   (wasted) [0m│
├────────────────┼───────────┼───────────────┼────────────┤
│[1m Newton         [0m│   2.89494 │       2.70331 │ 2287 (585) │
│[1m Linearization  [0m│   3.96582 │       3.70331 │ 3133 (624) │
│[1m Linear solver  [0m│   2.89494 │       2.70331 │ 2287 (585) │
│[1m Precond apply  [0m│       0.0 │           0.0 │      0 (0) │
╰────────────────┴───────────┴───────────────┴────────────╯
╭───────────────┬────────┬────────────┬────────╮
│[1m Timing type   [0m│[1m   Each [0m│[1m   Relative [0m│[1m  Total [0m│
│[1m               [0m│[90m     ms [0m│[90m Percentage [0m│[90m      s [0m│
├───────────────┼────────┼────────────┼────────┤
│[1m Properties    [0m│ 0.0391 │     1.98 % │ 0.0894 │
│[1m Equations     [0m│ 0.1829 │    12.69 % │ 0.5732 │
│[1m Assembly      [0m│ 0.1192 │     8.27 % │ 0.3733 │
│[1m Linear solve  [0m│ 0.4731 │    23.96 % │ 1.0821 │
│[1m Linear setup  [0m│ 0.0000 │     0.00 % │ 0.0000 │
│[1m Precond apply [0m│ 0.0000 │     0.00 % │ 0.0000 │
│[1m Update        [0m│ 0.0612 │     3.10 % │ 0.1399 │
│[1m Convergence   [0m│ 0.1880 │    13.04 % │ 0.5891 │
│[1m Input/Output  [0m│ 0.0520 │     0.97 % │ 0.0440 │
│[1m Other         [0m│ 0.7107 │    35.99 % │ 1.6254 │
├───────────────┼────────┼────────────┼────────┤
│[1m Total         [0m│ 1.9748 │   100.00 % │ 4.5163 │
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


```ansi
Dict{String, Float64} with 7 entries:
  "Discharge capacity"    => 3.67642
  "Specific energy"       => 7.23787e5
  "Charge capacity"       => -4.29316
  "Charge energy"         => 59682.3
  "Round trip efficiency" => 77.5772
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


```ansi
Dict{String, Float64} with 7 entries:
  "Discharge capacity"    => 3.67642
  "Specific energy"       => 7.23788e5
  "Charge capacity"       => -3.69006
  "Charge energy"         => 52142.5
  "Round trip efficiency" => 88.7947
  "Discharge energy"      => 45407.2
  "Energy density"        => 5.04224e8
```


## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/8_compute_cell_kpis.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/8_compute_cell_kpis.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._
