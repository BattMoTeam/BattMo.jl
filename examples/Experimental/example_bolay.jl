using BattMo
using GLMakie
using Statistics
using DelimitedFiles

# ### Load model with Arrhenius temperature dependence
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
fn = joinpath(battmo_base, "examples/Experimental/jsoninputs/bolay_cell_parameters_calibrated_stoich_effdens.json")
cell_parameters = load_cell_parameters(; from_file_path = fn)
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p2d")

model_settings["SEIModel"] = "Bolay"


model = LithiumIonBattery(; model_settings)

# Validation currently expects numeric transference number.
cell_parameters["Electrolyte"]["TransferenceNumber"] = 0.4083333333333333

# Calculate effective densities
pe_am_mf = cell_parameters["PositiveElectrode"]["ActiveMaterial"]["MassFraction"]
pe_b_mf = cell_parameters["PositiveElectrode"]["Binder"]["MassFraction"]
pe_add_mf = cell_parameters["PositiveElectrode"]["ConductiveAdditive"]["MassFraction"]
pe_am_density = cell_parameters["PositiveElectrode"]["ActiveMaterial"]["Density"]
pe_b_density = cell_parameters["PositiveElectrode"]["Binder"]["Density"]
pe_add_density = cell_parameters["PositiveElectrode"]["ConductiveAdditive"]["Density"]
pe_porosity = 0.4

ne_am_mf = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["MassFraction"]
ne_b_mf = cell_parameters["NegativeElectrode"]["Binder"]["MassFraction"]
ne_add_mf = cell_parameters["NegativeElectrode"]["ConductiveAdditive"]["MassFraction"]
ne_am_density = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["Density"]
ne_b_density = cell_parameters["NegativeElectrode"]["Binder"]["Density"]
ne_add_density = cell_parameters["NegativeElectrode"]["ConductiveAdditive"]["Density"]
ne_porosity = 0.4

cell_parameters["PositiveElectrode"]["Coating"]["EffectiveDensity"] = (1-pe_porosity) * (pe_am_mf * pe_am_density + pe_b_mf * pe_b_density + pe_add_mf * pe_add_density)
cell_parameters["NegativeElectrode"]["Coating"]["EffectiveDensity"] = (1-ne_porosity) * (ne_am_mf * ne_am_density + ne_b_mf * ne_b_density + ne_add_mf * ne_add_density)

@show cell_parameters["PositiveElectrode"]["Coating"]["EffectiveDensity"]
@show cell_parameters["NegativeElectrode"]["Coating"]["EffectiveDensity"]
# cycling_protocol["Experiment"] = [
# 	"Discharge at 0.3 A until 3.0 V"]

cycling_protocol["InitialTemperature"] = 298.15 - 5
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["InitialControl"] = "discharging"
cycling_protocol["TotalNumberOfCycles"] = 0
cycling_protocol["DRate"] = 1 / 3
cycling_protocol["CRate"] = cycling_protocol["DRate"]
cycling_protocol["LowerVoltageLimit"] = 3.0
cycling_protocol["UpperVoltageLimit"] = 4.0


sim = Simulation(model, cell_parameters, cycling_protocol)

output_1 = solve(sim; accept_invalid = true, info_level = 0)

time = output_1.time_series["Time"]
voltage = output_1.time_series["Voltage"]
capacity = output_1.time_series["CumulativeCapacity"]

csv_file = joinpath(battmo_base, "examples/Experimental/data/bolay_discharge_data_1.csv")
exp_data = readdlm(csv_file, ',', Float64)
exp_time = exp_data[:, 1]
exp_voltage = exp_data[:, 2]

# Convert simulation time to hours when it is given in seconds.
sim_time_h = maximum(time) > 100.0 ? time ./ 3600.0 : time

function linear_interpolate(x_grid::AbstractVector, y_grid::AbstractVector, xq::AbstractVector)
	yq = fill(NaN, length(xq))
	for (i, x) in pairs(xq)
		if x < x_grid[1] || x > x_grid[end]
			continue
		end
		k = searchsortedlast(x_grid, x)
		if k == length(x_grid)
			yq[i] = y_grid[end]
		elseif x == x_grid[k]
			yq[i] = y_grid[k]
		else
			x0, x1 = x_grid[k], x_grid[k+1]
			y0, y1 = y_grid[k], y_grid[k+1]
			yq[i] = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
		end
	end
	return yq
end

sim_voltage_on_exp = linear_interpolate(sim_time_h, voltage, exp_time)
valid = .!isnan.(sim_voltage_on_exp)
residual = sim_voltage_on_exp[valid] .- exp_voltage[valid]
rmse = sqrt(mean(residual .^ 2))
mae = mean(abs.(residual))
@info "Comparison against CSV: points=$(count(valid)), RMSE=$(rmse) V, MAE=$(mae) V"

