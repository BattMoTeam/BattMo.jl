"""
    BPX

Import and export of BPX (Battery Parameter eXchange, https://bpxstandard.com, version
1.1.1) parameter sets.

- Import: `load_cell_parameters(; from_bpx_file_path)` (or `load_from_bpx_file`,
  `parse_bpx_to_cell_parameters`) converts a BPX JSON file to BattMo cell parameters.
- Export: `write_bpx` (or `convert_to_bpx`) converts BattMo cell parameters to a BPX
  parameter set.

The conversion conventions, the differences between the BPX and BattMo models and the
known limitations are described on the "BPX parameter sets" page of the BattMo
documentation (`docs/src/manuals/user_guide/bpx.md`). Every conversion collects its
findings in a report, emitted as one warning (findings that need attention: schema
violations, inconsistent data, unsupported BPX features, model differences, unknown keys
and undetermined parameters) and one info message (approximations, unused parameters and
the operating conditions that belong to the `CyclingProtocol`).

# Schema validation and BPX versions
Inputs are validated against the JSON schema of the official BPX package
(https://github.com/FaradayInstitution/BPX, MIT license, copyright (c) 2022 University
of Oxford), bundled in `src/input/bpx_schema/` together with its license; see the
README there for its provenance and how to update it for a new BPX release. Legacy
BPX v0.x inputs are first converted to the v1.x layout (`migrate_legacy_bpx`, adapted
from the same package), so the conversion to BattMo only handles the v1.x layout.
"""
module BPX

using JSON
using JSONSchema

export load_from_bpx_file, parse_bpx_to_cell_parameters, convert_to_bpx, write_bpx
export load_cycling_protocol_from_bpx_file, parse_bpx_to_cycling_protocol
export load_full_simulation_input_from_bpx_file, parse_bpx_to_full_simulation_input

const BattMoModule = parentmodule(@__MODULE__)

const GAS_CONSTANT = 8.31446261815324 # J mol⁻¹ K⁻¹
const DEFAULT_REFERENCE_TEMPERATURE = 298.15 # K

# Version of the BPX package the bundled schema was generated from (see
# src/input/bpx_schema/README.md)
const BPX_SCHEMA_VERSION = v"1.1.1"
const BPX_SCHEMA_PATH = joinpath(@__DIR__, "bpx_schema", "bpx_schema.json")

# Tolerance of the check of the OCPs at the stoichiometry limits against the voltage
# cut-offs (the default of the Python BPX package)
const VOLTAGE_TOLERANCE = 1.0e-3 # V

# BPX operating conditions and the CyclingProtocol entries they correspond to:
# (section, BPX key, CyclingProtocol key)
const PROTOCOL_PARAMETERS = [
    ("Cell", "Lower voltage cut-off [V]", "LowerVoltageLimit"),
    ("Cell", "Upper voltage cut-off [V]", "UpperVoltageLimit"),
    ("Initial conditions", "Initial state-of-charge", "InitialStateOfCharge"),
    ("Initial conditions", "Initial temperature [K]", "InitialTemperature"),
    ("Thermal environment", "Ambient temperature [K]", "AmbientTemperature"),
]

const HYSTERESIS_PARAMETERS = [
    "OCP (lithiation) [V]",
    "OCP (delithiation) [V]",
    "OCP hysteresis decay constant",
]

# ============================================================================
# Conversion report
# ============================================================================

# Categories reported as a warning: findings that change the simulation results or need
# action from the user
const WARNING_CATEGORIES = [
    :schema => "Violations of the BPX $(BPX_SCHEMA_VERSION) standard",
    :consistency => "Inconsistencies within the BPX data",
    :unsupported => "BPX features that BattMo does not support (ignored)",
    :model_differences => "Differences between the BPX and BattMo models",
    :unknown_keys => "Keys that are not part of the BPX standard (ignored)",
    :zero_filled => "Parameters that could not be determined and were set to 0.0 (set them before simulating)",
    :assumed => "Operating conditions that the BPX input does not give (default values used, check them)",
]

# Categories reported as info: documented choices of the conversion
const INFO_CATEGORIES = [
    :approximations => "Approximations made in the conversion",
    :unused => "Parameters without a counterpart (not converted)",
    :protocol => "Operating conditions, which belong to the BattMo CyclingProtocol (load them with `load_cycling_protocol(; from_bpx_file_path)`)",
    :notes => "Notes",
]

"""
    ConversionReport

Findings of a BPX import or export, grouped by category (see `WARNING_CATEGORIES` and
`INFO_CATEGORIES`).
"""
mutable struct ConversionReport
    direction::String
    entries::Dict{Symbol, Vector{String}}
    # Whether the input has been validated against the schema; unknown keys are then
    # already reported as schema violations
    validated::Bool
end

ConversionReport(direction::String) = ConversionReport(direction, Dict{Symbol, Vector{String}}(), false)

function add!(report::ConversionReport, category::Symbol, message::AbstractString)
    entries = get!(report.entries, category, String[])
    message in entries || push!(entries, message)
    return report
end

entries(report::ConversionReport, category::Symbol) = get(report.entries, category, String[])

function format_report(report::ConversionReport, categories)
    parts = String[]
    for (category, title) in categories
        items = entries(report, category)
        isempty(items) && continue
        push!(parts, title * ":\n" * join(("  - " * item for item in items), "\n"))
    end
    return join(parts, "\n\n")
end

function emit_report(report::ConversionReport)
    warning_text = format_report(report, WARNING_CATEGORIES)
    if !isempty(warning_text)
        @warn "BPX $(report.direction): the result differs from the input or needs attention. See the \"BPX parameter sets\" page of the BattMo documentation.\n\n" * warning_text
    end
    info_text = format_report(report, INFO_CATEGORIES)
    if !isempty(info_text)
        @info "BPX $(report.direction): details of the conversion.\n\n" * info_text
    end
    return nothing
end

"""
    raise_if_strict(report, strict)

In strict mode, raise an error listing all violations of the BPX standard. As in the
Python BPX package, inconsistencies within the data are only warned about.
"""
function raise_if_strict(report::ConversionReport, strict::Bool)
    strict || return nothing
    text = format_report(report, filter(c -> first(c) == :schema, WARNING_CATEGORIES))
    isempty(text) || error("BPX $(report.direction) (strict mode): the BPX data does not conform to the BPX $(BPX_SCHEMA_VERSION) standard.\n\n" * text)
    return nothing
end

location(parts...) = join(parts, " → ")

# ============================================================================
# BPX schema
# ============================================================================

const SCHEMA_DATA = Ref{Any}(nothing)

function bpx_schema_data()
    if isnothing(SCHEMA_DATA[])
        SCHEMA_DATA[] = JSON.parsefile(BPX_SCHEMA_PATH)
    end
    return SCHEMA_DATA[]
end

schema_definitions() = bpx_schema_data()["\$defs"]

"""
    standard_keys(definition)

Return the parameter names that the BPX schema allows in the definition `definition`
(e.g. `"Cell"`, `"ElectrodeSingle"`).
"""
standard_keys(definition::String) = Set{String}(keys(get(schema_definitions()[definition], "properties", Dict())))

function resolve_reference(schema, definitions)
    while isa(schema, AbstractDict) && haskey(schema, "\$ref")
        name = last(split(schema["\$ref"], "/"))
        schema = definitions[name]
    end
    return schema
end

is_object_schema(schema) = isa(schema, AbstractDict) && (get(schema, "type", nothing) == "object" || haskey(schema, "properties"))

const LEAF_SCHEMA_CACHE = IdDict{Any, JSONSchema.Schema}()

function describe_schema(schema, definitions)
    schema = resolve_reference(schema, definitions)
    if haskey(schema, "anyOf")
        descriptions = unique(describe_schema(option, definitions) for option in schema["anyOf"])
        return join(descriptions, " or ")
    elseif haskey(schema, "enum")
        return "one of " * join(repr.(schema["enum"]), ", ")
    elseif is_object_schema(schema) && haskey(get(schema, "properties", Dict()), "x")
        return "a table with \"x\" and \"y\" arrays"
    elseif get(schema, "type", nothing) == "string" && haskey(schema, "pattern")
        return "a string matching $(schema["pattern"])"
    elseif get(schema, "type", nothing) == "string"
        return "a function string"
    elseif get(schema, "type", nothing) in ("number", "integer")
        return "a number"
    else
        return string(get(schema, "type", "a valid value"))
    end
end

function validate_leaf!(issues, value, schema, definitions, path)
    compiled = get!(LEAF_SCHEMA_CACHE, schema) do
        JSONSchema.Schema(merge(Dict{String, Any}(schema), Dict{String, Any}("\$defs" => definitions)))
    end
    if !isnothing(JSONSchema.validate(compiled, value))
        push!(issues, "$path: invalid value $(repr(value)); expected $(describe_schema(schema, definitions)).")
    end
    return issues
end

"""
    collect_schema_issues!(issues, value, schema, definitions, path)

Validate `value` against `schema` and collect all violations, with a readable location,
in `issues`. Objects are traversed key by key so that, unlike `JSONSchema.validate`, all
violations are found. For alternatives between object schemas (e.g. a single or a
blended electrode), the alternative with the fewest violations is reported.
"""
function collect_schema_issues!(issues::Vector{String}, value, schema, definitions, path::String)
    schema = resolve_reference(schema, definitions)
    if isa(schema, AbstractDict) && haskey(schema, "anyOf") && isa(value, AbstractDict)
        object_options = filter(is_object_schema, [resolve_reference(option, definitions) for option in schema["anyOf"]])
        if !isempty(object_options)
            best = nothing
            for option in object_options
                option_issues = collect_schema_issues!(String[], value, option, definitions, path)
                isempty(option_issues) && return issues
                if isnothing(best) || length(option_issues) < length(best)
                    best = option_issues
                end
            end
            return append!(issues, best)
        end
    end
    if is_object_schema(schema) && isa(value, AbstractDict)
        properties = get(schema, "properties", Dict())
        for required in get(schema, "required", String[])
            haskey(value, required) || push!(issues, "$(location(path, required)): missing required parameter.")
        end
        additional = get(schema, "additionalProperties", true)
        for (key, item) in value
            item_path = location(path, key)
            if haskey(properties, key)
                collect_schema_issues!(issues, item, properties[key], definitions, item_path)
            elseif additional === false
                push!(issues, "$item_path: not a parameter of the BPX standard at this location.")
            elseif isa(additional, AbstractDict)
                collect_schema_issues!(issues, item, additional, definitions, item_path)
            end
        end
        return issues
    end
    return validate_leaf!(issues, value, schema, definitions, path)
end

# The BPX schema accepts the "Parameterisation" of any model type (anyOf), so the
# Parameterisation definition matching the declared model is selected explicitly.
const PARAMETERISATION_DEFINITIONS = Dict(
    "DFN" => "Parameterisation",
    "SPMe" => "Parameterisation",
    "SPM" => "ParameterisationSPM",
    "Partial" => "ParameterisationPartial",
)

