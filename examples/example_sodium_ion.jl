using BattMo, GLMakie, CSV, DataFrames, Statistics, ForwardDiff, Jutul, RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

# ## Load the experimental data and set up a base case
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
exdata = joinpath(battmo_base, "examples", "example_data")
df_01 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_1_crate.csv"), DataFrame)
df_06 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_6_crate.csv"), DataFrame)
df_14 = CSV.read(joinpath(exdata, "Chayambuka_voltage_1_4_crate.csv"), DataFrame)

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")


function plot_(cell_parameters::CellParameters)
	num_points = 100

	# --- Define the known functional parameters ---
	param_map = Dict(
		"NegativeElectrode/ActiveMaterial/OpenCircuitPotential" => (BattMo.setup_ocp_evaluation_expression_from_string, [:c, :T, :refT, :cmax]),
		"PositiveElectrode/ActiveMaterial/OpenCircuitPotential" => (BattMo.setup_ocp_evaluation_expression_from_string, [:c, :T, :refT, :cmax]),
		"NegativeElectrode/ActiveMaterial/DiffusionCoefficient" => (BattMo.setup_electrode_diff_evaluation_expression_from_string, [:c, :T, :refT, :cmax]),
		"PositiveElectrode/ActiveMaterial/DiffusionCoefficient" => (BattMo.setup_electrode_diff_evaluation_expression_from_string, [:c, :T, :refT, :cmax]),
		"NegativeElectrode/ActiveMaterial/ReactionRateConstant" => (BattMo.setup_reaction_rate_constant_evaluation_expression_from_string, [:c, :T]),
		"PositiveElectrode/ActiveMaterial/ReactionRateConstant" => (BattMo.setup_reaction_rate_constant_evaluation_expression_from_string, [:c, :T]),
		"Electrolyte/IonicConductivity" => (BattMo.setup_conductivity_evaluation_expression_from_string, [:c, :T]),
		"Electrolyte/DiffusionCoefficient" => (BattMo.setup_diffusivity_evaluation_expression_from_string, [:c, :T]),
	)

	# --- Plot setup ---
	fig = Figure(size = (1200, 800))
	functional_params = collect(keys(param_map))
	n = length(functional_params)
	ncols = ceil(Int, sqrt(n))
	nrows = ceil(Int, n / ncols)

	for (i, param_path) in enumerate(functional_params)
		# Retrieve value from nested Dict
		keys = split(param_path, "/")
		val = cell_parameters.all
		for k in keys
			val = val[k]
		end

		# Determine axis label and c range
		if occursin("NegativeElectrode", param_path)
			cmax = cell_parameters.all["NegativeElectrode"]["ActiveMaterial"]["MaximumConcentration"]
			c_range = range(0, cmax, length = num_points)
			x_values = c_range ./ cmax  # normalized
			x_label = "c / cmax"
		elseif occursin("PositiveElectrode", param_path)
			cmax = cell_parameters.all["PositiveElectrode"]["ActiveMaterial"]["MaximumConcentration"]
			c_range = range(0, cmax, length = num_points)
			x_values = c_range ./ cmax  # normalized
			x_label = "c / cmax"
		elseif occursin("Electrolyte", param_path)
			c0 = cell_parameters.all["Electrolyte"]["Concentration"]
			c_range = range(0.5c0, 1.5c0, length = num_points)  # realistic range around initial conc.
			x_values = c_range
			x_label = "Electrolyte concentration [mol/m^3]"
		else
			c_range = range(0, 1, length = num_points)
			x_values = c_range
			x_label = "c"
		end

		row, col = divrem(i - 1, ncols)
		ax = Axis(fig[row+1, col+1], title = param_path, xlabel = x_label, ylabel = "Value")

		y = Float64[]

		if isa(val, AbstractString) && haskey(param_map, param_path)
			setup_func, args_symbols = param_map[param_path]
			f_expr = setup_func(val)
			f_generated = @RuntimeGeneratedFunction(f_expr)

			T_val = 298.15
			refT_val = 298.15

			# Evaluate function with the appropriate arguments
			if :cmax in args_symbols && :refT in args_symbols
				y = [f_generated(c, T_val, refT_val, cmax) for c in c_range]
			elseif length(args_symbols) == 2
				y = [f_generated(c, T_val) for c in c_range]
			else
				y = [f_generated(c) for c in c_range]
			end
		elseif isa(val, Dict)
			if all(haskey(val, k) for k in ["X", "Y"])
				x_values, y = val["X"], val["Y"]
			elseif haskey(val, "FunctionName")
				f = BattMo.setup_function_from_function_name(val["FunctionName"])
				y = [f(c) for c in c_range]
			end
		end

		lines!(ax, x_values, y, color = :blue)
	end

	fig
