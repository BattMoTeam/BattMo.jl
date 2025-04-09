
export validate_parameter_set

abstract type AbstractValidationReport end

"""
	struct SingleIssue
		x::Any
		path::String
		reason::String
		val::Any
	end

"""
struct ValidationReport <: AbstractValidationReport
    issues::Array{SingleIssue,1}
end

# Extending the JSONSchema.show function
function show(io::IO, report::ValidationReport)
    if isempty(report.issues)
        println(io, "Validation successful: No issues found.")
    else
        println(io, "Validation failed with $(length(report.issues)) issues:")
        for (i, issue) in enumerate(report.issues)
            println(io, "Issue $i:")
            show(io, issue)  # Calls the existing show function for SingleIssue
            println(io)  # Separate issues with a blank line for readability
        end
    end
end

function validate_parameter_set(parameters::CellParameters, model_settings::ModelSettings)
    schema = get_schema_cell_parameters(model_settings)

    # Convert schema Dict to JSONSchema object
    schema_obj = Schema(schema)

    # Validate the JSON data
    result = validate(schema_obj, parameters.all)

    log_schema_issues(result.issues, "CellParameters")

    if !isempty(result.issues)
        is_valid = false

    else
        is_valid = true
    end

    return is_valid
end

function validate_parameter_set(
    parameters::SimulationSettings, model_settings::ModelSettings
)
    schema = get_schema_simulation_settings(model_settings)

    # Convert schema Dict to JSONSchema object
    schema_obj = Schema(schema)

    # Validate the JSON data
    result = validate(schema_obj, parameters.all)

    log_schema_issues(result.issues, "SimulationSettings")

    if !isempty(result.issues)
        is_valid = false

    else
        is_valid = true
    end

    return is_valid
end

function validate_parameter_set(parameters::ModelSettings)
    schema = get_schema_model_settings()

    # Convert schema Dict to JSONSchema object
    schema_obj = Schema(schema)

    # Validate the JSON data
    result = validate(schema_obj, parameters.all)

    log_schema_issues(result.issues, "ModelSettings")

    if !isempty(result.issues)
        is_valid = false

    else
        is_valid = true
    end

    return is_valid
end

function validate_parameter_set(parameters::CyclingProtocol)
    schema = get_schema_cycling_protocol()

    # Convert schema Dict to JSONSchema object
    schema_obj = Schema(schema)

    # Validate the JSON data
    result = validate(schema_obj, parameters.all)

    log_schema_issues(result.issues, "CyclingProtocol")

    if !isempty(result.issues)
        is_valid = false

    else
        is_valid = true
    end

    return is_valid
end

function log_schema_issues(issues::Vector{SingleIssue}, set_name::String)
    if !isempty(issues)
        println(
            "🔍 Validation of $set_name failed with $(length(issues)) issue$(length(issues) == 1 ? "" : "s"):\n",
        )
        println("─"^50)

        for (i, issue) in enumerate(issues)
            println("─"^50)
            println("Issue $i:")

            label_width = 16  # adjust as needed

            println(rpad("📍 Where:", label_width), issue.path)
            println(rpad("🔢 Provided:", label_width), issue.x)
            println(rpad("🔑 Rule:", label_width), "$(issue.reason) = $(issue.val)")

            # Custom messages for common schema keys
            msg = if issue.reason == "required"
                "Missing required field(s): $(join(issue.val, ", "))"
            elseif issue.reason == "maximum"
                "Value exceeds maximum allowed ($(issue.val))"
            elseif issue.reason == "minimum"
                "Value is below the minimum allowed ($(issue.val))"
            elseif issue.reason == "type"
                "Expected type: $(issue.val)"
            elseif issue.reason == "enum"
                "Value must be one of: $(join(issue.val, ", "))"
            else
                "Schema violation: $(issue.reason)"
            end

            println(rpad("🛠  Issue:", label_width), msg, "\n")
        end

        println("─"^50)
    else
        println("✔️ Validation of $set_name passed: No issues found.")
        println("─"^50)
    end