"""
    schema_issues(bpx_data) -> Vector{String}

Return all violations of the bundled BPX schema in a BPX input in the v1.x layout.
"""
function schema_issues(bpx_data::AbstractDict)
    schema = deepcopy(bpx_schema_data())
    definitions = schema["\$defs"]
    header = get(bpx_data, "Header", nothing)
    model = isa(header, AbstractDict) ? get(header, "Model", nothing) : nothing
    definition = get(PARAMETERISATION_DEFINITIONS, model, nothing)
    if !isnothing(definition)
        schema["properties"]["Parameterisation"] = Dict{String, Any}("\$ref" => "#/\$defs/$definition")
    end
    return collect_schema_issues!(String[], bpx_data, schema, definitions, "")
end

"""
    validate_bpx(bpx_data; strict = false) -> Bool

Validate a BPX input in the v1.x layout against the bundled BPX schema and check the
consistency of its data (see `check_consistency!`). Findings are emitted as a warning;
with `strict`, schema violations raise an error. Return whether the input conforms to
the schema.
"""
function validate_bpx(bpx_data::AbstractDict; strict::Bool = false)
    report = ConversionReport("validation")
    for issue in schema_issues(bpx_data)
        add!(report, :schema, issue)
    end
    check_consistency!(report, bpx_data)
    raise_if_strict(report, strict)
    emit_report(report)
    return isempty(entries(report, :schema))
end

# ============================================================================
# BPX versions and legacy migration
# ============================================================================

"""
    bpx_version(bpx_data) -> VersionNumber

Return the BPX version from `Header.BPX`, which may be a string (`"1.1.0"`) or, in
older files, a number (`0.1`).
"""
function bpx_version(bpx_data::AbstractDict)
    header = get(bpx_data, "Header", nothing)
    version = isa(header, AbstractDict) ? get(header, "BPX", nothing) : nothing
    if isa(version, Real) && !isa(version, Bool)
        version = string(version)
    end
    parsed = isa(version, AbstractString) ? tryparse(VersionNumber, strip(version)) : nothing
    isnothing(parsed) && error("Invalid BPX input: the \"Header\" → \"BPX\" version field is missing or malformed ($(repr(version))).")
    return parsed
end

"""
    migrate_legacy_bpx(bpx_data) -> Dict

Return a copy of a legacy BPX v0.x input repacked into the v1.x layout: the initial and
ambient temperatures and the initial electrolyte concentration move from
`Parameterisation` to a new `State` section, with initial state-of-charge 1.

Adapted from `bpx/_migrations.py` of the BPX package
(https://github.com/FaradayInstitution/BPX, MIT license, copyright (c) 2022 University
of Oxford; see `src/input/bpx_schema/LICENSE`). Unlike the original, the lumped
`Thermal conductivity`, which has no v1.x counterpart but is used by BattMo, is kept
in the `User-defined` section instead of being dropped.
"""
function migrate_legacy_bpx(bpx_data::AbstractDict)
    data = deepcopy(bpx_data)
    parameterisation = get!(data, "Parameterisation", Dict{String, Any}())
    cell = get(parameterisation, "Cell", Dict{String, Any}())
    electrolyte = get(parameterisation, "Electrolyte", Dict{String, Any}())

    pop_value!(dict, key) = haskey(dict, key) ? pop!(dict, key) : nothing
    first_not_nothing(values...; default) = something(values..., default)

    ambient_temperature = pop_value!(cell, "Ambient temperature [K]")
    reference_temperature = get(cell, "Reference temperature [K]", nothing)
    initial_temperature = pop_value!(cell, "Initial temperature [K]")
    ambient_temperature = first_not_nothing(ambient_temperature, reference_temperature; default = DEFAULT_REFERENCE_TEMPERATURE)
    initial_temperature = first_not_nothing(initial_temperature, ambient_temperature; default = DEFAULT_REFERENCE_TEMPERATURE)

    thermal_conductivity = pop_value!(cell, "Thermal conductivity [W.m-1.K-1]")
    if !isnothing(thermal_conductivity)
        user_defined = get!(parameterisation, "User-defined", Dict{String, Any}())
        user_defined["Thermal conductivity [W.m-1.K-1]"] = thermal_conductivity
    end

    initial_conditions = Dict{String, Any}(
        "Initial state-of-charge" => 1,
        "Initial temperature [K]" => initial_temperature,
    )
    initial_concentration = pop_value!(electrolyte, "Initial concentration [mol.m-3]")
    if !isnothing(initial_concentration)
        initial_conditions["Initial electrolyte concentration [mol.m-3]"] = initial_concentration
    end

    data["State"] = Dict{String, Any}(
        "Initial conditions" => initial_conditions,
        "Thermal environment" => Dict{String, Any}("Ambient temperature [K]" => ambient_temperature),
    )
    data["Header"]["BPX"] = string(BPX_SCHEMA_VERSION)

    return data
end

"""
    prepare_bpx_input(bpx_data, report) -> Dict

Return a copy of a BPX input in the v1.x layout: legacy v0.x inputs are converted and a
numeric version field is written as a string, as the BPX package does.
"""
function prepare_bpx_input(bpx_data::AbstractDict, report::ConversionReport)
    version = bpx_version(bpx_data)
    if version.major < 1
        add!(report, :notes, "The input uses the legacy BPX $version format and was converted to the BPX $(BPX_SCHEMA_VERSION) layout (initial conditions and ambient temperature moved to \"State\"; the lumped thermal conductivity, which BPX 1.x no longer has, moved to \"User-defined\").")
        return migrate_legacy_bpx(bpx_data)
    end
    data = deepcopy(bpx_data)
    if isa(data["Header"]["BPX"], Real)
        data["Header"]["BPX"] = string(version)
    end
    if (version.major, version.minor) > (BPX_SCHEMA_VERSION.major, BPX_SCHEMA_VERSION.minor)
        add!(report, :notes, "The input uses BPX $version, which is newer than the BPX $(BPX_SCHEMA_VERSION) standard supported by BattMo. Parameters introduced after BPX $(BPX_SCHEMA_VERSION) are reported as violations and ignored.")
    end
    return data
end

# ============================================================================
# BPX function strings
# ============================================================================

# Operations allowed in BPX function strings (BPX 1.1.1, section 6)
const BPX_OPERATIONS = Dict{Symbol, Function}(
    :+ => +, :- => -, :* => *, :/ => /, :^ => ^, :exp => exp, :tanh => tanh,
)

"""
    parse_bpx_expression(expression) -> (Expr or number or Symbol, issue)

Parse a BPX function string (Python syntax, independent variable `x`). Return the
parsed expression and `nothing`, or `nothing` and a description of why the string is
not a valid BPX function.
"""
function parse_bpx_expression(expression::AbstractString)
    parsed = try
        Meta.parse(replace(expression, "**" => "^"))
    catch
        return nothing, "cannot be parsed"
    end
    issue = expression_issue(parsed)
    return isnothing(issue) ? (parsed, nothing) : (nothing, issue)
end

function expression_issue(expression)
    if isa(expression, Real)
        return nothing
    elseif isa(expression, Symbol)
        return expression == :x ? nothing : "uses the unknown variable `$expression` (BPX functions depend on `x` only)"
    elseif isa(expression, Expr) && expression.head == :call
        operation = expression.args[1]
        if !haskey(BPX_OPERATIONS, operation)
            return "uses `$operation`, which is not one of the operations allowed by BPX (*, /, -, +, **, exp, tanh)"
        end
        for argument in expression.args[2:end]
            issue = expression_issue(argument)
            isnothing(issue) || return issue
        end
        return nothing
    else
        return "cannot be parsed"
    end
end

function evaluate_expression(expression, x::Real)
    if isa(expression, Real)
        return Float64(expression)
    elseif isa(expression, Symbol)
        return Float64(x)
    else
        operation = BPX_OPERATIONS[expression.args[1]]
        return operation((evaluate_expression(argument, x) for argument in expression.args[2:end])...)
    end
end

"""
    evaluate_bpx_value(value, x) -> Float64 or nothing

Evaluate a BPX FloatFunctionTable value (number, function string or table, the latter
interpolated linearly) at `x`. Return `nothing` when the value cannot be evaluated.
"""
function evaluate_bpx_value(value, x::Real)
    if isa(value, Real)
        return Float64(value)
    elseif isa(value, AbstractString)
        expression, issue = parse_bpx_expression(value)
        return isnothing(issue) ? evaluate_expression(expression, x) : nothing
    elseif isa(value, AbstractDict) && haskey(value, "x") && haskey(value, "y")
        xs = Float64.(value["x"])
        ys = Float64.(value["y"])
        (isempty(xs) || length(xs) != length(ys)) && return nothing
        order = sortperm(xs)
        xs, ys = xs[order], ys[order]
        x <= xs[1] && return ys[1]
        x >= xs[end] && return ys[end]
        k = searchsortedlast(xs, x)
        return ys[k] + (ys[k + 1] - ys[k]) * (x - xs[k]) / (xs[k + 1] - xs[k])
    end
    return nothing
end

"""
    convert_bpx_expression(expression, variable)

Rewrite a BPX function string to BattMo conventions: replace the Python power
operator `**` by `^` and the BPX independent variable `x` by `variable`.
"""
function convert_bpx_expression(expression::AbstractString, variable::String)
    converted = replace(expression, "**" => "^")
    converted = replace(converted, r"\bx\b" => variable)
    return converted
end

"""
    convert_bpx_function(value, variable, report, place)

Convert a BPX FloatFunctionTable value (constant, function string or tabulated data) to
its BattMo counterpart, with `variable` replacing the BPX variable `x` in function
strings. Function strings that do not follow the BPX syntax are reported. Missing
values (`nothing`) are passed through so they can be zero-filled later.
"""
function convert_bpx_function(value, variable::String, report::ConversionReport, place::String)
    if isnothing(value) || isa(value, Real)
        return value
    elseif isa(value, AbstractString)
        _, issue = parse_bpx_expression(value)
        isnothing(issue) || add!(report, :schema, "$place: the function string $issue. It is passed to BattMo unchanged.")
        return convert_bpx_expression(value, variable)
    elseif isa(value, AbstractDict) && haskey(value, "x") && haskey(value, "y")
        # Tabulated data is given versus the same variable BattMo evaluates the
        # interpolator at, so it can be passed through unchanged.
        return value
    else
        add!(report, :schema, "$place: unsupported value of type $(typeof(value)); expected a number, a function string or a table with \"x\" and \"y\".")
        return nothing
    end
end

