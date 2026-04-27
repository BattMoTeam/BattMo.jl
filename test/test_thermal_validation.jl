using BattMo, Jutul, MAT, LinearAlgebra, Statistics, Test

const _THERMAL_VALIDATION_CACHE = Ref{Any}(nothing)

function convert_matlab_cells_to_matrix(cells)
	outer = vec(cells)
	vectors = [vec(inner[:, 1]) for inner in outer]
	M = reduce(hcat, vectors)
	return permutedims(M)
end

function get_thermal_validation_case()
	if _THERMAL_VALIDATION_CACHE[] !== nothing
		return _THERMAL_VALIDATION_CACHE[]
	end

	# MATLAB reference data
	fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/runOnlyThermal.mat")
	data = matread(fn)
	t_matlab = data["time"][:, 1][1:(end-1)]
	E_matlab = data["E"][:, 1][1:(end-1)]
	sources_matlab = convert_matlab_cells_to_matrix(data["sourceTerms"])

	T_max_matlab = Float64[]
	for i in eachindex(t_matlab)
		T_matlab = data["states_thermal"][i]["T"]
		push!(T_max_matlab, maximum(vec(T_matlab)))
	end

	# Julia simulation setup (same scenario as examples/Experimental/thermal_compare_to_matlab.jl)
	fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/lithium_ion_battery_nmc_graphite.json")
	inputparams_material = load_advanced_dict_input(fn)

	fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
	inputparams_geometry = load_advanced_dict_input(fn)
	inputparams_geometry["Geometry"]["Nh"] = 16

	inputparams = merge_input_params([inputparams_material, inputparams_geometry])

	fn = string(dirname(pathof(BattMo)), "/../examples/Experimental/jsoninputs/cc_discharge_control.json")
	inputparams_control = load_advanced_dict_input(fn)
	inputparams_control["Control"]["lowerCutoffVoltage"] = 3.6
	inputparams = merge_input_params(inputparams_control, inputparams; warn = true)

	fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
	inputparams_thermal = load_advanced_dict_input(fn)
	inputparams = merge_input_params(inputparams_thermal, inputparams; warn = true)

	inputparams["use_thermal"] = true

	output = run_simulation(inputparams; accept_invalid = true)
	model = output.model
	multimodel = model.multimodel
	states = output.jutul_output.states
	parameters = output.simulation.parameters
	grids = output.simulation.grids
	maps = output.simulation.global_maps
	timesteps = output.simulation.time_steps[1:length(states)]

	input = (
		model_settings = output.simulation.model.settings,
		cell_parameters = output.simulation.cell_parameters,
		cycling_protocol = output.simulation.cycling_protocol,
		simulation_settings = output.simulation.settings,
	)
	thermal_model, thermal_parameters = BattMo.setup_thermal_model(input, grids)

	cached = (
		output = output,
		model = model,
		multimodel = multimodel,
		states = states,
		parameters = parameters,
		maps = maps,
		timesteps = timesteps,
		thermal_model = thermal_model,
		thermal_parameters = thermal_parameters,
		sources_matlab = sources_matlab,
		t_matlab = t_matlab,
		E_matlab = E_matlab,
		T_max_matlab = T_max_matlab,
	)
	_THERMAL_VALIDATION_CACHE[] = cached
	return cached
end

