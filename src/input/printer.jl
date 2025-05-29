export print_default_input_sets_info, print_submodels_info, print_parameter_info


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

