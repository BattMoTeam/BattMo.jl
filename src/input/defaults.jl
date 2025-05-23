export parameter_file_path, generate_default_parameter_files

"""
	parameter_file_path("cell_parameters", "Chen2020")
	parameter_file_path("cell_parameters", "Chen2020.json")

Get the path to the default parameter file for a given type and filename. The
.json extension is added if not provided. If `check` is true, an error is thrown
if the file does not exist.
"""
function parameter_file_path

end


function parameter_file_path(typename::AbstractString, filename::AbstractString; check = true)
	fname, ext = splitext(filename)
	if lowercase(ext) == ".json" || ext == ""
		ext = ".json"
	else
		if check
			error("File extension must be .json")
		end
	end
	return parameter_file_path(joinpath(typename, fname * ext), check = check)
end

function parameter_file_path(fname::AbstractString; check = true)
	fpth = joinpath(defaults_folder_path(), fname)
	if check && !isfile(fpth)
		error("File not found at $fpth for requested file $fname")
	end
	return fpth
end

function parameter_file_path(; check = true)
	fpth = defaults_folder_path()
	if check && !isdir(fpth)
		error("Folder not found at $fpth. This is likely a BattMo.jl issue. Please file an issue on our GitHub page.")
	end
	return fpth
end

function defaults_folder_path()
	battmo_root = pkgdir(BattMo)
	return normpath(battmo_root, "src", "input", "defaults")
end

"""
	generate_default_parameter_files()
	generate_default_parameter_files("/some/path", force = true)
	generate_default_parameter_files("/some/path", name = "my_json_files")

Make a local copy of the default JSON parameter files in the specified directory. The
default name is "battmo_json". If the directory already exists, an error is thrown
unless `force` is set to true. The default path is the current working directory.
"""
function generate_default_parameter_files(
	pth = pwd(),
	name = "battmo_json";
	print = true,
	force = false,
)
	if !ispath(pth)
		error("Destination $pth does not exist. Specify a folder.")
	end
	dest = joinpath(pth, name)
	json_dir = defaults_folder_path()

	if ispath(dest)
		if !force
			error("Folder $name already already exists in $pth. Specify force = true, or choose another name.")
		end
	end
	cp(json_dir, dest, force = force)
	if print
		println("🛠 JSON files successfully written! Path:\n\t$dest")
	end
	chmod(dest, 0o777, recursive = true)
	return dest
end
