export EquilibriumCalibration, equilibrium_voltage, equilibrium_states, export_calibration_parameters
using ForwardDiff

const EQUILIBRIUM_CALIBRATION_PARAMETERS = (
    ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"],
    ["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"],
    ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"],
    ["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"],
)

const EQUILIBRIUM_ELECTRODES = (negative = "NegativeElectrode", positive = "PositiveElectrode")

"""
    EquilibriumCalibration(t, v, current::Number, cell_parameters; kwargs...)
    EquilibriumCalibration(t, v, current::AbstractVector, cell_parameters; kwargs...)

Set up equilibrium calibration against a low-rate constant-current curve, or against a
low-rate time series of discharges, charges, and rests (see the second method).

The calibrated Julia parameters are `StoichiometricCoefficientAtSOC100` and
`MaximumConcentration` for each electrode. `MaximumConcentration` is used as
the Julia representation of the MATLAB setup's total active-material amount,
with electrode geometry and volume fractions held fixed.

The initial calibration vector is stored in `calibration.X0` with ordering
`[theta100_ne, cmax_ne, theta100_pe, cmax_pe]`. For a time series, the stoichiometries are
those at the first sample, and a series resistance may follow.
"""
mutable struct EquilibriumCalibration <: AbstractCalibration
    "Time values from the first sample [s]."
    t::Vector{Float64}
    "Measured cell voltage [V]."
    v::Vector{Float64}
    "Applied signed current of a constant-current curve [A], positive on discharge and negative on charge; NaN for a time series."
    current::Float64
    "Applied signed current at each sample [A]."
    currents::Vector{Float64}
    "Net discharged charge since the first sample [C]."
    charge::Vector{Float64}
    "Cell parameters used as the calibration starting point."
    cell_parameters::CellParameters
    "Temperature used to evaluate the electrode OCP functions [K]."
    temperature::Float64
    "Voltage defining the end of the calibration curve [V]."
    cutoff_voltage::Float64
    "Target negative-to-positive electrode capacity ratio."
    np_ratio::Float64
    "Initial values of the calibration parameters."
    X0::Vector{Float64}
    "Lower and upper bounds for the calibration parameters."
    bounds::NamedTuple
    "Most recently calibrated parameter vector."
    Xopt::Any
    "Optimization history returned by Jutul's BFGS solver."
    history::Any
    ocp_functions::NamedTuple
    active_volumes::NamedTuple
    "OCP hysteresis parameters of each electrode (`setup_ocp_hysteresis_parameters!`), or nothing."
    hysteresis::NamedTuple
    "Hysteresis state of each electrode at the first sample."
    initial_hysteresis::NamedTuple
    "Whether the calibration vector ends with a series resistance [Ohm]."
    fit_resistance::Bool
end

function EquilibriumCalibration(
        t, v, current, cell_parameters::CellParameters;
        temperature = equilibrium_reference_temperature(cell_parameters),
        cutoff_voltage = minimum(v),
        np_ratio = 1.1,
        stoichiometry_bounds = (0.0, 1.0),
        concentration_factors = (0.1, 10.0),
    )
    if length(t) != length(v)
        throw(ArgumentError("Time and voltage data must have equal length."))
    end
    if length(t) < 2
        throw(ArgumentError("At least two calibration points are required."))
    end
    if !isa(current, Number)
        throw(ArgumentError("Current must be a scalar."))
    end
    if iszero(current)
        throw(ArgumentError("Equilibrium calibration expects a nonzero signed current."))
    end
    if !(np_ratio > 0)
        throw(ArgumentError("The N/P ratio must be positive."))
    end

    order = sortperm(t)
    t_sorted = Float64.(t[order])
    v_sorted = Float64.(v[order])
    t_sorted .-= first(t_sorted)
    if !all(diff(t_sorted) .> 0)
        throw(ArgumentError("Time values must be unique."))
    end

    parameters = deepcopy(cell_parameters)
    X0 = Float64[]
    lower = Float64[]
    upper = Float64[]
    for (i, key) in enumerate(EQUILIBRIUM_CALIBRATION_PARAMETERS)
        v0 = get_nested_json_value(parameters, key)
        bounds = isodd(i) ? stoichiometry_bounds : concentration_factors .* v0
        push!(X0, v0)
        push!(lower, first(bounds))
        push!(upper, last(bounds))
    end

    # A single curve at constant current, on the OpenCircuitPotential of each electrode.
    electrodes = setup_equilibrium_electrodes(parameters)
    if !all(isnothing, electrodes.hysteresis)
        @warn "The OCP hysteresis of the cell parameters is ignored for a constant-current curve; pass the current at each sample to include it."
    end

    return EquilibriumCalibration(
        t_sorted,
        v_sorted,
        Float64(current),
        fill(Float64(current), length(t_sorted)),
        t_sorted .* Float64(current),
        parameters,
        Float64(temperature),
        Float64(cutoff_voltage),
        Float64(np_ratio),
        X0,
        (lower = lower, upper = upper),
        missing,
        missing,
        electrodes.ocp_functions,
        electrodes.active_volumes,
        (negative = nothing, positive = nothing),
        (negative = 0.0, positive = 0.0),
        false,
    )
