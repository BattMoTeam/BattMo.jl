using BattMo, GLMakie, CSV, DataFrames, Statistics, Loess

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
include(joinpath(battmo_base, "src/input/defaults/cell_parameters/Chayambuka_functions.jl"))

######### Load Experimental Data #########

exdata = joinpath(battmo_base, "examples", "example_data")
df_01 = CSV.read(joinpath(exdata, "Chayambuka_V_01C.csv"), DataFrame)
df_06 = CSV.read(joinpath(exdata, "Chayambuka_V_06C.csv"), DataFrame)
df_14 = CSV.read(joinpath(exdata, "Chayambuka_V_14C.csv"), DataFrame)

# --- Smoothing functions ---
function moving_average(data::AbstractVector, window::Int = 5)
	[mean(data[max(1, i - window + 1):i]) for i in 1:length(data)]
end

function loess_smooth(x, y; span = 0.3)
	model = loess(x, y; span = span)
	Loess.predict(model, x)
end

function sort_df_by_x(df)
	sort(df, by = r -> r[1])  # sort by first column
end

function smooth_df(df; window = 5, span = 0.3)
	df = sort_df_by_x(df)
	x, y = df[:, 1], df[:, 2]
	df[:, :smooth_ma] = moving_average(y, window)      # <- use df[:, :symbol]
	df[:, :smooth_loess] = loess_smooth(x, y; span = span)
	return df
end

df_01 = smooth_df(df_01)
df_06 = smooth_df(df_06)
df_14 = smooth_df(df_14)

######### Load Simulation Data #########

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings = load_model_settings(; from_default_set = "P2D")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

######### Alter model settings #########
model_settings["ReactionRateConstant"] = "UserDefined"

######### Alter simulation settings #########
simulation_settings["GridResolution"]["NegativeElectrodeCoating"] = 8
simulation_settings["GridResolution"]["PositiveElectrodeCoating"] = 50
simulation_settings["GridResolution"]["NegativeElectrodeActiveMaterial"] = 50
simulation_settings["GridResolution"]["PositiveElectrodeActiveMaterial"] = 50
simulation_settings["GridResolution"]["Separator"] = 5

simulation_settings["TimeStepDuration"] = 100

######### Alter cycling protocol #########
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["DRate"] = 0.6
cycling_protocol["CRate"] = 1.4
cycling_protocol["LowerVoltageLimit"] = 2.0
cycling_protocol["UpperVoltageLimit"] = 4.2

######### Alter cell parameters #########
cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = Dict(
	"FunctionName" => "calc_ne_k",
)
cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = Dict(
	"FunctionName" => "calc_ne_D",
)
cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = Dict(
	"FunctionName" => "calc_pe_k",
)
cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = Dict(
	"FunctionName" => "calc_pe_D",
)

cell_parameters["PositiveElectrode"]["ActiveMaterial"]["OpenCircuitPotential"] = Dict(
	"FunctionName" => "calc_pe_ocp",
)

######### Run simulation ##########
model = LithiumIonBattery(; model_settings);

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);
output = solve(sim; info_level = 0);

######### Format experimental data ##########
A = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]
cap_exp_01 = df_01[:, 1]
t_exp_01 = (df_01[:, 1] .- minimum(df_01[:, 1])) .* 3600 ./ 1000 ./ A
V_exp_01 = df_01[:, 2]

cap_exp_06 = df_06[:, 1]
t_exp_06 = (df_06[:, 1] .- minimum(df_06[:, 1])) .* 3600 ./ 1000 ./ A ./ 5
V_exp_06 = df_06[:, 2]


cap_exp_14 = df_14[:, 1]
t_exp_14 = (df_14[:, 1] .- minimum(df_14[:, 1])) .* 3600 ./ 1000 ./ A ./ 12
V_exp_14 = df_14[:, 2]


######### Plot results ##########

time_series = get_output_time_series(output)
metrics = get_output_metrics(output)

fig = Figure()
ax = Axis(fig[1, 1], title = "Voltage", xlabel = "Capacity / mAh", ylabel = "Voltage / V")
lines!(ax, metrics[:Capacity] .* 1000, time_series[:Voltage], label = "Simulation data")
lines!(ax, cap_exp_06, V_exp_06, label = "Experimental data")
axislegend(position = :lb)
fig
