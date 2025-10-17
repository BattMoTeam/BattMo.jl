export print_info

function print_info(input::S) where {S <: ParameterSet}
	return print_overview(input)
end

function print_info(output::SimulationOutput)
	return print_overview(output)
end

function print_info(calibration::AbstractCalibration)
	return print_calibration_overview(calibration)
end

function print_info(from_name::String; view::Union{Nothing, String} = nothing)
	"""
	Print detailed information about parameters, settings, or output variables,
	optionally filtered by view. All values are aligned.
	"""

	# --- Map view → (metadata function, title, emoji) ---
	view_map = Dict(
		"CellParameters"     => (get_cell_parameters_meta_data, "Cell Parameter: ", "🔋"),
		"CyclingProtocol"    => (get_cycling_protocol_meta_data, "Cycling Protocol: ", "🚴"),
		"ModelSettings"      => (get_model_settings_meta_data, "Model Setting: ", "🕸️"),
		"SimulationSettings" => (get_simulation_settings_meta_data, "Simulation Setting: ", "◻️"),
		"SolverSettings"     => (get_solver_settings_meta_data, "Solver Setting: ", "🧮"),
		"OutputVariable"     => (get_output_variables_meta_data, "Output Variable: ", "📈"),
	)

	# Validate view
	if !isnothing(view) && !haskey(view_map, view)
		error("❌ Invalid view '$view'. Must be one of: " * join(keys(view_map), ", "))
	end

	output_fmt = detect_output_format()
	categories_to_search = isnothing(view) ? collect(keys(view_map)) : [view]

	# Accumulate matches
	all_matches = Dict{String, Vector{String}}()
	for cat in categories_to_search
		get_meta_data, _, _ = view_map[cat]
		meta_data = get_meta_data()
		matches = collect(filter(k -> occursin(lowercase(from_name), lowercase(k)), keys(meta_data)))
		if !isempty(matches)
			all_matches[cat] = matches
		end
	end

	if isempty(all_matches)
		println("❌ No entries found matching: ", from_name)
		return
	end

	# --- Print results ---
	label_width = 22  # fixed width for all labels
	indent = "    "

	for cat in sort(collect(keys(all_matches)))
		get_meta_data, title, emoji = view_map[cat]
		meta_data = get_meta_data()
		matches = all_matches[cat]

		for actual_key in matches
			param_info = meta_data[actual_key]

			println("\n" * "-"^100)
			println("$emoji  $title $actual_key")
			println("-"^100)

			function print_field(label, value)
				println(indent, rpad("🔹 $label", label_width), value)
			end

			print_field("Name", actual_key)
			print_field("Category", cat)

			if haskey(param_info, "variable_name")
				print_field("Keyword argument", param_info["variable_name"])
			end
			if haskey(param_info, "description")
				print_field("Description", param_info["description"])
			end
			if haskey(param_info, "type")
				t = param_info["type"]
				print_field("Type", isa(t, AbstractArray) ? join(t, ", ") : string(t))
			end
			if haskey(param_info, "shape")
				s = param_info["shape"]
				print_field("Shape", isa(s, AbstractArray) ? join(s, ", ") : string(s))
			end
			if haskey(param_info, "unit")
				print_field("Unit", param_info["unit"])
			end
			if haskey(param_info, "options")
				opts = param_info["options"]
				print_field("Options", isa(opts, AbstractArray) ? join(opts, ", ") : string(opts))
			end
			if haskey(param_info, "min_value")
				print_field("Minimum value", param_info["min_value"])
			end
			if haskey(param_info, "max_value")
				print_field("Maximum value", param_info["max_value"])
			end
			doc_url = get(param_info, "documentation", nothing)
			if doc_url isa String && doc_url != "-"
				print_field("Documentation", format_link("visit", doc_url, 50, output_fmt))
			end
			iri = get(param_info, "context_type_iri", nothing)
			if iri isa String && iri != "-"
				print_field("Ontology link", format_link("visit", iri, 50, output_fmt))
			end
		end
	end

	println("\n" * "="^120)
end