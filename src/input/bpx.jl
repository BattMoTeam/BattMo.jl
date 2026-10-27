"""
    BPX parser

Functions to parse BPX (Battery Parameter eXchange, https://bpxstandard.com, version 1.1.1) formatted
JSON files and convert them into the cell parameter format defined by the BattMo cell
parameter schema (see `get_schema_cell_parameters`).

The parser is used by `load_cell_parameters` through the `from_bpx_file_path` keyword.

# Conversion notes
- BPX parameter names include their unit (e.g. `"Thickness [m]"`), and the standard
  allows only the names listed in its parameter table, so every parameter has a fixed
  unit. These units match the BattMo cell parameter schema and the values are used
  without unit conversion. Keys with other units are not BPX compliant: they are
  reported by the schema validation and ignored.
- BattMo parameters that cannot be determined from the BPX input, because the BPX key is
  missing or an input to a derived quantity is missing, are set to `0.0` and reported in
  a warning. They must be set manually before running a simulation; the parameter set
  validation flags the ones required by the selected model.
- BPX function strings use `x` as independent variable and `**` for powers. They are
  rewritten to BattMo conventions: `^` for powers, `c` (concentration) for electrolyte
  functions and `(c / cmax)` (stoichiometry) for electrode functions.
- Tabulated data (`{"x": [...], "y": [...]}`) keeps its `x` values unchanged, since
  BattMo evaluates tabulated electrode functions at the stoichiometry `c / cmax`, which
  is the BPX `x` variable.
- BPX defines the exchange current density as
  `j0 = F * k * sqrt(c_e / c_e_ref) * sqrt(x) * sqrt(1 - x)` with the reaction rate
  constant `k` in mol·m⁻²·s⁻¹, while BattMo uses the Newman convention
  `j0 = R0 * n * F * sqrt(c_e * c * (cmax - c))` (see `reaction_rate_coefficient`).
  Hence `R0 = k / (cmax * sqrt(c_e_ref))`, with `c_e_ref` the BPX initial electrolyte
  concentration.
- BPX gives the porosity and the transport efficiency (tortuosity factor) of the porous
  regions; the BattMo Bruggeman coefficient is recovered from
  `transport_efficiency = porosity^bruggeman`.
- BPX electrode conductivities are effective values for the porous coating, while BattMo
  expects the intrinsic material conductivity and computes the effective one as
  `intrinsic * volume_fraction^bruggeman` (see `compute_effective_electronic_conductivity`).
- BPX electrolyte activation energies are folded into the electrolyte function strings as
  Arrhenius factors, since the BattMo electrolyte functions have signature `f(c, T)`. The
  BPX reference temperature is used as Arrhenius reference (298.15 K when absent, as
  prescribed by the BPX standard).
- The BPX standard assumes a single-electron reaction and a symmetric Butler-Volmer
  equation, so `NumberOfElectronsTransfered = 1`, `ChargeTransferCoefficient = 0.5` and
  `ChargeNumber = 1` are set accordingly.
- BPX does not provide component densities (only a lumped cell density), nor separate
  binder/conductive additive data. The lumped cell density is used as density for the
  active materials, separator and electrolyte, and the coating effective density is
  chosen such that the solid volume fraction equals `1 - porosity`.
- BPX defines the active material volume fraction of an electrode as
  `surface_area_per_unit_volume * particle_radius / 3`, which sets the electrode
  capacity. The active material mass fraction is chosen to reproduce it; the remaining
  solid is lumped into the binder and the conductive additive is a zero-mass
  placeholder. All three get the same intrinsic electronic conductivity.
- The initial electrolyte concentration is read from `State` → `Initial conditions`.
- Operating-condition keys (voltage cut-offs, temperatures, initial state-of-charge,
  thermal environment) belong to the BattMo `CyclingProtocol` and are not part of the
  cell parameters. A non-zero degradation state is not supported and the `Validation`
  section of a BPX file is ignored.

# Schema validation and BPX versions
The input is validated against the JSON schema of the official BPX package
(https://github.com/FaradayInstitution/BPX, MIT license, copyright (c) 2022 University
of Oxford), bundled in `src/input/bpx_schema/` together with its license; see the
README there for its provenance and how to update it for a new BPX release. Legacy
BPX v0.x inputs are first converted to the v1.x layout (`migrate_legacy_bpx`, adapted
from the same package), so the conversion to BattMo only handles the v1.x layout.
Schema violations are reported as a warning, or raised as an error with `strict = true`.
"""
module BPX