end

"""
    EquilibriumCalibration(t, v, current::AbstractVector, cell_parameters;
        initial_hysteresis = (negative = 0.0, positive = 0.0), fit_resistance = false,
        resistance_bounds = (0.0, 0.1 / maximum(abs, current)),
        temperature = equilibrium_reference_temperature(cell_parameters), np_ratio = 1.1,
        stoichiometry_bounds = (0.0, 1.0), concentration_factors = (0.1, 10.0))

Set up equilibrium calibration against a low-rate time series: strictly increasing sample times
`t` [s], cell voltages `v` [V], and the applied signed current at each sample `current` [A],
positive on discharge. The series may hold any sequence of discharges, charges, and rests, at
any rates. The current is integrated over the series with the trapezoidal rule, so that the
stoichiometries follow the net charge passed since the first sample. A current step between two
samples is integrated as a linear ramp, which misplaces up to half the step times the sample
interval of charge.

The objective is the time integral of the squared voltage error over all samples; pass only the
part of a measurement that is to be fitted.

The calibration vector is `[theta_ne, cmax_ne, theta_pe, cmax_pe]`, with the stoichiometry of each
electrode at the first sample; with `fit_resistance = true`, a series resistance `R` [Ohm]
follows, and the cell voltage is the equilibrium voltage minus `R` times the current. The
resistance is a lumped parameter that also takes up any error in the gap between the two OCP
branches. The initial stoichiometries lie between `StoichiometricCoefficientAtSOC100` and
`StoichiometricCoefficientAtSOC0` of `cell_parameters`, as the first sample lies between the
fullest and the emptiest sample.

If the active material of an electrode gives both OCP branches (`OpenCircuitPotentialLithiation`
and `OpenCircuitPotentialDelithiation`) and their decay rates, its OCP follows the one-state
hysteresis of the DFN, starting at `initial_hysteresis` (see `equilibrium_states`); otherwise
`OpenCircuitPotential` is used. The hysteresis state takes one step per sample, so it depends on
the sample spacing. `export_calibration_parameters` takes SOC 100 and SOC 0 at the
fullest and the emptiest sample by default; `np_ratio` only enters the export of a
constant-current calibration.
"""
function EquilibriumCalibration(
        t, v, current::AbstractVector, cell_parameters::CellParameters;
        initial_hysteresis = (negative = 0.0, positive = 0.0),
        fit_resistance = false,
        resistance_bounds = (0.0, 0.1 / maximum(abs, current)),
        temperature = equilibrium_reference_temperature(cell_parameters),
        np_ratio = 1.1,
        stoichiometry_bounds = (0.0, 1.0),
        concentration_factors = (0.1, 10.0),
    )
    n = length(t)
    if length(v) != n || length(current) != n
        throw(ArgumentError("Time, voltage, and current data must have equal length."))
    end
    if n < 2
        throw(ArgumentError("At least two calibration points are required."))
    end
    if !(all(isfinite, t) && all(isfinite, v) && all(isfinite, current))
        throw(ArgumentError("Time, voltage, and current data must be finite."))
    end
    times = Float64.(t)
    if !all(diff(times) .> 0)
        throw(ArgumentError("Time values must be strictly increasing."))
    end
    times .-= first(times)
    currents = Float64.(current)
    charge = cumtrapz(times, currents)
    if !(maximum(charge) > minimum(charge))
        throw(ArgumentError("The series must pass a net charge."))
    end
    if !all(electrode -> -1 <= getproperty(initial_hysteresis, electrode) <= 1, (:negative, :positive))
        throw(ArgumentError("Initial hysteresis states must lie in [-1, 1]."))
    end
    if !(np_ratio > 0)
        throw(ArgumentError("The N/P ratio must be positive."))
    end

    parameters = deepcopy(cell_parameters)
    # The first sample lies this far from the fullest towards the emptiest sample.
    fraction = (first(charge) - minimum(charge)) / (maximum(charge) - minimum(charge))
    X0 = Float64[]
    lower = Float64[]
    upper = Float64[]
    for electrode in ("NegativeElectrode", "PositiveElectrode")
        am = parameters[electrode]["ActiveMaterial"]
        theta100 = am["StoichiometricCoefficientAtSOC100"]
        theta0 = get(am, "StoichiometricCoefficientAtSOC0", theta100)
        cmax = am["MaximumConcentration"]
        append!(X0, [theta100 + fraction * (theta0 - theta100), cmax])
        append!(lower, [first(stoichiometry_bounds), first(concentration_factors) * cmax])
        append!(upper, [last(stoichiometry_bounds), last(concentration_factors) * cmax])
    end
    if fit_resistance
        push!(X0, first(resistance_bounds))
        push!(lower, first(resistance_bounds))
        push!(upper, last(resistance_bounds))
    end

    electrodes = setup_equilibrium_electrodes(parameters)

    return EquilibriumCalibration(
        times,
        Float64.(v),
        NaN,
        currents,
        charge,
        parameters,
        Float64(temperature),
        minimum(v),
        Float64(np_ratio),
        X0,
        (lower = lower, upper = upper),
        missing,
        missing,
        electrodes.ocp_functions,
        electrodes.active_volumes,
        electrodes.hysteresis,
        (negative = Float64(initial_hysteresis.negative), positive = Float64(initial_hysteresis.positive)),
        fit_resistance,
    )
