export quick_cell_check, print_default_input_sets_info, print_submodels_info, print_info, print_overview


function print_overview(input::S) where {S <: ParameterSet}
	input_dict = deepcopy(input.all)

	# Remove "Metadata" if present
	if haskey(input_dict, "Metadata")
		pop!(input_dict, "Metadata")
	end

	# Create a complete metadata dict
	meta_data_cell_par = get_cell_parameters_meta_data()
	meta_data_cycl_par = get_cycling_protocol_meta_data()
	meta_data_model_set = get_model_settings_meta_data()
	meta_data_sim_set = get_simulation_settings_meta_data()
	meta_data_solv_set = get_solver_settings_meta_data()
	meta_data_1 = merge_dict(meta_data_cell_par, meta_data_cycl_par)
	meta_data_2 = merge_dict(meta_data_1, meta_data_model_set)
	meta_data_3 = merge_dict(meta_data_2, meta_data_sim_set)
	meta_data = merge_dict(meta_data_3, meta_data_solv_set)


	# Shared accumulator
	params = NamedTuple[]

	# Recursive traversal that populates `params`
	function collect_parameters!(d::Dict, prefix::Vector{String} = String[])
		for (k, v) in sort(collect(d); by = first)
			path = vcat(prefix, string(k))
			if isa(v, Dict)
				if haskey(v, "Description")
					pop!(v, "Description")
				end
				collect_parameters!(v, path)
			else
				push!(params, (path = path, key = string(k), value = v, type = typeof(v)))
			end
		end
	end

	collect_parameters!(input_dict)

	# Layout widths
	par_space = isa(input, FullSimulationInput) ? 95 : 80
	val_space = 30
	unit_space = 20
	type_space = 20

	println("\nPARAMETER OVERVIEW")
	println("="^(par_space + unit_space + type_space + val_space))
	println(rpad("Parameter", par_space), rpad("Unit", unit_space), rpad("Type", type_space), rpad("Value", val_space))
	println("-"^(par_space + unit_space + type_space + val_space))

	# Helper to format value compactly (without Printf)
	function format_value(v)
		if isa(v, AbstractVector)
			return "[" * string(length(v)) * " el.]"
		elseif isa(v, AbstractDict)
			return "{Dict}"
		elseif isa(v, AbstractString)
			return length(v) > val_space ? v[1:(val_space-4)]*"..." : v
		elseif isa(v, Bool)
			return string(v)
		elseif isa(v, Integer)
			s = string(v)
			return length(s) > val_space ? s[1:(val_space-4)]*"..." : s
		elseif isa(v, AbstractFloat)
			# Compact numeric representation
			abs(v) ≥ 1e4 || abs(v) ≤ 1e-3 ? string(round(v, sigdigits = 5)) :
			string(round(v, digits = 5))
		else
			s = string(v)
			return length(s) > val_space ? s[1:(val_space-4)]*"..." : s
		end
	end

	for p in params
		full_path = join(p.path, " / ")
		value_str = format_value(p.value)
		info = get(meta_data, p.path[end], Dict())
		unit = get(info, "unit", "N/A")
		isdefault = get(info, "isdefault", false)
		name_str = isdefault ? "$(full_path) (default)" : full_path
		type_str = string(p.type)

		println(
			rpad(name_str, par_space),
			rpad(unit, unit_space),
			rpad(type_str, type_space),
			rpad(value_str, val_space),
		)
	end

	println("="^(par_space + val_space + unit_space + type_space))
	println("Total parameters: $(length(params))")
end


function print_info(from_name::String; category::Union{Nothing, String} = nothing)
	"""
	Print detailed information about parameters, settings, or output variables,
	optionally filtered by category. All values are aligned.
	"""

	# --- Map category → (metadata function, title, emoji) ---
	category_map = Dict(
		"CellParameters"     => (get_cell_parameters_meta_data, "Cell Parameter Information", "🔋"),
		"CyclingProtocol"    => (get_cycling_protocol_meta_data, "Cycling Protocol Information", "🚴"),
		"ModelSettings"      => (get_model_settings_meta_data, "Model Setting Information", "🕸️"),
		"SimulationSettings" => (get_simulation_settings_meta_data, "Simulation Setting Information", "◻️"),
		"SolverSettings"     => (get_solver_settings_meta_data, "Solver Setting Information", "🧮"),
		"OutputVariable"     => (get_output_variables_meta_data, "Output Variable Information", "📈"),
	)

	# Validate category
	if !isnothing(category) && !haskey(category_map, category)
		error("❌ Invalid category '$category'. Must be one of: " * join(keys(category_map), ", "))
	end

	output_fmt = detect_output_format()
	categories_to_search = isnothing(category) ? collect(keys(category_map)) : [category]

	# Accumulate matches
	all_matches = Dict{String, Vector{String}}()
	for cat in categories_to_search
		get_meta_data, _, _ = category_map[cat]
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
		get_meta_data, title, emoji = category_map[cat]
		meta_data = get_meta_data()
		matches = all_matches[cat]

		for actual_key in matches
			param_info = meta_data[actual_key]

			println("\n" * "-"^100)
			println("$emoji  $title")
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