end

################################################################################
# Parameter set validation
# 
# The following functions have been altered from JSONSchema, so that validate 
# catches all issues instead of only returning the first issue it encounteres.
################################################################################

function validate(schema::Schema, x)
    issues = Vector{SingleIssue}()
    _validate(x, schema.data, "", issues)
    return ValidationReport(issues)
end

# Fallbacks for the opposite argument.
validate(x, schema::Schema) = validate(schema, x)

function _validate(x, schema, path::String, issues::Vector{SingleIssue})
    schema = _resolve_refs(schema)
    _validate_entry(x, schema, path, issues)
end

function _validate_entry(x, schema::AbstractDict, path, issues)
    for (k, v) in schema
        ret = _validate(x, schema, Val{Symbol(k)}(), v, path, issues)
    end
end

function _validate_entry(x, schema::Bool, path::String, issues::Vector{SingleIssue})
    if !schema
        push!(issues, SingleIssue(x, path, "schema", schema))
    end
end

# Default fallback
_validate(::Any, ::Any, ::Val, ::Any, ::String, issues::Vector{SingleIssue}) = nothing

# JSON treats == between Bool and Number differently to Julia, so:
_isequal(x, y) = x == y
_isequal(::Bool, ::Number) = false
_isequal(::Number, ::Bool) = false
_isequal(x::Bool, y::Bool) = x == y
function _isequal(x::AbstractVector, y::AbstractVector)
    return length(x) == length(y) && all(_isequal.(x, y))
end
function _isequal(x::AbstractDict, y::AbstractDict)
    return Set(keys(x)) == Set(keys(y)) && all(_isequal(v, y[k]) for (k, v) in x)
end

# 9.2.1.1
function _validate(
    x, schema, ::Val{:allOf}, val::AbstractVector, path::String, issues::Vector{SingleIssue}
)
    for v in val
        _validate(x, v, path, issues)
    end
end

# 9.2.1.2
function _validate(
    x, schema, ::Val{:anyOf}, val::AbstractVector, path::String, issues::Vector{SingleIssue}
)
    temp_issues = Vector{SingleIssue}()
    for v in val
        local_issues = Vector{SingleIssue}()
        _validate(x, v, path, local_issues)
        if isempty(local_issues)
            return nothing
        end
        append!(temp_issues, local_issues)
    end
    append!(issues, temp_issues)
    push!(issues, SingleIssue(x, path, "anyOf", val))
end

# 9.2.1.3
function _validate(
    x, schema, ::Val{:oneOf}, val::AbstractVector, path::String, issues::Vector{SingleIssue}
)
    found_match = false
    temp_issues = Vector{SingleIssue}()

    for v in val
        local_issues = Vector{SingleIssue}()
        _validate(x, v, path, local_issues)

        if isempty(local_issues)
            if found_match
                push!(issues, SingleIssue(x, path, "oneOf", "More than one schema matched"))
                return nothing
            end
            found_match = true
        else
            append!(temp_issues, local_issues)
        end
    end

    if !found_match
        # Only push errors if none matched
        append!(issues, temp_issues)
    end
end

# 9.2.1.4
function _validate(x, schema, ::Val{:not}, val, path::String, issues::Vector{SingleIssue})
    local_issues = Vector{SingleIssue}()
    _validate(x, val, path, local_issues)
    if isempty(local_issues)
        push!(issues, SingleIssue(x, path, "not", val))
    end
end

# 9.2.2.1: if
function _validate(x, schema, ::Val{:if}, val, path::String, issues::Vector{SingleIssue})
    if haskey(schema, "then") || haskey(schema, "else")
        _if_then_else(x, schema, path, issues)
    end
end

# 9.2.2.2: then
function _validate(x, schema, ::Val{:then}, val, path::String, issues::Vector{SingleIssue})
    if haskey(schema, "if")
        _if_then_else(x, schema, path, issues)
    end
