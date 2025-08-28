# # Sodium ion modeling

# This is an example for showing a sodium ion simulation based on [Chayambuka](https://www.sciencedirect.com/science/article/pii/S0013468621020478?via%3Dihub).
# There is no difference between the sodium ion and lithium ion PXD model.

using BattMo, GLMakie, CSV, DataFrames

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
include(joinpath(battmo_base, "src/input/defaults/cell_parameters/Chayambuka_functions.jl"))

######### Load Simulation Data #########

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings = load_model_settings(; from_default_set = "P2D")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

######### Alter simulation settings #########
simulation_settings["GridResolution"]["NegativeElectrodeCoating"] = 8
simulation_settings["GridResolution"]["PositiveElectrodeCoating"] = 50
simulation_settings["GridResolution"]["NegativeElectrodeActiveMaterial"] = 50
simulation_settings["GridResolution"]["PositiveElectrodeActiveMaterial"] = 50
simulation_settings["GridResolution"]["Separator"] = 5

######### Alter cycling protocol #########
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["LowerVoltageLimit"] = 2.0
cycling_protocol["UpperVoltageLimit"] = 4.2

######### Run simulation ##########

model = SodiumIonBattery(; model_settings);

drates = [0.1, 0.5, 1.2, 1.4]
delta_t = [200, 50, 50, 50]

fig = Figure()
ax = Axis(fig[1, 1], title = "Voltage", xlabel = "Capacity / mAh", ylabel = "Voltage / V")
outputs_crate = []
for (i, rate) in enumerate(drates)

	cycling_protocol["DRate"] = rate
	simulation_settings["TimeStepDuration"] = delta_t[i]

	sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

	output = solve(sim; info_level = 0)
	time_series = get_output_time_series(output)
	metrics = get_output_metrics(output)

	lines!(ax, metrics[:Capacity] .* 1000, time_series[:Voltage], label = "$rate C")

end

axislegend(position = :lb)
fig
