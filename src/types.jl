import JSON
import MAT

########################################################
#Types to simplify reading data from different formats
########################################################
abstract type InputFile end

struct MatlabFile <: InputFile
    source::Symbol
    object
    function MatlabFile(file::Symbol) #Read from stored mat file
        return new(file, MAT.matread(file))
    end
    function MatlabFile(file::Symbol,object) #Used when we launch julia from matlab
        return new(file,object)
    end
end

struct JSONFile <: InputFile
    source::Symbol
    object::Dict{String,Any}
    function JSONFile(file::Symbol)
        return new(file,JSON.parsefile(file))
    end
end

###############################################
#Setup object
###############################################

struct SetupObject
    model
    state0
    parameters
    stateref
end