end

# 9.2.2.3: else
function _validate(x, schema, ::Val{:else}, val, path::String, issues::Vector{SingleIssue})
    if haskey(schema, "if")
        _if_then_else(x, schema, path, issues)
    end
end

function _if_then_else(x, schema, path, issues::Vector{SingleIssue})
    local_issues = Vector{SingleIssue}()
    _validate(x, schema["if"], path, local_issues)
    if isempty(local_issues)
        if haskey(schema, "then")
            _validate(x, schema["then"], path, issues)
        end
    elseif haskey(schema, "else")
        _validate(x, schema["else"], path, issues)
    end
end

# 9.3.1.1
function _validate(
    x::AbstractVector,
    schema,
    ::Val{:items},
    val::AbstractDict,
    path::String,
    issues::Vector{SingleIssue},
)
    items = fill(false, length(x))
    for (i, xi) in enumerate(x)
        if _validate(xi, val, path * "[$(i)]", issues) !== nothing
            return nothing
        end
        items[i] = true
    end
    additionalItems = get(schema, "additionalItems", nothing)
    _additional_items(x, schema, items, additionalItems, path, issues)
end

function _validate(
    x::AbstractVector,
    schema,
    ::Val{:items},
    val::AbstractVector,
    path::String,
    issues::Vector{SingleIssue},
)
    items = fill(false, length(x))
    for (i, xi) in enumerate(x)
        if i > length(val)
            break
        end
        if _validate(xi, val[i], path * "[$(i)]", issues) !== nothing
            return nothing
        end
        items[i] = true
    end
    additionalItems = get(schema, "additionalItems", nothing)
    _additional_items(x, schema, items, additionalItems, path, issues)
end

function _validate(
    x::AbstractVector,
    schema,
    ::Val{:items},
    val::Bool,
    path::String,
    issues::Vector{SingleIssue},
)
    if !val && length(x) > 0
        push!(issues, SingleIssue(x, path, "items", val))
    end
end

function _additional_items(x, schema, items, val, path, issues::Vector{SingleIssue})
    for i in 1:length(x)
        if items[i]
            continue
        end
        if _validate(x[i], val, path * "[$(i)]", issues) !== nothing
            return nothing
        end
    end
end

function _additional_items(x, schema, items, val::Bool, path, issues::Vector{SingleIssue})
    if !val && !all(items)
        push!(issues, SingleIssue(x, path, "additionalItems", val))
    end
end

_additional_items(x, schema, items, val::Nothing, path, issues) = nothing
function _additional_items(
    x, schema, items, val::Nothing, path, issues::Vector{SingleIssue}
)
    nothing
end

# 9.3.1.2
function _validate(
    x::AbstractVector,
    schema,
    ::Val{:additionalItems},
    val,
    path::String,
    issues::Vector{SingleIssue},
)
    return nothing  # Supported in `items`.
end

# 9.3.1.4
function _validate(
    x::AbstractVector,
    schema,
    ::Val{:contains},
    val,
    path::String,
    issues::Vector{SingleIssue},
)
    for (i, xi) in enumerate(x)
        ret = _validate(xi, val, path * "[$(i)]", issues)
        if ret === nothing
            return nothing
        end
    end
    push!(issues, SingleIssue(x, path, "contains", val))
end

### Checks for Objects ###

# 9.3.2.1
function _validate(
    x::AbstractDict,
    schema,
    ::Val{:properties},
    val::AbstractDict,
    path::String,
    issues::Vector{SingleIssue},
)
    for (k, v) in x
        if haskey(val, k)
            ret = _validate(v, val[k], path * "[$(k)]", issues)
            if ret !== nothing
                push!(issues, ret)
            end
        end
    end
    return nothing
end

