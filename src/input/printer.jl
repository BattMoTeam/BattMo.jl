export print_cell_info, print_default_input_sets_info, print_submodels_info, print_parameter_info, print_setting_info


function print_cell_info(cell_parameters::CellParameters)
	# --- ANSI Colors ---
	green(s) = "\033[92m$(s)\033[0m"
	yellow(s) = "\033[93m$(s)\033[0m"
	blue(s) = "\033[94m$(s)\033[0m"
	red(s) = "\033[91m$(s)\033[0m"
	bold(s) = "\033[1m$(s)\033[0m"

	# --- Helper: detect if value is CONST, FUNC, or DICT ---
	function param_status(val)
		if isa(val, Number)
			return green("CONST ✓")
		elseif isa(val, AbstractString)
			return yellow("FUNC")
		elseif isa(val, Dict)
			return yellow("FUNC")
		else
			return red("UNKNOWN ❓")
		end
	end

	# --- KPI dictionary inside ---
	cell_kpis_from_set = Dict(
		"Positive Electrode Coating Mass" =>
			compute_electrode_coating_mass(cell_parameters, "PositiveElectrode"),
		"Negative Electrode Coating Mass" =>
			compute_electrode_coating_mass(cell_parameters, "NegativeElectrode"),
		"Separator Mass" =>
			compute_separator_mass(cell_parameters),
		"Electrolyte Mass" =>
			compute_electrolyte_mass(cell_parameters),
		"Cell Mass" =>
			compute_cell_mass(cell_parameters),
		"Cell Volume" =>
			compute_cell_volume(cell_parameters),
		"Positive Electrode Mass Loading" =>
			compute_electrode_mass_loading(cell_parameters, "PositiveElectrode"),
		"Negative Electrode Mass Loading" =>
			compute_electrode_mass_loading(cell_parameters, "NegativeElectrode"),
		"Cell Theoretical Capacity" =>
			compute_cell_theoretical_capacity(cell_parameters),
		"Cell N:P Ratio" =>
			compute_np_ratio(cell_parameters),
	)

	# --- Safe KPI accessor ---
	function safe_kpi(name)
		try
			val = cell_kpis_from_set[name]
			return round(val, sigdigits = 4)
		catch
			return red("ERR")
		end
	end

	# --- Header ---
	println(bold("\n─────────────────────────────"))
	println(bold("\n🔋 Quick Cell Check"))
	println(bold("─────────────────────────────"))
	println("Title: ", get(cell_parameters["Metadata"], "Title", "Unknown"))

	# --- Minimal KPIs ---
	println("\n" * bold("📏 Core quantities"))
	println("  Nominal Voltage:        ", haskey(cell_parameters["Cell"], "NominalVoltage") ? cell_parameters["Cell"]["NominalVoltage"] : nothing, " V")
	println("  Nominal Capacity:       ", haskey(cell_parameters["Cell"], "NominalCapacity") ? cell_parameters["Cell"]["NominalCapacity"] : nothing, " Ah")
	println("  Theoretical Capacity:   ", safe_kpi("Cell Theoretical Capacity"), " Ah")
	println("  N:P Ratio:               ", safe_kpi("Cell N:P Ratio"))
	println("  Cell Mass:               ", safe_kpi("Cell Mass"), " g")
	println("  Pos. Mass Loading:       ", safe_kpi("Positive Electrode Mass Loading"), " mg/cm²")
	println("  Neg. Mass Loading:       ", safe_kpi("Negative Electrode Mass Loading"), " mg/cm²")

	# --- Functional Status ---
	println("\n" * bold("🧠 Functional Status"))
	neg = cell_parameters["NegativeElectrode"]["ActiveMaterial"]
	pos = cell_parameters["PositiveElectrode"]["ActiveMaterial"]
	elec = cell_parameters["Electrolyte"]

	println("  Neg. Diffusion Coeff:     ", param_status(neg["DiffusionCoefficient"]))
	println("  Neg. OCP:                 ", param_status(neg["OpenCircuitPotential"]))
	println("  Neg. Reaction Rate:       ", param_status(neg["ReactionRateConstant"]))
	println("  Pos. Diffusion Coeff:     ", param_status(pos["DiffusionCoefficient"]))
	println("  Pos. OCP:                 ", param_status(pos["OpenCircuitPotential"]))
	println("  Pos. Reaction Rate:       ", param_status(pos["ReactionRateConstant"]))
	println("  Electrolyte Conductivity: ", param_status(elec["IonicConductivity"]))
	println("  Electrolyte Diffusion:    ", param_status(elec["DiffusionCoefficient"]))

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
	meta_data = get_setting_meta_data()

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
	meta_data = get_setting_meta_data()
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
