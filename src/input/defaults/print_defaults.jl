export print_default_parameter_sets


function print_default_parameter_sets()
	script_dir = @__DIR__  # Directory where this script is located
	entries = readdir(script_dir; join = true)

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
