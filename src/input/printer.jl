export quick_cell_check, print_default_input_sets, print_submodels


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
			return length(v) > val_space ? v[1:(val_space-4)] * "..." : v
		elseif isa(v, Bool)
			return string(v)
		elseif isa(v, Integer)
			s = string(v)
			return length(s) > val_space ? s[1:(val_space-4)] * "..." : s
		elseif isa(v, AbstractFloat)
			# Compact numeric representation
			abs(v) ≥ 1e4 || abs(v) ≤ 1e-3 ? string(round(v, sigdigits = 5)) :
			string(round(v, digits = 5))
		else
			s = string(v)
			return length(s) > val_space ? s[1:(val_space-4)] * "..." : s
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


function quick_cell_check(cell::CellParameters; cell_2::Union{Nothing, CellParameters} = nothing)
	# --- ANSI Colors ---
	green(s) = "\033[92m$(s)\033[0m"   # calculated
	blue(s) = "\033[94m$(s)\033[0m"    # input
	bold(s) = "\033[1m$(s)\033[0m"
	red(s) = "\033[91m$(s)\033[0m"
	yellow(s) = "\033[93m$(s)\033[0m"

	# --- Helper for visible string padding ---
	function visible_length(s::AbstractString)
		length(replace(s, r"\033\[[0-9;]*m" => ""))  # strip ANSI escape sequences
	end

	function rpad_visible(s::AbstractString, n::Int)
		padlen = n - visible_length(s)
		padlen > 0 ? s * repeat(" ", padlen) : s
	end

	# --- KPI dictionary ---
	function get_kpis(cell::CellParameters)
		Dict(
			"Positive Electrode Coating Mass" => compute_electrode_coating_mass(cell, "PositiveElectrode"),
			"Negative Electrode Coating Mass" => compute_electrode_coating_mass(cell, "NegativeElectrode"),
			"Separator Mass" => compute_separator_mass(cell),
			"Electrolyte Mass" => compute_electrolyte_mass(cell),
			"Cell Mass" => compute_cell_mass(cell),
			"Cell Volume" => compute_cell_volume(cell),
			"Positive Electrode Mass Loading" => compute_electrode_mass_loading(cell, "PositiveElectrode") * 100, # kg/m^2 to mg/cm^2
			"Negative Electrode Mass Loading" => compute_electrode_mass_loading(cell, "NegativeElectrode") * 100, # kg/m^2 to mg/cm^2
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
	label_width = 40
	val_width = 14
	delta_width = 12
	unit_width = 12
	source_width = 12

	total_width = label_width + val_width + (isnothing(cell_2) ? 30 : val_width + delta_width + 30) + unit_width + source_width

	println(bold("═"^total_width))
	println(bold("🔋 Quick Cell Check"))
	println(bold("═"^total_width))

	name_cell_1 = get(cell["Metadata"], "Title", "Cell 1")
	name_cell_2 = isnothing(cell_2) ? "" : get(cell_2["Metadata"], "Title", "Cell 2")

	# --- Column headers ---

	println()
	println(
		rpad_visible("Quantity", label_width),
		rpad_visible(name_cell_1, val_width),
		isnothing(cell_2) ? "" : " | " * rpad_visible(name_cell_2, val_width),
		isnothing(cell_2) ? "" : " | " * rpad_visible("Δ", delta_width),
		" | " * rpad_visible("Unit", unit_width),
		" | " * "Source",
	)

	println("─"^total_width)

	# --- Helper for printing quantities ---
	function print_quantity(name, val1, val2 = nothing, unit = "", source = "[INPUT]")

		if isnothing(val2)
			println(
				rpad_visible(name, label_width),
				rpad_visible(string(val1), val_width),
				" | " * rpad_visible(unit, unit_width),
				" | " * rpad_visible(source == "[INPUT]" ? blue(source) : green(source), source_width),
			)
		else
			delta = (isa(val1, Number) && isa(val2, Number)) ? round(val2 - val1, sigdigits = 4) : ""
			delta_colored = (delta != "" && delta != 0) ? yellow(delta) : delta

			println(
				rpad_visible(name, label_width),
				rpad_visible(string(val1), val_width), " | ",
				rpad_visible(string(val2), val_width), " | ",
				rpad_visible(string(delta_colored), delta_width), " | ",
				rpad_visible(unit, unit_width), " | ",
				rpad_visible(source == "[INPUT]" ? blue(source) : green(source), source_width),
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
		"Cell Mass" => "kg",
		"Positive Electrode Mass Loading" => "mg/cm²",
		"Negative Electrode Mass Loading" => "mg/cm²",
	)

	for key in calc_keys
		val1 = safe_val(kpis1, key)
		val2 = isnothing(kpis2) ? nothing : safe_val(kpis2, key)
		unit = get(units_map, key, "")
		print_quantity(key, val1, val2, unit, "[EQUILIBRIUM CALCULATION]")
	end

	println(bold("═"^total_width))
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
	print_default_input_sets()

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
  - Available JSON set names (e.g., `"chen_2020"`)
  - Descriptions and intended use cases for each set

# Use Case
- Helps users quickly understand what predefined inputs are available for simulation without needing to inspect the files manually.
- Useful for educational purposes, rapid prototyping, or configuration setup.

# Notes
- Only `.json` files are considered valid input sets.
- Requires that the `defaults/` directory structure and expected metadata fields are present and correctly formatted.
"""
function print_default_input_sets()
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
	print_submodels()

Prints an overview of configurable submodels available within the simulation framework, including valid options and documentation links.

# Behavior
- Retrieves model configuration metadata using `get_model_settings_meta_data()`.
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
function print_submodels()
	# Get the metadata dictionary
	meta_data = get_model_settings_meta_data()

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
