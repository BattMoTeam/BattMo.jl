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

function run_sei_simulation(model, cell_parameters, cycling_protocol)
	protocol = deepcopy(cycling_protocol)
	protocol["InitialTemperature"] = 298.15
	protocol["InitialStateOfCharge"] = 0.99
	protocol["InitialControl"] = "discharging"
	protocol["TotalNumberOfCycles"] = 25
	protocol["CurrentChangeLimit"] = 1e-5
	protocol["VoltageChangeLimit"] = 1e-5

	simulation_settings = load_simulation_settings(; from_default_set = "p2d")
	simulation_settings["TimeStepDuration"] = 50

	sim = Simulation(model, cell_parameters, protocol; simulation_settings = simulation_settings)
	output = solve(sim; accept_invalid = true, info_level = 1, error_on_incomplete = false)

	time = output.time_series["Time"]
	cycle_count = output.time_series["CycleNumber"]
	sei_thickness = output.states["NegativeElectrode"]["Interphase"]["Thickness"]
	ne_resolution = output.simulation.settings["NegativeElectrodeCoatingGridPoints"]
	mean_sei_thickness_t = vec(mean(sei_thickness[:, 1:ne_resolution], dims = 2))

	return (; output, time, cycle_count, mean_sei_thickness_t)
end

# ### Load model with Arrhenius temperature dependence
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
fn = joinpath(battmo_base, "examples/Experimental/jsoninputs/bolay_cell_parameters_calibrated_stoich_effdens.json")
cell_parameters = load_cell_parameters(; from_file_path = fn)
cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")
model_settings = load_model_settings(; from_default_set = "p4d")

model_settings["SEIModel"] = "Bolay"

model = LithiumIonBattery(; model_settings)

# Average of Bolay fit t_plus(c) = 0.4 + 0.2*(c/1000) - 0.125*(c/1000)^2
# over c in [1000, 2000] mol/m^3 to provide a scalar value accepted by validation.
cell_parameters["Electrolyte"]["TransferenceNumber"] = 0.4083333333333333


cap = 2.838  # Ah, calculated using BattMo.quick_cell_check()
current_discharge_base = 1.0  # A
current_discharge_high = 2.0  # A
current_charge = 1.5  # A
drate_base = current_discharge_base / cap
drate_high = current_discharge_high / cap
crate = current_charge / cap

@show drate_base
@show drate_high
@show crate

cycling_protocol_base = deepcopy(cycling_protocol)
cycling_protocol_base["DRate"] = drate_base
cycling_protocol_base["CRate"] = crate
cycling_protocol_base["LowerVoltageLimit"] = 3.95
cycling_protocol_base["UpperVoltageLimit"] = 4.1

cycling_protocol_high = deepcopy(cycling_protocol)
cycling_protocol_high["DRate"] = drate_high
cycling_protocol_high["CRate"] = crate
cycling_protocol_high["LowerVoltageLimit"] = 3.90
cycling_protocol_high["UpperVoltageLimit"] = 4.1

baseline = run_sei_simulation(model, cell_parameters, cycling_protocol_base)
high_rate = run_sei_simulation(model, cell_parameters, cycling_protocol_high)

output = baseline.output
time = baseline.time
voltage = output.time_series["Voltage"]
cycle_time = 35*60 + 65*60
cycle_count = baseline.cycle_count
sim_time_h = maximum(time) > 100.0 ? time ./ 3600.0 : time
mean_sei_thickness_t = baseline.mean_sei_thickness_t

capacity_metrics = output.time_series["NetCapacity"]

exp_capacity_file = joinpath(battmo_base, "examples/Experimental/data/bolay_capacity_cycling_data.csv")
exp_capacity_data = readdlm(exp_capacity_file, ',', Float64)
exp_cycle_k = exp_capacity_data[:, 1]
exp_capacity = exp_capacity_data[:, 2]

exp_sei_low_rate_file = joinpath(battmo_base, "examples/Experimental/data/bolay_sei_thickness_low_rate.csv")
exp_sei_high_rate_file = joinpath(battmo_base, "examples/Experimental/data/bolay_sei_thickness_high_rate.csv")
exp_sei_low_rate_data = readdlm(exp_sei_low_rate_file, ',', Float64)
exp_sei_high_rate_data = readdlm(exp_sei_high_rate_file, ',', Float64)
exp_cycle_low = exp_sei_low_rate_data[:, 1]
exp_sei_low_nm = exp_sei_low_rate_data[:, 2]
exp_cycle_high = exp_sei_high_rate_data[:, 1]
exp_sei_high_nm = exp_sei_high_rate_data[:, 2]

# Plot first three simulated cycles (or fewer if fewer exist)

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

lines!(
	ax1,
	time ./ 3600.0,
	voltage;
	linewidth = 2.5)


