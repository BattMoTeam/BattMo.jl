"""
    BPX parser

Functions to parse BPX (Battery Parameter eXchange, https://bpxstandard.com) formatted
JSON files and convert them into the cell parameter format defined by the BattMo cell
parameter schema (see `get_schema_cell_parameters`).

The parser is used by `load_cell_parameters` through the `from_bpx_file_path` keyword.

# Conversion notes
- BPX keys carry their unit in brackets (e.g. `"Thickness [m]"`). Parameters are looked
  up by their base name, the unit is parsed from the bracket and the value is converted
  to the unit expected by the BattMo schema (see `get_cell_parameters_meta_data`). Common
  unit variants (e.g. `um`, `mS.cm-1`, `mol.L-1`, `mA.h`, `g.cm-3`, `degC`) are
  recognized; an error is raised for units that cannot be converted. Keys without a unit
  bracket are assumed to use the standard BPX (SI-based) unit. For function strings and
  tabulated data the output values are scaled; the function argument is always assumed to
  be in SI units.
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
  active materials, separator and electrolyte, the coating effective density is chosen
  such that the solid volume fraction equals `1 - porosity`, and the binder and
  conductive additive are added as zero-mass placeholders.
- Operating-condition keys (voltage cut-offs, temperatures) belong to the BattMo
  `CyclingProtocol` and are not part of the cell parameters; the `Validation` section
  of a BPX file is ignored.
"""
module BPX

using JSON

export load_from_bpx_file, parse_bpx_to_cell_parameters

const GAS_CONSTANT = 8.31446261815324 # J mol⁻¹ K⁻¹
const DEFAULT_REFERENCE_TEMPERATURE = 298.15 # K

# Cell-level BPX parameters that map onto the BattMo cycling protocol instead of the
# cell parameters
const PROTOCOL_LEVEL_CELL_PARAMETERS = [
    "Lower voltage cut-off",
    "Upper voltage cut-off",
    "Ambient temperature",
    "Initial temperature",
]

# ============================================================================
# Unit handling
# ============================================================================

"""
    normalize_unit(unit)

Normalize a unit string to a canonical component form so that equivalent spellings
compare equal: `µ` → `u`, `°` → `deg`, `·`/`*` → `.`, slash notation converted to
negative exponents (`W/(m.K)` → `K-1.m-1.W`) and components sorted alphabetically.
"""
function normalize_unit(unit::AbstractString)
    stripped = replace(
        unit,
        " " => "",
        "µ" => "u",
        "μ" => "u",
        "·" => ".",
        "*" => ".",
        "°" => "deg",
        "^" => "",
    )

    components = String[]
    for (i, part) in enumerate(split(stripped, "/"))
        part = strip(part, ['(', ')'])
        add_unit_components!(components, part, i == 1 ? 1 : -1)
    end

    return join(sort(components), ".")
end

function add_unit_components!(components, unit_part, exponent_sign)
    for component in split(unit_part, ".")
        (component == "" || component == "1") && continue
        m = match(r"^([A-Za-z%]+)(-?\d+)?$", component)
        if isnothing(m)
            push!(components, String(component))
            continue
        end
        symbol = m.captures[1]
        exponent = isnothing(m.captures[2]) ? 1 : parse(Int, m.captures[2])
        exponent *= exponent_sign
        push!(components, exponent == 1 ? String(symbol) : symbol * string(exponent))
    end
    return components
end

