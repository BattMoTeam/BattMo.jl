export
    AbstractInputParams,
    InputParams,
    DictInputParams,
    MatlabInputParams,
    InputGeometryParams,
    mergeInputParams

"Abstract type for all input parameters in BattMo"
abstract type AbstractInputParams end

""" Abstract type for input parameters that have an underlying dictionary structure.

For any structure of this type, it is possible to access and set the values of the object using the same syntax a
standard julia [dictionary](https://docs.julialang.org/en/v1/base/collections/#Dictionaries)
"""
abstract type DictInputParams <: AbstractInputParams end

function Base.getindex(input::DictInputParams, keyname)
    return input.dict[keyname]
end

function Base.setindex!(input::DictInputParams, value, keyname)
    input.dict[keyname] = value
end

function Base.haskey(input::DictInputParams, keyname)
    return haskey(input.dict, keyname)
end

function Base.keys(input::DictInputParams)
    return keys(input.dict)
end

"""
   Input parameter type that is instantiated from a json file, see [`readBattMoJsonInputFile`](@ref).
"""
struct InputParams <: DictInputParams
    dict::Dict{String, Any}
end

"""
   Input parameter type that is instantiated from a matlab output file, see [`readBattMoMatlabInputFile`](@ref).
"""
struct MatlabInputParams <: DictInputParams
    dict::Dict{String, Any}
end


const InputGeometryParams = InputParams

function recursiveMergeDict(d1, d2; warn = false)

    if isa(d1, Dict) && isa(d2, Dict)
        
        combiner(d1, d2) = recursiveMergeDict(d1, d2; warn = warn)
        return mergewith(combiner, d1, d2)
        
    else

        if (d1 != d2) && warn
            println("Some variables have distinct values, we use the value give by the first one")
        end
        
        return d1

    end
end

""" 
   mergeInputParams(inputparams1::T, inputparams2::T; warn = false) where {T <: DictInputParams}


# Arguments

- `inputparams1  ::T` : First input parameter structure
- `inputparams2  ::T` : Second input parameter structure
- `warn = false` : If option `warn` is true, then give a warning when two distinct values are given for the same field. The first value has other precedence.

# Returns
A `DictInputParams` structure whose field are the composition of the two input parameter structures.
"""
function mergeInputParams(inputparams1::T, inputparams2::T; warn = false) where {T <: DictInputParams}

    dict1 = inputparams1.dict
    dict2 = inputparams2.dict

    combiner(d1, d2) = recursiveMergeDict(d1, d2; warn = warn)
    dict = mergewith!(combiner, dict1, dict2)

    return T(dict)
    
end