end

"""Reference temperature of the OCP functions of `cell_parameters` [K], as for the DFN."""
function equilibrium_reference_temperature(cell_parameters)
    return get(cell_parameters["Cell"], "ReferenceTemperature", DEFAULT_REFERENCE_TEMPERATURE)
end

"""OCP functions, active-material volumes, and hysteresis parameters of both electrodes."""
function setup_equilibrium_electrodes(cell_parameters)
    return (
        ocp_functions = map(electrode -> setup_equilibrium_ocp(cell_parameters, electrode), EQUILIBRIUM_ELECTRODES),
        active_volumes = map(electrode -> equilibrium_active_material_volume(cell_parameters, electrode), EQUILIBRIUM_ELECTRODES),
        hysteresis = map(electrode -> setup_equilibrium_hysteresis(cell_parameters, electrode), EQUILIBRIUM_ELECTRODES),
    )
end

function equilibrium_base_path(cell_parameters)
    if isnothing(cell_parameters.source_path)
        return pwd()
    else
        return dirname(cell_parameters.source_path)
    end
end

function setup_equilibrium_ocp(cell_parameters, electrode)
    am = cell_parameters[electrode]["ActiveMaterial"]
    func, func_type = setup_function(equilibrium_base_path(cell_parameters), am["OpenCircuitPotential"], "ActiveMaterial", "OpenCircuitPotential")
    return (func = func, type = func_type, reference_temperature = equilibrium_reference_temperature(cell_parameters))
end

"""Hysteresis parameters of `electrode`, as for the DFN (`setup_ocp_hysteresis_parameters!`), or nothing."""
function setup_equilibrium_hysteresis(cell_parameters, electrode)
    params = Dict{Symbol, Any}(:reference_temperature => equilibrium_reference_temperature(cell_parameters))
    if setup_ocp_hysteresis_parameters!(params, cell_parameters[electrode]["ActiveMaterial"], equilibrium_base_path(cell_parameters), electrode)
        return params
    else
        return nothing
    end