using JSON
using JSONSchema

export load_from_bpx_file, parse_bpx_to_cell_parameters

const GAS_CONSTANT = 8.31446261815324 # J mol⁻¹ K⁻¹
const DEFAULT_REFERENCE_TEMPERATURE = 298.15 # K

# Version of the BPX package the bundled schema was generated from (see
# src/input/bpx_schema/README.md)
const BPX_SCHEMA_VERSION = v"1.1.1"
const BPX_SCHEMA_PATH = joinpath(@__DIR__, "bpx_schema", "bpx_schema.json")

# Cell-level BPX parameters that map onto the BattMo cycling protocol instead of the
# cell parameters
const PROTOCOL_LEVEL_CELL_PARAMETERS = [
    "Lower voltage cut-off [V]",
    "Upper voltage cut-off [V]",
]

# ============================================================================
# Section access
# ============================================================================

# Wrapper around a BPX section that keeps track of which keys have been used, so that
# unmapped keys can be reported.
struct BPXSection
    name::String
    data::AbstractDict
    used_keys::Set{String}
end

BPXSection(name::String, data::AbstractDict) = BPXSection(name, data, Set{String}())

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

function report_ignored_keys(section::BPXSection)
    ignored = sort(collect(setdiff(keys(section.data), section.used_keys)))
    if !isempty(ignored)
        @warn "The following BPX keys in section \"$(section.name)\" have no counterpart in the BattMo cell parameter schema and were ignored: $(join(ignored, ", "))."
    end
    return nothing
end

# ============================================================================
# Missing value handling
# ============================================================================

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
# Function conversion helpers
# ============================================================================

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
    convert_bpx_function(value, variable)

Convert a BPX parameter value that may be a constant, a function string or tabulated
data to its BattMo counterpart. Missing values (`nothing`) are passed through so they
can be zero-filled later.
"""
function convert_bpx_function(value, variable::String)
    if isnothing(value)
        return nothing
    elseif isa(value, Real)
        return value
    elseif isa(value, AbstractString)
        return convert_bpx_expression(value, variable)
    elseif isa(value, AbstractDict) && haskey(value, "x") && haskey(value, "y")
        # Tabulated data is given versus the same variable BattMo evaluates the
        # interpolator at, so it can be passed through unchanged.
        return value
    else
        error("Unsupported BPX parameter value of type $(typeof(value)). Expected a number, a function string or tabulated data with \"x\" and \"y\" keys.")
    end
end

"""
    apply_arrhenius(value, activation_energy, reference_temperature)

Fold a BPX activation energy into a parameter function as an Arrhenius factor
`exp(Ea / R * (1 / refT - 1 / T))`. Used for the electrolyte transport parameters,
for which the BattMo schema has no activation energy fields but whose function
strings are evaluated as `f(c, T)`.
"""
function apply_arrhenius(value, activation_energy, reference_temperature)
    if isnothing(value) || isnothing(activation_energy) || activation_energy == 0
        return value
    end
    if isa(value, Real) || isa(value, AbstractString)
        base = isa(value, Real) ? string(value) : "(" * value * ")"
        return base * " * exp($activation_energy / $GAS_CONSTANT * (1.0 / $reference_temperature - 1.0 / T))"
    else
        @warn "An activation energy cannot be combined with tabulated BPX data; the activation energy was ignored."
        return value
    end
end

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
    compute_active_mass_fraction(surface_area, radius, porosity, section_name)

Return the active material fraction of the solid coating volume. BPX defines the active
material volume fraction as `surface_area * radius / 3` (spherical particles), which is
in general smaller than the solid volume fraction `1 - porosity`. Since all coating
components share the lumped BPX density, the volume fraction equals the mass fraction.
"""
function compute_active_mass_fraction(surface_area, radius, porosity, section_name::String)
    active_volume_fraction = surface_area * radius / 3
    solid_volume_fraction = 1 - porosity
    if active_volume_fraction > solid_volume_fraction * (1 + 1.0e-6)
        @warn "BPX section \"$section_name\" has an active material volume fraction (surface area per unit volume * particle radius / 3 = $active_volume_fraction) larger than the solid volume fraction (1 - porosity = $solid_volume_fraction). The active material fraction of the solid is capped at 1."
    end
    return min(active_volume_fraction / solid_volume_fraction, 1.0)
end

# ============================================================================
# Section converters
# ============================================================================

