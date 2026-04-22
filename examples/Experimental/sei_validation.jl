using BattMo
using GLMakie
using Statistics
using DelimitedFiles

function deduplicate_monotonic_xy(x, y)
	if isempty(x)
		return (Float64[], Float64[])
	end

	xd = Float64[]
	yd = Float64[]
	for i in eachindex(x)
		xi = Float64(x[i])
		yi = Float64(y[i])
		if !isempty(xd) && isapprox(xi, xd[end]; atol = 0.0, rtol = 0.0)
			yd[end] = yi
		else
			push!(xd, xi)
			push!(yd, yi)
		end
	end
	return (xd, yd)
end

function interpolate_linear(x_src, y_src, x_query)
	y_query = fill(NaN, length(x_query))
	if length(x_src) < 2
		return y_query
	end

	for (i, xq) in pairs(x_query)
		if xq < x_src[1] || xq > x_src[end]
			continue
		end
		k = searchsortedlast(x_src, xq)
		if k == length(x_src)
			y_query[i] = y_src[end]
		elseif xq == x_src[k]
			y_query[i] = y_src[k]
		else
			x0, x1 = x_src[k], x_src[k+1]
			y0, y1 = y_src[k], y_src[k+1]
			y_query[i] = y0 + (y1 - y0) * (xq - x0) / (x1 - x0)
		end
	end
	return y_query
end

function run_sei_simulation(model, cell_parameters, cycling_protocol, experiment_steps)
	protocol = deepcopy(cycling_protocol)
	protocol["Experiment"] = experiment_steps
	protocol["InitialTemperature"] = 298.15
	protocol["InitialStateOfCharge"] = 0.99

	simulation_settings = load_simulation_settings(; from_default_set = "p4d")
	simulation_settings["TimeStepDuration"] = 5
	# simulation_settings["NegativeElectrodeCoatingGridPoints"] = 30
	# simulation_settings["NegativeElectrodeParticleGridPoints"] = 30

	sim = Simulation(model, cell_parameters, protocol; simulation_settings = simulation_settings)
	output = solve(sim; accept_invalid = true, info_level = 0, error_on_incomplete = false)

	plot_dashboard(output)

	time = output.time_series["Time"]
	cycle_count = output.time_series["CycleCount"]
	sei_thickness = output.states["SEIThickness"]
	ne_resolution = output.simulation.settings["NegativeElectrodeCoatingGridPoints"]
	mean_sei_thickness_t = vec(mean(sei_thickness[:, 1:ne_resolution], dims = 2))

	return (; output, time, cycle_count, mean_sei_thickness_t)
end

# ### Load model with Arrhenius temperature dependence
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
fn = joinpath(battmo_base, "examples/Experimental/jsoninputs/bolay_cell_parameters.json")
cell_parameters = load_cell_parameters(; from_file_path = fn)
cycling_protocol = load_cycling_protocol(; from_default_set = "experiment")
model_settings = load_model_settings(; from_default_set = "p4d_")

model_settings["SEIModel"] = "Bolay"

model = LithiumIonBattery(; model_settings)

# Average of Bolay fit t_plus(c) = 0.4 + 0.2*(c/1000) - 0.125*(c/1000)^2
# over c in [1000, 2000] mol/m^3 to provide a scalar value accepted by validation.
cell_parameters["Electrolyte"]["TransferenceNumber"] = 0.4083333333333333

baseline_experiment = [
	"Discharge at 1.0 A for 35 min",
	"Charge at 1.5 A until 4.1 V",
	"Rest for 10 s",
	"Hold at 4.1 V for 65 min",
	"Increase cycle count",
	"Repeat 50 times",
]

high_rate_experiment = [
	"Discharge at 2.0 A for 35 min",
	"Charge at 3.0 A until 4.1 V",
	"Hold at 4.1 V for 65 min",
	"Increase cycle count",
	"Repeat 50 times",
]

baseline = run_sei_simulation(model, cell_parameters, cycling_protocol, baseline_experiment)
high_rate = run_sei_simulation(model, cell_parameters, cycling_protocol, high_rate_experiment)