end






plot_(cell_parameters)

# cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
# model_settings = load_model_settings(; from_default_set = "P2D")
# simulation_settings = load_simulation_settings(; from_default_set = "P2D")

# A = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]

# t_exp_06 = df_06[:, 1] * 3600 / 1000 / A / 5
# v_exp_06 = df_06[:, 2]

# t_exp_01 = df_01[:, 1] * 3600 / 1000 / A
# v_exp_01 = df_01[:, 2]

# t_exp_14 = df_14[:, 1] * 3600 / 1000 / A / 12
# v_exp_14 = df_14[:, 2]

# cell_parameters["NegativeElectrode"]["ElectrodeCoating"]["Thickness"] = 1.2 * 64e-6
# cmax = cell_parameters["PositiveElectrode"]["ActiveMaterial"]["MaximumConcentration"]
# # cell_parameters["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"] = 0.83
# # cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] = 1.667145305054536 * cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"]
# simulation_settings["GridResolution"]["NegativeElectrodeCoating"] = 8
# simulation_settings["GridResolution"]["PositiveElectrodeCoating"] = 10
# simulation_settings["GridResolution"]["NegativeElectrodeActiveMaterial"] = 10
# simulation_settings["GridResolution"]["PositiveElectrodeActiveMaterial"] = 10
# simulation_settings["GridResolution"]["Separator"] = 5

# simulation_settings["TimeStepDuration"] = 50
# @info "np ratio" compute_np_ratio(cell_parameters)

# model_settings["ReactionRateConstant"] = "UserDefined"

# cycling_protocol["DRate"] = 0.6
# cycling_protocol["CRate"] = 0.5
# cycling_protocol["LowerVoltageLimit"] = 2.0
# cycling_protocol["UpperVoltageLimit"] = 4.0
# # cycling_protocol["InitialControl"] = "discharging"
# # cycling_protocol["TotalNumberOfCycles"] = 1
# # cycling_protocol["InitialStateOfCharge"] = 1.0


# ########## Determine OCPs ##########

# battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
# exdata = joinpath(battmo_base, "examples", "example_data")
# df_1 = CSV.read(joinpath(exdata, "Chayambuka_pe_ocp.csv"), DataFrame)
# df_2 = CSV.read(joinpath(exdata, "Chayambuka_ne_ocp.csv"), DataFrame)

# exp_pe_ocp = df_1[:, 2]
# exp_pe_transfered_charge = df_1[:, 1] # mAh/g

# exp_ne_ocp = df_2[:, 2]
# exp_ne_transfered_charge = df_2[:, 1] # mAh/g

# max_pe_charge = maximum(exp_pe_transfered_charge)
# min_pe_charge = minimum(exp_pe_transfered_charge)
# max_ne_charge = maximum(exp_ne_transfered_charge)
# min_ne_charge = minimum(exp_ne_transfered_charge)

# x_pe = (exp_pe_transfered_charge .- min_pe_charge) ./ (max_pe_charge - min_pe_charge)
# x_ne = (exp_ne_transfered_charge .- min_ne_charge) ./ (max_ne_charge - min_ne_charge)

# function ne_ocp(c, T, cmax)

# 	ocp = get_1d_interpolator(x_ne, exp_ne_ocp)
# 	return ocp(c / cmax)
# end

# @eval Main ne_ocp = $ne_ocp

# function pe_ocp(c, T, cmax)

