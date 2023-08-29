import JSON
import MAT

export InputFile, MatlabFile, JSONFile 

########################################################
#Types to simplify reading data from different formats
########################################################
abstract type InputFile end

struct MatlabFile <: InputFile
    source::String
    object::Dict{String,Any}
    use_state_ref::Bool
    function MatlabFile(file::String; 
        state_ref::Bool=true) #Read from stored mat file
        
        return new(file, MAT.matread(file),state_ref)
    end
    function MatlabFile(file::String,
        object::Dict{String,Any};
        state_ref::Bool=false) #Used when we launch julia from matlab
        
        return new(file,object,state_ref)
    end
end

struct JSONFile <: InputFile
    source::String
    object::Dict{String,Any}
    function JSONFile(file::String)
        return new(file,JSON.parsefile(file))
    end
end
