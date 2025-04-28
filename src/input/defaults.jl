export parameter_file_path

"""
    parameter_file_path("cell_parameters", "Chen2020_calibrated")
    parameter_file_path("cell_parameters", "Chen2020_calibrated.json")

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
    return parameter_file_path(joinpath(typename, fname*ext), check = check)
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

