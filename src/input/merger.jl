export merge_input, merge_dict

function merge_input(base::P, new::P; type = "fill", key_path = nothing) where {P <: ParameterSet}

    if typeof(base) != typeof(new)
        error("Cannot merge ParameterSets of different types: $(typeof(base)) and $(typeof(new))")
    end
    base_dict = base.all
    new_dict = new.all

    merged_dict = merge_dict(base_dict, new_dict; type = type, key_path = key_path)
    return P(merged_dict)
end

"""
    merge_dict(base, new; type = "fill", key_path = nothing)

Recursively merge `new` into a deep copy of `base`.

The supported merge types are:
- `"fill"`: add missing values and replace existing values that are `0` or
  `nothing`. Other existing values are preserved.
- `"overwrite"`: recursively replace existing values with values from `new`.
- `"replace"`: replace the entire subtree selected by `key_path`. The
  replacement must exist at the same key in `new`.

`base` and `new` are not modified.

# Examples

Fill missing or empty values:

```julia
base = Dict("x" => 1, "y" => 0)
new = Dict("x" => 9, "y" => 2, "z" => 3)

merged = merge_dict(base, new; type = "fill")
merged == Dict("x" => 1, "y" => 2, "z" => 3)
```

Recursively overwrite only the values supplied by `new`:

```julia
base = Dict("A" => Dict("x" => 1, "y" => 2))
new = Dict("A" => Dict("x" => 9))

merged = merge_dict(base, new; type = "overwrite")
merged == Dict("A" => Dict("x" => 9, "y" => 2))
```

Replace an entire subtree:

```julia
base = Dict("A" => Dict("x" => 1, "y" => 2), "B" => 3)
new = Dict("A" => Dict("x" => 9))

merged = merge_dict(base, new; type = "replace", key_path = "A")
merged == Dict("A" => Dict("x" => 9), "B" => 3)
```
"""
function merge_dict(base::AbstractDict, new::AbstractDict; type = "fill", key_path = nothing)
    merged = deepcopy(base)

    if type == "replace"
        if isnothing(key_path)
            error("The key that is wished to be replaced is not specified.")
        end

        key_path = isa(key_path, String) ? [key_path] : key_path

        current = merged
        for (i, key) in enumerate(key_path)
            if i == length(key_path)
                if haskey(new, key)
                    current[key] = deepcopy(new[key])
                else
                    error("Replacement key '$key' not found in new ParameterSet.")
                end
            else
                if haskey(current, key) && current[key] isa AbstractDict
                    current = current[key]
                else
                    error("Intermediate key '$key' not found or not a Dict in base ParameterSet.")
                end
            end
        end

    elseif type == "overwrite"
        for (k, v) in new
            if haskey(merged, k) && v isa AbstractDict && merged[k] isa AbstractDict
                merged[k] = merge_dict(merged[k], v; type = "overwrite")
            else
                merged[k] = deepcopy(v)
            end
        end
    elseif type == "fill"
        for (k, v) in new
            if haskey(merged, k)
                if v isa AbstractDict && merged[k] isa AbstractDict
                    merged[k] = merge_dict(merged[k], v; type = "fill")
                elseif merged[k] === 0 || merged[k] === nothing
                    merged[k] = deepcopy(v)
                end
            else
                merged[k] = deepcopy(v)
            end
        end
    else
        error("Unknown merge type: $type. Use 'fill', 'overwrite', or 'replace'.")
    end

    return merged
end
