export print_info


"""
	print_info(input::S; view = nothing) where {S <: ParameterSet}

Print a formatted overview of parameters in a `ParameterSet`.

Lists parameter names, units, types, and values in a structured table,
using available metadata for labeling and formatting.

# Arguments
- `input::ParameterSet`: Parameter set (e.g., cell, cycling, solver, or simulation settings).
- `view::Union{Nothing, String}` (optional): If provided, filters and displays only parameters whose path contains the given string.

# Notes
- Recursively traverses nested dictionaries within the parameter set.
- Default parameters are marked as `(default)`.
- Used for quick inspection of model inputs in BattMo.
- If `view` is specified, only matching parameters are shown.
"""
function print_info(input::S; view = nothing) where {S <: ParameterSet}
	return print_overview(input; view)
end



"""
	print_info(output::SimulationOutput)

Print a structured overview of all available output variables in a simulation result.

Displays variable names, units, and shapes grouped by category (time series, metrics, and states),
based on BattMo output metadata.

# Arguments
- `output::SimulationOutput`: Simulation results object to inspect.

# Notes
- Only variables present in the simulation output are listed.
- Groups variables by case for easier browsing.
- Intended for quick post-simulation inspection within BattMo.
"""
function print_info(output::SimulationOutput)
	return print_overview(output)
end


"""
	print_info(calibration::AbstractCalibration) -> Nothing

Prints an overview of the calibration parameters and their current values for a
given `calibration` object. This is a convenience wrapper around
[`print_calibration_overview`](@ref), which performs the actual display.

# Arguments
- `calibration::AbstractCalibration`: the calibration object containing parameter
  targets and (optionally) optimized values.

# Returns
- `Nothing`: this function only prints formatted output to the console.

# Notes
- Delegates to [`print_calibration_overview`](@ref) to display:
  - Parameter names
  - Initial values
  - Bounds
  - Optimized values (if available)
  - Percentage change from initial values
- If the calibration has not been performed, only initial values and bounds are shown.

# Example
```julia
print_info(my_calibration)
"""
function print_info(calibration::AbstractCalibration)
	return print_calibration_overview(calibration)
end

"""
	print_info(from_name::String; view::Union{Nothing, String}=nothing) -> Nothing

Prints information on specific parameters, settings, and output variables. 
Searches available metadata categories for entries matching `from_name` and prints
detailed information about each match. The output is formatted with emojis, section
headers, and aligned labels for readability.

# Arguments
- `from_name::String`: the (partial or full) name to search for in the metadata.

# Keywords
- `view::Union{Nothing, String}=nothing`: restricts the search to a specific category.
  Must be one of:
  `"CellParameters"`, `"CyclingProtocol"`, `"ModelSettings"`, `"SimulationSettings"`,
  `"SolverSettings"`, or `"OutputVariable"`.  
  If `nothing` (default), all categories are searched.

# Returns
- `Nothing`: this function only prints formatted results to the console.

# Throws
- `ErrorException`: if `view` is provided but not one of the allowed categories.

# Notes
- Each matching entry prints metadata fields such as:
  - `Name`, `Category`, `Keyword argument`, `Description`, `Type`, `Shape`, `Unit`
  - `Options`, `Minimum value`, `Maximum value`, `Documentation`, `Ontology link`
- Output formatting adjusts automatically depending on the detected output format.

# Example
```julia
print_info("concentration")
print_info("thickness"; view="CellParameters")
"""
function print_info(from_name::String; view::Union{Nothing, String} = nothing)

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