f = Figure(size = (1000, 400))

ax = GLMakie.Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / h",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	sim_time_h,
	voltage;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Simulation",
)

scatterlines!(ax,
	exp_time,
	exp_voltage;
	linewidth = 2,
	markersize = 7,
	marker = :circle,
	color = :tomato,
	label = "Digitized experiment",
)

axislegend()
display(GLMakie.Screen(), f)



const N = 3  # number of cycles to repeat
cycle_time_p1 = 63 * 60 + 15 * 60 + 19 * 60
total_time_p1 = N * cycle_time_p1

const T_ramp = 50.0       # seconds
const I_ramp_target = 0.88       # first discharge current (A)


function protocol_p1(time, voltage)

	# --- durations (seconds) ---
	t_dis1_total = 15 * 60
	t_dis2_total = 19 * 60
	t_charge_total = 63 * 60

	cycle_time = t_dis1_total + t_dis2_total + t_charge_total

	# --- parameters ---
	T_ramp = 50.0
	ΔV_smooth = 0.02

	I_dis1 = 0.88
	I_dis2 = 0.74
	I_cc   = -1.0

	if time >= N * cycle_time
		return 0.0
	end

	t = mod(time, cycle_time)

	# ================= DISCHARGE 1 =================
	if t < t_dis1_total
		return t < T_ramp ? I_dis1 * sin(0.5π * t / T_ramp) : I_dis1

		# ================= DISCHARGE 2 =================
	elseif t < t_dis1_total + t_dis2_total
		τ = t - t_dis1_total
		if τ < T_ramp
			w = 0.5 * (1 - cos(π * τ / T_ramp))
			return (1 - w) * I_dis1 + w * I_dis2
		else
			return I_dis2
		end

		# ================= CHARGE (63 min total) =================
	else
		τ = t - (t_dis1_total + t_dis2_total)

		# --- ramp into charge ---
		if τ < T_ramp
			return I_cc * sin(0.5π * τ / T_ramp)
		end

		# --- smooth CC → CV transition ---
		s = 1 / (1 + exp((voltage - 4.1) / ΔV_smooth))

		# --- enforce decay over full charge window ---
		# decay goes from ~1 → ~0 across 63 min
		τ_eff = τ - T_ramp
		τ_decay = t_charge_total - T_ramp

		decay = exp(-3 * τ_eff / τ_decay)
		# factor 3 ensures near-zero at end, but not too sharp

		return I_cc * s * decay
	end
end


cycling_protocol = load_cycling_protocol(; from_default_set = "user_defined_current_function")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")

simulation_settings["TimeStepDuration"] = 5

cycling_protocol["FunctionName"] = "protocol_p1"
cycling_protocol["InitialTemperature"] = 298.15 - 5
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["TotalTime"] = total_time_p1


sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

# output_2 = solve(sim; accept_invalid = true, info_level = 0)

plot_dashboard(output_2)


cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")
cycling_protocol["InitialTemperature"] = 298.15
cycling_protocol["InitialStateOfCharge"] = 0.95
cycling_protocol["InitialControl"] = "discharging"
cycling_protocol["TotalNumberOfCycles"] = 25


cap = 2.838  # Ah, calculated using BattMo.quick_cell_check()
current_discharge_base = 1.0  # A
current_discharge_high = 3.0  # A
current_charge = 1.5  # A
drate_base = current_discharge_base / cap
drate_high = current_discharge_high / cap
crate = current_charge / cap

cycling_protocol_base = deepcopy(cycling_protocol)
cycling_protocol_base["DRate"] = drate_base
cycling_protocol_base["CRate"] = crate
cycling_protocol_base["LowerVoltageLimit"] = 3.94
cycling_protocol_base["UpperVoltageLimit"] = 4.1

cycling_protocol_high = deepcopy(cycling_protocol)
cycling_protocol_high["DRate"] = drate_high
cycling_protocol_high["CRate"] = crate
cycling_protocol_high["LowerVoltageLimit"] = 3.90
cycling_protocol_high["UpperVoltageLimit"] = 4.1


sim_long_base = Simulation(model, cell_parameters, cycling_protocol_base)
output_long_base = solve(sim_long_base; accept_invalid = true, info_level = 1);

plot_dashboard(output_long_base)

sim_long_high = Simulation(model, cell_parameters, cycling_protocol_high)
output_long_high = solve(sim_long_high; accept_invalid = true, info_level = 1);

plot_dashboard(output_long_high)