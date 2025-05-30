
function get_nested_json_value(x::ParameterSet, key::Vector{String})
    return get_nested_json_value(x.all, key)
end

function get_nested_json_value(x::AbstractDict, key::Vector{String})
    for k in key
        x = x[k]
    end
    return x
end

function set_nested_json_value!(x::ParameterSet, key::Vector{String}, value)
    return set_nested_json_value!(x.all, key, value)
end

function set_nested_json_value!(x::AbstractDict, key::Vector{String}, value)
    for k in key[1:end-1]
        x = x[k]
    end
    x[key[end]] = value
end
