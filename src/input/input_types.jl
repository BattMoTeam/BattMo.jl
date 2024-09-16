export
    AbstractInputParams,
    InputParams,
    MatlabInputParams,
    InputGeometryParams,
    mergeInputParams

abstract type AbstractInputParams end

""" All AbstractInputParams are expected to have a dict property"""
abstract type DictInputParams <: AbstractInputParams end

function Base.getindex(input::DictInputParams, keyname)
    return input.dict[keyname]
end

function Base.haskey(input::DictInputParams, keyname)
    return haskey(input.dict, keyname)
end

struct InputParams <: DictInputParams
    dict::Dict{String, Any}
end

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
        
function mergeInputParams(inputparams1::T, inputparams2::T; warn = false) where {T <: DictInputParams}

    dict1 = inputparams1.dict
    dict2 = inputparams2.dict

    combiner(d1, d2) = recursiveMergeDict(d1, d2; warn = warn)
    dict = mergewith!(combiner, dict1, dict2)

    return T(dict)
    
end