function quick_cell_check(cell::CellParameters; cell_2::Union{Nothing, CellParameters} = nothing)
	# --- ANSI Colors ---
	green(s) = "\033[92m$(s)\033[0m"   # calculated
	blue(s) = "\033[94m$(s)\033[0m"    # input
	bold(s) = "\033[1m$(s)\033[0m"
	red(s) = "\033[91m$(s)\033[0m"
	yellow(s) = "\033[93m$(s)\033[0m"

	# --- KPI dictionary ---
	function get_kpis(cell::CellParameters)
		Dict(
			"Positive Electrode Coating Mass" => compute_electrode_coating_mass(cell, "PositiveElectrode"),
			"Negative Electrode Coating Mass" => compute_electrode_coating_mass(cell, "NegativeElectrode"),
			"Separator Mass" => compute_separator_mass(cell),
			"Electrolyte Mass" => compute_electrolyte_mass(cell),
			"Cell Mass" => compute_cell_mass(cell),
			"Cell Volume" => compute_cell_volume(cell),
			"Positive Electrode Mass Loading" => compute_electrode_mass_loading(cell, "PositiveElectrode"),
			"Negative Electrode Mass Loading" => compute_electrode_mass_loading(cell, "NegativeElectrode"),
			"Cell Theoretical Capacity" => compute_cell_theoretical_capacity(cell),
			"Cell N:P Ratio" => compute_np_ratio(cell),
		)
	end

	kpis1 = get_kpis(cell)
	kpis2 = isnothing(cell_2) ? nothing : get_kpis(cell_2)

	# --- Safe accessor ---
	safe_val(kpis, key) =
		try
			round(kpis[key], sigdigits = 4)
		catch _
			red("ERR")
		end

	# --- Header ---
	println(bold("\n════════════════════════════════════════════════════════════════════════════"))
	println(bold("🔋 Quick Cell Check"))
	println(bold("════════════════════════════════════════════════════════════════════════════"))

	name_cell_1 = get(cell["Metadata"], "Title", "Cell 1")
	name_cell_2 = isnothing(cell_2) ? "" : get(cell_2["Metadata"], "Title", "Cell 2")

	# --- Column headers ---
	label_width = 35
	val_width = 14
	delta_width = 12
	unit_width = 12
	source_width = 12

	println()
	println(
		rpad("Quantity", label_width),
		rpad(name_cell_1, val_width),
		isnothing(cell_2) ? "" : " | " * rpad(name_cell_2, val_width),
		isnothing(cell_2) ? "" : " | " * rpad("Δ", delta_width),
		rpad("Unit", unit_width),
		"Source",
	)
	println("─"^(label_width + val_width + (isnothing(cell_2) ? 0 : val_width + delta_width + 3) + unit_width + source_width))

	# --- Helper for printing quantities ---
	function print_quantity(name, val1, val2 = nothing, unit = "", source = "[INPUT]")
		label_width = 35
		val_width = 12
		delta_width = 12
		unit_width = 8
		source_width = 12

		if isnothing(val2)
			# Single input
			println(
				rpad(name, label_width),
				rpad(string(val1), val_width),
				rpad(unit, unit_width),
				rpad(source == "[INPUT]" ? blue(source) : green(source), source_width),
			)
		else
			# Compute delta if numeric
			delta = (isa(val1, Number) && isa(val2, Number)) ? round(val2 - val1, sigdigits = 4) : ""
			delta_colored = (delta != "" && delta != 0) ? yellow(delta) : delta

			println(
				rpad(name, label_width),
				rpad(string(val1), val_width), " | ",
				rpad(string(val2), val_width), " | ",
				rpad(delta_colored, delta_width), " | ",
				rpad(unit, unit_width), " | ",
				rpad(source == "[INPUT]" ? blue(source) : green(source), source_width),
			)
		end
	end



	# --- Input quantities ---
	print_quantity("Nominal Voltage", get(cell["Cell"], "NominalVoltage", "N/A"),
		isnothing(cell_2) ? nothing : get(cell_2["Cell"], "NominalVoltage", "N/A"), "V", "[INPUT]")
	print_quantity("Nominal Capacity", get(cell["Cell"], "NominalCapacity", "N/A"),
		isnothing(cell_2) ? nothing : get(cell_2["Cell"], "NominalCapacity", "N/A"), "Ah", "[INPUT]")

	# --- Calculated quantities ---
	calc_keys = ["Cell Theoretical Capacity", "Cell N:P Ratio", "Cell Mass",
		"Positive Electrode Mass Loading", "Negative Electrode Mass Loading"]

	units_map = Dict(
		"Cell Theoretical Capacity" => "Ah",
		"Cell N:P Ratio" => "-",
		"Cell Mass" => "g",
		"Positive Electrode Mass Loading" => "g/m²",
		"Negative Electrode Mass Loading" => "g/m²",
	)

	for key in calc_keys
		val1 = safe_val(kpis1, key)
		val2 = isnothing(kpis2) ? nothing : safe_val(kpis2, key)
		unit = get(units_map, key, "")
		print_quantity(key, val1, val2, unit, "[CALCULATED]")
	end

	println(bold("\n════════════════════════════════════════════════════════════════════════════"))