"""
    apply_arrhenius(value, activation_energy, reference_temperature, report, place)

Fold a BPX activation energy into a parameter function as an Arrhenius factor
`exp(Ea / R * (1 / refT - 1 / T))`. Used for the electrolyte transport parameters,
for which the BattMo schema has no activation energy fields but whose function
strings are evaluated as `f(c, T)`.
"""
function apply_arrhenius(value, activation_energy, reference_temperature, report::ConversionReport, place::String)
    if isnothing(value) || isnothing(activation_energy) || activation_energy == 0
        return value
    end
    if isa(value, Real) || isa(value, AbstractString)
        base = isa(value, Real) ? string(value) : "(" * value * ")"
        return base * " * exp($activation_energy / $GAS_CONSTANT * (1.0 / $reference_temperature - 1.0 / T))"
    else
        add!(report, :unsupported, "$place: the activation energy ($activation_energy J.mol-1) cannot be combined with tabulated data, because BattMo evaluates tabulated electrolyte properties as a function of concentration only. The property is temperature independent in BattMo.")
        return value
    end
end

# ============================================================================
# Import: section access and missing values
# ============================================================================

# Wrapper around a BPX section that keeps track of which keys have been used, so that
# unconverted keys can be reported.
struct BPXSection
    name::String
    data::AbstractDict
    used_keys::Set{String}
    # Parameter names allowed by the BPX standard in this section; `nothing` for the
    # free-form "User-defined" section
    standard_keys::Union{Set{String}, Nothing}
end

BPXSection(name::String, data::AbstractDict, definition) =
    BPXSection(name, data, Set{String}(), isnothing(definition) ? nothing : standard_keys(definition))

"""
    get_parameter(section, key)

Return the value of the BPX parameter `key`, the full BPX name including its unit (e.g.
`"Thickness [m]"`), or `nothing` when it is absent. The BPX standard fixes the unit of
every parameter, and the units of the BPX names used here match the units of the
BattMo cell parameter schema, so no unit conversion is needed.
"""
function get_parameter(section::BPXSection, key::String)
    haskey(section.data, key) || return nothing
    push!(section.used_keys, key)
    return section.data[key]
end

has_parameter(section::BPXSection, key::String) = haskey(section.data, key)

function report_unconverted_keys!(report::ConversionReport, section::BPXSection)
    for key in sort(collect(setdiff(keys(section.data), section.used_keys)))
        place = location(section.name, key)
        if isnothing(section.standard_keys)
            add!(report, :unused, "$place: user-defined parameter, not interpreted by BattMo.")
        elseif key in section.standard_keys
            add!(report, :unused, "$place: BPX parameter without a BattMo counterpart.")
        elseif !report.validated
            # Otherwise already reported as a schema violation
            add!(report, :unknown_keys, "$place.")
        end
    end
    return report
end

"""
    derive(f, inputs...)

Evaluate the derived quantity `f(inputs...)`, or return `nothing` when any input is
missing so that the result is zero-filled and reported.
"""
derive(f, inputs...) = any(isnothing, inputs) ? nothing : f(inputs...)

"""
    fill_missing_with_zero!(parameters, prefix, zeroed_parameters)

Recursively replace `nothing` values, which mark BattMo parameters that could not be
determined from the BPX input, by `0.0` and record their paths in
`zeroed_parameters`.
"""
function fill_missing_with_zero!(parameters::AbstractDict, prefix::String, zeroed_parameters::Vector{String})
    for (key, value) in parameters
        path = prefix == "" ? key : prefix * "." * key
        if isnothing(value)
            parameters[key] = 0.0
            push!(zeroed_parameters, path)
        elseif isa(value, AbstractDict) && !(haskey(value, "x") && haskey(value, "y"))
            fill_missing_with_zero!(value, path, zeroed_parameters)
        end
    end
    return parameters
end

# ============================================================================
# Import: physical conversions
# ============================================================================

"""
    compute_bruggeman_coefficient(porosity, transport_efficiency, section_name)

Recover the Bruggeman coefficient from the BPX porosity and transport efficiency,
using `transport_efficiency = porosity^bruggeman`. Return `nothing` when either
input is missing.
"""
function compute_bruggeman_coefficient(porosity, transport_efficiency, section_name::String)
    if isnothing(porosity) || isnothing(transport_efficiency)
        return nothing
    end
    if !(0 < porosity < 1) || !(0 < transport_efficiency < 1)
        error("BPX section \"$section_name\" has porosity $porosity and transport efficiency $transport_efficiency; both must lie strictly between 0 and 1.")
    end
    return log(transport_efficiency) / log(porosity)
end

function add_lumped_thermal_parameters!(component::AbstractDict, lumped)
    component["SpecificHeatCapacity"] = lumped.specific_heat_capacity
    component["ThermalConductivity"] = lumped.thermal_conductivity
    return component
end

# BPX does not describe the binder and conductive additive separately. The solid that
# is not active material is lumped into the binder; the conductive additive is a
# zero-mass placeholder. Both get the same intrinsic conductivity as the active
# material, so that the volume-weighted coating conductivity equals that value.
function inert_component(description, mass_fraction, electronic_conductivity, lumped)
    component = Dict{String, Any}(
        "Description" => description,
        "Density" => lumped.density,
        "MassFraction" => mass_fraction,
        "ElectronicConductivity" => electronic_conductivity,
    )
    return add_lumped_thermal_parameters!(component, lumped)
end

"""
    compute_active_mass_fraction(surface_area, radius, porosity, report, section_name)

Return the active material fraction of the solid coating volume. BPX defines the active
material volume fraction as `surface_area * radius / 3` (spherical particles), which is
in general smaller than the solid volume fraction `1 - porosity`. Since all coating
components share the lumped BPX density, the volume fraction equals the mass fraction.
"""
function compute_active_mass_fraction(surface_area, radius, porosity, report::ConversionReport, section_name::String)
    active_volume_fraction = surface_area * radius / 3
    solid_volume_fraction = 1 - porosity
    if active_volume_fraction > solid_volume_fraction * (1 + 1.0e-6)
        add!(report, :consistency, "$section_name: the active material volume fraction (surface area per unit volume × particle radius / 3 = $(round(active_volume_fraction, sigdigits = 4))) exceeds the solid volume fraction (1 - porosity = $(round(solid_volume_fraction, sigdigits = 4))). BattMo caps the active material fraction of the solid at 1, which lowers the capacity compared with BPX.")
    end
    return min(active_volume_fraction / solid_volume_fraction, 1.0)
end

# ============================================================================
# Import: consistency checks
# ============================================================================

"""
    check_consistency!(report, bpx_data)

Checks of the BPX data beyond the schema, following the Python BPX package: the voltage
window given by the OCPs at the stoichiometry limits must lie within the voltage
cut-offs (tolerance $(VOLTAGE_TOLERANCE * 1000) mV), and the initial state-of-charge
must lie between 0 and 1. The OCPs are evaluated at the reference temperature; blended
electrodes are not checked.
"""
function check_consistency!(report::ConversionReport, bpx_data::AbstractDict)
    parameterisation = get(bpx_data, "Parameterisation", Dict())
    cell = get(parameterisation, "Cell", Dict())
    negative = get(parameterisation, "Negative electrode", Dict())
    positive = get(parameterisation, "Positive electrode", Dict())

    lower = get(cell, "Lower voltage cut-off [V]", nothing)
    upper = get(cell, "Upper voltage cut-off [V]", nothing)
    values = (
        get(negative, "OCP [V]", nothing), get(positive, "OCP [V]", nothing),
        get(negative, "Minimum stoichiometry", nothing), get(negative, "Maximum stoichiometry", nothing),
        get(positive, "Minimum stoichiometry", nothing), get(positive, "Maximum stoichiometry", nothing),
    )
    if !any(isnothing, values) && all(v -> isa(v, Real), values[3:end])
        ocp_n, ocp_p, sto_n_min, sto_n_max, sto_p_min, sto_p_max = values
        v_max = derive((up, un) -> up - un, evaluate_bpx_value(ocp_p, sto_p_min), evaluate_bpx_value(ocp_n, sto_n_max))
        v_min = derive((up, un) -> up - un, evaluate_bpx_value(ocp_p, sto_p_max), evaluate_bpx_value(ocp_n, sto_n_min))
        if isa(upper, Real) && !isnothing(v_max) && v_max - upper > VOLTAGE_TOLERANCE
            add!(report, :consistency, "Parameterisation: the maximum voltage given by the OCPs at the stoichiometry limits ($(round(v_max, digits = 4)) V) is above the upper voltage cut-off ($upper V).")
        end
        if isa(lower, Real) && !isnothing(v_min) && v_min - lower < -VOLTAGE_TOLERANCE
            add!(report, :consistency, "Parameterisation: the minimum voltage given by the OCPs at the stoichiometry limits ($(round(v_min, digits = 4)) V) is below the lower voltage cut-off ($lower V).")
        end
    end

    state = get(bpx_data, "State", nothing)
    initial_conditions = isa(state, AbstractDict) ? get(state, "Initial conditions", Dict()) : Dict()
    soc = get(initial_conditions, "Initial state-of-charge", nothing)
    if isa(soc, Real) && !(0 <= soc <= 1)
        add!(report, :consistency, "State → Initial conditions → Initial state-of-charge: $soc lies outside [0, 1].")
    end

    for (name, data) in validation_experiments(bpx_data)
        isa(data, AbstractDict) || continue
        current = get(data, "Current [A]", nothing)
        voltage = get(data, "Voltage [V]", nothing)
        if isa(current, AbstractVector) && isa(voltage, AbstractVector) && !isempty(voltage) && all(x -> isa(x, Real), current) && all(x -> isa(x, Real), voltage)
            check_current_sign!(report, name, data, -Float64.(current))
        end
    end
    return report
end

# ============================================================================
# Import: section converters
# ============================================================================

function convert_metadata(header::AbstractDict, report::ConversionReport)
    metadata = Dict{String, Any}()
    for key in ("Title", "Description", "References")
        haskey(header, key) && (metadata[key] = header[key])
    end
    metadata["Source"] = "Converted from a BPX $(get(header, "BPX", "")) parameter set"

    model = get(header, "Model", nothing)
    if model in ("DFN", "SPMe", "SPM")
        metadata["Models"] = Dict{String, Any}(
            "ModelFramework" => "P2D",
            "TransportInSolid" => "FullDiffusion",
        )
    end
    if model in ("SPMe", "SPM")
        add!(report, :model_differences, "The BPX file is parameterised for the $model model. BattMo simulates the full P2D (DFN) model with these parameters, so its results differ from a $model simulation." * (model == "SPM" ? " An SPM parameter set has no electrolyte and transport parameters; the corresponding BattMo parameters are listed below as undetermined." : ""))
    elseif model == "Partial"
        add!(report, :notes, "The BPX file is a partial parameter set; parameters it does not contain are listed as undetermined.")
    end
    return metadata
end

function infer_case(header::AbstractDict)
    text = lowercase(string(get(header, "Title", ""), " ", get(header, "Description", "")))
    if occursin("pouch", text)
        return "Pouch"
    elseif occursin("cylindrical", text) || occursin(r"\b(18650|21700|4680)\b", text)
        return "Cylindrical"
    else
        return nothing
    end