end

function equilibrium_active_material_volume(cell_parameters, electrode)
    electrode_parameters = cell_parameters[electrode]
    am = electrode_parameters["ActiveMaterial"]
    coating = electrode_parameters["Coating"]
    cell = cell_parameters["Cell"]
    if haskey(cell, "ElectrodeGeometricSurfaceArea")
        area = compute_total_electrode_area(cell_parameters)
    else
        throw(ArgumentError("Only 1D geometry is currently supported for equilibrium calibration."))
    end
    coating_volume = area * coating["Thickness"]
    return coating_volume * coating["EffectiveDensity"] * am["MassFraction"] / am["Density"]
end

function evaluate_equilibrium_ocp(ocp, theta, cmax, temperature)
    return evaluate_ocp_function(ocp.func, ocp.type, theta * cmax, temperature, ocp.reference_temperature, cmax)
end

"""Charge that takes the stoichiometry of `electrode` from 0 to 1 at maximum concentration `cmax` [C]."""
function equilibrium_electrode_capacity(eqc::EquilibriumCalibration, electrode, cmax)
    am = eqc.cell_parameters[EQUILIBRIUM_ELECTRODES[electrode]]["ActiveMaterial"]
    return am["NumberOfElectronsTransfered"] * FARADAY_CONSTANT * eqc.active_volumes[electrode] * cmax
end

"""
Stoichiometries of both electrodes after the net discharged charge `q` [C] since the first sample,
for one charge or a vector of charges.
"""
function equilibrium_stoichiometries_at_charge(eqc::EquilibriumCalibration, q, x)
    negative = x[1] .- q ./ equilibrium_electrode_capacity(eqc, :negative, x[2])
    positive = x[3] .+ q ./ equilibrium_electrode_capacity(eqc, :positive, x[4])
    return (; negative, positive)
end

function check_constant_current(eqc::EquilibriumCalibration)
    if isnan(eqc.current)
        throw(ArgumentError("Evaluation at a time needs a constant-current calibration; use equilibrium_states for a time series."))
    end
    return nothing
end

function equilibrium_stoichiometries(eqc::EquilibriumCalibration, t, x)
    check_constant_current(eqc)
    return equilibrium_stoichiometries_at_charge(eqc, t * eqc.current, x)
end

"""
    equilibrium_voltage(eqc, t, x)

Evaluate the equilibrium full-cell voltage at time `t` of a constant-current calibration `eqc`
for calibration vector `x = [theta100_ne, cmax_ne, theta100_pe, cmax_pe]`.
"""
function equilibrium_voltage(eqc::EquilibriumCalibration, t, x)
    theta = equilibrium_stoichiometries(eqc, t, x)
    ne_theta = clamp(theta.negative, zero(theta.negative), one(theta.negative))
    pe_theta = clamp(theta.positive, zero(theta.positive), one(theta.positive))
    ne_ocp = evaluate_equilibrium_ocp(eqc.ocp_functions.negative, ne_theta, x[2], eqc.temperature)
    pe_ocp = evaluate_equilibrium_ocp(eqc.ocp_functions.positive, pe_theta, x[4], eqc.temperature)
    return pe_ocp - ne_ocp
end

"""
    equilibrium_states(eqc, x)

Evaluate the equilibrium model of `eqc` at every sample for calibration vector `x`. Return the
cell `voltage` and, for the `negative` and `positive` electrode, the stoichiometry `theta`, the
hysteresis state `h` (`nothing` without hysteresis), and the open-circuit potential `ocp`. The
OCPs are evaluated at stoichiometries clamped to [0, 1].

With hysteresis, the state of an electrode starts at `initial_hysteresis` and follows the
implicit Euler step of `HysteresisEquation` from sample to sample: over a stoichiometry change
`dtheta`, with the decay rate at the later sample, it moves towards the delithiation branch
(`h = 1`) when `dtheta < 0` and towards the lithiation branch (`h = -1`) otherwise. The OCP is
`(1 + h) / 2 * U_delith + (1 - h) / 2 * U_lith`. With a series resistance `R`, the voltage is the
equilibrium voltage minus `R` times the applied current.
"""
function equilibrium_states(eqc::EquilibriumCalibration, x)
    theta = equilibrium_stoichiometries_at_charge(eqc, eqc.charge, x)
    negative = equilibrium_electrode_states(eqc, theta.negative, x[2], :negative)
    positive = equilibrium_electrode_states(eqc, theta.positive, x[4], :positive)
    voltage = positive.ocp .- negative.ocp
    if eqc.fit_resistance
        voltage = voltage .- x[5] .* eqc.currents
    end
    return (; negative, positive, voltage)