end




# Format link depending on output format
function format_link(label::String, url::String, width::Int, fmt::Symbol)
	link = begin
		if fmt == :markdown
			parse("[$label]($url)")
		elseif fmt == :ansi
			"\e]8;;$url\e\\$label\e]8;;\e\\"
		else
			"$url"
		end
	end

	return fmt == :markdown ? link : rpad(link, width)
end

# Environment detection
function detect_output_format()
	# Check if running in IJulia (Jupyter)
	if isdefined(Main, :IJulia) && Main.IJulia.inited
		return :markdown
		# Check if Markdown display is available (e.g., in VSCode or other notebooks)
	elseif get(ENV, "JULIA_EDITOR", "") == "code" || get(ENV, "VSCODE_PID", "") != ""
		return :markdown
	elseif get(ENV, "LITERATE_RUNNING", "") == "true"
		return :markdown
	elseif get(ENV, "TERM", "") != "dumb"
		return :ansi
	else
		return :plain
	end
end

"""
	print_default_input_sets_info()

Prints a structured overview of all available default input sets for battery simulations, including high-level summaries and detailed metadata for each set.

# Behavior
- Scans the `defaults/` directory (located relative to the script file) for available JSON input sets organized by category (subfolders).
- Prints:
  1. 📋 A concise aligned list of categories and their corresponding default set names.
  2. 📖 A detailed description for each default set, including:
	 - Cell name and case
	 - Source (with optional formatted link)
	 - Supported models
	 - Set description

- Metadata is extracted using helper functions such as `read_meta_data` and `read_source_from_meta_data`, which pull structured data (e.g., description, model support) from the JSON files.

# Output
- Prints directly to the console using `println`, formatted for clarity with Unicode symbols and horizontal dividers.
- Output includes:
  - Folder/category names (e.g., `CellParameters"`)
  - Available JSON set names (e.g., `"Chen2020"`)
  - Descriptions and intended use cases for each set

# Use Case
- Helps users quickly understand what predefined inputs are available for simulation without needing to inspect the files manually.
- Useful for educational purposes, rapid prototyping, or configuration setup.

# Notes
- Only `.json` files are considered valid input sets.
- Requires that the `defaults/` directory structure and expected metadata fields are present and correctly formatted.
"""
function print_default_input_sets_info()
	output_fmt = detect_output_format()
	script_dir = @__DIR__
	defaults_dir = joinpath(script_dir, "defaults")
	entries = readdir(defaults_dir; join = true)

	category_col_width = 25

	println("\n", "="^100)
	println("📋 Overview of Available Default Sets")
	println("="^100, "\n")

	# Concise Aligned Overview
	for entry in entries
		if isdir(entry)
			folder_name = basename(entry)
			files = readdir(entry; join = true)

			set_names = String[]
			for file in files
				if isfile(file) && splitext(file)[2] == ".json"
					push!(set_names, splitext(basename(file))[1])
				end
			end

			options_str = isempty(set_names) ? "-" : join(set_names, ", ")
			println("📁 ", rpad(folder_name * ":", category_col_width), options_str)
		end
	end

	# Detailed Descriptions
	println("\n", "="^100)
	println("📖 Detailed Descriptions")
	println("="^100, "\n")

	for entry in entries
		if isdir(entry)
			folder_name = basename(entry)
			println("📂 $folder_name")
			println("-"^100)

			files = readdir(entry; join = true)
			for file in files
				if isfile(file) && splitext(file)[2] == ".json"
					file_name = splitext(basename(file))[1]

					# Read metadata
					description, cell_name, cell_case, models = read_meta_data(file)  # updated helper to also return full metadata dict
					source = read_source_from_meta_data(file)

					link = (isnothing(source) || source == "-") ? nothing : format_link("visit", source, 50, output_fmt)

					println(file_name)

					if !isnothing(cell_name)
						println("🔹 Cell name:       	", cell_name)
					end

					if !isnothing(cell_case)
						println("🔹 Cell case:       	", cell_case)
					end

					if !isnothing(link)
						println("🔹 Source:          	", link)
					end


					if models isa Dict
						println("🔹 Suitable for:")
						for (k, v) in models
							val_str = isa(v, AbstractVector) ? join(v, ", ") : string(v)
							println("   • ", rpad(k * ":", 20), val_str)
						end
					end

					if !isempty(description)
						println("🔹 Description:     	", description)
					end

					println()  # Extra space between sets
				end
			end
		end
	end