# 9.3.2.2
function _validate(
    x::AbstractDict,
    schema,
    ::Val{:patternProperties},
    val::AbstractDict,
    path::String,
    issues::Vector{SingleIssue},
)
    for (k_val, v_val) in val
        r = Regex(k_val)
        for (k_x, v_x) in x
            if match(r, k_x) === nothing
                continue
            end
            ret = _validate(v_x, v_val, path * "[$(k_x)]", issues)
            if ret !== nothing
                return ret
            end
        end
    end
    return nothing
end

# 9.3.2.3
function _validate(
    x::AbstractDict,
    schema,
    ::Val{:additionalProperties},
    val::AbstractDict,
    path::String,
    issues::Vector{SingleIssue},
)
    properties = get(schema, "properties", Dict{String,Any}())
    patternProperties = get(schema, "patternProperties", Dict{String,Any}())
    for (k, v) in x
        if k in keys(properties) ||
            any(r -> match(Regex(r), k) !== nothing, keys(patternProperties))
            continue
        end
        ret = _validate(v, val, path * "[$(k)]", issues)
        if ret !== nothing
            return ret
        end
    end
    return nothing
end

function _validate(
    x::AbstractDict,
    schema,
    ::Val{:additionalProperties},
    val::Bool,
    path::String,
    issues::Vector{SingleIssue},
)
    if val
        return nothing
    end
    properties = get(schema, "properties", Dict{String,Any}())
    patternProperties = get(schema, "patternProperties", Dict{String,Any}())
    for (k, v) in x
        if k in keys(properties) ||
            any(r -> match(Regex(r), k) !== nothing, keys(patternProperties))
            continue
        end
        push!(issues, SingleIssue(x, path, "additionalProperties", val))
        return nothing
    end
    return nothing
end

# 9.3.2.5
function _validate(
    x::AbstractDict,
    schema,
    ::Val{:propertyNames},
    val,
    path::String,
    issues::Vector{SingleIssue},
)
    for k in keys(x)
        ret = _validate(k, val, path, issues)
        if ret !== nothing
            return ret
        end
    end
    return nothing
end

### Checks for generic types ###

# 6.1.1
function _validate(
    x, schema, ::Val{:type}, val::String, path::String, issues::Vector{SingleIssue}
)
    if !_is_type(x, Val{Symbol(val)}())
        push!(issues, SingleIssue(x, path, "type", val))
    end
    return nothing
end

function _validate(
    x, schema, ::Val{:type}, val::AbstractVector, path::String, issues::Vector{SingleIssue}
)
    if !any(v -> _is_type(x, Val{Symbol(v)}()), val)
        push!(issues, SingleIssue(x, path, "type", val))
    end
    return nothing
end

# Type-checking helper function
_is_type(::Any, ::Val) = false
_is_type(::Array, ::Val{:array}) = true
_is_type(::Bool, ::Val{:boolean}) = true
_is_type(::Integer, ::Val{:integer}) = true
_is_type(x::Float64, ::Val{:integer}) = isinteger(x)
_is_type(::Real, ::Val{:number}) = true
_is_type(::Nothing, ::Val{:null}) = true
_is_type(::Missing, ::Val{:null}) = true
_is_type(::AbstractDict, ::Val{:object}) = true
_is_type(::String, ::Val{:string}) = true
# Note that Julia treats Bool <: Number, but JSON-Schema distinguishes them.
_is_type(::Bool, ::Val{:number}) = false
_is_type(::Bool, ::Val{:integer}) = false

# 6.1.2
function _validate(x, schema, ::Val{:enum}, val, path::String, issues::Vector{SingleIssue})
    if !any(_isequal(x, v) for v in val)
        push!(issues, SingleIssue(x, path, "enum", val))
    end
    return nothing
end

# 6.1.3
function _validate(x, schema, ::Val{:const}, val, path::String, issues::Vector{SingleIssue})
    if !_isequal(x, val)
        push!(issues, SingleIssue(x, path, "const", val))
    end
    return nothing
end

### Checks for numbers ###

