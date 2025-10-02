using BattMo
using Statistics
using Printf
using GLMakie
using Jutul
using LinearAlgebra

# Grid points to test
x_res_list = [5, 10, 20, 40, 80]  # spatial resolution in electrode x-direction

# Store voltage outputs
voltage_profiles = Dict{Int, Vector{Float64}}()
time_profiles = Dict{Int, Vector{Float64}}()
rel_errors = Dict{Int, Float64}()

# Load base inputs
cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
base_simulation_settings = load_simulation_settings(; from_default_set = "P2D")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

for (i, x_res) in enumerate(x_res_list)
	println("🔧 Running simulation with x resolution = $x_res")

	# Deep copy the cell parameters so each run is isolated
	simulation_settings = deepcopy(base_simulation_settings)

	# Modify grid resolution
	simulation_settings["NegativeElectrodeCoatingGridPoints"] = x_res
	simulation_settings["PositiveElectrodeCoatingGridPoints"] = x_res
	simulation_settings["SeparatorGridPoints"] = Int(x_res ÷ 2)

	# Load model settings
	model_settings = load_model_settings(; from_default_set = "P2D")
	model_settings["ReactionRateConstant"] = "UserDefined"
	model = LithiumIonBattery(; model_settings)

	# Run simulation
	sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
	output = solve(sim; accept_invalid = true)

	# Extract time and voltage
	time_series = get_output_time_series(output)
	time = time_series[:Time]
	voltage = time_series[:Voltage]

	voltage_profiles[x_res] = voltage
	time_profiles[x_res] = time

	# Compute relative voltage error compared to previous run
	if i > 1
		prev_x = x_res_list[i-1]
		prev_voltage = voltage_profiles[prev_x]
		# Interpolate previous voltage to current time points
		interp = get_1d_interpolator(time_profiles[prev_x], prev_voltage)
		interp_prev_voltage = interp.(time)
		rel_error = norm(voltage .- interp_prev_voltage) / norm(interp_prev_voltage)
		rel_errors[x_res] = rel_error
		@printf("   Relative voltage error vs N=%d: %.3e\n", prev_x, rel_error)
	end
end

# --- Plotting ---

# Voltage vs time plot

fig = Figure()
ax = Axis(fig[1, 1], title = "Voltage convergence", xlabel = "Time / s", ylabel = "Voltage / V")
for x_res in x_res_list
	lines!(time_profiles[x_res], voltage_profiles[x_res], label = "N = $x_res")
end


# Relative error plot
fig2 = Figure()
ax2 = Axis(fig2[1, 1], title = "Convergence of Voltage Profile", xlabel = "Grid rsolution / N", ylabel = "Relative voltage error")
x_vals = collect(keys(rel_errors))
y_vals = [rel_errors[x] for x in x_vals]
lines!(ax2, x_vals, y_vals)
scatter!(ax2, x_vals, y_vals, color = :red)