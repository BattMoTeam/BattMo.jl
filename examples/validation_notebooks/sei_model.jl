using BattMo
using GLMakie
using Statistics
using DelimitedFiles

# ### Load model with Arrhenius temperature dependence
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
fn = joinpath(battmo_base, "examples/Experimental/jsoninputs/bolay_cell_parameters.json")
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
pe_porosity = 0.3658

ne_am_mf = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["MassFraction"]
ne_b_mf = cell_parameters["NegativeElectrode"]["Binder"]["MassFraction"]
ne_add_mf = cell_parameters["NegativeElectrode"]["ConductiveAdditive"]["MassFraction"]
ne_am_density = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["Density"]
ne_b_density = cell_parameters["NegativeElectrode"]["Binder"]["Density"]
ne_add_density = cell_parameters["NegativeElectrode"]["ConductiveAdditive"]["Density"]
ne_porosity = 0.4883

cell_parameters["PositiveElectrode"]["Coating"]["EffectiveDensity"] = (1-pe_porosity) * (pe_am_mf * pe_am_density + pe_b_mf * pe_b_density + pe_add_mf * pe_add_density)
cell_parameters["NegativeElectrode"]["Coating"]["EffectiveDensity"] = (1-ne_porosity) * (ne_am_mf * ne_am_density + ne_b_mf * ne_b_density + ne_add_mf * ne_add_density)

@show cell_parameters["PositiveElectrode"]["Coating"]["EffectiveDensity"]
@show cell_parameters["NegativeElectrode"]["Coating"]["EffectiveDensity"]
# cycling_protocol["Experiment"] = [
# 	"Discharge at 0.3 A until 3.0 V"]

cycling_protocol["InitialTemperature"] = 298.15 - 5
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["DRate"] = 1/3
cycling_protocol["LowerVoltageLimit"] = 3.0


sim = Simulation(model, cell_parameters, cycling_protocol)

output = solve(sim; accept_invalid = true, info_level = 1)

time = output.time_series["Time"]
voltage = output.time_series["Voltage"]
capacity = output.time_series["CumulativeCapacity"]

csv_file = joinpath(battmo_base, "examples/Experimental/resources/bolay_discharge_data_1.csv")
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
f
