using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol);

output = solve(sim;)

time_series = get_output_time_series(output, ["Voltage", "Current"])


function get_output_state(output::NamedTuple, quantities::Vector{String})

	selected_pairs = []
	available_quantities = [
		"ConcentrationNegativeElectrodeActiveMaterial",
		"ConcentrationPositiveElectrodeActiveMaterial",
		"ConcentrationElectrolyte",
		"PotentialNegativeElectrodeActiveMaterial",
		"PotentialPositiveElectrodeActiveMaterial",
		"PotentialElectrolyte"]


	time = extract_output_times(output)

	push!(selected_pairs, :Time => time)



	return (; selected_pairs...)
end


time_series = get_output_state(output, ["Voltage", "Current"])

t = time_series[:Time]
I = time_series[:Current]
E = time_series[:Voltage]


f = Figure(size = (1000, 400))

ax = Axis(f[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

ax = Axis(f[1, 2], title = "Current", xlabel = "Time / s", ylabel = "Current / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

