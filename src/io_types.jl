import JSON
import MAT

export InputFile, MatlabFile, JSONFile 

########################################################
#Types to simplify reading data from different formats
########################################################
abstract type InputFile end

struct MatlabFile <: InputFile
    inputFileName::String
    object::Dict{String, Any}
    use_state_ref::Bool
    function MatlabFile(inputFileName::String; 
                        use_state_ref::Bool = true) # Read from stored mat file
        return new(inputFileName, MAT.matread(inputFileName), use_state_ref)
    end
    function MatlabFile(inputFileName::String,
                        data::Dict{String, Any};
                        use_state_ref::Bool = false) # Used when we launch julia from matlab
        return new(inputFileName, data, use_state_ref)
    end
end

struct JSONFile <: InputFile
    inputFileName::Union{String, Missing}
    object::Dict{String, Any}
end

function JSONFile(inputFileName::String)
    return JSONFile(inputFileName, JSON.parsefile(inputFileName))
end

function JSONFile(object::Dict{String, Any})
    return JSONFile(missing, object)
end


