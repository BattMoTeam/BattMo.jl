import JSON
import MAT

export readBattMoMatlabInputFile, readBattMoJsonInputFile


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