function convert_metadata(header::AbstractDict)
    metadata = Dict{String, Any}()
    if haskey(header, "Title")
        metadata["Title"] = header["Title"]
    end
    if haskey(header, "Description")
        metadata["Description"] = header["Description"]
    end

    model = get(header, "Model", nothing)
    if model == "DFN"
        metadata["Models"] = Dict{String, Any}(
            "ModelFramework" => "P2D",
            "TransportInSolid" => "FullDiffusion",
        )
    elseif !isnothing(model)
        @warn "The BPX file was parameterised for the \"$model\" model. The parameters are converted as-is, but BattMo simulates the full P2D (DFN) model."
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

function convert_cell(section::BPXSection, header::AbstractDict)
    cell = Dict{String, Any}()

    electrode_area = get_parameter(section, "Electrode area [m2]")
    number_of_pairs = get_parameter(section, "Number of electrode pairs connected in parallel to make a cell")

    cell["ElectrodeGeometricSurfaceArea"] = derive(*, electrode_area, number_of_pairs)
    cell["NumberOfLayersInParallel"] = derive(pairs -> round(Int, pairs), number_of_pairs)
    cell["NominalCapacity"] = get_parameter(section, "Nominal cell capacity [A.h]")
    cell["DeviceSurfaceArea"] = get_parameter(section, "External surface area [m2]")

    case = infer_case(header)
    if !isnothing(case)
        cell["Case"] = case
    end

    protocol_parameters = filter(name -> has_parameter(section, name), PROTOCOL_LEVEL_CELL_PARAMETERS)
    if !isempty(protocol_parameters)
        @info "The BPX parameters $(join(protocol_parameters, ", ")) describe operating conditions and are not part of the BattMo cell parameters. Set the corresponding values in the CyclingProtocol instead."
    end

    return cell
end

collect_numbers(value::Real) = [value]
collect_numbers(value::AbstractDict) = reduce(vcat, (collect_numbers(v) for v in values(value)); init = Real[])
collect_numbers(value) = Real[]

"""
    convert_state(state)

Process the BPX `State` section (BPX ≥ 1.0). Return the initial electrolyte concentration
(or `nothing`) and report the remaining state entries, which describe operating
conditions (initial SOC and temperature, thermal environment) that belong to the
BattMo `CyclingProtocol`, or a degradation state that is not supported.
"""
function convert_state(state::AbstractDict)
    initial_conditions = get(state, "Initial conditions", Dict{String, Any}())
    initial_conditions_section = BPXSection("State.Initial conditions", isa(initial_conditions, AbstractDict) ? initial_conditions : Dict{String, Any}())
    concentration = get_parameter(initial_conditions_section, "Initial electrolyte concentration [mol.m-3]")

    protocol_keys = sort(collect(setdiff(keys(initial_conditions_section.data), initial_conditions_section.used_keys)))
    thermal_environment = get(state, "Thermal environment", nothing)
    if isa(thermal_environment, AbstractDict)
        append!(protocol_keys, sort(collect(keys(thermal_environment))))
    end
    if !isempty(protocol_keys)
        @info "The BPX state entries $(join(protocol_keys, ", ")) describe operating conditions and are not part of the BattMo cell parameters. Set the corresponding values in the CyclingProtocol instead."
    end

    degradation = get(state, "Degradation", nothing)
    if any(!iszero, collect_numbers(degradation))
        @warn "The BPX file specifies a non-zero degradation state (LAM/LLI), which is not supported. The parameters of the reference (unaged) cell are used."
    end

    other_keys = setdiff(keys(state), ["Initial conditions", "Thermal environment", "Degradation"])
    if !isempty(other_keys)
        @warn "The following BPX state entries are not recognized and were ignored: $(join(sort(collect(other_keys)), ", "))."
    end

    return concentration
end

function convert_electrolyte(section::BPXSection, initial_concentration, lumped, reference_temperature)
    conductivity_activation_energy = get_parameter(section, "Conductivity activation energy [J.mol-1]")
    diffusivity_activation_energy = get_parameter(section, "Diffusivity activation energy [J.mol-1]")

    conductivity = convert_bpx_function(get_parameter(section, "Conductivity [S.m-1]"), "c")
    diffusivity = convert_bpx_function(get_parameter(section, "Diffusivity [m2.s-1]"), "c")

    electrolyte = Dict{String, Any}(
        "Concentration" => initial_concentration,
        "TransferenceNumber" => get_parameter(section, "Cation transference number"),
        "ChargeNumber" => 1,
        "Density" => lumped.density,
        "IonicConductivity" => apply_arrhenius(conductivity, conductivity_activation_energy, reference_temperature),
        "DiffusionCoefficient" => apply_arrhenius(diffusivity, diffusivity_activation_energy, reference_temperature),
    )
    add_lumped_thermal_parameters!(electrolyte, lumped)

    report_ignored_keys(section)

    return electrolyte
