export interpolate_state_at_voltage



"""
    interpolate_state_at_voltage(states, target_voltage)

Given a vector of simulation output states and a target voltage, find the two
consecutive states whose voltages bracket `target_voltage` and return a new state
obtained by linear interpolation of every field (including time).

The voltage of each state is read from `state[:Control][:ElectricPotential][1]`.
Interpolation weights are computed from the voltages of the two bracketing states
and applied uniformly to all numeric fields in the state tree (scalars, vectors,
matrices) as well as to the numeric fields of the `Controller` struct.

The returned state is a fresh `Dict` that can be passed directly as `initial_state`
to the `Simulation` constructor.

# Arguments
- `states`: A vector of state dictionaries, e.g. `output.jutul_output.states`.
- `target_voltage::Real`: The desired voltage (V).

# Returns
A new state dictionary approximating the battery state at `target_voltage`.

# Throws
- An error if `states` has fewer than two entries.
- An error if `target_voltage` is not bracketed by any pair of consecutive states
  (i.e. the voltage sequence never crosses the target).

# Example
```julia
sim = Simulation(model, cell_parameters, protocol; output_all_secondary_variables = true)
output = solve(sim)
states = output.jutul_output.states
state_at_3V = interpolate_state_at_voltage(states, 3.0)
sim2 = Simulation(model, cell_parameters, protocol; initial_state = state_at_3V)
```
"""
function interpolate_state_at_voltage(states::AbstractVector, target_voltage::Real)
    length(states) >= 2 || error("Need at least two states to interpolate; got $(length(states)).")

    # Extract voltages for every state
    voltages = [Float64(s[:Control][:ElectricPotential][1]) for s in states]

    # Find the first pair of consecutive states that brackets the target voltage.
    # The voltage may be increasing or decreasing, so we look for a sign change
    # in (voltage - target) between consecutive states.
    bracket_idx = nothing
    for i in 1:(length(voltages) - 1)
        v_lo = voltages[i] - target_voltage
        v_hi = voltages[i + 1] - target_voltage
        if v_lo * v_hi <= 0  # sign change or exact match
            bracket_idx = i
            break
        end
    end

    isnothing(bracket_idx) && error(
        "Target voltage $target_voltage V is not bracketed by any pair of " *
        "consecutive states.  Voltage range: [$(minimum(voltages)), $(maximum(voltages))] V."
    )

    s1 = states[bracket_idx]
    s2 = states[bracket_idx + 1]
    v1 = voltages[bracket_idx]
    v2 = voltages[bracket_idx + 1]

    # Interpolation weight: w such that (1 - w) * v1 + w * v2 == target_voltage
    if v1 == v2
        w = 0.5
    else
        w = (target_voltage - v1) / (v2 - v1)
    end

    return _interpolate_states(s1, s2, w)
end

# ── Internal helpers ──────────────────────────────────────────────────────────

"""Recursively interpolate two state dictionaries with weight `w` (where w=0 returns s1 and w=1 returns s2)."""
function _interpolate_states(s1::AbstractDict, s2::AbstractDict, w::Real)
    result = Dict{keytype(s1), Any}()
    for key in keys(s1)
        haskey(s2, key) || continue
        result[key] = _interpolate_field(s1[key], s2[key], w)
    end
    return result
end

"""Interpolate two values of the same type.  Dispatches on the actual type."""
function _interpolate_field(a::AbstractDict, b::AbstractDict, w::Real)
    return _interpolate_states(a, b, w)
end

function _interpolate_field(a::AbstractArray{<:Number}, b::AbstractArray{<:Number}, w::Real)
    return @. (1 - w) * a + w * b
end

function _interpolate_field(a::Number, b::Number, w::Real)
    return (1 - w) * a + w * b
end

function _interpolate_field(a::Controller, b::Controller, w::Real)
    T = typeof(a)
    T == typeof(b) || error("Controller types differ: $(typeof(a)) vs $(typeof(b))")
    result = deepcopy(a)
    for f in fieldnames(T)
        va = getproperty(a, f)
        vb = getproperty(b, f)
        if va isa Number && vb isa Number
            setproperty!(result, f, (1 - w) * va + w * vb)
        elseif va isa Controller && vb isa Controller
            setfield!(result, f, _interpolate_field(va, vb, w))
        end
        # Non-numeric fields (Bool, String, etc.) keep the value from `a`.
    end
    return result
end

# Fallback: non-interpolatable fields (e.g. strings, bools) keep the first value.
function _interpolate_field(a, b, w::Real)
    return deepcopy(a)
end

function get_model(base_model::String, model_settings::ModelSettings)

    if base_model == "LithiumIonBattery"
        model = LithiumIonBattery(; model_settings = model_settings)
    elseif base_model == "SodiumIonBattery"
        model = SodiumIonBattery(; model_settings = model_settings)
    else
        error("BaseModel $base_model is not valid. The following models are available: LithiumIonBattery, SodiumIonBattery")
    end

    return model
end

struct SourceAtCell
    cell::Any
    src::Any
    function SourceAtCell(cell, src)
        return new(cell, src)
    end
end


function amg_precond(; max_levels = 10, max_coarse = 10, type = :smoothed_aggregation)

    gs_its = 1
    cyc = AlgebraicMultigrid.V()
    if type == :smoothed_aggregation
        m = smoothed_aggregation
    else
        m = ruge_stuben
    end
    gs = GaussSeidel(ForwardSweep(), gs_its)

    return AMGPreconditioner(m, max_levels = max_levels, max_coarse = max_coarse, presmoother = gs, postsmoother = gs, cycle = cyc)

end