output = baseline.output
time = baseline.time
voltage = output.time_series["Voltage"]
cycle_count = baseline.cycle_count
sim_time_h = maximum(time) > 100.0 ? time ./ 3600.0 : time
mean_sei_thickness_t = baseline.mean_sei_thickness_t

capacity_metrics = output.metrics["DischargeCapacity"]
cycle_index_metrics = get(output.metrics, "CycleIndex", collect(1:length(capacity_metrics)))
if length(cycle_index_metrics) != length(capacity_metrics)
	cycle_index_metrics = collect(1:length(capacity_metrics))
end

exp_capacity_file = joinpath(battmo_base, "examples/Experimental/resources/bolay_capacity_cycling_data.csv")
exp_capacity_data = readdlm(exp_capacity_file, ',', Float64)
exp_cycle_k = exp_capacity_data[:, 1]
exp_capacity = exp_capacity_data[:, 2]

exp_sei_low_rate_file = joinpath(battmo_base, "examples/Experimental/resources/bolay_sei_thickness_low_rate.csv")
exp_sei_high_rate_file = joinpath(battmo_base, "examples/Experimental/resources/bolay_sei_thickness_high_rate.csv")
exp_sei_low_rate_data = readdlm(exp_sei_low_rate_file, ',', Float64)
exp_sei_high_rate_data = readdlm(exp_sei_high_rate_file, ',', Float64)
exp_cycle_low = exp_sei_low_rate_data[:, 1]
exp_sei_low_nm = exp_sei_low_rate_data[:, 2]
exp_cycle_high = exp_sei_high_rate_data[:, 1]
exp_sei_high_nm = exp_sei_high_rate_data[:, 2]

# Plot first three simulated cycles (or fewer if fewer exist)
unique_cycles = unique(cycle_count)
first_three_cycles = unique_cycles[1:min(3, length(unique_cycles))]

f = Figure(size = (1700, 500))

ax1 = GLMakie.Axis(
	f[1, 1],
	title = "Voltage vs Time (First Three Cycles)",
	xlabel = "Time / h",
	ylabel = "Voltage / V",
	xlabelsize = 18,
	ylabelsize = 18,
	xticklabelsize = 14,
	yticklabelsize = 14,
)

for cyc in first_three_cycles
	mask = cycle_count .== cyc
	lines!(
		ax1,
		sim_time_h[mask],
		voltage[mask];
		linewidth = 2.5,
		label = "Cycle $(Int(cyc))",
	)
end

axislegend(ax1, position = :lb)

# Capacity-vs-cycle comparison against Bolay data
# ax2 = GLMakie.Axis(
# 	f[1, 2],
# 	title = "Capacity Fade vs Cycle Count",
# 	xlabel = "Cycle count × 10^3",
# 	ylabel = "Discharge capacity / Ah",
# 	xlabelsize = 18,
# 	ylabelsize = 18,
# 	xticklabelsize = 14,
# 	yticklabelsize = 14,
# )

# sim_cycle_k = cycle_index_metrics ./ 1e3

# scatterlines!(
# 	ax2,
# 	sim_cycle_k,
# 	capacity_metrics;
# 	marker = :cross,
# 	markersize = 8,
# 	linewidth = 2.5,
# 	color = :black,
# 	label = "Simulation",
# )

# scatterlines!(
# 	ax2,
# 	exp_cycle_k,
# 	exp_capacity;
# 	marker = :circle,
# 	markersize = 7,
# 	linewidth = 2.0,
# 	color = :tomato,
# 	label = "Digitized experiment",
# )

# Mean SEI thickness vs cycle number
ax3 = GLMakie.Axis(
	f[1, 2],
	title = "Mean SEI Thickness vs Cycle (vs Bolay data)",
	xlabel = "Cycle number",
	ylabel = "Mean SEI thickness / nm",
	xlabelsize = 18,
	ylabelsize = 18,
	xticklabelsize = 14,
	yticklabelsize = 14,
)

scatterlines!(
	ax3,
	baseline.cycle_count,
	mean_sei_thickness_t .* 1e9;
	marker = :circle,
	markersize = 7,
	linewidth = 2.5,
	color = :dodgerblue,
	label = "BattMo: 1.0 A discharge / 1.5 A charge",
)