end

function convert_electrode(section::BPXSection, polarity::Symbol, electrolyte_reference_concentration, lumped)
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
        (b, r, p) -> compute_active_mass_fraction(b, r, p, section.name),
        surface_area, particle_radius, porosity,
    )

    active_material = Dict{String, Any}(
        "MassFraction" => active_mass_fraction,
        "Density" => lumped.density,
        "VolumetricSurfaceArea" => surface_area,
        "DiffusionCoefficient" => convert_bpx_function(get_parameter(section, "Diffusivity [m2.s-1]"), "(c / cmax)"),
        "ParticleRadius" => particle_radius,
        "MaximumConcentration" => maximum_concentration,
        "StoichiometricCoefficientAtSOC0" => theta0,
        "StoichiometricCoefficientAtSOC100" => theta100,
        "OpenCircuitPotential" => convert_bpx_function(get_parameter(section, "OCP [V]"), "(c / cmax)"),
        "EntropyChange" => convert_bpx_function(get_parameter(section, "Entropic change coefficient [V.K-1]"), "(c / cmax)"),
        "NumberOfElectronsTransfered" => 1,
        "ChargeTransferCoefficient" => 0.5,
        "ReactionRateConstant" => derive(
            (k, cmax, c_e_ref) -> k / (cmax * sqrt(c_e_ref)),
            reaction_rate_constant, maximum_concentration, electrolyte_reference_concentration,
        ),
        "ActivationEnergyOfDiffusion" => get_parameter(section, "Diffusivity activation energy [J.mol-1]"),
        "ActivationEnergyOfReaction" => get_parameter(section, "Reaction rate constant activation energy [J.mol-1]"),
    )

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

    report_ignored_keys(section)

    return electrode
end

function convert_separator(section::BPXSection, lumped)
    porosity = get_parameter(section, "Porosity")
    transport_efficiency = get_parameter(section, "Transport efficiency")

    separator = Dict{String, Any}(
        "Thickness" => get_parameter(section, "Thickness [m]"),
        "Porosity" => porosity,
        "BruggemanCoefficient" => compute_bruggeman_coefficient(porosity, transport_efficiency, section.name),
        "Density" => lumped.density,
    )
    add_lumped_thermal_parameters!(separator, lumped)

    report_ignored_keys(section)

    return separator
end

# ============================================================================
# Schema validation and legacy migration
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

# The BPX schema accepts the "Parameterisation" of any model type (anyOf), which gives
# uninformative validation messages. The schema is therefore specialised to the
# Parameterisation definition matching the declared model.
const PARAMETERISATION_DEFINITIONS = Dict(
    "DFN" => "Parameterisation",
    "SPMe" => "Parameterisation",
    "SPM" => "ParameterisationSPM",
    "Partial" => "ParameterisationPartial",
)

const SCHEMA_CACHE = Dict{Any, JSONSchema.Schema}()

function bpx_schema(model)
    return get!(SCHEMA_CACHE, model) do
        schema = JSON.parsefile(BPX_SCHEMA_PATH)
        definition = get(PARAMETERISATION_DEFINITIONS, model, nothing)
        if !isnothing(definition)
            schema["properties"]["Parameterisation"] = Dict{String, Any}("\$ref" => "#/\$defs/$definition")
        end
        JSONSchema.Schema(schema)
    end
end

"""
    validate_bpx(bpx_data; strict = false)

Validate a BPX input (in the v1.x layout) against the bundled BPX schema. A violation
is reported as a warning, or raised as an error when `strict` is true. Only the schema
is checked; the additional consistency checks of the Python BPX package (e.g. OCP
values at the stoichiometry limits versus the voltage cut-offs) are not performed.
"""
function validate_bpx(bpx_data::AbstractDict; strict::Bool = false)
    header = get(bpx_data, "Header", nothing)
    model = isa(header, AbstractDict) ? get(header, "Model", nothing) : nothing
    issue = JSONSchema.validate(bpx_schema(model), bpx_data)
    isnothing(issue) && return true

    message = "The BPX input does not conform to the BPX $(BPX_SCHEMA_VERSION) schema (first violation shown):\n$(sprint(show, issue))"
    if strict
        error(message)
    end
    @warn message * "\nThe conversion continues; parameters that cannot be determined are reported below."
    return false
