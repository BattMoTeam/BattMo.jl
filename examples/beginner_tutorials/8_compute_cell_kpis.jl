# # Compute Cell KPIs

# BattMo implements several utilities to compute cell metrics, derived both from the cell parameter set and from simulation outputs.
# These metrics cover most of the points required by battery checklists published by reputable journals, namely the
# [Cell Press checklist](https://doi.org/10.1016/j.joule.2020.12.026) and the [ACS Energy Letter's checklist](https://doi.org/10.1021/acsenergylett.1c00870).

# ###  Load parameter set and run simulation

using BattMo, GLMakie


cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
nothing # hide

model = LithiumIonBattery()

sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim)
nothing # hide

# ### Cell KPIs from the parameter set
# Some KPIs are directly computable from the cell parameter set. Here below we list the main KPIs we can compute with BattMo.
# For illustration, we create a Dictionary storing the values of the computations.

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



# The functions to compute the cell mass and cell volume also offer an option to print the breakdown of masses without returning the total mass. The breakdown can be useful to 
# verify the parameters are sensible, and to calculate a Bill of Materials (BOM)
compute_cell_mass(cell_parameters; print_breakdown = true);

# ### Cell KPIs from simulation output
# Once we run a simulation we can access additional cell KPIs such as energy density, specific energy, mean power output, etc.

cell_kpis_from_output = Dict(
	"Discharge capacity" => compute_discharge_capacity(output),
	"Discharge energy" => compute_discharge_energy(output),
	"Energy density" => compute_discharge_energy(output) / compute_cell_volume(cell_parameters),
	"Specific energy" => compute_discharge_energy(output) / compute_cell_mass(cell_parameters),
)


# ## Example full cycle

# When we run a protocol with a full or multiple cycles we can retrieve some extra KPIs from the output. Let's run a cccv protocol.

cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")

# This protocol will run 3 cycles

sim = Simulation(model, cell_parameters, cycling_protocol)

output = solve(sim)
nothing # hide 

# As our data represents multiple cycles now, we can choose for which cycle we'd like to compute the KPI.

cell_kpis_from_output_cycle_0 = Dict(
	"Discharge capacity" => compute_discharge_capacity(output; cycle_number = 0),
	"Discharge energy" => compute_discharge_energy(output; cycle_number = 0),
	"Energy density" => compute_discharge_energy(output; cycle_number = 0) / compute_cell_volume(cell_parameters),
	"Specific energy" => compute_discharge_energy(output; cycle_number = 0) / compute_cell_mass(cell_parameters),
	"Charge capacity" => compute_charge_capacity(output; cycle_number = 0),
	"Charge energy" => compute_charge_energy(output; cycle_number = 0),
	"Round trip efficiency" => compute_round_trip_efficiency(output; cycle_number = 0),
)

# Or from the second cycle:

cell_kpis_from_output_cycle_1 = Dict(
	"Discharge capacity" => compute_discharge_capacity(output; cycle_number = 1),
	"Discharge energy" => compute_discharge_energy(output; cycle_number = 1),
	"Energy density" => compute_discharge_energy(output; cycle_number = 1) / compute_cell_volume(cell_parameters),
	"Specific energy" => compute_discharge_energy(output; cycle_number = 1) / compute_cell_mass(cell_parameters),
	"Charge capacity" => compute_charge_capacity(output; cycle_number = 1),
	"Charge energy" => compute_charge_energy(output; cycle_number = 1),
	"Round trip efficiency" => compute_round_trip_efficiency(output; cycle_number = 1),
)