scatter!(
	ax3,
	exp_cycle_low,
	exp_sei_low_nm;
	marker = :cross,
	markersize = 8,
	color = :navy,
	label = "Bolay: 1.0 A discharge / 1.5 A charge",
)

scatterlines!(
	ax3,
	high_rate.cycle_count,
	high_rate.mean_sei_thickness_t .* 1e9;
	marker = :utriangle,
	markersize = 7,
	linewidth = 2.5,
	color = :tomato,
	label = "BattMo: 2.0 A discharge / 3.0 A charge",
)

scatter!(
	ax3,
	exp_cycle_high,
	exp_sei_high_nm;
	marker = :rect,
	markersize = 7,
	color = :darkred,
	label = "Bolay: 2.0 A discharge / 3.0 A charge",
)

axislegend(ax3, position = :lt)

if !isempty(capacity_metrics)
	sim_cycle_k = cycle_index_metrics ./ 1e3
	capacity_interp = fill(NaN, length(exp_cycle_k))
	for (i, x) in pairs(exp_cycle_k)
		if x < sim_cycle_k[1] || x > sim_cycle_k[end]
			continue
		end
		k = searchsortedlast(sim_cycle_k, x)
		if k == length(sim_cycle_k)
			capacity_interp[i] = capacity_metrics[end]
		elseif x == sim_cycle_k[k]
			capacity_interp[i] = capacity_metrics[k]
		else
			x0, x1 = sim_cycle_k[k], sim_cycle_k[k+1]
			y0, y1 = capacity_metrics[k], capacity_metrics[k+1]
			capacity_interp[i] = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
		end
	end

	valid = .!isnan.(capacity_interp)
	if any(valid)
		residual = capacity_interp[valid] .- exp_capacity[valid]
		rmse = sqrt(mean(residual .^ 2))
		mae = mean(abs.(residual))
		@info "Capacity-vs-cycle comparison: points=$(count(valid)), RMSE=$(rmse) Ah, MAE=$(mae) Ah"
	end
end

baseline_x, baseline_y_nm = deduplicate_monotonic_xy(baseline.cycle_count, baseline.mean_sei_thickness_t .* 1e9)
high_rate_x, high_rate_y_nm = deduplicate_monotonic_xy(high_rate.cycle_count, high_rate.mean_sei_thickness_t .* 1e9)

if !isempty(baseline_x) && !isempty(exp_cycle_low)
	sei_low_interp = interpolate_linear(baseline_x, baseline_y_nm, exp_cycle_low)
	valid = .!isnan.(sei_low_interp)
	if any(valid)
		residual = sei_low_interp[valid] .- exp_sei_low_nm[valid]
		rmse = sqrt(mean(residual .^ 2))
		mae = mean(abs.(residual))
		@info "SEI low-rate comparison: points=$(count(valid)), RMSE=$(rmse) nm, MAE=$(mae) nm"
	end
end

if !isempty(high_rate_x) && !isempty(exp_cycle_high)
	sei_high_interp = interpolate_linear(high_rate_x, high_rate_y_nm, exp_cycle_high)
	valid = .!isnan.(sei_high_interp)
	if any(valid)
		residual = sei_high_interp[valid] .- exp_sei_high_nm[valid]
		rmse = sqrt(mean(residual .^ 2))
		mae = mean(abs.(residual))
		@info "SEI high-rate comparison: points=$(count(valid)), RMSE=$(rmse) nm, MAE=$(mae) nm"
	end
end

if !isempty(baseline.mean_sei_thickness_t) && !isempty(high_rate.mean_sei_thickness_t)
	final_baseline_nm = baseline.mean_sei_thickness_t[end] * 1e9
	final_high_rate_nm = high_rate.mean_sei_thickness_t[end] * 1e9
	delta_nm = final_high_rate_nm - final_baseline_nm
	rel_delta = iszero(final_baseline_nm) ? NaN : 100 * delta_nm / final_baseline_nm
	@info "Final mean SEI thickness comparison (nm): baseline=$(final_baseline_nm), high_rate=$(final_high_rate_nm), Δ=$(delta_nm), Δ%=$(rel_delta)"
end

f