end

function convert_cell(section::BPXSection, header::AbstractDict, reference_temperature, cell_case, report::ConversionReport)
    cell = Dict{String, Any}()

    electrode_area = get_parameter(section, "Electrode area [m2]")
    number_of_pairs = get_parameter(section, "Number of electrode pairs connected in parallel to make a cell")

    # BPX: the cell consists of N_p electrode pairs of area A in parallel, each with one
    # negative coating, separator and positive coating (i_app = I / (A N_p)). In BattMo,
    # ElectrodeGeometricSurfaceArea is the area of one layer and the number of electrode
    # pairs of single coated electrodes is NumberOfLayersInParallel, which gives the same
    # total area A N_p.
    cell["ElectrodeGeometricSurfaceArea"] = electrode_area
    cell["NumberOfLayersInParallel"] = number_of_pairs
    cell["DoubleCoatedElectrodes"] = false
    cell["NominalCapacity"] = get_parameter(section, "Nominal cell capacity [A.h]")
    cell["ReferenceTemperature"] = reference_temperature
    cell["DeviceSurfaceArea"] = get_parameter(section, "External surface area [m2]")

    if !isnothing(cell_case)
        cell["Case"] = cell_case
    else
        case = infer_case(header)
        if isnothing(case)
            add!(report, :notes, "Cell → Case (cell format) is not given by BPX and could not be inferred from the header; it is left unset. Pass `cell_case` to set it.")
        else
            cell["Case"] = case
            add!(report, :notes, "Cell → Case = \"$case\" (cell format) was inferred from the header title or description, since BPX does not specify it. Pass `cell_case` to override it.")
        end
    end

    return cell
end

collect_numbers(value::Real) = [value]
collect_numbers(value::AbstractDict) = reduce(vcat, (collect_numbers(v) for v in values(value)); init = Real[])
collect_numbers(value) = Real[]

"""
    convert_state(state, report) -> (initial electrolyte concentration, heat transfer coefficient)

Process the BPX `State` section (BPX ≥ 1.0). The initial electrolyte concentration is a
BattMo cell parameter; the remaining entries are reported as operating conditions or as
unsupported features.
"""
function convert_state(state::AbstractDict, report::ConversionReport)
    initial_conditions = BPXSection("State → Initial conditions", get(state, "Initial conditions", Dict{String, Any}()), "InitialConditions")
    thermal_environment = BPXSection("State → Thermal environment", get(state, "Thermal environment", Dict{String, Any}()), "ThermalState")
    concentration = get_parameter(initial_conditions, "Initial electrolyte concentration [mol.m-3]")
    heat_transfer_coefficient = get_parameter(thermal_environment, "Heat transfer coefficient [W.m-2.K-1]")

    for (section, key, _) in PROTOCOL_PARAMETERS
        section == "Initial conditions" && get_parameter(initial_conditions, key)
        section == "Thermal environment" && get_parameter(thermal_environment, key)
    end
    for electrode in ("Negative electrode", "Positive electrode")
        key = "Initial hysteresis state: $electrode"
        if has_parameter(initial_conditions, key)
            get_parameter(initial_conditions, key)
            add!(report, :unsupported, "State → Initial conditions → $key: OCP hysteresis is not supported (see the hysteresis parameters).")
        end
    end

    degradation = get(state, "Degradation", nothing)
    if any(!iszero, collect_numbers(degradation))
        add!(report, :unsupported, "State → Degradation: the degradation state (loss of active material and of lithium inventory) is not supported. The parameters of the reference (unaged) cell are used.")
    end

    report_unconverted_keys!(report, initial_conditions)
    report_unconverted_keys!(report, thermal_environment)

    return concentration, heat_transfer_coefficient
end

function convert_electrolyte(section::BPXSection, initial_concentration, lumped, reference_temperature, report::ConversionReport)
    conductivity_activation_energy = get_parameter(section, "Conductivity activation energy [J.mol-1]")
    diffusivity_activation_energy = get_parameter(section, "Diffusivity activation energy [J.mol-1]")

    conductivity_key = location(section.name, "Conductivity [S.m-1]")
    diffusivity_key = location(section.name, "Diffusivity [m2.s-1]")
    conductivity = convert_bpx_function(get_parameter(section, "Conductivity [S.m-1]"), "c", report, conductivity_key)
    diffusivity = convert_bpx_function(get_parameter(section, "Diffusivity [m2.s-1]"), "c", report, diffusivity_key)

    if !isnothing(conductivity_activation_energy) || !isnothing(diffusivity_activation_energy)
        add!(report, :approximations, "Electrolyte: BattMo has no activation energies for the electrolyte, so the BPX activation energies are folded into the conductivity and diffusivity functions as Arrhenius factors exp(Ea / R (1 / $reference_temperature - 1 / T)). This is exact.")
    end

    electrolyte = Dict{String, Any}(
        "Concentration" => initial_concentration,
        "TransferenceNumber" => get_parameter(section, "Cation transference number"),
        "ChargeNumber" => 1,
        "Density" => lumped.density,
        "IonicConductivity" => apply_arrhenius(conductivity, conductivity_activation_energy, reference_temperature, report, conductivity_key),
        "DiffusionCoefficient" => apply_arrhenius(diffusivity, diffusivity_activation_energy, reference_temperature, report, diffusivity_key),
    )
    add_lumped_thermal_parameters!(electrolyte, lumped)

    report_unconverted_keys!(report, section)

    return electrolyte
end

function convert_electrode(section::BPXSection, polarity::Symbol, electrolyte_reference_concentration, lumped, report::ConversionReport)
    porosity = get_parameter(section, "Porosity")
    transport_efficiency = get_parameter(section, "Transport efficiency")
    bruggeman = compute_bruggeman_coefficient(porosity, transport_efficiency, section.name)
    solid_volume_fraction = derive(p -> 1.0 - p, porosity)

    maximum_concentration = get_parameter(section, "Maximum concentration [mol.m-3]")

    minimum_stoichiometry = get_parameter(section, "Minimum stoichiometry")
    maximum_stoichiometry = get_parameter(section, "Maximum stoichiometry")
    if polarity == :negative
        # The negative electrode is delithiated at SOC 0
        theta0 = minimum_stoichiometry
        theta100 = maximum_stoichiometry
    else
        # The positive electrode is lithiated at SOC 0
        theta0 = maximum_stoichiometry
        theta100 = minimum_stoichiometry
    end

    reaction_rate_constant = get_parameter(section, "Reaction rate constant [mol.m-2.s-1]")

    surface_area = get_parameter(section, "Surface area per unit volume [m-1]")
    particle_radius = get_parameter(section, "Particle radius [m]")
    active_mass_fraction = derive(
        (b, r, p) -> compute_active_mass_fraction(b, r, p, report, section.name),
        surface_area, particle_radius, porosity,
    )
    if !isnothing(active_mass_fraction) && active_mass_fraction < 1
        add!(report, :approximations, "$(section.name): BPX describes the active material only (volume fraction surface area × radius / 3 = $(round(surface_area * particle_radius / 3, sigdigits = 4)) of the coating). The rest of the solid ($(round((1 - active_mass_fraction) * solid_volume_fraction, sigdigits = 4)) of the coating) is lumped into the binder; the conductive additive has zero mass.")
    end

    place(key) = location(section.name, key)

    active_material = Dict{String, Any}(
        "MassFraction" => active_mass_fraction,
        "Density" => lumped.density,
        "VolumetricSurfaceArea" => surface_area,
        "DiffusionCoefficient" => convert_bpx_function(get_parameter(section, "Diffusivity [m2.s-1]"), "(c / cmax)", report, place("Diffusivity [m2.s-1]")),
        "ParticleRadius" => particle_radius,
        "MaximumConcentration" => maximum_concentration,
        "StoichiometricCoefficientAtSOC0" => theta0,
        "StoichiometricCoefficientAtSOC100" => theta100,
        "OpenCircuitPotential" => convert_bpx_function(get_parameter(section, "OCP [V]"), "(c / cmax)", report, place("OCP [V]")),
        "EntropyChange" => convert_bpx_function(get_parameter(section, "Entropic change coefficient [V.K-1]"), "(c / cmax)", report, place("Entropic change coefficient [V.K-1]")),
        "NumberOfElectronsTransfered" => 1,
        "ChargeTransferCoefficient" => 0.5,
        "ReactionRateConstant" => derive(
            (k, cmax, c_e_ref) -> k / (cmax * sqrt(c_e_ref)),
            reaction_rate_constant, maximum_concentration, electrolyte_reference_concentration,
        ),
        "ActivationEnergyOfDiffusion" => get_parameter(section, "Diffusivity activation energy [J.mol-1]"),
        "ActivationEnergyOfReaction" => get_parameter(section, "Reaction rate constant activation energy [J.mol-1]"),
    )

    hysteresis_keys = filter(key -> has_parameter(section, key), HYSTERESIS_PARAMETERS)
    if !isempty(hysteresis_keys)
        foreach(key -> get_parameter(section, key), hysteresis_keys)
        add!(report, :unsupported, "$(section.name) → $(join(hysteresis_keys, ", ")): BattMo has no OCP hysteresis model; the equilibrium OCP (\"OCP [V]\") is used for both lithiation and delithiation.")
    end

    # BPX gives the effective electronic conductivity of the porous coating, while
    # BattMo expects the intrinsic material conductivity
    effective_conductivity = get_parameter(section, "Conductivity [S.m-1]")
    intrinsic_conductivity = derive(
        (kappa, vf, b) -> kappa / vf^b,
        effective_conductivity, solid_volume_fraction, bruggeman,
    )
    active_material["ElectronicConductivity"] = intrinsic_conductivity

    add_lumped_thermal_parameters!(active_material, lumped)

    electrode = Dict{String, Any}(
        "Coating" => Dict{String, Any}(
            "Thickness" => get_parameter(section, "Thickness [m]"),
            "BruggemanCoefficient" => bruggeman,
            "EffectiveDensity" => derive(*, lumped.density, solid_volume_fraction),
        ),
        "ActiveMaterial" => active_material,
        "Binder" => inert_component(
            "Not provided by BPX; lumps all inactive solid (binder and conductive additive).",
            derive(f -> 1.0 - f, active_mass_fraction), intrinsic_conductivity, lumped,
        ),
        "ConductiveAdditive" => inert_component(
            "Not provided by BPX; zero-mass placeholder.",
            0.0, intrinsic_conductivity, lumped,
        ),
    )

    report_unconverted_keys!(report, section)

    return electrode
end

