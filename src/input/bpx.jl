"""
    BPX parsers and loaders

This module provides functions to parse BPX-formatted JSON files and convert them
into the cell parameter input format expected by BattMo's CellParameters schema.
"""

module BPX

    using JSON

    # ============================================================================
    # Key normalization
    # ============================================================================

    """
        _normalize_key(source_section::String, section::String, key::String) -> String
    
    Normalize a hierarchical BPX key path into a flat BattMo schema key.
    
    BPX keys are organized hierarchically (e.g. "Particle radius [m]" inside
    "Negative electrode" inside "Parameterisation"), while the BattMo CellParameters
    schema uses a flat namespace with section prefixes such as ``negative_particle_radius``.
    This function maps BPX paths to the corresponding flat keys.
    
    # Arguments
    - `source_section::String`: The top-level source identifier (e.g. "nmc_pouch_cell").
    - `section::String`: The BPX hierarchical section name, e.g. "Negative electrode", "Cell".
    - `key::String`: The raw key name from the BPX file, e.g. "Particle radius [m]".
    
    # Returns
    A `String` representing the normalized flat key in the BattMo schema namespace.
    
    # Notes
    The mapping between BPX section/key names and BattMo schema keys is defined
    in ``KEY_TO_BATTMO_MAP``. If a exact match is not found the function falls
    back to heuristic normalisation (lowercasing, replacing special characters, etc.).
    """
    function _normalize_key(source_section::String, section::String, key::String)
        # Clean up the section name for use as a dictionary key
        clean_section = replace(section, r"[^\w\s-]" => "")  # Remove special chars except spaces, dashes

        # Find matching BattMo key from the map if it exists
        if haskey(KEY_TO_BATTMO_MAP, key)
            return KEY_TO_BATTMO_MAP[key]
        else
            # Fallback: try to build a reasonable key
            base_key = replace(key, r"[^\w\s]" => "")  # Remove all non-alphanumeric except spaces
            base_key = replace(base_key, r"\s+" => "_")  # Replace multiple spaces with underscore
            base_key = lowercase(base_key)
            return base_key
        end
    end

    # Map from BPX keys to BattMo schema keys (partial - will be extended based on actual needs)
    const KEY_TO_BATTMO_MAP = Dict(
        # Cell parameters
        "Ambient temperature [K]" => "cell_ambient_temperature",
        "Initial temperature [K]" => "cell_initial_temperature",
        "Reference temperature [K]" => "cell_reference_temperature",
        "Lower voltage cut-off [V]" => "cell_lower_voltage_cutoff",
        "Upper voltage cut-off [V]" => "cell_upper_voltage_cutoff",
        "Nominal cell capacity [A.h]" => "cell_nominal_capacity",
        "Specific heat capacity [J.K-1.kg-1]" => "cell_specific_heat_capacity",
        "Thermal conductivity [W.m-1.K-1]" => "cell_thermal_conductivity",
        "Density [kg.m-3]" => "cell_density",
        "Electrode area [m2]" => "cell_electrode_area",
        "Number of electrode pairs connected in parallel to make a cell" => "cell_number_electrode_pairs",
        "External surface area [m2]" => "cell_external_surface_area",
        "Volume [m3]" => "cell_volume",

        # Electrolyte parameters
        "Initial concentration [mol.m-3]" => "electrolyte_initial_concentration",
        "Cation transference number" => "electrolyte_cation_transference_number",
        "Conductivity [S.m-1]" => "electrolyte_conductivity",
        "Diffusivity [m2.s-1]" => "electrolyte_diffusivity",
        "Conductivity activation energy [J.mol-1]" => "electrolyte_conductivity_activation_energy",
        "Diffusivity activation energy [J.mol-1]" => "electrolyte_diffusivity_activation_energy",

        # Electrode parameters (negative)
        "Particle radius [m]" => "negative_electrode_particle_radius",
        "Thickness [m]" => "negative_electrode_thickness",
        "Diffusivity [m2.s-1]" => "negative_electrode_diffusivity",
        "OCP [V]" => "negative_electrode_ocp",
        "Entropic change coefficient [V.K-1]" => "negative_electrode_entropic_coefficient",
        "Conductivity [S.m-1]" => "negative_electrode_conductivity",
        "Surface area per unit volume [m-1]" => "negative_electrode_surface_area_volume",
        "Porosity" => "negative_electrode_porosity",
        "Transport efficiency" => "negative_electrode_transport_efficiency",
        "Reaction rate constant [mol.m-2.s-1]" => "negative_electrode_reaction_rate_constant",
        "Minimum stoichiometry" => "negative_electrode_minimum_stoichiometry",
        "Maximum stoichiometry" => "negative_electrode_maximum_stoichiometry",
        "Maximum concentration [mol.m-3]" => "negative_electrode_maximum_concentration",
        "Diffusivity activation energy [J.mol-1]" => "negative_electrode_diffusivity_activation_energy",
        "Reaction rate constant activation energy [J.mol-1]" => "negative_electrode_reaction_rate_activation_energy",

        # Electrode parameters (positive) - will override negative ones when in positive section
        # These are mapped through the electrode section logic

        # Separator parameters
        "Thickness [m]" => "separator_thickness",
        "Porosity" => "separator_porosity",
        "Transport efficiency" => "separator_transport_efficiency",

        # Thermal parameters (for P2D model)
        # These will be derived from electrode sections

        # Grid parameters
        # These are not in BPX and will use defaults
    )

    """
        _extract_electrode_section(source_section::String, section::String, nested_data::Dict{String, Any}) -> Tuple{Bool, Dict{String, Any}}
    
    Extract electrode-specific parameters from a hierarchical BPX structure. Returns the 
    appropriate electrode type ("negative", "positive", or nothing) based on the section name
    along with any relevant nested data (like entropic coefficient tables).
    
    # Arguments
    - `source_section::String`: The top-level source identifier.
    - `section::String`: The BPX section name (e.g., "Negative electrode", "Positive electrode").
    - `nested_data::Dict{String, Any}`: The nested data dictionary for the section.
    
    # Returns
    A tuple of `(is_electrode_section::Bool, electrode_params::Dict{String, Any})`.
    """
    function _extract_electrode_section(source_section::String, section::String, nested_data::Dict{String, Any})
        electrode_params = Dict{String, Any}()

        if section == "Negative electrode"
            for (key, value) in nested_data
                normalized_key = _normalize_key(source_section, section, key)
                electrode_params[normalized_key] = value
            end
        elseif section == "Positive electrode"
            for (key, value) in nested_data
                normalized_key = _normalize_key(source_section, section, key)
                # For positive electrode, we could add a prefix or keep as-is
                # Since the schema uses unique keys, we store them directly
                electrode_params["positive_" * normalized_key] = value
            end
        elseif section == "Separator"
            for (key, value) in nested_data
                normalized_key = _normalize_key(source_section, section, key)
                electrode_params[normalized_key] = value
            end
        end

        return (length(electrode_params) > 0, electrode_params)
    end

    # ============================================================================
    # BPX file parsing
    # ============================================================================

    """
        _flatten_bpx_dict(data::Dict{String, Any}) -> Dict{String, Any}
    
    Flatten a hierarchical BPX dictionary into a single-level dictionary.
    
    BPX files use nested sections like:
    ```
    "Parameterisation" => {
        "Cell" => { ... },
        "Negative electrode" => { ... },
        ...
    }
    ```
    
    This function flattens such structures by concatenating section names with keys
    using a ``__`` separator. For example:
    - ``"Parameterisation"__"Negative electrode"__"Particle radius [m]"`` → value
    
    # Arguments
    - `data::Dict{String, Any}`: The hierarchical BPX dictionary to flatten.
    
    # Returns
    A flattened `Dict{String, Any}` where keys are concatenated paths using ``__`` separator.
    """
    function _flatten_bpx_dict(data::Dict{String, Any})::Dict{String, Any}
        flat_dict = Dict{String, Any}()

        for (section, value) in data
            if isa(value, Dict{String, Any})
                # Recursively flatten nested dictionaries
                for (sub_key, sub_value) in value
                    if isa(sub_value, Dict{String, Any})
                        # Double-nested: e.g. Parameterisation -> Negative electrode -> {key: value}
                        for (inner_key, inner_value) in sub_value
                            flat_key = section * "__" * sub_key * "__" * inner_key
                            if isa(inner_value, Dict{String, Any})
                                # Handle special cases like entropic coefficient with x/y arrays
                                flat_dict[flat_key] = inner_value
                            else
                                flat_dict[flat_key] = inner_value
                            end
                        end
                    else
                        # Single-nested: e.g. Cell -> {key: value}
                        flat_dict[section * "__" * sub_key] = sub_value
                    end
                end
            else
                # Top-level scalar value
                flat_dict[section] = value
            end
        end

        return flat_dict
    end

    """
        _parse_flat_to_cell_parameters(flat_dict::Dict{String, Any}, source_section::String) -> Dict{String, Any}
    
    Convert a flattened BPX dictionary to the CellParameters input format.
    
    This function maps the flattened hierarchical keys (using ``__`` separator) from 
    the BPX format into the flat key structure expected by BattMo's ``CellParameters`` 
    schema via `_normalize_key()`.
    
    # Arguments
    - `flat_dict::Dict{String, Any}`: A flattened dictionary with ``__`` separated keys.
    - `source_section::String`: The source identifier (e.g. filename without extension).
    
    # Returns
    A `Dict{String, Any}` in the format expected by ``CellParameters``.
    """
    function _parse_flat_to_cell_parameters(flat_dict::Dict{String, Any}, source_section::String)
        cell_params = Dict{String, Any}()

        for (flat_key, value) in flat_dict
            # Extract section and key from flattened path
            parts = split(flat_key, "__"; keepempty = false)

            if length(parts) >= 3
                # Triple-nested: Parameterisation__Negative electrode__Particle radius [m]
                section = parts[2]
                nested_data = Dict{String, Any}(parts[3] => value)
                _, electrode_params = _extract_electrode_section(source_section, section, nested_data)
                for (k, v) in electrode_params
                    cell_params[k] = v
                end
            elseif length(parts) == 2
                # Double-nested: Cell__Ambient temperature [K]
                section = parts[1]
                key = parts[2]

                if section == "Cell"
                    normalized_key = _normalize_key(source_section, section, key)
                    cell_params[normalized_key] = value
                elseif section == "Parameterisation"
                    # For parameterisation section, we need to look up nested sections
                    continue  # Already handled in triple-nested path
                end
            end
        end

        return cell_params
    end

    """
        _parse_to_cell_parameters(raw_data::Dict{String, Any}, source_section::String) -> Dict{String, Any}
    
    Parse raw BPX JSON data directly without flattening, mapping values to the 
    CellParameters input format according to the BattMo schema.
    
    This function handles both flat and hierarchical BPX structures. It recursively
    traverses the data dictionary, normalizing keys and extracting values into 
    the appropriate schema fields.
    
    # Arguments
    - `raw_data::Dict{String, Any}`: The raw JSON data from a BPX file.
    - `source_section::String`: The source section name (typically filename without extension).
    
    # Returns
    A `Dict{String, Any>` where keys are normalized to match the CellParameters schema 
    expected by BattMo.jl.
    """
    function _parse_to_cell_parameters(raw_data::Dict{String, Any}, source_section::String)::Dict{String, Any}
        cell_params = Dict{String, Any}()

        for (section, value) in raw_data
            if isa(value, Dict{String, Any})
                # Handle nested dictionaries
                for (key, sub_value) in value
                    if isa(sub_value, Dict{String, Any})
                        # Double-nested structure: e.g. Parameterisation -> Negative electrode -> { ... }
                        electrode_section = key  # "Negative electrode", "Positive electrode", "Separator"

                        if electrode_section == "Cell"
                            # Cell-level parameters
                            for (param_key, param_value) in sub_value
                                normalized_key = _normalize_key(source_section, "Cell", param_key)
                                cell_params[normalized_key] = param_value
                            end
                        elseif startswith(electrode_section, "Negative") ||
                                startswith(electrode_section, "Positive") ||
                                electrode_section == "Separator"
                            # Electrode parameters (negative/positive electrodes or separator)
                            for (param_key, param_value) in sub_value
                                normalized_key = _normalize_key(source_section, electrode_section, param_key)
                                cell_params[normalized_key] = param_value
                            end
                        end
                    else
                        # Single-nested scalar (e.g. Header -> "BPX": 0.1): skip non-scalar values we don't need
                        continue
                    end
                end
            else
                # Top-level scalar (e.g. "BPX": 0.1)
                continue
            end
        end

        return cell_params
    end

    # ============================================================================
    # Public API
    # ============================================================================

    """
        load_from_bpx_file(file_path::String) -> Dict{String, Any}
    
    Load and parse a BPX-formatted JSON file into the CellParameters input format.
    
    This function reads a BPX (Battery Parameter eXchange) JSON file and converts
    it to the cell parameter input format expected by BattMo's ``CellParameters``
    schema.
    
    # Arguments
    - `file_path::String`: Path to the BPX-formatted JSON file to load.
    
    # Returns
    A `Dict{String, Any}` where keys are normalized to match the ``CellParameters`` 
    schema expected by BattMo.jl.
    
    # Example
    ```julia
    cell_parameters = load_from_bpx_file("path/to/bpx_input.json")
    ```
    
    # Notes
    - The function handles both flat and hierarchical BPX structures.
    - Keys are normalized using ``_normalize_key()`` to match the BattMo schema.
    - Unit information in brackets (e.g., "[m]", "[K]") is preserved in keys where applicable.
    """
    function load_from_bpx_file(file_path::String)::Dict{String, Any}
        raw_data = JSON.parsefile(file_path)

        # Extract source section from filename
        source_section = replace(splitext(basename(file_path))[1], r"[^a-zA-Z0-9]" => "_")

        # Parse the raw data to cell parameters format
        return _parse_to_cell_parameters(raw_data, source_section)
    end

    # Helper function to get basename (for cross-platform compatibility)
    basename(path::String) = replace(path, r"^.*[\\/:]" => "")

    # Helper function to get extension and stem
    splitext(filename::String) = begin
        name = filename
        ext = ""
        # Find the last dot
        dots = findall(==('.'), name)
        if !isempty(dots)
            last_dot = dots[end]
            # Don't split at leading dot (hidden files) or if dot is at position 1
            if last_dot > 1 && last_dot < length(name)
                ext = name[(last_dot + 1):end]
                name = name[1:(last_dot - 1)]
            end
        end
        return name, ext
    end

    # Helper for getting file extension (unused but kept for API compatibility)
    get_extension(filename::String) = splitext(filename)[2]

    # ============================================================================
    # Legacy support functions (if needed elsewhere in the codebase)
    # ============================================================================

    """
        parse_bpx_to_cell_parameters(bpx_data::Dict{String, Any}) -> Dict{String, Any}
    
    Parse BPX-formatted data to BattMo cell parameters format.
    
    This is a convenience wrapper around ``load_from_bpx_file()`` that takes
    already-parsed JSON data (as a ``Dict``) and converts it to the 
    CellParameters input format.
    
    # Arguments
    - `bpx_data::Dict{String, Any>`: BPX-formatted data as a dictionary.
    
    # Returns
    A `Dict{String, Any>` in the format expected by ``CellParameters``.
    """
    function parse_bpx_to_cell_parameters(bpx_data::Dict{String, Any})::Dict{String, Any}
        source_section = "default"
        return _parse_to_cell_parameters(bpx_data, source_section)
    end

end # end of BPX module