# axislegend(ax1, position = :lb)

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
	sim_cycle_k = cycle_count ./ 1e3
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


# const N = 1  # number of cycles to repeat
# cycle_time = 65 * 60 + 35 * 60
# total_time = N * cycle_time

# const T_ramp = 50.0       # seconds
# const I_ramp_target_p3 = 1.0       # first discharge current (A)
# const I_ramp_target_p5 = 3.0       # first discharge current (A)

# function protocol_p3(time, voltage)

# 	t_discharge = 35 * 60
# 	t_charge    = 65 * 60
# 	cycle_time  = t_discharge + t_charge

# 	T_ramp   = 50.0
# 	V_target = 4.1
# 	V_switch = 0.03

# 	I_dis = 1.0
# 	I_cc  = -1.5

# 	# stop condition
# 	if time >= N * cycle_time
# 		return 0.0
# 	end

# 	# =========================================================
# 	# GLOBAL CONTINUOUS TIME (NO RESET PER CYCLE)
# 	# =========================================================
# 	t = time

# 	cycle_phase_time = mod(t, cycle_time)

# 	# =========================================================
# 	# DISCHARGE
# 	# =========================================================
# 	if cycle_phase_time < t_discharge

# 		τ = cycle_phase_time

# 		return τ < T_ramp ?
# 			   I_dis * sin(0.5π * τ / T_ramp) :
# 			   I_dis

# 		# =========================================================
# 		# CHARGE
# 		# =========================================================
# 	else

# 		τ = cycle_phase_time - t_discharge

# 		# ramp into charge
# 		if τ < T_ramp
# 			return I_cc * sin(0.5π * τ / T_ramp)
# 		end

# 		if !isfinite(voltage)
# 			return 0.0
# 		end

# 		# CC–CV blending
# 		x = (voltage - V_target) / V_switch
# 		w_cv = 0.5 * (1 - tanh(x))

# 		τ_eff   = τ - T_ramp
# 		τ_decay = t_charge - T_ramp

# 		I_CV = I_cc * exp(-3 * τ_eff / τ_decay)

# 		return w_cv * I_cc + (1 - w_cv) * I_CV
# 	end
# end

# function protocol_p5(time, voltage)

# 	# =========================
# 	# GLOBAL SETTINGS
# 	# =========================
# 	t_discharge = 35 * 60
# 	t_charge    = 65 * 60
# 	cycle_time  = t_discharge + t_charge

# 	N_cycles = N

# 	# smoothing parameters
# 	T_ramp   = 50.0
# 	T_switch = 20.0

# 	V_target = 4.1
# 	V_switch = 0.03

# 	ΔV_smooth = 0.03

# 	# currents
# 	I_dis = 3.0
# 	I_cc  = -1.5

# 	# stop condition
# 	if time >= N_cycles * cycle_time
# 		return 0.0
# 	end

# 	# cycle time
# 	t = mod(time, cycle_time)

# 	# =========================================================
# 	# 1. DISCHARGE PHASE (with smooth transition into charge)
# 	# =========================================================
# 	if t < t_discharge - T_switch

# 		# pure discharge
# 		return t < T_ramp ? I_dis * sin(0.5π * t / T_ramp) : I_dis

# 	elseif t < t_discharge + T_switch

# 		# =========================
# 		# DISCHARGE → CHARGE BLEND
# 		# =========================
# 		w = 0.5 * (1 - cos(π * (t - (t_discharge - T_switch)) / (2*T_switch)))

# 		# discharge value
# 		Id = I_dis

# 		# start of charge ramp (smoothly entering charge physics)
# 		τ = 0.0
# 		Ic = I_cc * sin(0.5π * τ / T_ramp)

# 		return (1 - w) * Id + w * Ic
# 	end

# 	# =========================================================
# 	# 2. CHARGE PHASE
# 	# =========================================================
# 	τ = t - t_discharge

# 	# --- ramp into charge ---
# 	if τ < T_ramp
# 		return I_cc * sin(0.5π * τ / T_ramp)
# 	end

# 	# safety
# 	if !isfinite(voltage)
# 		return 0.0
# 	end

# 	# =========================================================
# 	# 3. CC–CV VOLTAGE-BASED BLENDING
# 	# =========================================================

# 	# smooth voltage switch (CC ↔ CV)
# 	x = (voltage - V_target) / V_switch
# 	w_cv = 0.5 * (1 - tanh(x))   # CC=1, CV=0

# 	# constant current mode
# 	I_CC = I_cc

# 	# CV mode: slow decay over full charge window
# 	τ_eff   = τ - T_ramp
# 	τ_decay = t_charge - T_ramp

# 	I_CV = I_cc * exp(-3 * τ_eff / τ_decay)

# 	# blended current
# 	return w_cv * I_CC + (1 - w_cv) * I_CV
# end