function convert_separator(section::BPXSection, lumped, report::ConversionReport)
    porosity = get_parameter(section, "Porosity")
    transport_efficiency = get_parameter(section, "Transport efficiency")

    separator = Dict{String, Any}(
        "Thickness" => get_parameter(section, "Thickness [m]"),
        "Porosity" => porosity,
        "BruggemanCoefficient" => compute_bruggeman_coefficient(porosity, transport_efficiency, section.name),
        "Density" => lumped.density,
    )
    add_lumped_thermal_parameters!(separator, lumped)

    report_unconverted_keys!(report, section)

    return separator
end

"""
    report_thermal_model!(report, cell_section, cell_parameters, lumped, heat_transfer_coefficient)

Report the differences between the lumped thermal model of BPX and the BattMo thermal
model, when the BPX input contains thermal parameters.
"""
function report_thermal_model!(report::ConversionReport, cell_section::BPXSection, cell_parameters, lumped, heat_transfer_coefficient)
    volume = get_parameter(cell_section, "Volume [m3]")
    external_area = cell_parameters["Cell"]["DeviceSurfaceArea"]
    thermal = (lumped.density, lumped.specific_heat_capacity, volume, external_area, heat_transfer_coefficient)
    all(isnothing, thermal) && return report

    area = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]
    number_of_pairs = cell_parameters["Cell"]["NumberOfLayersInParallel"]
    thicknesses = (
        cell_parameters["NegativeElectrode"]["Coating"]["Thickness"],
        cell_parameters["Separator"]["Thickness"],
        cell_parameters["PositiveElectrode"]["Coating"]["Thickness"],
    )
    stack_volume = derive((a, n, l...) -> a * n * sum(l), area, number_of_pairs, thicknesses...)

    message = "Thermal model: BPX uses a lumped heat balance for the whole cell, with heat capacity density × specific heat capacity × cell volume"
    message *= isnothing(volume) ? "" : " (cell volume $volume m3)"
    message *= " and cooling by the heat transfer coefficient over the external surface area"
    message *= isnothing(external_area) ? "." : " ($external_area m2)."
    message *= " BattMo resolves the temperature in the simulated electrode stack only"
    if !isnothing(stack_volume)
        message *= " (volume $(round(stack_volume, sigdigits = 4)) m3"
        message *= isnothing(volume) ? ")" : ", $(round(100 * stack_volume / volume, digits = 1)) % of the cell volume)"
    end
    message *= " and cools it through the faces of the simulation grid with Cell → SurfaceHeatTransferCoefficient. The cell volume, the external surface area and the heat transfer coefficient are not used, so thermal simulations do not reproduce BPX. Isothermal simulations are unaffected."
    add!(report, :model_differences, message)

    if !isnothing(volume)
        add!(report, :unused, "Parameterisation → Cell → Volume [m3]: volume of the BPX lumped thermal model (see the thermal model difference).")
    end
    if !isnothing(heat_transfer_coefficient)
        add!(report, :unused, "State → Thermal environment → Heat transfer coefficient [W.m-2.K-1]: not equivalent to the BattMo SurfaceHeatTransferCoefficient (see the thermal model difference).")
    end
    if isnothing(lumped.thermal_conductivity)
        add!(report, :notes, "BPX 1.x has no thermal conductivity (the BPX thermal model is lumped); the BattMo ThermalConductivity parameters are undetermined.")
    end
    return report
end

function report_protocol_parameters!(report::ConversionReport, bpx_data::AbstractDict)
    sections = operating_condition_sections(bpx_data)
    for (section, key, protocol_key) in PROTOCOL_PARAMETERS
        data = sections[section]
        if haskey(data, key)
            add!(report, :protocol, "$key = $(data[key]) → CyclingProtocol[\"$protocol_key\"]")
        end
    end
    return report
end

# ============================================================================
# Import: public API
# ============================================================================

"""
    prepare_import(bpx_data, report; validate, strict) -> Dict

Bring a BPX input to the v1.x layout and, with `validate`, check it against the schema
and for internal consistency. With `strict`, schema violations raise an error.
"""
function prepare_import(bpx_data::AbstractDict, report::ConversionReport; validate::Bool, strict::Bool)
    haskey(bpx_data, "Parameterisation") || error("The input is not BPX formatted: the top-level \"Parameterisation\" section is missing.")
    bpx_data = prepare_bpx_input(bpx_data, report)
    if validate
        for issue in schema_issues(bpx_data)
            add!(report, :schema, issue)
        end
        report.validated = true
        check_consistency!(report, bpx_data)
    end
    raise_if_strict(report, strict)
    return bpx_data
end

"""
    convert_cell_parameters(bpx_data, report; cell_case) -> Dict

Convert a prepared BPX input (see `prepare_import`) to BattMo cell parameters.
"""
function convert_cell_parameters(bpx_data::AbstractDict, report::ConversionReport; cell_case = nothing)
    parameterisation = bpx_data["Parameterisation"]

    for electrode in ("Negative electrode", "Positive electrode")
        if haskey(get(parameterisation, electrode, Dict()), "Particle")
            error("BPX import: the \"$electrode\" is a blended electrode (\"Particle\" node with several particle types). BattMo models a single active material per electrode, so blended electrodes cannot be converted.")
        end
    end

    header = get(bpx_data, "Header", Dict{String, Any}())

    function section(name, definition)
        data = get(parameterisation, name, nothing)
        if !isa(data, AbstractDict)
            # A missing section means all its parameters are missing; they are
            # zero-filled like any other missing parameter
            data = Dict{String, Any}()
        end
        return BPXSection(location("Parameterisation", name), data, definition)
    end

    cell_section = section("Cell", "Cell")
    electrolyte_section = section("Electrolyte", "Electrolyte")
    negative_electrode_section = section("Negative electrode", "ElectrodeSingle")
    positive_electrode_section = section("Positive electrode", "ElectrodeSingle")
    separator_section = section("Separator", "Contact")
    user_defined_section = section("User-defined", nothing)

    density = get_parameter(cell_section, "Density [kg.m-3]")
    if !isnothing(density)
        add!(report, :approximations, "BPX only gives a lumped cell density ($density kg.m-3), which is used as the density of every component (active material, inactive solid, electrolyte and separator). The simulated electrochemistry is unaffected; masses and gravimetric quantities are approximate.")
    end

    lumped = (
        density = density,
        specific_heat_capacity = get_parameter(cell_section, "Specific heat capacity [J.K-1.kg-1]"),
        # Not a BPX v1.x parameter; kept in "User-defined" when converting legacy files
        thermal_conductivity = get_parameter(user_defined_section, "Thermal conductivity [W.m-1.K-1]"),
    )

    reference_temperature = get_parameter(cell_section, "Reference temperature [K]")
    if isnothing(reference_temperature)
        reference_temperature = DEFAULT_REFERENCE_TEMPERATURE
    end
    for (section_name, key, _) in PROTOCOL_PARAMETERS
        section_name == "Cell" && get_parameter(cell_section, key)
    end

    state = get(bpx_data, "State", nothing)
    electrolyte_reference_concentration, heat_transfer_coefficient = isa(state, AbstractDict) ? convert_state(state, report) : (nothing, nothing)

    cell_parameters = Dict{String, Any}(
        "Metadata" => convert_metadata(header, report),
        "Cell" => convert_cell(cell_section, header, reference_temperature, cell_case, report),
        "NegativeElectrode" => convert_electrode(negative_electrode_section, :negative, electrolyte_reference_concentration, lumped, report),
        "PositiveElectrode" => convert_electrode(positive_electrode_section, :positive, electrolyte_reference_concentration, lumped, report),
        "Separator" => convert_separator(separator_section, lumped, report),
        "Electrolyte" => convert_electrolyte(electrolyte_section, electrolyte_reference_concentration, lumped, reference_temperature, report),
    )

    report_thermal_model!(report, cell_section, cell_parameters, lumped, heat_transfer_coefficient)
    report_unconverted_keys!(report, cell_section)
    report_unconverted_keys!(report, user_defined_section)

    zeroed_parameters = String[]
    fill_missing_with_zero!(cell_parameters, "", zeroed_parameters)
    for path in sort(zeroed_parameters)
        add!(report, :zero_filled, path)
    end

    return cell_parameters
end

"""
    parse_bpx_to_cell_parameters(bpx_data::AbstractDict; validate = true, strict = false, cell_case = nothing) -> Dict{String, Any}

Convert already-parsed BPX data to the format expected by `CellParameters`.

Legacy BPX v0.x inputs are converted to the v1.x layout first. With `validate`, the
input is checked against the bundled BPX schema and for internal consistency. All
findings of the conversion are emitted as one warning and one info message; with
`strict`, violations of the BPX standard (schema) raise an error instead.
`cell_case` sets `Cell.Case` (e.g. `"Pouch"`), which is otherwise inferred from the
header text. Blended electrodes are not supported and raise an error.

The operating conditions of the BPX input are listed in the report; use
`parse_bpx_to_cycling_protocol` to convert them to a cycling protocol.
"""
function parse_bpx_to_cell_parameters(
        bpx_data::AbstractDict;
        validate::Bool = true,
        strict::Bool = false,
        cell_case::Union{Nothing, AbstractString} = nothing,
    )::Dict{String, Any}
    report = ConversionReport("import")
    bpx_data = prepare_import(bpx_data, report; validate, strict)
    cell_parameters = convert_cell_parameters(bpx_data, report; cell_case)
    report_protocol_parameters!(report, bpx_data)
    emit_report(report)
    return cell_parameters
end

"""
    load_from_bpx_file(file_path::String; validate = true, strict = false, cell_case = nothing) -> Dict{String, Any}

Load a BPX (Battery Parameter eXchange) JSON file and convert it to the cell
parameter format expected by `CellParameters`. See `parse_bpx_to_cell_parameters`
for the keyword arguments.

# Example
```julia
cell_parameters = load_cell_parameters(; from_bpx_file_path = "path/to/bpx_input.json")
```
"""
function load_from_bpx_file(file_path::String; kwargs...)::Dict{String, Any}
    return parse_bpx_to_cell_parameters(JSON.parsefile(file_path); kwargs...)
end

# ============================================================================
# Import: cycling protocol and full simulation input
# ============================================================================

function operating_condition_sections(bpx_data::AbstractDict)
    state = get(bpx_data, "State", nothing)
    state = isa(state, AbstractDict) ? state : Dict{String, Any}()
    return Dict(
        "Cell" => get(get(bpx_data, "Parameterisation", Dict()), "Cell", Dict()),
        "Initial conditions" => get(state, "Initial conditions", Dict()),
        "Thermal environment" => get(state, "Thermal environment", Dict()),
    )
end

function validation_experiments(bpx_data::AbstractDict)
    validation = get(bpx_data, "Validation", nothing)
    return isa(validation, AbstractDict) ? validation : Dict{String, Any}()
end

# Voltage change below which the direction of a validation experiment is not checked
const VOLTAGE_TREND_TOLERANCE = 1.0e-2 # V

