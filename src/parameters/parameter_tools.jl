export 
    setup_ocp_evaluation_expression_from_string, 
    setup_diffusivity_evaluation_expression_from_string,
    setup_conductivity_evaluation_expression_from_string,
    readBattMoMatlabInputFile, readBattMoJsonInputFile

using JSON
import MAT


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



function setup_ocp_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the OCP function, with the proper signature."""

    str = "function f(c, T, refT, cmax) return $str end"
    return Meta.parse(str);
    
end

function setup_diffusivity_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the electrolyte diffusivity function, with the proper signature."""

    str = "function f(c, T) return $str end"
    return Meta.parse(str);
    
end

function setup_conductivity_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the electrolyte conductivity function, with the proper signature."""
    
    str = "function f(c, T) return $str end"
    return Meta.parse(str);
    
end