@testset "thermal source decomposition" begin
	@test begin
		case = get_thermal_validation_case()

		model = case.model
		multimodel = case.multimodel
		parameters = case.parameters
		maps = case.maps
		thermal_model = case.thermal_model
		states = case.states

		cross_terms = filter(model.multimodel.cross_terms) do c
			isa(c.cross_term, ButlerVolmerActmatToElyteCT) && c.target_equation == :charge_conservation
		end

		sample_indices = unique(round.(Int, [1, max(1, length(states) ÷ 2), length(states)]))
		for i in sample_indices
			state = BattMo.get_state_with_secondary_variables(multimodel, states[i], parameters)
			src_total, src_parts = BattMo.get_energy_source!(thermal_model, model, state, maps)

			src_component_sum = zeros(length(src_total))
			for vec_src in values(src_parts)
				mask = .!isnan.(vec_src)
				src_component_sum[mask] .+= vec_src[mask]
				@test minimum(vec_src[mask]) >= -1e-10
			end

			src_reaction = zeros(length(src_total))
			for cross_term in cross_terms
				reaction_src = BattMo.get_reaction_energy_source(cross_term, multimodel, state)
				map = maps[string(cross_term.source)][:cellmap]
				src_reaction[map] .+= reaction_src
			end

			@test all(isfinite, src_total)
			@test src_total ≈ (src_component_sum .+ src_reaction) atol = 1e-8 rtol = 1e-10
		end

		true
	end
end

@testset "thermal vs matlab reference" begin
	@test begin
		case = get_thermal_validation_case()

		output = case.output
		model = case.model
		multimodel = case.multimodel
		states = case.states
		parameters = case.parameters
		maps = case.maps
		timesteps = case.timesteps
		thermal_model = case.thermal_model
		thermal_parameters = case.thermal_parameters
		sources_matlab = case.sources_matlab
		t_matlab = case.t_matlab
		E_matlab = case.E_matlab
		T_max_matlab = case.T_max_matlab

		# Compare Julia-generated source terms against MATLAB reference source terms.
		src_rows = Vector{Vector{Float64}}()
		for state in states
			state = BattMo.get_state_with_secondary_variables(multimodel, state, parameters)
			src, _ = BattMo.get_energy_source!(thermal_model, model, state, maps)
			push!(src_rows, src)
		end
		src_matrix = reduce(vcat, (x' for x in src_rows))

		nsrc = min(size(src_matrix, 1), size(sources_matlab, 1))
		ncell = min(size(src_matrix, 2), size(sources_matlab, 2))
		src_ref = sources_matlab[1:nsrc, 1:ncell]
		src_cmp = src_matrix[1:nsrc, 1:ncell]
		src_diff = src_cmp .- src_ref

		src_rel_l2 = norm(src_diff) / max(norm(src_ref), eps())
		src_corr = cor(vec(src_cmp), vec(src_ref))
		@test isfinite(src_rel_l2)
		@test isfinite(src_corr)
		@test src_corr > 0.70
		@test src_rel_l2 < 2.5

		# Force thermal simulation with MATLAB source terms and compare temperature trajectory.
		forces = [(value = vec(sources_matlab[i, 1:number_of_cells(thermal_model.domain)]),) for i in 1:length(states)]
		nc = number_of_cells(thermal_model.domain)
		thermal_state0 = setup_state(thermal_model, Dict(:Temperature => fill(298.0, nc)))
		thermal_sim = Simulator(thermal_model;
			state0 = thermal_state0,
			parameters = thermal_parameters,
			copy_state = true)
		thermal_states, = simulate(thermal_sim, timesteps; info_level = -1, forces = forces)

		T_max = [maximum(state[:Temperature]) for state in thermal_states]
		nt = min(length(T_max), length(T_max_matlab))
		dT = T_max[1:nt] .- T_max_matlab[1:nt]
		dT_rmse = sqrt(mean(dT .^ 2))
		dT_max = maximum(abs.(dT))
		T_span = max(maximum(T_max_matlab[1:nt]) - minimum(T_max_matlab[1:nt]), eps())
		dT_nrmse = dT_rmse / T_span
		@test dT_rmse < 3.0
		@test dT_max < 5.0
		@test dT_nrmse < 0.25

		# Also keep an electrochemical consistency check against MATLAB voltage.
		E = output.time_series["Voltage"]
		nE = min(length(E), length(E_matlab))
		dE = E[1:nE] .- E_matlab[1:nE]
		dE_rmse = sqrt(mean(dE .^ 2))
		dE_max = maximum(abs.(dE))
		@test dE_rmse < 0.1
		@test dE_max < 0.25

		true
	end
end
