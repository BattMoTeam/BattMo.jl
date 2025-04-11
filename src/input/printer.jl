export print_default_parameter_sets, print_submodels_info, print_parameter_info


function print_default_parameter_sets()
	script_dir = @__DIR__  # Directory where this script is located
	defaults_dir = joinpath(script_dir, "defaults")
	entries = readdir(defaults_dir; join = true)

	for entry in entries
		if isdir(entry)
			folder_name = basename(entry)
			println("\n" * "="^80)
			println("📁  $folder_name")
			println("="^80)

			# Table header
			header1 = "Parameter Set"
			header2 = "Description"
			println(rpad(header1, 30), header2)
			println("-"^80)

			files = readdir(entry; join = true)
			for file in files
				if isfile(file)
					file_name = splitext(basename(file))[1]  # Remove extension
					description = read_meta_data(file)
					println(rpad(file_name, 30), description)
				end
			end

			println()  # Extra line after each table
		end
	end
end


function read_meta_data(file::String)
	content = read(file, String)

	if isempty(strip(content))
		return "(File is empty or not valid JSON)"
	end

	json_file = JSON.parse(content)
	try
		if haskey(json_file, "Metadata") && haskey(json_file["Metadata"], "Description")
			return String(json_file["Metadata"]["Description"])
		end
	catch e
		return "(Invalid metadata format)"
	end

	return "(No description found)"
end

function print_submodels_info()
	# Get the metadata dictionary
	meta_data = get_parameter_meta_data()

	# Filter parameters with "is_sub_model" == true
	submodel_params = []
	for (param, info) in meta_data
		if get(info, "is_sub_model", false)
			options = get(info, "options", "N/A")
			options_str = isa(options, AbstractArray) ? join(options, ", ") : string(options)
			push!(submodel_params, (param, options_str))
		end
	end

	# If there are no submodel parameters, print a message
	if isempty(submodel_params)
		println("No submodel parameters found.")
		return
	end

	# Print the submodels information with the same design as your example
	println("="^80)
	println("📁  Submodels Information")
	println("="^80)

	# Table header
	header1 = "Parameter"
	header2 = "Options"
	println(rpad(header1, 30), header2)
	println("-"^80)

	# Print each parameter and its options
	for (param, options) in submodel_params
		println(rpad(param, 30), options)
	end

	println()  # Extra line after the table
end

function print_parameter_info(from_name::String)

	# Get the metadata dictionary
	meta_data = get_parameter_meta_data()

	# Find parameter

	if haskey(meta_data, from_name)
		# Print the information
		println("="^80)
		println("📁  Parameter Information")
		println("="^80)

		# Table header
		header1 = "Parameter"
		header2 = "type"

		if haskey(meta_data[from_name], "unit")
			header3 = "unit"
			println(rpad(header1, 30), rpad(header2, 30), header3)
			println("-"^80)
			types = meta_data[from_name]["type"]
			types_str = isa(types, AbstractArray) ? join(types, ", ") : string(types)
			println(rpad(from_name, 30), rpad(types_str, 30), meta_data[from_name]["unit"])
		elseif haskey(meta_data[from_name], "options")
			header3 = "options"
			println(rpad(header1, 30), rpad(header2, 30), header3)
			println("-"^80)
			options = meta_data[from_name]["options"]
			options_str = isa(options, AbstractArray) ? join(options, ", ") : string(options)
			println(rpad(from_name, 30), rpad(meta_data[from_name]["type"], 30), options_str)
		end
	else
		println("Parameter not found.")
	end


	println()  # Extra line after the table
end