end

"""Hysteresis state and OCP of `electrode` with maximum concentration `cmax` along its stoichiometries `theta`."""
function equilibrium_electrode_states(eqc::EquilibriumCalibration, theta, cmax, electrode)
    clamped = [clamp(value, zero(value), one(value)) for value in theta]
    hysteresis = getproperty(eqc.hysteresis, electrode)
    if isnothing(hysteresis)
        ocp_function = getproperty(eqc.ocp_functions, electrode)
        ocp = [evaluate_equilibrium_ocp(ocp_function, value, cmax, eqc.temperature) for value in clamped]
        return (; theta, h = nothing, ocp)
    end
    h = Vector{promote_type(eltype(theta), Float64)}(undef, length(theta))
    h[1] = getproperty(eqc.initial_hysteresis, electrode)
    for k in 2:length(theta)
        h[k] = equilibrium_hysteresis_step(hysteresis, h[k - 1], theta[k] - theta[k - 1], clamped[k], cmax, eqc.temperature)
    end
    reference_temperature = hysteresis[:reference_temperature]
    ocp = map(clamped, h) do value, state
        c = value * cmax
        u_lith = evaluate_ocp_function(hysteresis[:ocp_lithiation_func], hysteresis[:ocp_lithiation_func_type], c, eqc.temperature, reference_temperature, cmax)
        u_delith = evaluate_ocp_function(hysteresis[:ocp_delithiation_func], hysteresis[:ocp_delithiation_func_type], c, eqc.temperature, reference_temperature, cmax)
        return (1 + state) / 2 * u_delith + (1 - state) / 2 * u_lith
    end
    return (; theta, h, ocp)
end

"""
Hysteresis state after one implicit Euler step of `HysteresisEquation` from `h0` over the
stoichiometry change `dtheta`, with the decay rate at stoichiometry `theta`.
"""
function equilibrium_hysteresis_step(hysteresis, h0, dtheta, theta, cmax, temperature)
    reference_temperature = hysteresis[:reference_temperature]
    if dtheta < 0
        gamma = evaluate_ocp_function(
            hysteresis[:hysteresis_decay_delithiation_func], hysteresis[:hysteresis_decay_delithiation_func_type],
            theta * cmax, temperature, reference_temperature, cmax,
        )
        # h - h0 - a * (1 - h) = 0
        a = -gamma * dtheta / 2
        return (h0 + a) / (1 + a)
    else
        gamma = evaluate_ocp_function(
            hysteresis[:hysteresis_decay_lithiation_func], hysteresis[:hysteresis_decay_lithiation_func_type],
            theta * cmax, temperature, reference_temperature, cmax,
        )
        # h - h0 + a * (1 + h) = 0
        a = gamma * dtheta / 2
        return (h0 - a) / (1 + a)
    end
end

"""Time integral of the squared voltage error of calibration vector `x` over the samples of `eqc`."""
function equilibrium_calibration_objective(eqc::EquilibriumCalibration, x)
    e = equilibrium_states(eqc, x).voltage .- eqc.v
    return trapz(eqc.t, abs2.(e))
end

function equilibrium_calibration_objective_and_gradient(eqc::EquilibriumCalibration, x)
    objective(z) = equilibrium_calibration_objective(eqc, z)
    return (objective(x), ForwardDiff.gradient(objective, x))
end

