export print_default_parameter_sets_info, print_submodels_info, print_parameter_info


# Format link depending on output format
function format_link(label::String, url::String, width::Int, fmt::Symbol)
	link = begin
		if fmt == :markdown
			"[$label]($url)"
		elseif fmt == :ansi
			"\e]8;;$url\e\\$label\e]8;;\e\\"
		else
			"$label: $url"
		end
	end
	return rpad(link, width)
end

# Environment detection
function detect_output_format()
	if isdefined(Main, :IJulia) && Main.IJulia.inited
		return :markdown  # Jupyter notebooks
	elseif get(ENV, "LITERATE_RUNNING", "") == "true"
		return :markdown  # Literate.jl environment
	elseif get(ENV, "TERM", "") != "dumb"
		return :ansi       # Rich terminal
	else
		return :plain      # Minimal terminal or unknown
	end
end

function print_default_parameter_sets_info()

	# Column layout
	col1_width = 35
	col2_width = 50

	# Begin main logic
	output_fmt = detect_output_format()
	script_dir = @__DIR__
	defaults_dir = joinpath(script_dir, "defaults")
	entries = readdir(defaults_dir; join = true)

	doc_link = "https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/default_sets"
	doc_link = format_link("documentation", doc_link, 50, output_fmt)
	println("\n")
	println("ℹ️  More detailed information can be found in the $doc_link")

	for entry in entries
		if isdir(entry)
			folder_name = basename(entry)

			println("\n" * "="^(col1_width + col2_width + 40))
			println("📁  $folder_name")
			println("="^(col1_width + col2_width + 40))

			header1 = "Parameter Set"
			header2 = "Description"
			header3 = "Source"

			println(rpad(header1, col1_width), rpad(header2, col2_width), header3)
			println("-"^(col1_width + col2_width + 40))

			files = readdir(entry; join = true)
			for file in files
				if isfile(file)
					ext = splitext(file)[2]
					if ext == ".json"
						file_name = splitext(basename(file))[1]
						description = read_description_from_meta_data(file)
						source = read_source_from_meta_data(file)

						if isnothing(source) || source == "-"
							link = "-"
						else
							link = format_link("visit", source, col2_width, output_fmt)
						end

						println(rpad(file_name, col1_width), rpad(description, col2_width), link)
					end
				end
			end
			println()
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

function read_description_from_meta_data(file::String)
	content = read(file, String)

	if isempty(strip(content))
		return "(File is empty or not valid JSON)"
	end

	json_file = JSON.parse(content)

	if haskey(json_file, "Cell")
		cell_name, cell_case = read_cell_information(file)
		return "$cell_name $cell_case"

	else
		try
			if haskey(json_file, "Metadata") && haskey(json_file["Metadata"], "Description")
				return String(json_file["Metadata"]["Description"])
			end
		catch e
			return "(Invalid metadata format)"
		end

		return "-"
	end
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

function print_submodels_info()
	# Get the metadata dictionary
	meta_data = get_parameter_meta_data()

	# Filter parameters with "is_sub_model" == true
	submodel_params = []
	for (param, info) in meta_data
		if get(info, "is_sub_model", false)
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
	println("="^80)
	println("ℹ️  Submodels Information")
	println("="^80)

	# Table header
	header1 = "Parameter"
	header2 = "Options"
	header3 = "Documentation"

	output_fmt = detect_output_format()

	println(rpad(header1, 30), rpad(header2, 30), header3)
	println("-"^80)

	# Print each parameter and its options
	for (param, options, doc_url) in submodel_params
		if isnothing(doc_url)
			url = rpad("-", 10)
		else
			url = doc_url == "-" ? "-" : format_link("visit", doc_url, 50, output_fmt)
		end
		println(rpad(param, 30), rpad(options, 30), url)
	end

	println()  # Extra line after the table
end



function print_parameter_info(from_name::String)
	# Get the metadata dictionary
	meta_data = get_parameter_meta_data()
	output_fmt = detect_output_format()

	if haskey(meta_data, from_name)
		param_info = meta_data[from_name]

		println("="^80)
		println("ℹ️  Parameter Information")
		println("="^80)

		# Name
		println("🔹 Name:         	", from_name)

		# Description
		if haskey(param_info, "description")
			description = param_info["description"]
			println("🔹 Description:		", description)
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
		if haskey(param_info, "documentation")
			doc_url = param_info["documentation"]
			link = doc_url == "-" ? "-" : format_link("visit", doc_url, 50, output_fmt)
			println("🔹 Documentation:	", link)
		end

		# Ontology
		if haskey(param_info, "context_type_iri")
			context_type_iri = param_info["context_type_iri"]
			iri = context_type_iri == "-" ? "-" : format_link("visit", context_type_iri, 50, output_fmt)
			println("🔹 Ontology link:	", iri)
		end
	else
		println("❌ Parameter not found.")
	end

	println()  # Extra spacing
end