"""
    check_current_sign!(report, name, data, currents)

Check that the sign of the current of a validation experiment matches the BPX convention
(positive for charging). `currents` is the current in the BattMo convention (positive
for discharging). For experiments that only charge or only discharge, the current must
match the change of the voltage and, when the name says so, the type of experiment.
"""
function check_current_sign!(report::ConversionReport, name::AbstractString, data::AbstractDict, currents::AbstractVector)
    nonzero = filter(!iszero, currents)
    # Experiments with rests between charge and discharge steps, or without current, are not checked
    (isempty(nonzero) || !(all(>(0), nonzero) || all(<(0), nonzero))) && return report
    discharging = nonzero[1] > 0
    direction = discharging ? "discharge" : "charge"
    bpx_sign = discharging ? "negative" : "positive"

    voltages = Float64.(data["Voltage [V]"])
    change = voltages[end] - voltages[1]
    if abs(change) > VOLTAGE_TREND_TOLERANCE && (change < 0) != discharging
        add!(report, :consistency, "Validation → $name: the current is $bpx_sign, which is a $direction in the BPX convention (positive current for charging), but the voltage $(change > 0 ? "rises" : "falls") from $(voltages[1]) V to $(voltages[end]) V. The sign of the current is probably reversed; the simulation then $(discharging ? "discharges" : "charges") the cell.")
    end

    lowercase_name = lowercase(name)
    named_discharge = occursin("discharg", lowercase_name)
    named_charge = !named_discharge && occursin("charg", lowercase_name)
    if (named_discharge && !discharging) || (named_charge && discharging)
        add!(report, :consistency, "Validation → $name: the current is $bpx_sign, which is a $direction in the BPX convention (positive current for charging), but the name of the experiment says $(named_discharge ? "discharge" : "charge").")
    end
    return report
end

"""
    convert_cycling_protocol(bpx_data, report; experiment) -> Dict

Convert the operating conditions of a prepared BPX input (see `prepare_import`) to a
BattMo cycling protocol. Without `experiment`, a constant current discharge with
`DRate = 1` is set up; with `experiment`, the current of that validation experiment is
prescribed with the `InputCurrentSeries` protocol.
"""
function convert_cycling_protocol(bpx_data::AbstractDict, report::ConversionReport; experiment = nothing)
    protocol = Dict{String, Any}()

    sections = operating_condition_sections(bpx_data)
    for (section, key, protocol_key) in PROTOCOL_PARAMETERS
        value = get(sections[section], key, nothing)
        isa(value, Real) && (protocol[protocol_key] = value)
    end

    experiments = validation_experiments(bpx_data)
    available = isempty(experiments) ? "the input has no validation experiments" :
        "validation experiments: " * join(("\"$name\"" for name in sort(collect(keys(experiments)))), ", ")

    if isnothing(experiment)
        protocol["Protocol"] = "CC"
        protocol["InitialControl"] = "discharging"
        protocol["TotalNumberOfCycles"] = 0
        protocol["DRate"] = 1.0
        discharging = true
        description = "Constant current discharge within the voltage window of the BPX parameter set."
        add!(report, :assumed, "CyclingProtocol: BPX does not define a cycling protocol, so a constant current discharge with DRate = 1.0 is set up. The DRate is relative to the theoretical cell capacity computed by BattMo, not to the BPX nominal capacity. Set DRate, or pass `experiment` to use the current of a validation experiment ($available).")
    else
        haskey(experiments, experiment) || throw(ArgumentError("BPX import: there is no validation experiment \"$experiment\" ($available)."))
        data = experiments[experiment]
        times = Float64.(data["Time [s]"])
        # BPX uses a positive current for charging, BattMo for discharging
        currents = -Float64.(data["Current [A]"])
        if !issorted(times, lt = <)
            throw(ArgumentError("BPX import: the times of the validation experiment \"$experiment\" are not strictly increasing, which the InputCurrentSeries protocol requires."))
        end
        if times[1] != 0
            add!(report, :notes, "CyclingProtocol: the times of the validation experiment \"$experiment\" start at $(times[1]) s and are shifted to start at 0 s.")
            times .-= times[1]
        end
        check_current_sign!(report, experiment, data, currents)
        protocol["Protocol"] = "InputCurrentSeries"
        protocol["Times"] = times
        protocol["Currents"] = currents
        first_current = findfirst(!iszero, currents)
        discharging = isnothing(first_current) || currents[first_current] > 0
        description = "Current of the BPX validation experiment \"$experiment\"."
        add!(report, :notes, "CyclingProtocol: the current of the validation experiment \"$experiment\" ($(length(times)) points over $(times[end]) s) is prescribed with the InputCurrentSeries protocol, which uses the time steps of the data. The sign of the current is reversed, since BPX uses a positive current for charging and BattMo for discharging.")
        if !haskey(protocol, "InitialTemperature") && haskey(data, "Temperature [K]")
            protocol["InitialTemperature"] = Float64(data["Temperature [K]"][1])
            add!(report, :assumed, "CyclingProtocol: the initial temperature is not given; InitialTemperature = $(protocol["InitialTemperature"]) K is taken from the start of the validation experiment \"$experiment\".")
        end
    end

    if !haskey(protocol, "InitialStateOfCharge")
        protocol["InitialStateOfCharge"] = discharging ? 1.0 : 0.0
        add!(report, :assumed, "CyclingProtocol: the initial state of charge is not given; InitialStateOfCharge = $(protocol["InitialStateOfCharge"]) is used, since the protocol starts with $(discharging ? "a discharge" : "a charge").")
    end
    if !haskey(protocol, "InitialTemperature")
        protocol["InitialTemperature"] = DEFAULT_REFERENCE_TEMPERATURE
        add!(report, :assumed, "CyclingProtocol: the initial temperature is not given; InitialTemperature = $DEFAULT_REFERENCE_TEMPERATURE K is used.")
    end
    if !haskey(protocol, "AmbientTemperature")
        protocol["AmbientTemperature"] = protocol["InitialTemperature"]
        add!(report, :assumed, "CyclingProtocol: the ambient temperature is not given; AmbientTemperature = InitialTemperature = $(protocol["AmbientTemperature"]) K is used.")
    end

    title = get(get(bpx_data, "Header", Dict()), "Title", nothing)
    protocol["Metadata"] = Dict{String, Any}(
        "Title" => isa(title, AbstractString) ? title : "BPX cycling protocol",
        "Description" => description,
        "Source" => "Converted from BPX",
    )
    return protocol
end

"""
    parse_bpx_to_cycling_protocol(bpx_data::AbstractDict; experiment = nothing, validate = true, strict = false) -> Dict{String, Any}

Convert the operating conditions of already-parsed BPX data to the format expected by
`CyclingProtocol`.

The voltage cut-offs, initial state of charge, initial temperature and ambient
temperature are taken from the BPX input; values that the input does not give are set
to defaults and reported. BPX does not define a cycling experiment, so

- without `experiment`, a constant current discharge with `DRate = 1` is set up (the
  DRate is relative to the theoretical capacity computed by BattMo);
- with `experiment`, the name of an experiment in the BPX `Validation` section (e.g.
  `"1C discharge"`), its measured current is prescribed with the `InputCurrentSeries`
  protocol, so that the simulation can be compared with the validation data.

`validate` and `strict` are as for `parse_bpx_to_cell_parameters`.
"""
function parse_bpx_to_cycling_protocol(
        bpx_data::AbstractDict;
        experiment::Union{Nothing, AbstractString} = nothing,
        validate::Bool = true,
        strict::Bool = false,
    )::Dict{String, Any}
    report = ConversionReport("import of the cycling protocol")
    bpx_data = prepare_import(bpx_data, report; validate, strict)
    protocol = convert_cycling_protocol(bpx_data, report; experiment)
    emit_report(report)
    return protocol
end

"""
    load_cycling_protocol_from_bpx_file(file_path::String; experiment = nothing, validate = true, strict = false) -> Dict{String, Any}

Load a BPX JSON file and convert its operating conditions to the format expected by
`CyclingProtocol`. See `parse_bpx_to_cycling_protocol` for the keyword arguments.

# Example
```julia
cycling_protocol = load_cycling_protocol(; from_bpx_file_path = "path/to/bpx_input.json", bpx_options = (experiment = "1C discharge",))
```
"""
function load_cycling_protocol_from_bpx_file(file_path::String; kwargs...)::Dict{String, Any}
    return parse_bpx_to_cycling_protocol(JSON.parsefile(file_path); kwargs...)
end

"""
    parse_bpx_to_full_simulation_input(bpx_data::AbstractDict; experiment = nothing, validate = true, strict = false, cell_case = nothing) -> Dict{String, Any}

Convert already-parsed BPX data to the format expected by `FullSimulationInput`: the
cell parameters (`parse_bpx_to_cell_parameters`) and the cycling protocol
(`parse_bpx_to_cycling_protocol`), together with the default BattMo P2D model,
simulation and solver settings. The findings of both conversions are emitted in one
report. The keyword arguments are those of the two conversions.
"""
function parse_bpx_to_full_simulation_input(
        bpx_data::AbstractDict;
        experiment::Union{Nothing, AbstractString} = nothing,
        validate::Bool = true,
        strict::Bool = false,
        cell_case::Union{Nothing, AbstractString} = nothing,
    )::Dict{String, Any}
    report = ConversionReport("import")
    bpx_data = prepare_import(bpx_data, report; validate, strict)
    cell_parameters = convert_cell_parameters(bpx_data, report; cell_case)
    cycling_protocol = convert_cycling_protocol(bpx_data, report; experiment)

    model = get(get(bpx_data, "Header", Dict()), "Model", "DFN")
    add!(report, :notes, "The model, simulation and solver settings are the BattMo defaults for the P2D (DFN) model" * (model == "DFN" ? "." : ", also for this $model parameter set."))
    emit_report(report)

    return Dict{String, Any}(
        "Metadata" => Dict{String, Any}(
            "Title" => get(cell_parameters["Metadata"], "Title", "BPX parameter set"),
            "Description" => "Simulation input converted from a BPX parameter set.",
        ),
        "BaseModel" => "LithiumIonBattery",
        "ModelSettings" => BattMoModule.load_model_settings(; from_default_set = "p2d").all,
        "CellParameters" => cell_parameters,
        "CyclingProtocol" => cycling_protocol,
        "SimulationSettings" => BattMoModule.load_simulation_settings(; from_default_set = "p2d").all,
        "SolverSettings" => BattMoModule.load_solver_settings(; from_default_set = "default").all,
    )
end

"""
    load_full_simulation_input_from_bpx_file(file_path::String; experiment = nothing, validate = true, strict = false, cell_case = nothing) -> Dict{String, Any}

Load a BPX JSON file and convert it to the format expected by `FullSimulationInput`.
See `parse_bpx_to_full_simulation_input` for the keyword arguments.

# Example
```julia
simulation_input = load_full_simulation_input(; from_bpx_file_path = "path/to/bpx_input.json", bpx_options = (experiment = "1C discharge",))
output = run_simulation(simulation_input)
```
"""
function load_full_simulation_input_from_bpx_file(file_path::String; kwargs...)::Dict{String, Any}
    return parse_bpx_to_full_simulation_input(JSON.parsefile(file_path); kwargs...)