function find_equilibrium_cutoff_time(eqc::EquilibriumCalibration, x)
    t_low = zero(eltype(x))
    t_high = max(eqc.t[end], one(eltype(x)))
    voltage(t) = equilibrium_voltage(eqc, t, x)
    is_discharge = eqc.current > 0
    cutoff_reached(t) = is_discharge ? voltage(t) <= eqc.cutoff_voltage : voltage(t) >= eqc.cutoff_voltage
    for _ in 1:20
        cutoff_reached(t_high) && break
        t_high *= 1.5
    end
    if !cutoff_reached(t_high)
        return eqc.t[end]
    end
    for _ in 1:60
        t_mid = (t_low + t_high) / 2
        if !cutoff_reached(t_mid)
            t_low = t_mid
        else
            t_high = t_mid
        end
    end
    return t_high
end

"""
    export_calibration_parameters(eqc, x_calibrated; soc100_sample = argmin(eqc.charge),
        soc0_sample = argmax(eqc.charge))

Export the calibrated and derived equilibrium parameters as a minimal nested
dictionary. The result can overwrite the corresponding values in an existing
parameter dictionary with
`merge_dict(parameters, exported; type = "overwrite")`.

For a time series, the SOC 100 and SOC 0 stoichiometries are those of the samples
`soc100_sample` and `soc0_sample`, by default the fullest and the emptiest sample, clamped to
[0, 1]; a series resistance is not exported. A constant-current calibration ignores these keywords.
"""
function export_calibration_parameters(
        eqc::EquilibriumCalibration, x_calibrated; soc100_sample = argmin(eqc.charge), soc0_sample = argmax(eqc.charge),
    )
    if length(x_calibrated) != length(eqc.X0)
        throw(ArgumentError("Expected $(length(eqc.X0)) calibrated equilibrium parameters."))
    end

    if isnan(eqc.current)
        full = equilibrium_stoichiometries_at_charge(eqc, eqc.charge[soc100_sample], x_calibrated)
        empty = equilibrium_stoichiometries_at_charge(eqc, eqc.charge[soc0_sample], x_calibrated)
        return Dict(
            electrode => Dict(
                "ActiveMaterial" => Dict(
                    "StoichiometricCoefficientAtSOC100" => clamp(getproperty(full, key), 0.0, 1.0),
                    "StoichiometricCoefficientAtSOC0" => clamp(getproperty(empty, key), 0.0, 1.0),
                    "MaximumConcentration" => x_calibrated[index],
                ),
            ) for (electrode, key, index) in (("NegativeElectrode", :negative, 2), ("PositiveElectrode", :positive, 4))
        )
    end

    cutoff_time = find_equilibrium_cutoff_time(eqc, x_calibrated)
    theta = equilibrium_stoichiometries(eqc, cutoff_time, x_calibrated)
    pe_theta0 = clamp(theta.positive, 0.0, 1.0)
    amount_ratio = equilibrium_electrode_capacity(eqc, :positive, x_calibrated[4]) / equilibrium_electrode_capacity(eqc, :negative, x_calibrated[2])
    ne_theta0 = x_calibrated[1] - eqc.np_ratio * amount_ratio * (pe_theta0 - x_calibrated[3])
    ne_theta0 = clamp(ne_theta0, 0.0, 1.0)

    return Dict(
        "NegativeElectrode" => Dict(
            "ActiveMaterial" => Dict(
                "StoichiometricCoefficientAtSOC100" => x_calibrated[1],
                "StoichiometricCoefficientAtSOC0" => ne_theta0,
                "MaximumConcentration" => x_calibrated[2],
            ),
        ),
        "PositiveElectrode" => Dict(
            "ActiveMaterial" => Dict(
                "StoichiometricCoefficientAtSOC100" => x_calibrated[3],
                "StoichiometricCoefficientAtSOC0" => pe_theta0,
                "MaximumConcentration" => x_calibrated[4],
            ),
        ),
    )
end