end

"""
    prepare_bpx_input(bpx_data; validate = true, strict = false) -> AbstractDict

Bring a BPX input into the v1.x layout (converting legacy v0.x inputs) and validate it.
"""
function prepare_bpx_input(bpx_data::AbstractDict; validate::Bool = true, strict::Bool = false)
    version = bpx_version(bpx_data)
    if version.major < 1
        @info "The input uses the legacy BPX $version format; it is converted to the BPX $(BPX_SCHEMA_VERSION) layout."
        bpx_data = migrate_legacy_bpx(bpx_data)
    elseif (version.major, version.minor) > (BPX_SCHEMA_VERSION.major, BPX_SCHEMA_VERSION.minor)
        @warn "The input uses BPX $version, which is newer than the BPX $(BPX_SCHEMA_VERSION) schema supported by BattMo. New parameters may be reported as unknown or ignored."
    end
    if validate
        validate_bpx(bpx_data; strict)
    end
    return bpx_data
end

# ============================================================================
# Public API
# ============================================================================

"""
    parse_bpx_to_cell_parameters(bpx_data::AbstractDict; validate = true, strict = false) -> Dict{String, Any}

Convert already-parsed BPX data to the format expected by `CellParameters`. Legacy
BPX v0.x inputs are converted to the v1.x layout first. With `validate`, the input is
checked against the bundled BPX schema; violations give a warning, or an error when
`strict` is true. See the module docstring for the conversion conventions.
"""
function parse_bpx_to_cell_parameters(bpx_data::AbstractDict; validate::Bool = true, strict::Bool = false)::Dict{String, Any}
    haskey(bpx_data, "Parameterisation") || error("The input is not BPX formatted: the top-level \"Parameterisation\" section is missing.")
    bpx_data = prepare_bpx_input(bpx_data; validate, strict)
    parameterisation = bpx_data["Parameterisation"]

    header = get(bpx_data, "Header", Dict{String, Any}())

    function section(name)
        data = get(parameterisation, name, nothing)
        if !isa(data, AbstractDict)
            # A missing section means all its parameters are missing; they are
            # zero-filled like any other missing parameter
            data = Dict{String, Any}()
        end
        return BPXSection(name, data)
    end

    cell_section = section("Cell")
    electrolyte_section = section("Electrolyte")
    negative_electrode_section = section("Negative electrode")
    positive_electrode_section = section("Positive electrode")
    separator_section = section("Separator")
    user_defined_section = section("User-defined")

    density = get_parameter(cell_section, "Density [kg.m-3]")
    if !isnothing(density)
        @warn "BPX only provides a lumped cell density, which is used as density for the active materials, separator and electrolyte. Volume fractions and the simulated electrochemistry are unaffected, but gravimetric quantities are only approximate."
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
    state = get(bpx_data, "State", Dict{String, Any}())
    electrolyte_reference_concentration = isa(state, AbstractDict) ? convert_state(state) : nothing

    cell_parameters = Dict{String, Any}(
        "Metadata" => convert_metadata(header),
        "Cell" => convert_cell(cell_section, header),
        "NegativeElectrode" => convert_electrode(negative_electrode_section, :negative, electrolyte_reference_concentration, lumped),
        "PositiveElectrode" => convert_electrode(positive_electrode_section, :positive, electrolyte_reference_concentration, lumped),
        "Separator" => convert_separator(separator_section, lumped),
        "Electrolyte" => convert_electrolyte(electrolyte_section, electrolyte_reference_concentration, lumped, reference_temperature),
    )

    report_ignored_keys(cell_section)
    report_ignored_keys(user_defined_section)

    zeroed_parameters = String[]
    fill_missing_with_zero!(cell_parameters, "", zeroed_parameters)
    if !isempty(zeroed_parameters)
        sort!(zeroed_parameters)
        @warn "The following BattMo cell parameters could not be determined from the BPX input and were set to 0.0: $(join(zeroed_parameters, ", ")). Set these values manually before running a simulation."
    end

    return cell_parameters
end

"""
    load_from_bpx_file(file_path::String; validate = true, strict = false) -> Dict{String, Any}

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

end # module BPX