end

# ============================================================================
# Export: BattMo → BPX
# ============================================================================

# Access to BattMo cell parameters that records which parameters were exported, so that
# parameters without a BPX counterpart can be reported.
struct TrackedParameters
    data::AbstractDict
    used::Set{String}
end

function battmo_value(parameters::TrackedParameters, path::String...)
    value = parameters.data
    for (i, key) in enumerate(path)
        (isa(value, AbstractDict) && haskey(value, key)) || return nothing
        value = value[key]
        i == length(path) && push!(parameters.used, join(path, "."))
    end
    return value
end

function leaf_paths(data::AbstractDict, prefix::String = "")
    paths = String[]
    for (key, value) in data
        path = prefix == "" ? key : prefix * "." * key
        if isa(value, AbstractDict) && !(haskey(value, "x") && haskey(value, "y")) && !haskey(value, "FunctionName")
            append!(paths, leaf_paths(value, path))
        else
            push!(paths, path)
        end
    end
    return paths
end

# BattMo parameters that are fixed by the BPX model or that only describe the parameter
# set; they are checked separately or not exported.
const EXPORT_IGNORED_PARAMETERS = r"(^Metadata\.|\.Description$|\.ChargeNumber$|\.NumberOfElectronsTransfered$|\.ChargeTransferCoefficient$|^Cell\.Case$)"

const ARRHENIUS_PATTERN = r"^(.*) \* exp\(([-+0-9.eE]+) / [-+0-9.eE]+ \* \(1\.0 / ([-+0-9.eE]+) - 1\.0 / T\)\)$"

function strip_outer_parentheses(expression::AbstractString)
    expression = strip(expression)
    while startswith(expression, "(") && endswith(expression, ")")
        depth = 0
        closes_at_end = true
        for (i, character) in enumerate(collect(expression))
            depth += character == '(' ? 1 : character == ')' ? -1 : 0
            if depth == 0 && i < length(collect(expression))
                closes_at_end = false
                break
            end
        end
        closes_at_end || break
        expression = strip(expression[nextind(expression, 1):prevind(expression, lastindex(expression))])
    end
    return String(expression)
end

"""
    export_function(value, variable, report, place; maximum_concentration = nothing, reference_temperature = nothing)

Convert a BattMo parameter value to a BPX FloatFunctionTable value. `variable` is
`:concentration` for electrolyte functions of `c` and `:stoichiometry` for electrode
functions of `c / cmax`. For electrolyte functions, an Arrhenius factor added by the
BPX import is recovered as activation energy. Return `(value, activation_energy)`.
"""
function export_function(value, variable::Symbol, report::ConversionReport, place::String; maximum_concentration = nothing, reference_temperature = nothing)
    if isnothing(value) || isa(value, Real)
        return value, nothing
    elseif isa(value, AbstractDict) && haskey(value, "x") && haskey(value, "y")
        return Dict{String, Any}("x" => value["x"], "y" => value["y"]), nothing
    elseif isa(value, AbstractDict) && haskey(value, "FunctionName")
        add!(report, :unsupported, "$place: the Julia function \"$(value["FunctionName"])\" cannot be expressed in BPX, which only allows function strings and tables. Not exported.")
        return nothing, nothing
    elseif !isa(value, AbstractString)
        add!(report, :unsupported, "$place: values of type $(typeof(value)) cannot be exported. Not exported.")
        return nothing, nothing
    end

    expression = String(strip(value))
    activation_energy = nothing
    if variable == :concentration
        m = match(ARRHENIUS_PATTERN, expression)
        if !isnothing(m)
            expression = strip_outer_parentheses(m.captures[1])
            activation_energy = something(tryparse(Int, m.captures[2]), parse(Float64, m.captures[2]))
            arrhenius_reference = parse(Float64, m.captures[3])
            if !isnothing(reference_temperature) && !isapprox(arrhenius_reference, reference_temperature)
                add!(report, :model_differences, "$place: the Arrhenius reference temperature of the function ($arrhenius_reference K) differs from Cell → ReferenceTemperature ($reference_temperature K), which BPX uses for all Arrhenius relations.")
            end
            number = tryparse(Float64, expression)
            isnothing(number) || return number, activation_energy
        end
        expression = replace(expression, r"\bc\b" => "x")
    else
        expression = replace(expression, r"\(\s*c\s*/\s*cmax\s*\)" => "x")
        if occursin(r"\b(c|cmax)\b", expression)
            if isnothing(maximum_concentration)
                add!(report, :unsupported, "$place: the function depends on c and cmax, but the maximum concentration is unknown. Not exported.")
                return nothing, nothing
            end
            expression = replace(expression, r"\bc\b" => "(x * $maximum_concentration)")
            expression = replace(expression, r"\bcmax\b" => string(maximum_concentration))
        end
    end
    if occursin(r"\b(T|refT)\b", expression)
        add!(report, :unsupported, "$place: the function depends on temperature, while BPX functions depend on a single variable (temperature dependence is given by activation energies and the entropic change coefficient). Not exported.")
        return nothing, nothing
    end
    expression = replace(expression, "^" => "**")
    _, issue = parse_bpx_expression(expression)
    if !isnothing(issue)
        add!(report, :schema, "$place: the exported function string $issue.")
    end
    return expression, activation_energy
end

function add_value!(target::AbstractDict, key::String, value)
    isnothing(value) || (target[key] = value)
    return target
end

function export_electrode(parameters::TrackedParameters, name::String, polarity::Symbol, initial_concentration, report::ConversionReport)
    bpx_name = polarity == :negative ? "Negative electrode" : "Positive electrode"
    place(key) = location("Parameterisation", bpx_name, key)
    get_value(path...) = battmo_value(parameters, name, path...)

    electrode = Dict{String, Any}()
    coating = parameters.data[name]
    volume_fraction, volume_fractions = try
        vf, vfs, _ = BattMoModule.compute_volume_fraction(coating)
        foreach(component -> foreach(key -> get_value(component, key), ("MassFraction", "Density")), ("ActiveMaterial", "Binder", "ConductiveAdditive"))
        get_value("Coating", "EffectiveDensity")
        vf, vfs
    catch
        add!(report, :unsupported, "$name: the coating volume fraction cannot be computed (missing mass fractions, densities or effective density); porosity, transport efficiency and conductivity are not exported.")
        nothing, nothing
    end
    porosity = derive(vf -> 1 - vf, volume_fraction)
    bruggeman = get_value("Coating", "BruggemanCoefficient")

    maximum_concentration = get_value("ActiveMaterial", "MaximumConcentration")
    theta0 = get_value("ActiveMaterial", "StoichiometricCoefficientAtSOC0")
    theta100 = get_value("ActiveMaterial", "StoichiometricCoefficientAtSOC100")
    if !isnothing(theta0) && !isnothing(theta100)
        electrode["Minimum stoichiometry"] = min(theta0, theta100)
        electrode["Maximum stoichiometry"] = max(theta0, theta100)
    end
    add_value!(electrode, "Maximum concentration [mol.m-3]", maximum_concentration)
    radius = get_value("ActiveMaterial", "ParticleRadius")
    surface_area = get_value("ActiveMaterial", "VolumetricSurfaceArea")
    add_value!(electrode, "Particle radius [m]", radius)
    add_value!(electrode, "Surface area per unit volume [m-1]", surface_area)
    add_value!(electrode, "Thickness [m]", get_value("Coating", "Thickness"))
    add_value!(electrode, "Porosity", porosity)
    add_value!(electrode, "Transport efficiency", derive((p, b) -> p^b, porosity, bruggeman))

    for (bpx_key, battmo_key) in (
            ("Diffusivity [m2.s-1]", "DiffusionCoefficient"),
            ("OCP [V]", "OpenCircuitPotential"),
            ("Entropic change coefficient [V.K-1]", "EntropyChange"),
        )
        value, _ = export_function(get_value("ActiveMaterial", battmo_key), :stoichiometry, report, place(bpx_key); maximum_concentration)
        add_value!(electrode, bpx_key, value)
    end

    rate_constant = get_value("ActiveMaterial", "ReactionRateConstant")
    if isa(rate_constant, Real)
        add_value!(electrode, "Reaction rate constant [mol.m-2.s-1]", derive((r0, cmax, ce0) -> r0 * cmax * sqrt(ce0), rate_constant, maximum_concentration, initial_concentration))
    elseif !isnothing(rate_constant)
        add!(report, :unsupported, "$name → ActiveMaterial → ReactionRateConstant: only a constant reaction rate constant can be expressed in BPX. Not exported.")
    end
    add_value!(electrode, "Diffusivity activation energy [J.mol-1]", get_value("ActiveMaterial", "ActivationEnergyOfDiffusion"))
    add_value!(electrode, "Reaction rate constant activation energy [J.mol-1]", get_value("ActiveMaterial", "ActivationEnergyOfReaction"))

    # BattMo intrinsic conductivity (volume-weighted over the solid components) to the
    # BPX effective conductivity of the porous coating
    conductivities = [get_value(component, "ElectronicConductivity") for component in ("ActiveMaterial", "Binder", "ConductiveAdditive")]
    if !isnothing(volume_fraction) && !isnothing(bruggeman) && all(c -> isa(c, Real), conductivities)
        intrinsic = sum(volume_fractions .* conductivities)
        electrode["Conductivity [S.m-1]"] = intrinsic * volume_fraction^bruggeman
    end

    # BPX defines the active material volume fraction as surface area × radius / 3, which
    # sets the capacity of the BPX model
    if !isnothing(volume_fraction) && isa(surface_area, Real) && isa(radius, Real)
        battmo_fraction = volume_fraction * volume_fractions[1]
        bpx_fraction = surface_area * radius / 3
        if !isapprox(battmo_fraction, bpx_fraction; rtol = 1.0e-3)
            add!(report, :model_differences, "$name: the BattMo active material volume fraction ($(round(battmo_fraction, sigdigits = 4))) differs from the one BPX derives from surface area × radius / 3 ($(round(bpx_fraction, sigdigits = 4))). A BPX model gives a $(round(100 * (bpx_fraction / battmo_fraction - 1), digits = 1)) % different electrode capacity.")
        end
    end

    electrons = get_value("ActiveMaterial", "NumberOfElectronsTransfered")
    transfer = get_value("ActiveMaterial", "ChargeTransferCoefficient")
    if (isa(electrons, Real) && electrons != 1) || (isa(transfer, Real) && transfer != 0.5)
        add!(report, :model_differences, "$name: BPX assumes a single-electron reaction with symmetric Butler-Volmer kinetics (charge transfer coefficient 0.5); this parameter set has $electrons electrons and charge transfer coefficient $transfer.")
    end

    return electrode