# 	ocp = get_1d_interpolator(x_pe, exp_pe_ocp)
# 	return ocp(c / cmax)
# end

# @eval Main pe_ocp = $pe_ocp

# # cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 2.0306459345750275e-16
# # cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 4.542183772045386e-11
# # cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 1.2952951004386266e-15
# # cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 1.6787424917471138e-11

# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["OpenCircuitPotential"] = Dict(
# 	"FunctionName" => "pe_ocp",
# )
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["OpenCircuitPotential"] = Dict(
# 	"FunctionName" => "ne_ocp",
# )


# nothing # hide

# model = LithiumIonBattery(; model_settings)

# fig1 = Figure()
# ax1 = Axis(fig1[1, 1], title = "Stoichiometry PE", xlabel = "Time / s", ylabel = "Cs/Cmax / -")

# c_neg = Observable(Float64[])
# c_pos = Observable(Float64[])
# times = Observable(Float64[])

# scatter!(ax1, times, c_pos, label = "Positive electrode")
# # lines!(ax1, times, c_pos, label = "Positive electrode")
# axislegend(position = :lb)


# function logger(converged, report, storage, model, dt, forces, cfg, iteration)

# 	t = storage.state.Control.Controller.time
# 	# c_n = ForwardDiff.value(storage.state.Control.Phi[1])
# 	stoich = ForwardDiff.value(storage.state.PeAm.Cs[8]) ./ cmax
# 	@info ForwardDiff.value(storage.state.PeAm.Cs[8]) ./ cmax

# 	push!(times[], t)
# 	push!(c_pos[], stoich)
# 	# push!(stoich_pos[], x_pos)
# 	notify(times)
# 	notify(c_pos)
# 	display(fig1)
# 	# notify(stoich_pos)
# 	return converged
# end

# sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

# # Now we can run the simulation
# output = solve(sim; accept_invalid = true, logger, info_level = 0)
# nothing # hide


# # Now we can easily plot some results

# states = get_output_states(output)
# time_series = get_output_time_series(output)

# # ne_am_diff = states[:NeAmDiffusionCoefficient][:, :20]
# # pe_am_diff = states[:PeAmDiffusionCoefficient][:, 31:50]

# # @info maximum(states[:PeAmSurfaceConcentration][:, 14:23])


# plot_dashboard(output; plot_type = "contour")

# max_t_exp = maximum(t_exp_06)
# max_t = maximum(time_series[:Time])

# @info "ratio", max_t_exp / max_t

# ne_stoich = []
# pe_stoich = []
# for i in 1:length(states[:NeAmSurfaceConcentration][:, 1])
# 	push!(ne_stoich, mean(states[:NeAmSurfaceConcentration][i, :8]) ./ cell_parameters["NegativeElectrode"]["ActiveMaterial"]["MaximumConcentration"])
# 	push!(pe_stoich, mean(states[:PeAmSurfaceConcentration][i, 14:23]) ./ cell_parameters["PositiveElectrode"]["ActiveMaterial"]["MaximumConcentration"])

# end

# fig = Figure()
# ax = Axis(fig[1, 1], title = "Stoichiometry", xlabel = "Time / s", ylabel = "Stoichiometry / -")
# lines!(ax, time_series[:Time], ne_stoich, label = "Negative")
# lines!(ax, time_series[:Time], pe_stoich, label = "Positive")
# # lines!(ax, t_exp_06, v_exp_06, label = "Experimental data")
# axislegend(position = :lb)
# fig

# fig = Figure()
# ax = Axis(fig[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V")
# lines!(ax, time_series[:Time], time_series[:Voltage], label = "Simulation data")
# lines!(ax, t_exp_06, v_exp_06, label = "Experimental data")
# axislegend(position = :lb)
# fig
# # plot_output(output, ["NeAmOpenCircuitPotential vs ", "PeAmOpenCircuitPotential vs Time and Position", "NeAmSurfaceConcentration vs Time and Position"]; layout = (3, 1))
# # plot_output(output, ["NeAmReactionRateConst vs Time and Position", "PeAmReactionRateConst vs Time and Position"]; layout = (2, 1))
