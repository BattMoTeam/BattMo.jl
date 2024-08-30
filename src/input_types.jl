export InputParams, InputGeometry, InputGeometryParams

abstract type InputParams end

struct InputGeometry <: InputParams
    data::Dict{String, Any}
end

function Base.getindex(input::InputGeometry, fdname)
    return input.data[fdname]
end

struct InputGeometryParams <: InputParams
    data::Dict{String, Any}
end

function Base.getindex(input::InputGeometry, fdname)
    return input.data[fdname]
end