end

function export_lumped_thermal!(cell::AbstractDict, parameters::TrackedParameters, report::ConversionReport)
    data = parameters.data
    # Mass and heat capacity per unit electrode area of the coatings, electrolyte and separator
    try
        mass = 0.0
        heat_capacity = 0.0
        thickness = 0.0
        electrolyte = data["Electrolyte"]
        for name in ("NegativeElectrode", "PositiveElectrode")
            electrode = data[name]
            vf, _, effective_density = BattMoModule.compute_volume_fraction(electrode)
            L = electrode["Coating"]["Thickness"]
            solid_cp = sum(electrode[c]["MassFraction"] * electrode[c]["SpecificHeatCapacity"] for c in ("ActiveMaterial", "Binder", "ConductiveAdditive"))
            solid_mass = effective_density * L
            electrolyte_mass = electrolyte["Density"] * (1 - vf) * L
            mass += solid_mass + electrolyte_mass
            heat_capacity += solid_mass * solid_cp + electrolyte_mass * electrolyte["SpecificHeatCapacity"]
            thickness += L
        end
        separator = data["Separator"]
        L = separator["Thickness"]
        separator_mass = separator["Density"] * (1 - separator["Porosity"]) * L
        electrolyte_mass = electrolyte["Density"] * separator["Porosity"] * L
        mass += separator_mass + electrolyte_mass
        heat_capacity += separator_mass * separator["SpecificHeatCapacity"] + electrolyte_mass * electrolyte["SpecificHeatCapacity"]
        thickness += L

        cell["Density [kg.m-3]"] = mass / thickness
        cell["Specific heat capacity [J.K-1.kg-1]"] = heat_capacity / mass
        if haskey(cell, "Electrode area [m2]")
            cell["Volume [m3]"] = cell["Electrode area [m2]"] * cell["Number of electrode pairs connected in parallel to make a cell"] * thickness
        end
        for path in ("Electrolyte.Density", "Electrolyte.SpecificHeatCapacity", "Separator.Density", "Separator.SpecificHeatCapacity")
            push!(parameters.used, path)
        end
        for name in ("NegativeElectrode", "PositiveElectrode"), component in ("ActiveMaterial", "Binder", "ConductiveAdditive")
            push!(parameters.used, "$name.$component.SpecificHeatCapacity")
        end
        add!(report, :approximations, "Cell: the BPX lumped density, specific heat capacity and volume are computed from the coatings, electrolyte and separator (the simulated electrode stack); current collectors and casing are not included.")
    catch
        add!(report, :notes, "Cell: the lumped thermal parameters (density, specific heat capacity, volume) are not exported, because the densities or specific heat capacities of the components are incomplete.")
    end

    paths = Tuple{Vararg{String}}[("Electrolyte",), ("Separator",)]
    for name in ("NegativeElectrode", "PositiveElectrode"), component in ("ActiveMaterial", "Binder", "ConductiveAdditive")
        push!(paths, (name, component))
    end
    values = [battmo_value(parameters, path..., "ThermalConductivity") for path in paths]
    conductivities = unique(filter(!isnothing, values))
    return length(conductivities) == 1 ? only(conductivities) : nothing
end

"""
    convert_to_bpx(cell_parameters; cycling_protocol = nothing, validate = true, strict = false) -> Dict{String, Any}

Convert BattMo cell parameters (a `CellParameters` or a `Dict`) to a BPX $(BPX_SCHEMA_VERSION)
parameter set (DFN model). The voltage cut-offs, initial state-of-charge and
temperatures, which BPX requires or stores in its `State` section, are taken from
`cycling_protocol` (a `CyclingProtocol` or a `Dict`) when given.

The inverse of the BPX import conventions is applied (see the BPX documentation page);
a parameter set imported from BPX is exported to an equivalent BPX parameter set. The
result is validated against the BPX schema. All findings are emitted as one warning and
one info message; with `strict`, a result that violates the BPX standard raises an
error.
"""
function convert_to_bpx(cell_parameters; cycling_protocol = nothing, validate::Bool = true, strict::Bool = false)::Dict{String, Any}
    data = isa(cell_parameters, AbstractDict) ? cell_parameters : cell_parameters.all
    protocol = isnothing(cycling_protocol) ? Dict{String, Any}() : (isa(cycling_protocol, AbstractDict) ? cycling_protocol : cycling_protocol.all)
    parameters = TrackedParameters(data, Set{String}())
    report = ConversionReport("export")

    metadata = get(data, "Metadata", Dict())
    header = Dict{String, Any}("BPX" => string(BPX_SCHEMA_VERSION), "Model" => "DFN")
    for key in ("Title", "Description", "References")
        value = get(metadata, key, nothing)
        isa(value, AbstractString) && (header[key] = value)
    end

    reference_temperature = something(battmo_value(parameters, "Cell", "ReferenceTemperature"), DEFAULT_REFERENCE_TEMPERATURE)
    initial_concentration = battmo_value(parameters, "Electrolyte", "Concentration")

    # Cell
    cell = Dict{String, Any}()
    area = battmo_value(parameters, "Cell", "ElectrodeGeometricSurfaceArea")
    add_value!(cell, "Electrode area [m2]", area)
    # BPX counts facing negative/positive coating pairs, i.e. separators, which is what
    # BattMo uses to compute the total electrode area.
    number_of_pairs = BattMoModule.compute_number_of_electrode_pairs(data)
    isinteger(number_of_pairs) && (number_of_pairs = Int(number_of_pairs))
    cell["Number of electrode pairs connected in parallel to make a cell"] = number_of_pairs
    for key in ("NumberOfLayersInParallel", "DoubleCoatedElectrodes", "CloseOffWithNegativeElectrode")
        haskey(data["Cell"], key) && push!(parameters.used, "Cell.$key")
    end
    if get(data["Cell"], "DoubleCoatedElectrodes", false) == true
        add!(report, :notes, "Cell: the double coated electrodes ($(get(data["Cell"], "NumberOfLayersInParallel", 1)) layers) form $number_of_pairs facing electrode pairs, exported as \"Number of electrode pairs connected in parallel to make a cell\". BPX does not describe the electrode coating layout; current collectors are not exported.")
    end
    add_value!(cell, "Nominal cell capacity [A.h]", battmo_value(parameters, "Cell", "NominalCapacity"))
    add_value!(cell, "External surface area [m2]", battmo_value(parameters, "Cell", "DeviceSurfaceArea"))
    cell["Reference temperature [K]"] = reference_temperature
    add_value!(cell, "Lower voltage cut-off [V]", get(protocol, "LowerVoltageLimit", nothing))
    add_value!(cell, "Upper voltage cut-off [V]", get(protocol, "UpperVoltageLimit", nothing))
    if isnothing(cycling_protocol)
        add!(report, :notes, "No cycling protocol was given, so the voltage cut-offs (required by BPX) and the initial state are not exported. Pass `cycling_protocol` to include them.")
    end
    thermal_conductivity = export_lumped_thermal!(cell, parameters, report)

    # Electrolyte
    electrolyte = Dict{String, Any}()
    add_value!(electrolyte, "Cation transference number", battmo_value(parameters, "Electrolyte", "TransferenceNumber"))
    for (bpx_key, battmo_key, energy_key) in (
            ("Conductivity [S.m-1]", "IonicConductivity", "Conductivity activation energy [J.mol-1]"),
            ("Diffusivity [m2.s-1]", "DiffusionCoefficient", "Diffusivity activation energy [J.mol-1]"),
        )
        value, energy = export_function(battmo_value(parameters, "Electrolyte", battmo_key), :concentration, report, location("Parameterisation", "Electrolyte", bpx_key); reference_temperature)
        add_value!(electrolyte, bpx_key, value)
        add_value!(electrolyte, energy_key, energy)
    end
    charge_number = get(data["Electrolyte"], "ChargeNumber", 1)
    if charge_number != 1
        add!(report, :model_differences, "Electrolyte: BPX assumes a monovalent electrolyte; this parameter set has charge number $charge_number.")
    end

    # Separator
    separator = Dict{String, Any}()
    separator_porosity = battmo_value(parameters, "Separator", "Porosity")
    add_value!(separator, "Thickness [m]", battmo_value(parameters, "Separator", "Thickness"))
    add_value!(separator, "Porosity", separator_porosity)
    add_value!(separator, "Transport efficiency", derive((p, b) -> p^b, separator_porosity, battmo_value(parameters, "Separator", "BruggemanCoefficient")))

    parameterisation = Dict{String, Any}(
        "Cell" => cell,
        "Electrolyte" => electrolyte,
        "Negative electrode" => export_electrode(parameters, "NegativeElectrode", :negative, initial_concentration, report),
        "Positive electrode" => export_electrode(parameters, "PositiveElectrode", :positive, initial_concentration, report),
        "Separator" => separator,
    )
    if !isnothing(thermal_conductivity)
        parameterisation["User-defined"] = Dict{String, Any}("Thermal conductivity [W.m-1.K-1]" => thermal_conductivity)
        add!(report, :notes, "The thermal conductivity, which BPX 1.x does not define, is exported to \"User-defined\".")
    end

    # State
    initial_conditions = Dict{String, Any}()
    add_value!(initial_conditions, "Initial electrolyte concentration [mol.m-3]", initial_concentration)
    add_value!(initial_conditions, "Initial state-of-charge", get(protocol, "InitialStateOfCharge", nothing))
    add_value!(initial_conditions, "Initial temperature [K]", get(protocol, "InitialTemperature", nothing))
    state = Dict{String, Any}("Initial conditions" => initial_conditions)
    if haskey(protocol, "AmbientTemperature")
        state["Thermal environment"] = Dict{String, Any}("Ambient temperature [K]" => protocol["AmbientTemperature"])
    end

    bpx = Dict{String, Any}("Header" => header, "Parameterisation" => parameterisation, "State" => state)

    for path in sort(leaf_paths(data))
        if !(path in parameters.used) && !occursin(EXPORT_IGNORED_PARAMETERS, path)
            add!(report, :unused, "$path: not exported (no BPX counterpart, or see the notes).")
        end
    end

    if validate
        for issue in schema_issues(bpx)
            add!(report, :schema, issue)
        end
        check_consistency!(report, bpx)
    end
    raise_if_strict(report, strict)
    emit_report(report)

    return bpx
end

"""
    write_bpx(file_path, cell_parameters; cycling_protocol = nothing, validate = true, strict = false)

Convert BattMo cell parameters to a BPX parameter set (see `convert_to_bpx`) and write
it as a JSON file. Return the BPX data.
"""
function write_bpx(file_path::AbstractString, cell_parameters; kwargs...)
    bpx = convert_to_bpx(cell_parameters; kwargs...)
    open(file_path, "w") do io
        JSON.print(io, bpx, 4)
    end
    return bpx
end

end # module BPX