# Conversion table from recognized units to the canonical (SI-based) units expected by
# the BattMo cell parameter schema. Maps a normalized unit string to
# (canonical unit, multiplicative factor, additive offset).
const UNIT_FACTORS = let
    table = Dict{String, Tuple{String, Float64, Float64}}()

    register!(canonical, units) = for (unit, factor) in units
        table[normalize_unit(unit)] = (canonical, factor, 0.0)
    end

    # Dimensionless
    register!("1", ["1" => 1.0, "-" => 1.0, "%" => 1.0e-2])
    # Length
    register!("m", ["m" => 1.0, "dm" => 1.0e-1, "cm" => 1.0e-2, "mm" => 1.0e-3, "um" => 1.0e-6, "nm" => 1.0e-9])
    # Area
    register!("m2", ["m2" => 1.0, "dm2" => 1.0e-2, "cm2" => 1.0e-4, "mm2" => 1.0e-6])
    # Inverse length (surface area per unit volume)
    register!("m-1", ["m-1" => 1.0, "cm-1" => 1.0e2, "mm-1" => 1.0e3, "m2.m-3" => 1.0])
    # Diffusivity
    register!("m2.s-1", ["m2.s-1" => 1.0, "cm2.s-1" => 1.0e-4, "mm2.s-1" => 1.0e-6])
    # Ionic / electronic conductivity
    register!("S.m-1", ["S.m-1" => 1.0, "S.cm-1" => 1.0e2, "mS.m-1" => 1.0e-3, "mS.cm-1" => 1.0e-1, "uS.cm-1" => 1.0e-4])
    # Concentration
    register!("mol.m-3", ["mol.m-3" => 1.0, "kmol.m-3" => 1.0e3, "mol.L-1" => 1.0e3, "mol.dm-3" => 1.0e3, "mmol.L-1" => 1.0, "mol.cm-3" => 1.0e6, "mmol.cm-3" => 1.0e3])
    # Charge capacity
    register!("A.h", ["A.h" => 1.0, "Ah" => 1.0, "mA.h" => 1.0e-3, "mAh" => 1.0e-3, "A.s" => 1.0 / 3600])
    # Voltage
    register!("V", ["V" => 1.0, "mV" => 1.0e-3, "uV" => 1.0e-6])
    # Entropic change coefficient
    register!("V.K-1", ["V.K-1" => 1.0, "mV.K-1" => 1.0e-3, "uV.K-1" => 1.0e-6])
    # Molar energy (activation energies)
    register!("J.mol-1", ["J.mol-1" => 1.0, "kJ.mol-1" => 1.0e3])
    # Density
    register!("kg.m-3", ["kg.m-3" => 1.0, "g.m-3" => 1.0e-3, "g.cm-3" => 1.0e3, "mg.cm-3" => 1.0, "g.L-1" => 1.0, "kg.L-1" => 1.0e3, "g.mL-1" => 1.0e3])
    # Specific heat capacity
    register!("J.K-1.kg-1", ["J.K-1.kg-1" => 1.0, "kJ.K-1.kg-1" => 1.0e3, "J.K-1.g-1" => 1.0e3, "mJ.K-1.kg-1" => 1.0e-3])
    # Thermal conductivity
    register!("W.m-1.K-1", ["W.m-1.K-1" => 1.0, "mW.m-1.K-1" => 1.0e-3, "W.cm-1.K-1" => 1.0e2, "kW.m-1.K-1" => 1.0e3])
    # Reaction rate constant (BPX convention)
    register!("mol.m-2.s-1", ["mol.m-2.s-1" => 1.0, "mmol.m-2.s-1" => 1.0e-3, "umol.m-2.s-1" => 1.0e-6, "mol.cm-2.s-1" => 1.0e4, "umol.cm-2.s-1" => 1.0e-2])
    # Temperature (offset units are only supported for scalar values)
    table[normalize_unit("K")] = ("K", 1.0, 0.0)
    table[normalize_unit("degC")] = ("K", 1.0, 273.15)

    table
end

"""
    unit_conversion(unit, canonical_unit, key, section_name)

Return the `(factor, offset)` pair that converts a value in `unit` to `canonical_unit`.
Raise an error when the unit is not recognized or is not convertible to
`canonical_unit`.
"""
function unit_conversion(unit::AbstractString, canonical_unit::String, key::String, section_name::String)
    entry = get(UNIT_FACTORS, normalize_unit(unit), nothing)
    if isnothing(entry)
        error("The unit \"$unit\" of BPX key \"$key\" in section \"$section_name\" is not recognized; expected a unit convertible to \"$canonical_unit\".")
    elseif entry[1] != canonical_unit
        error("Cannot convert the unit \"$unit\" of BPX key \"$key\" in section \"$section_name\" to \"$canonical_unit\".")
    end
    return entry[2], entry[3]
