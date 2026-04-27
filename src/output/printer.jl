"""
	print_overview(output::SimulationOutput)

Print a structured summary of the output variables available in a simulation result.

# Description
Recursively traverses `time_series`, `states`, and `metrics` and prints the available
quantities in the same path-oriented style used by `print_info(input::ParameterSet)`.

# Arguments
- `output::SimulationOutput`: Simulation output to inspect.

# Example
```julia
print_overview(output)
```
"""
function print_overview(output::SimulationOutput)
    meta_data = get_output_variables_meta_data()
    case_groups = Dict(
        "time_series" => NamedTuple[],
        "states" => NamedTuple[],
        "metrics" => NamedTuple[],
    )

    function collect_outputs!(d::AbstractDict{String, Any}, category::String, prefix::Vector{String} = String[])
        for (k, v) in sort(collect(d); by = first)
            path = vcat(prefix, string(k))
            if v isa AbstractDict{String, Any}
                collect_outputs!(v, category, path)
            else
                push!(case_groups[category], (category = category, path = path, key = string(k), value = v, type = typeof(v)))
            end
        end
        return
    end

    collect_outputs!(output.time_series, "time_series")
    collect_outputs!(output.states, "states")
    collect_outputs!(output.metrics, "metrics")
    total_params = sum(length(values) for values in values(case_groups))

    par_space = 105
    unit_space = 20
    shape_space = 30

    println("\nOUTPUT OVERVIEW")
    println("="^(par_space + unit_space + shape_space))
    println(rpad("Variable", par_space), rpad("Unit", unit_space), rpad("Shape", shape_space))
    println("-"^(par_space + unit_space + shape_space))

    function output_metadata_key(category::String, path::Vector{String})
        if category == "states"
            for flat_key in keys(meta_data)
                info = meta_data[flat_key]
                if get(info, "case", nothing) == "states" && output_state_path(flat_key) == path
                    return flat_key
                end
            end
            return last(path)
        else
            return last(path)
        end
    end

    function print_group(title, group_params)
        isempty(group_params) && return
        println("\n$(uppercase(title))")
        println("="^(par_space + unit_space + shape_space))
        println(rpad("Variable", par_space), rpad("Unit", unit_space), rpad("Shape", shape_space))
        println("-"^(par_space + unit_space + shape_space))

        for p in group_params
            full_path = join(["[ \"$(s)\" ]" for s in p.path], "")
            meta_key = output_metadata_key(p.category, p.path)
            info = get(meta_data, meta_key, Dict())
            unit = get(info, "unit", "N/A")
            shape_str = get(info, "shape", output_value_shape(p.value))

            println(
                rpad(full_path, par_space),
                rpad(unit, unit_space),
                rpad(shape_str, shape_space),
            )
        end

        return println("="^(par_space + unit_space + shape_space))
    end

    print_group("time_series", case_groups["time_series"])
    print_group("states", case_groups["states"])
    print_group("metrics", case_groups["metrics"])

    return println("Total output variables: $(total_params)")
end

function output_value_shape(v)
    if v isa AbstractArray
        return "(" * join(size(v), ", ") * ")"
    elseif v isa BattMoPosition
        return "(mesh)"
    else
        return "N/A"
    end
end
