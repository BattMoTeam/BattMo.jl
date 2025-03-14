import JSON
import MAT

export readBattMoMatlabInputFile, readBattMoJsonInputFile, load_parameters

#########################################
# Functions to loading parameter sets
#########################################


function load_parameters(source::Union{String,Dict}, ::Type{T}) where {T <: Union{BattMoInputParameters,CellParameters,CyclingParameters,ModelParameters}} 

    if source isa String
        parameter_object = T(JSON.parsefile(source))
    else
        parameter_object = T(source)
    end
    return parameter_object
end

function load_parameters(source::Union{String,Dict}, ::Type{MatlabInputParameters})

    if source isa String
        parameter_object = MatlabInputParameters(MAT.matread(source))
    else
        parameter_object = MatlabInputParameters(source)
    end
    return parameter_object
end

function load_parameters(source::Union{String,Dict}, ::Type{}) 

    if source isa String
        parameter_object = CellParameters(JSON.parsefile(source))
    else
        parameter_object = CellParameters(source)
    end
    return parameter_object
end

function load_parameters(source::Union{String,Dict}, ::Type{BPXCellParameters}) 

    if source isa String
        bpx_object = BPXCellParameters(JSON.parsefile(source))
    else
        bpx_object = BPXCellParameters(source)
    end

    # parameter_object = bpx_to_battmo(bpx_object)

    return parameter_object
end



""" 
   readBattMoMatlabInputFile(inputFileName::String)

Reads the input from a matlab output file which contains a description of the model and returns an `MatlabInputParams`
that can be sent to the simulator.

# Arguments

- `inputFileName ::String` : filename of the input

# Returns
An instance of [`MatlabInputParams`](@ref) that can be sent to the simulator via [`run_battery`](@ref)
"""
function readBattMoMatlabInputFile(inputFileName::String)
    inputparams = MatlabInputParams(MAT.matread(inputFileName))
    return inputparams
end

""" 
   readBattMoJsonInputFile(inputFileName::String)

Reads the input file in JSON format and returns the input parameters as a dictionary

# Arguments

- `inputFileName ::String` : name of the json file that contains the input

# Returns
An instance of [`InputParams`](@ref) that can be sent to the simulator via [`run_battery`](@ref)
"""
function readBattMoJsonInputFile(inputFileName::String)
    inputparams = InputParams(JSON.parsefile(inputFileName))
    return inputparams
end


