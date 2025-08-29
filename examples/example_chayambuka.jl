# # Sodium ion modeling

# This is an example for showing a sodium ion simulation based on [Chayambuka2022](https://www.sciencedirect.com/science/article/pii/S0013468621020478?via%3Dihub).
# There is hardly any difference between the sodium ion and lithium ion PXD basis model and equations. The only difference is that for the SodiumIonBattery model 
# you can chose a slightly adapted butler volmer equation from [Chayambuka2022](https://www.sciencedirect.com/science/article/pii/S0013468621020478?via%3Dihub). See documentation for more information.

using BattMo, GLMakie

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
include(joinpath(battmo_base, "src/input/defaults/cell_parameters/Chayambuka_functions.jl"))

######### Load Simulation Data #########

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings = load_model_settings(; from_default_set = "P2D")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

######### Alter model settings #########
model_settings["ButlerVolmer"] = "Chayambuka"

######### Alter simulation settings #########
simulation_settings["GridNegativeElectrodeCoating"] = 8
simulation_settings["GridPositiveElectrodeCoating"] = 50
simulation_settings["GridNegativeElectrodeParticle"] = 50
simulation_settings["GridPositiveElectrodeParticle"] = 50
simulation_settings["GridSeparator"] = 5

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

	output = solve(sim;)
	time_series = get_output_time_series(output)

	lines!(ax, time_series[:Capacity] .* 1000, time_series[:Voltage], label = "$rate C")

end

axislegend(position = :lb)
fig