end




function terminal_link(text, url)
	return "\e]8;;$url\a$text\e]8;;\a"
end

function padded_link(text, url, width)
	link = terminal_link(text, url)
	pad_spaces = max(width - length(text), 0)
	return link * " "^pad_spaces
end

function read_cell_information(file::String)
	content = read(file, String)

	if isempty(strip(content))
		return "(File is empty or not valid JSON)"
	end

	json_file = JSON.parse(content)
	try
		if haskey(json_file, "Cell") && haskey(json_file["Cell"], "Name")
			cell_name = String(json_file["Cell"]["Name"])
		else
			cell_name = "-"
		end
		if haskey(json_file, "Cell") && haskey(json_file["Cell"], "Case")
			cell_case = String(json_file["Cell"]["Case"])
		else
			cell_case = " "
		end
		return (cell_name, cell_case)
	catch e
		return "(Invalid metadata format)"
	end


end

function read_meta_data(file::String)
	content = read(file, String)

	if isempty(strip(content))
		return "(File is empty or not valid JSON)"
	end

	json_file = JSON.parse(content)

	if haskey(json_file, "Metadata") && haskey(json_file["Metadata"], "Models")
		models = json_file["Metadata"]["Models"]
	else
		models = ""
	end

	if haskey(json_file, "Cell")
		cell_name, cell_case = read_cell_information(file)

		if haskey(json_file, "Metadata") && haskey(json_file["Metadata"], "Description")
			description = String(json_file["Metadata"]["Description"])
		else
			description = ""
		end

	else

		if haskey(json_file, "Metadata") && haskey(json_file["Metadata"], "Description")
			description = String(json_file["Metadata"]["Description"])
		else
			description = ""
		end

		cell_name = nothing
		cell_case = nothing
	end
	return description, cell_name, cell_case, models
end

function read_source_from_meta_data(file::String)
	content = read(file, String)

	if isempty(strip(content))
		return "(File is empty or not valid JSON)"
	end

	json_file = JSON.parse(content)
	try
		if haskey(json_file, "Metadata") && haskey(json_file["Metadata"], "Source")
			return String(json_file["Metadata"]["Source"])
		end
	catch e
		return "(Invalid metadata format)"
	end

	return nothing
end