"""
    solve(eqc::EquilibriumCalibration; kwargs...)

Calibrate the equilibrium curve or time series with `Jutul.LBFGS.optimize_bound_constrained` and
return the calibrated parameter vector.
"""
function solve(
        eqc::EquilibriumCalibration;
        grad_tol = 1.0e-6,
        obj_change_tol = 1.0e-8,
        print = 1,
        kwarg...,
    )
    objective(x) = equilibrium_calibration_objective_and_gradient(eqc, x)
    jutul_message("Calibration", "Starting equilibrium calibration.", color = :green)
    optimizer_kwargs = Dict{Symbol, Any}(kwarg)
    if haskey(optimizer_kwargs, :line_searchmax_it)
        if !haskey(optimizer_kwargs, :ls_max_it)
            optimizer_kwargs[:ls_max_it] = optimizer_kwargs[:line_searchmax_it]
        end
        delete!(optimizer_kwargs, :line_searchmax_it)
    end
    lower = eqc.bounds.lower
    upper = eqc.bounds.upper
    dx_du = upper .- lower
    x_to_u(x) = (x .- lower) ./ dx_du
    u_to_x(u) = u .* dx_du .+ lower
    function unit_objective(u)
        value, gradient = objective(u_to_x(u))
        return value, gradient .* dx_du
    end
    optimize = () -> Jutul.LBFGS.optimize_bound_constrained(
        x_to_u(eqc.X0), unit_objective, zeros(length(eqc.X0)), ones(length(eqc.X0));
        maximize = false,
        grad_tol = grad_tol,
        grad_rel_tol = -Inf,
        obj_change_tol = obj_change_tol,
        obj_change_tol_rel = -Inf,
        obj_rel_tol = -Inf,
        optimizer_kwargs...,
    )
    if print > 0
        value, u, history = optimize()
    else
        value, u, history = redirect_stdout(optimize, devnull)
    end
    x = u_to_x(u)
    eqc.Xopt = copy(x)
    eqc.history = history
    milli = Jutul.si_unit("milli")
    voltage_rmse = rmse(eqc.t, eqc.v, eqc.t, equilibrium_states(eqc, x).voltage)
    jutul_message("Calibration", "Equilibrium calibration finished with objective $value and RMSE $(voltage_rmse / milli) mV.", color = :green)
    return x
end

"""Parameter paths of the calibration vector of `eqc`, for printing."""
function equilibrium_calibration_parameter_names(eqc::EquilibriumCalibration)
    names = [collect(path) for path in EQUILIBRIUM_CALIBRATION_PARAMETERS]
    if isnan(eqc.current)
        names[1][end] = "StoichiometryAtFirstSample"
        names[3][end] = "StoichiometryAtFirstSample"
    end
    if eqc.fit_resistance
        push!(names, ["SeriesResistance"])
    end
    return names
end

function print_calibration_overview(eqc::EquilibriumCalibration; use_acronyms = true)
    acronyms = Dict(
        "ActiveMaterial" => "am",
        "MaximumConcentration" => "cmax",
        "NegativeElectrode" => "ne",
        "PositiveElectrode" => "pe",
        "StoichiometricCoefficientAtSOC100" => "theta100",
        "StoichiometryAtFirstSample" => "theta_first",
        "SeriesResistance" => "R",
    )
    if ismissing(eqc.Xopt)
        optimized = fill(missing, length(eqc.X0))
    else
        optimized = eqc.Xopt
    end
    names = equilibrium_calibration_parameter_names(eqc)
    header = ["Parameter", "Bounds", "Initial value", "Optimized value", "Box limit hit"]
    table = Matrix{Any}(undef, length(eqc.X0), length(header))
    for i in eachindex(eqc.X0)
        parameter = names[i]
        if use_acronyms
            parameter = [get(acronyms, part, part) for part in parameter]
        end
        lower_bound = eqc.bounds.lower[i]
        upper_bound = eqc.bounds.upper[i]
        limit_hit = ""
        if !ismissing(optimized[i])
            # Match the unit-box scaling used by the optimizer, allowing for roundoff.
            bound_tolerance = 1.0e-8 * (upper_bound - lower_bound)
            if isapprox(optimized[i], lower_bound; atol = bound_tolerance, rtol = 0.0) ||
                    isapprox(optimized[i], upper_bound; atol = bound_tolerance, rtol = 0.0)
                limit_hit = "*"
            end
        end
        table[i, :] = [
            join(parameter, "."),
            "$lower_bound - $upper_bound",
            eqc.X0[i],
            optimized[i],
            limit_hit,
        ]
    end

    return Jutul.PrettyTables.pretty_table(table; column_labels = header, title = "Equilibrium calibration parameters")

end