# 6.2.1
function _validate(
    x::Number,
    schema,
    ::Val{:multipleOf},
    val::Number,
    path::String,
    issues::Vector{SingleIssue},
)
    y = x / val
    if !isfinite(y) || !isapprox(y, round(y))
        push!(issues, SingleIssue(x, path, "multipleOf", val))
    end
    return nothing
end

# 6.2.2
function _validate(
    x::Number,
    schema,
    ::Val{:maximum},
    val::Number,
    path::String,
    issues::Vector{SingleIssue},
)
    if x > val
        push!(issues, SingleIssue(x, path, "maximum", val))
    end
    return nothing
end

# 6.2.3
function _validate(
    x::Number,
    schema,
    ::Val{:exclusiveMaximum},
    val::Number,
    path::String,
    issues::Vector{SingleIssue},
)
    if x >= val
        push!(issues, SingleIssue(x, path, "exclusiveMaximum", val))
    end
    return nothing
end

function _validate(
    x::Number,
    schema,
    ::Val{:exclusiveMaximum},
    val::Bool,
    path::String,
    issues::Vector{SingleIssue},
)
    if val && x >= get(schema, "maximum", Inf)
        push!(issues, SingleIssue(x, path, "exclusiveMaximum", val))
    end
    return nothing
end

# 6.2.4
function _validate(
    x::Number,
    schema,
    ::Val{:minimum},
    val::Number,
    path::String,
    issues::Vector{SingleIssue},
)
    if x < val
        push!(issues, SingleIssue(x, path, "minimum", val))
    end
    return nothing
end

# 6.2.5
function _validate(
    x::Number,
    schema,
    ::Val{:exclusiveMinimum},
    val::Number,
    path::String,
    issues::Vector{SingleIssue},
)
    if x <= val
        push!(issues, SingleIssue(x, path, "exclusiveMinimum", val))
    end
    return nothing
end

function _validate(
    x::Number,
    schema,
    ::Val{:exclusiveMinimum},
    val::Bool,
    path::String,
    issues::Vector{SingleIssue},
)
    if val && x <= get(schema, "minimum", -Inf)
        push!(issues, SingleIssue(x, path, "exclusiveMinimum", val))
    end
    return nothing
end

###
### Checks for strings.
###

# 6.3.1
function _validate(
    x::String,
    schema,
    ::Val{:maxLength},
    val::Union{Integer,Float64},
    path::String,
    issues::Vector{SingleIssue},
)
    if length(x) > val
        push!(issues, SingleIssue(x, path, "maxLength", val))
    end
    return nothing
end

# 6.3.2
function _validate(
    x::String,
    schema,
    ::Val{:minLength},
    val::Union{Integer,Float64},
    path::String,
    issues::Vector{SingleIssue},
)
    if length(x) < val
        push!(issues, SingleIssue(x, path, "minLength", val))
    end
    return nothing
end

# 6.3.3
function _validate(
    x::String,
    schema,
    ::Val{:pattern},
    val::String,
    path::String,
    issues::Vector{SingleIssue},
)
    if !occursin(Regex(val), x)
        push!(issues, SingleIssue(x, path, "pattern", val))
    end
    return nothing
end

###
### Checks for arrays.
###

# 6.4.1
function _validate(
    x::AbstractVector,
    schema,
    ::Val{:maxItems},
    val::Union{Integer,Float64},
    path::String,
    issues::Vector{SingleIssue},
)
    if length(x) > val
        push!(issues, SingleIssue(x, path, "maxItems", val))
    end
    return nothing
end

# 6.4.2
function _validate(
    x::AbstractVector,
    schema,
    ::Val{:minItems},
    val::Union{Integer,Float64},
    path::String,
    issues::Vector{SingleIssue},
)
    if length(x) < val
        push!(issues, SingleIssue(x, path, "minItems", val))
    end
    return nothing
end