"""
	print_submodels_info()

Prints an overview of configurable submodels available within the simulation framework, including valid options and documentation links.

# Behavior
- Retrieves model configuration metadata using `get_setting_meta_data()`.
- Filters the metadata to include only entries marked with `"is_sub_model" => true`.
- Extracts:
  - The submodel parameter name
  - The list of valid options (or `"N/A"` if not specified)
  - A documentation link (if available)
- Prints a well-formatted table summarizing each submodel, with aligned columns:
  - **Parameter** – the submodel key name (e.g., `"electrolyte_transport"`)
  - **Options** – available values that can be assigned to the parameter
  - **Documentation** – a URL (formatted with `format_link`) or `-` if missing

# Output
- Directly prints a structured table to the console.
- Uses consistent width formatting for readability.
- Includes Unicode symbols and horizontal lines for visual structure.

# Use Case
- Helps users understand which submodels are configurable and how to select between them.
- Useful for exploring model flexibility and guiding configuration in notebooks, scripts, or GUIs.
"""
function print_submodels_info()
	# Get the metadata dictionary
	meta_data = get_model_settings_meta_data()

	# Filter parameters with "is_sub_model" == true
	submodel_params = []
	for (param, info) in meta_data
		if get(info, "category", nothing) == "ModelSettings"
			options = get(info, "options", "N/A")
			doc_url = get(info, "documentation", nothing)
			options_str = isa(options, AbstractArray) ? join(options, ", ") : string(options)
			push!(submodel_params, (param, options_str, doc_url))
		end
	end

	# If there are no submodel parameters, print a message
	if isempty(submodel_params)
		println("No submodel parameters found.")
		return
	end

	# Print the submodels information with the same design as your example
	println("="^100)
	println("ℹ️  Submodels Information")
	println("="^100)

	# Table header
	header1 = "Parameter"
	header2 = "Options"
	header3 = "Documentation"

	output_fmt = detect_output_format()

	println(rpad(header1, 30), rpad(header2, 50), header3)
	println("-"^100)

	# Print each parameter and its options
	for (param, options, doc_url) in submodel_params
		if isnothing(doc_url)
			url = rpad("-", 10)
		else
			url = doc_url == "-" ? "-" : format_link("visit", doc_url, 50, output_fmt)
		end
		println(rpad(param, 30), rpad(options, 50), url)
	end

	println()  # Extra line after the table
end


"""
	print_setting_info(from_name::String)

Displays detailed metadata for any model or simulation setting whose name matches (fully or partially) the provided `from_name` string.

# Arguments
- `from_name::String`: A (partial or full) string used to search for matching parameter names in the settings metadata.

# Behavior
- Performs a case-insensitive fuzzy match across all available setting keys.
- For each matching setting, prints detailed metadata including:
  - Name
  - Description
  - Allowed types
  - Units (if specified)
  - Valid options
  - Validation bounds (min/max values)
  - Documentation links
  - Ontology (context IRI) links

- Uses Unicode symbols and structured formatting to produce readable output.
- Uses helper functions like `get_setting_meta_data()` and `format_link()` to retrieve metadata and produce clickable/documented links depending on output format.

# Output
- If no matches are found: prints a ❌ message indicating no results.
- If matches are found: prints a block of detailed metadata for each, separated by horizontal lines.
"""
function print_setting_info(from_name::String; category::Union{Nothing, String} = nothing)
	# Get the metadata dictionary
	meta_data_mod = get_model_settings_meta_data()
	meta_data_sim = get_simulation_settings_meta_data()
	meta_data_solv = get_solver_settings_meta_data()
	meta_data_1 = merge_dict(meta_data_mod, meta_data_sim)
	meta_data = merge_dict(meta_data_1, meta_data_solv)
	output_fmt = detect_output_format()

	if !isnothing(category)
		# Filter meta_data by category if provided
		meta_data = Dict(k => v for (k, v) in meta_data if get(v, "category", nothing) == category)
	end

	# Soft match: find keys containing `from_name` (case-insensitive)
	matches = collect(filter(key -> occursin(lowercase(from_name), lowercase(key)), keys(meta_data)))

	if isempty(matches)
		println("❌ No settings found matching: ", from_name)
	else
		for actual_key in matches
			param_info = meta_data[actual_key]

			println("="^80)
			println("ℹ️  Setting Information")
			println("="^80)

			# Name
			println("🔹 Name:         	", actual_key)

			# category
			if haskey(param_info, "category")
				category = param_info["category"]
				println("🔹 Category:		", category)
			end

			# Variable name
			if haskey(param_info, "variable_name")
				var_name = param_info["variable_name"]
				println("🔹 Keyword argument:	", var_name)
			end

			# Type
			if haskey(param_info, "type")
				types = param_info["type"]
				types_str = isa(types, AbstractArray) ? join(types, ", ") : string(types)
				println("🔹 Type:         	", types_str)
			end

			# Unit
			if haskey(param_info, "unit")
				println("🔹 Unit:         	", param_info["unit"])
			end

			# Options
			if haskey(param_info, "options")
				options = param_info["options"]
				options_str = isa(options, AbstractArray) ? join(options, ", ") : string(options)
				println("🔹 Options:      	", options_str)
			end

			# Validation bounds
			if haskey(param_info, "min_value")
				min_value = param_info["min_value"]
				println("🔹 Minimum value:      	", min_value)
			end
			if haskey(param_info, "max_value")
				max_value = param_info["max_value"]
				println("🔹 Maximum value:      	", max_value)
			end

			# Documentation
			doc_url = get(param_info, "documentation", nothing)
			if isnothing(doc_url) || doc_url == "-"
				link = "-"
			elseif doc_url isa String
				link = format_link("visit", doc_url, 50, output_fmt)
			end
			if @isdefined link
				println("🔹 Documentation:	", link)
			end

			# Ontology
			context_type_iri = get(param_info, "context_type_iri", nothing)
			if isnothing(context_type_iri) || context_type_iri == "-"
				iri = "-"
			elseif context_type_iri isa String
				iri = format_link("visit", context_type_iri, 50, output_fmt)
			end
			if @isdefined iri
				println("🔹 Ontology link:	", iri)
			end

			# Description
			if haskey(param_info, "description")
				description = param_info["description"]
				println("🔹 Description:		", description)
			end

			println()  # Extra spacing between entries
		end
	end