end

"""
    apply_unit_conversion(value, factor, offset, key, section_name)

Apply a unit conversion to a BPX parameter value. Scalars are rescaled directly,
function strings are wrapped as `(expression) * factor` and tabulated data has its
output (`y`) values rescaled. Offset units (e.g. `degC`) are only supported for
scalar values.
"""
function apply_unit_conversion(value, factor, offset, key::String, section_name::String)
    if factor == 1.0 && offset == 0.0
        return value
    end
    if isa(value, Real)
        return value * factor + offset
    elseif offset != 0.0
        error("The unit of BPX key \"$key\" in section \"$section_name\" requires an offset conversion, which is only supported for scalar values.")
    elseif isa(value, AbstractString)
        return "(" * value * ") * $factor"
    elseif isa(value, AbstractDict) && haskey(value, "y")
        converted = copy(value)
        converted["y"] = [y * factor for y in value["y"]]
        return converted
    else
        error("Cannot apply a unit conversion to the value of BPX key \"$key\" in section \"$section_name\" (type $(typeof(value))).")
    end
end

# ============================================================================
# Section access
# ============================================================================

# Wrapper around a BPX section that allows unit-aware lookup by parameter base name
# and keeps track of which keys have been used, so that unmapped keys can be reported.
struct BPXSection
    name::String
    data::AbstractDict
    used_keys::Set{String}
end

BPXSection(name::String, data::AbstractDict) = BPXSection(name, data, Set{String}())

"""
    find_entry(section, parameter_name)

Find a parameter in a BPX section by its base name, i.e. the key name without the
unit bracket. Return `(key, value, unit)` where `unit` is the bracket content or
`nothing`, or `nothing` when the parameter is absent.
"""
function find_entry(section::BPXSection, parameter_name::String)
    found = nothing
    for (key, value) in section.data
        m = match(r"^(.*?)\s*\[(.+?)\]\s*$", key)
        base_name = isnothing(m) ? strip(key) : strip(m.captures[1])
        if base_name == parameter_name
            if !isnothing(found)
                error("BPX section \"$(section.name)\" contains multiple entries for \"$parameter_name\".")
            end
            unit = isnothing(m) ? nothing : String(m.captures[2])
            found = (key, value, unit)
        end
    end
    if isnothing(found)
        return nothing
    end
    push!(section.used_keys, found[1])
    return found
end

"""
    get_quantity(section, parameter_name, canonical_unit)

Look up a parameter by base name and convert its value to `canonical_unit` (the unit
expected by the BattMo schema; `"1"` for dimensionless parameters). Keys without a
unit bracket are assumed to already use the canonical unit. Return `nothing` when the
parameter is absent.
"""
function get_quantity(section::BPXSection, parameter_name::String, canonical_unit::String)
    entry = find_entry(section, parameter_name)
    isnothing(entry) && return nothing
    key, value, unit = entry
    isnothing(unit) && return value
    factor, offset = unit_conversion(unit, canonical_unit, key, section.name)
    return apply_unit_conversion(value, factor, offset, key, section.name)
end

has_parameter(section::BPXSection, parameter_name::String) = !isnothing(find_entry(section, parameter_name))

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

# BPX does not describe the binder and conductive additive separately, so they are
# included as zero-mass placeholders (the same convention as the default parameter
# sets) and all coating mass is assigned to the active material.
function placeholder_inert_component(lumped)
    component = Dict{String, Any}(
        "Description" => "Not provided by BPX; zero-mass placeholder.",
        "Density" => lumped.density,
        "MassFraction" => 0.0,
        "ElectronicConductivity" => 100.0,
    )
    return add_lumped_thermal_parameters!(component, lumped)
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

    electrode_area = get_quantity(section, "Electrode area", "m2")
    number_of_pairs = get_quantity(section, "Number of electrode pairs connected in parallel to make a cell", "1")

    cell["ElectrodeGeometricSurfaceArea"] = derive(*, electrode_area, number_of_pairs)
    cell["NumberOfLayersInParallel"] = derive(pairs -> round(Int, pairs), number_of_pairs)
    cell["NominalCapacity"] = get_quantity(section, "Nominal cell capacity", "A.h")
    cell["DeviceSurfaceArea"] = get_quantity(section, "External surface area", "m2")

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