# 6.4.3
function _validate(
    x::AbstractVector,
    schema,
    ::Val{:uniqueItems},
    val::Bool,
    path::String,
    issues::Vector{SingleIssue},
)
    if !val
        return nothing
    end
    # TODO(odow): O(n^2) here. But probably not too bad, because there shouldn't
    # be a large x.
    for i in eachindex(x), j in eachindex(x)
        if i != j && _isequal(x[i], x[j])
            push!(issues, SingleIssue(x, path, "uniqueItems", val))
            return nothing
        end
    end
    return nothing
end

# 6.4.4: maxContains

# 6.4.5: minContains

###
### Checks for objects.
###

# 6.5.1
function _validate(
    x::AbstractDict,
    schema,
    ::Val{:maxProperties},
    val::Union{Integer,Float64},
    path::String,
    issues::Vector{SingleIssue},
)
    if length(x) > val
        push!(issues, SingleIssue(x, path, "maxProperties", val))
    end
    return nothing
end

# 6.5.2
function _validate(
    x::AbstractDict,
    schema,
    ::Val{:minProperties},
    val::Union{Integer,Float64},
    path::String,
    issues::Vector{SingleIssue},
)
    if length(x) < val
        push!(issues, SingleIssue(x, path, "minProperties", val))
    end
    return nothing
end

# 6.5.3
function _validate(
    x::AbstractDict,
    schema,
    ::Val{:required},
    val::AbstractVector,
    path::String,
    issues::Vector{SingleIssue},
)
    if any(v -> !haskey(x, v), val)
        push!(issues, SingleIssue(x, path, "required", val))
    end
    return nothing
end

# 6.5.4
function _validate(
    x::AbstractDict,
    schema,
    ::Val{:dependencies},
    val::AbstractDict,
    path::String,
    issues::Vector{SingleIssue},
)
    for (k, v) in val
        if !haskey(x, k)
            continue
        elseif !_dependencies(x, path, v, issues)
            push!(issues, SingleIssue(x, path, "dependencies", val))
            return nothing
        end
    end
    return nothing
end

function _dependencies(
    x::AbstractDict,
    path::String,
    val::Union{Bool,AbstractDict},
    issues::Vector{SingleIssue},
)
    return _validate(x, val, path, issues) === nothing
end

function _dependencies(
    x::AbstractDict, path::String, val::Array, issues::Vector{SingleIssue}
)
    return all(v -> haskey(x, v), val)
end

################################################################################
# Data manipulation Tools
################################################################################

function parse_path(path::String)
    # Extract everything between the brackets, removing the brackets
    matches = eachmatch(r"\[([^\]]+)\]", path)
    return [strip(String(match.match), ['[', ']']) for match in matches]
end

function get_nested_value(
    dict::AbstractDict, keys::Vector{SubString{String}}, default=nothing
)
    value = dict
    for key in keys
        if isa(value, AbstractDict) && haskey(value, key)
            value = value[key]  # Move deeper into the dictionary
        else
            return default  # Return default if key is missing
        end
    end
    return value  # Return the final value
end

function delete_nested!(dict::AbstractDict, keys::Vector{SubString{String}})
    if length(keys) == 1
        delete!(dict, keys[1])  # Base case: delete the final key
    else
        parent_dict = get(dict, keys[1], nothing)
        if isa(parent_dict, AbstractDict)
            delete_nested!(parent_dict, keys[2:end])  # Recursive call on sub-dictionary
        end
    end
end

function set_nested!(dict::AbstractDict, keys::Vector{SubString{String}}, value)
    if length(keys) == 1
        dict[keys[1]] = value  # Base case: Set the final key to the value
    else
        if !haskey(dict, keys[1]) || !isa(dict[keys[1]], AbstractDict)
            dict[keys[1]] = Dict()  # Ensure intermediate keys are dictionaries
        end
        set_nested!(dict[keys[1]], keys[2:end], value)  # Recursive call on sub-dictionary
    end
end