end


"""
	print_parameter_info(from_name::String)

Prints detailed metadata for physical or model parameters whose names match (fully or partially) the provided `from_name` string.

# Arguments
- `from_name::String`: A case-insensitive search term used to match parameter names from the metadata registry.

# Behavior
- Loads parameter metadata using `get_parameter_meta_data()`.
- Performs a fuzzy search for parameter names containing the given `from_name` string.
- For each matched parameter, prints:
  - Parameter name
  - Description (if available)
  - Accepted types
  - Units
  - List of allowed options (if any)
  - Minimum and maximum bounds (if defined)
  - Documentation URL (formatted using `format_link`)
  - Ontology/context type IRI link (if provided)

# Output
- Prints the information directly to the console in a structured, readable format with aligned labels and Unicode icons.
- If no parameters match the search, a ❌ warning message is printed.

# Returns
- Nothing (side-effect only: prints to console).
"""
function print_parameter_info(from_name::String)
	# Get the metadata dictionary
	meta_data = get_parameter_meta_data()
	output_fmt = detect_output_format()

	# Soft match: find keys containing `from_name` (case-insensitive)
	matches = collect(filter(key -> occursin(lowercase(from_name), lowercase(key)), keys(meta_data)))

	if isempty(matches)
		println("❌ No parameters found matching: ", from_name)
	else
		for actual_key in matches
			param_info = meta_data[actual_key]

			println("="^80)
			println("ℹ️  Parameter Information")
			println("="^80)

			# Name
			println("🔹 Name:         	", actual_key)

			# Type
			if haskey(param_info, "type")
				types = param_info["type"]
				types_str = isa(types, AbstractArray) ? join(types, ", ") : string(types)
				println("🔹 Type:         	", types_str)
			end

			# Unit
			if haskey(param_info, "unit")
				println("🔹 Unit:         	", param_info["unit"])
			end

			# Options
			if haskey(param_info, "options")
				options = param_info["options"]
				options_str = isa(options, AbstractArray) ? join(options, ", ") : string(options)
				println("🔹 Options:      	", options_str)
			end

			# Validation bounds
			if haskey(param_info, "min_value")
				min_value = param_info["min_value"]
				println("🔹 Minimum value:      	", min_value)
			end
			if haskey(param_info, "max_value")
				max_value = param_info["max_value"]
				println("🔹 Maximum value:      	", max_value)
			end

			# Documentation
			doc_url = get(param_info, "documentation", nothing)
			if isnothing(doc_url) || doc_url == "-"
				link = "-"
			elseif doc_url isa String
				link = format_link("visit", doc_url, 50, output_fmt)
			end
			if @isdefined link
				println("🔹 Documentation:	", link)
			end

			# Ontology
			context_type_iri = get(param_info, "context_type_iri", nothing)
			if isnothing(context_type_iri) || context_type_iri == "-"
				iri = "-"
			elseif context_type_iri isa String
				iri = format_link("visit", context_type_iri, 50, output_fmt)
			end
			if @isdefined iri
				println("🔹 Ontology link:	", iri)
			end

			# Description
			if haskey(param_info, "description")
				description = param_info["description"]
				println("🔹 Description:		", description)
			end

			println()  # Extra spacing between entries
		end
	end
end