function convert_electrolyte(section::BPXSection, lumped, reference_temperature)
    conductivity_activation_energy = get_quantity(section, "Conductivity activation energy", "J.mol-1")
    diffusivity_activation_energy = get_quantity(section, "Diffusivity activation energy", "J.mol-1")

    conductivity = convert_bpx_function(get_quantity(section, "Conductivity", "S.m-1"), "c")
    diffusivity = convert_bpx_function(get_quantity(section, "Diffusivity", "m2.s-1"), "c")

    electrolyte = Dict{String, Any}(
        "Concentration" => get_quantity(section, "Initial concentration", "mol.m-3"),
        "TransferenceNumber" => get_quantity(section, "Cation transference number", "1"),
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
    porosity = get_quantity(section, "Porosity", "1")
    transport_efficiency = get_quantity(section, "Transport efficiency", "1")
    bruggeman = compute_bruggeman_coefficient(porosity, transport_efficiency, section.name)
    solid_volume_fraction = derive(p -> 1.0 - p, porosity)

    maximum_concentration = get_quantity(section, "Maximum concentration", "mol.m-3")

    minimum_stoichiometry = get_quantity(section, "Minimum stoichiometry", "1")
    maximum_stoichiometry = get_quantity(section, "Maximum stoichiometry", "1")
    if polarity == :negative
        # The negative electrode is delithiated at SOC 0
        theta0 = minimum_stoichiometry
        theta100 = maximum_stoichiometry
    else
        # The positive electrode is lithiated at SOC 0
        theta0 = maximum_stoichiometry
        theta100 = minimum_stoichiometry
    end

    reaction_rate_constant = get_quantity(section, "Reaction rate constant", "mol.m-2.s-1")

    active_material = Dict{String, Any}(
        "MassFraction" => 1.0,
        "Density" => lumped.density,
        "VolumetricSurfaceArea" => get_quantity(section, "Surface area per unit volume", "m-1"),
        "DiffusionCoefficient" => convert_bpx_function(get_quantity(section, "Diffusivity", "m2.s-1"), "(c / cmax)"),
        "ParticleRadius" => get_quantity(section, "Particle radius", "m"),
        "MaximumConcentration" => maximum_concentration,
        "StoichiometricCoefficientAtSOC0" => theta0,
        "StoichiometricCoefficientAtSOC100" => theta100,
        "OpenCircuitPotential" => convert_bpx_function(get_quantity(section, "OCP", "V"), "(c / cmax)"),
        "EntropyChange" => convert_bpx_function(get_quantity(section, "Entropic change coefficient", "V.K-1"), "(c / cmax)"),
        "NumberOfElectronsTransfered" => 1,
        "ChargeTransferCoefficient" => 0.5,
        "ReactionRateConstant" => derive(
            (k, cmax, c_e_ref) -> k / (cmax * sqrt(c_e_ref)),
            reaction_rate_constant, maximum_concentration, electrolyte_reference_concentration,
        ),
        "ActivationEnergyOfDiffusion" => get_quantity(section, "Diffusivity activation energy", "J.mol-1"),
        "ActivationEnergyOfReaction" => get_quantity(section, "Reaction rate constant activation energy", "J.mol-1"),
    )

    # BPX gives the effective electronic conductivity of the porous coating, while
    # BattMo expects the intrinsic material conductivity
    effective_conductivity = get_quantity(section, "Conductivity", "S.m-1")
    active_material["ElectronicConductivity"] = derive(
        (kappa, vf, b) -> kappa / vf^b,
        effective_conductivity, solid_volume_fraction, bruggeman,
    )

    add_lumped_thermal_parameters!(active_material, lumped)

    electrode = Dict{String, Any}(
        "Coating" => Dict{String, Any}(
            "Thickness" => get_quantity(section, "Thickness", "m"),
            "BruggemanCoefficient" => bruggeman,
            "EffectiveDensity" => derive(*, lumped.density, solid_volume_fraction),
        ),
        "ActiveMaterial" => active_material,
        "Binder" => placeholder_inert_component(lumped),
        "ConductiveAdditive" => placeholder_inert_component(lumped),
    )

    report_ignored_keys(section)

    return electrode
end

function convert_separator(section::BPXSection, lumped)
    porosity = get_quantity(section, "Porosity", "1")
    transport_efficiency = get_quantity(section, "Transport efficiency", "1")

    separator = Dict{String, Any}(
        "Thickness" => get_quantity(section, "Thickness", "m"),
        "Porosity" => porosity,
        "BruggemanCoefficient" => compute_bruggeman_coefficient(porosity, transport_efficiency, section.name),
        "Density" => lumped.density,
    )
    add_lumped_thermal_parameters!(separator, lumped)

    report_ignored_keys(section)

    return separator
end

# ============================================================================
# Public API
# ============================================================================

"""
    parse_bpx_to_cell_parameters(bpx_data::AbstractDict) -> Dict{String, Any}

Convert already-parsed BPX data to the format expected by `CellParameters`.
See the module docstring for the conversion conventions.
"""
function parse_bpx_to_cell_parameters(bpx_data::AbstractDict)::Dict{String, Any}
    haskey(bpx_data, "Parameterisation") || error("The input is not BPX formatted: the top-level \"Parameterisation\" section is missing.")
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

    density = get_quantity(cell_section, "Density", "kg.m-3")
    if !isnothing(density)
        @warn "BPX only provides a lumped cell density, which is used as density for the active materials, separator and electrolyte. Volume fractions and the simulated electrochemistry are unaffected, but gravimetric quantities are only approximate."
    end

    lumped = (
        density = density,
        specific_heat_capacity = get_quantity(cell_section, "Specific heat capacity", "J.K-1.kg-1"),
        thermal_conductivity = get_quantity(cell_section, "Thermal conductivity", "W.m-1.K-1"),
    )

    reference_temperature = get_quantity(cell_section, "Reference temperature", "K")
    if isnothing(reference_temperature)
        reference_temperature = DEFAULT_REFERENCE_TEMPERATURE
    end
    electrolyte_reference_concentration = get_quantity(electrolyte_section, "Initial concentration", "mol.m-3")

    cell_parameters = Dict{String, Any}(
        "Metadata" => convert_metadata(header),
        "Cell" => convert_cell(cell_section, header),
        "NegativeElectrode" => convert_electrode(negative_electrode_section, :negative, electrolyte_reference_concentration, lumped),
        "PositiveElectrode" => convert_electrode(positive_electrode_section, :positive, electrolyte_reference_concentration, lumped),
        "Separator" => convert_separator(separator_section, lumped),
        "Electrolyte" => convert_electrolyte(electrolyte_section, lumped, reference_temperature),
    )

    report_ignored_keys(cell_section)

    zeroed_parameters = String[]
    fill_missing_with_zero!(cell_parameters, "", zeroed_parameters)
    if !isempty(zeroed_parameters)
        sort!(zeroed_parameters)
        @warn "The following BattMo cell parameters could not be determined from the BPX input and were set to 0.0: $(join(zeroed_parameters, ", ")). Set these values manually before running a simulation."
    end

    return cell_parameters
end

"""
    load_from_bpx_file(file_path::String) -> Dict{String, Any}

Load a BPX (Battery Parameter eXchange) JSON file and convert it to the cell
parameter format expected by `CellParameters`.

# Example
```julia
cell_parameters = load_cell_parameters(; from_bpx_file_path = "path/to/bpx_input.json")
```
"""
function load_from_bpx_file(file_path::String)::Dict{String, Any}
    return parse_bpx_to_cell_parameters(JSON.parsefile(file_path))
end

end # module BPX
