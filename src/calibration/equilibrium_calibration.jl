export EquilibriumCalibration, equilibrium_voltage, export_calibration_parameters
using ForwardDiff

const EQUILIBRIUM_CALIBRATION_PARAMETERS = (
    ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"],
    ["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"],
    ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"],
    ["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"],
)

const EQUILIBRIUM_CALIBRATION_ACRONYMS = Dict(
    "ActiveMaterial" => "am",
    "Binder" => "bd",
    "ConductiveAdditive" => "ca",
    "CurrentCollector" => "cc",
    "Coating" => "co",
    "Control" => "ctrl",
    "Electrolyte" => "elyte",
    "Geometry" => "geom",
    "Interface" => "itf",
    "Interphase" => "itp",
    "NegativeElectrode" => "ne",
    "OpenCircuitPotential" => "ocp",
    "PositiveElectrode" => "pe",
    "SolidDiffusion" => "sd",
    "Separator" => "sep",
    "TimeStepping" => "ts",
)

"""
    EquilibriumCalibration(t, v, current, cell_parameters; kwargs...)

Set up equilibrium calibration against a low-rate discharge curve.

The calibrated Julia parameters are `StoichiometricCoefficientAtSOC100` and
`MaximumConcentration` for each electrode. `MaximumConcentration` is used as
the Julia representation of the MATLAB setup's total active-material amount,
with electrode geometry and volume fractions held fixed.

The initial calibration vector is stored in `calibration.X0` with ordering
`[theta100_ne, cmax_ne, theta100_pe, cmax_pe]`.
"""
mutable struct EquilibriumCalibration <: AbstractCalibration
    "Time values for the low-rate discharge data [s]."
    t::Vector{Float64}
    "Measured cell voltage [V]."
    v::Vector{Float64}
    "Applied discharge current [A]."
    current::Float64
    "Cell parameters used as the calibration starting point."
    cell_parameters::CellParameters
    "Temperature used to evaluate the electrode OCP functions [K]."
    temperature::Float64
    "Voltage defining the end of discharge [V]."
    lower_cutoff_voltage::Float64
    "Target negative-to-positive electrode capacity ratio."
    np_ratio::Float64
    "Initial values of the four calibration parameters."
    X0::Vector{Float64}
    "Lower and upper bounds for the four calibration parameters."
    bounds::NamedTuple
    "Most recently calibrated parameter vector."
    X_calibrated::Any
    "Optimization history returned by Jutul's BFGS solver."
    history::Any
    ocp_functions::NamedTuple
    active_volumes::NamedTuple
end

function EquilibriumCalibration(
        t, v, current, cell_parameters::CellParameters;
        temperature = 298.15,
        lower_cutoff_voltage = minimum(v),
        np_ratio = 1.1,
        stoichiometry_bounds = (0.0, 1.0),
        concentration_factors = (0.1, 10.0),
    )
    length(t) == length(v) || throw(ArgumentError("Time and voltage data must have equal length."))
    length(t) >= 2 || throw(ArgumentError("At least two calibration points are required."))
    current > 0 || throw(ArgumentError("Equilibrium calibration expects a positive discharge current."))
    np_ratio > 0 || throw(ArgumentError("The N/P ratio must be positive."))

    order = sortperm(t)
    t_sorted = Float64.(t[order])
    v_sorted = Float64.(v[order])
    t_sorted .-= first(t_sorted)
    all(diff(t_sorted) .> 0) || throw(ArgumentError("Time values must be unique."))

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

    ocp_functions = (
        negative = setup_equilibrium_ocp(parameters, "NegativeElectrode"),
        positive = setup_equilibrium_ocp(parameters, "PositiveElectrode"),
    )
    active_volumes = (
        negative = equilibrium_active_material_volume(parameters, "NegativeElectrode"),
        positive = equilibrium_active_material_volume(parameters, "PositiveElectrode"),
    )

    return EquilibriumCalibration(
        t_sorted,
        v_sorted,
        Float64(current),
        parameters,
        Float64(temperature),
        Float64(lower_cutoff_voltage),
        Float64(np_ratio),
        X0,
        (lower = lower, upper = upper),
        missing,
        missing,
        ocp_functions,
        active_volumes,
    )
end

function setup_equilibrium_ocp(cell_parameters, electrode)
    am = cell_parameters[electrode]["ActiveMaterial"]
    base_path = isnothing(cell_parameters.source_path) ? pwd() : dirname(cell_parameters.source_path)
    func, func_type = setup_function(base_path, am["OpenCircuitPotential"], "ActiveMaterial", "OpenCircuitPotential")
    return (func = func, type = func_type)
end

function equilibrium_active_material_volume(cell_parameters, electrode)
    electrode_parameters = cell_parameters[electrode]
    am = electrode_parameters["ActiveMaterial"]
    coating = electrode_parameters["Coating"]
    cell = cell_parameters["Cell"]
    if haskey(cell, "ElectrodeGeometricSurfaceArea")
        area = cell["ElectrodeGeometricSurfaceArea"]
    else
        throw(ArgumentError("Only 1D geometry is currently supported for equilibrium calibration."))
    end
    coating_volume = area * coating["Thickness"]
    return coating_volume * coating["EffectiveDensity"] * am["MassFraction"] / am["Density"]
end

function evaluate_equilibrium_ocp(ocp, theta, cmax, temperature)
    if ocp.type == :interpolator
        return ocp.func(theta)
    else
        return ocp.func(theta * cmax, temperature, 298.15, cmax)
    end
end

function equilibrium_stoichiometries(ec::EquilibriumCalibration, t, x)
    ne_theta100, ne_cmax, pe_theta100, pe_cmax = x
    ne_total_amount = ec.active_volumes.negative * ne_cmax
    pe_total_amount = ec.active_volumes.positive * pe_cmax
    ne_n = ec.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["NumberOfElectronsTransfered"]
    pe_n = ec.cell_parameters["PositiveElectrode"]["ActiveMaterial"]["NumberOfElectronsTransfered"]
    ne_theta = ne_theta100 - t * ec.current / (ne_n * FARADAY_CONSTANT * ne_total_amount)
    pe_theta = pe_theta100 + t * ec.current / (pe_n * FARADAY_CONSTANT * pe_total_amount)
    return (negative = ne_theta, positive = pe_theta)
end

"""
    equilibrium_voltage(ec, t, x)

Evaluate the equilibrium full-cell voltage at time `t` for calibration vector
`x = [theta100_ne, cmax_ne, theta100_pe, cmax_pe]`.
"""
function equilibrium_voltage(ec::EquilibriumCalibration, t, x)
    theta = equilibrium_stoichiometries(ec, t, x)
    ne_theta = clamp(theta.negative, zero(theta.negative), one(theta.negative))
    pe_theta = clamp(theta.positive, zero(theta.positive), one(theta.positive))
    ne_ocp = evaluate_equilibrium_ocp(ec.ocp_functions.negative, ne_theta, x[2], ec.temperature)
    pe_ocp = evaluate_equilibrium_ocp(ec.ocp_functions.positive, pe_theta, x[4], ec.temperature)
    return pe_ocp - ne_ocp
end

function equilibrium_calibration_objective(ec::EquilibriumCalibration, x)
    voltage = [equilibrium_voltage(ec, t, x) for t in ec.t]
    e = voltage .- ec.v
    return sqrt(trapz(ec.t, abs2.(e)))
end

function equilibrium_calibration_objective_and_gradient(ec::EquilibriumCalibration, x)
    objective(z) = equilibrium_calibration_objective(ec, z)
    return (objective(x), ForwardDiff.gradient(objective, x))
end

function find_equilibrium_cutoff_time(ec::EquilibriumCalibration, x)
    t_low = zero(eltype(x))
    t_high = max(ec.t[end], one(eltype(x)))
    voltage(t) = equilibrium_voltage(ec, t, x)
    for _ in 1:20
        voltage(t_high) <= ec.lower_cutoff_voltage && break
        t_high *= 1.5
    end
    if voltage(t_high) > ec.lower_cutoff_voltage
        return ec.t[end]
    end
    for _ in 1:60
        t_mid = (t_low + t_high) / 2
        if voltage(t_mid) > ec.lower_cutoff_voltage
            t_low = t_mid
        else
            t_high = t_mid
        end
    end
    return t_high
end

"""
    export_calibration_parameters(ec, x_calibrated)

Export the calibrated and derived equilibrium parameters as a minimal nested
dictionary. The result can overwrite the corresponding values in an existing
parameter dictionary with
`merge_dict(parameters, exported; type = "overwrite")`.
"""
function export_calibration_parameters(ec::EquilibriumCalibration, x_calibrated)
    length(x_calibrated) == length(EQUILIBRIUM_CALIBRATION_PARAMETERS) ||
        throw(ArgumentError("Expected four calibrated equilibrium parameters."))

    cutoff_time = find_equilibrium_cutoff_time(ec, x_calibrated)
    theta = equilibrium_stoichiometries(ec, cutoff_time, x_calibrated)
    pe_theta0 = clamp(theta.positive, 0.0, 1.0)
    ne_total_amount = ec.active_volumes.negative * x_calibrated[2]
    pe_total_amount = ec.active_volumes.positive * x_calibrated[4]
    ne_n = ec.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["NumberOfElectronsTransfered"]
    pe_n = ec.cell_parameters["PositiveElectrode"]["ActiveMaterial"]["NumberOfElectronsTransfered"]
    amount_ratio = pe_n * pe_total_amount / (ne_n * ne_total_amount)
    ne_theta0 = x_calibrated[1] - ec.np_ratio * amount_ratio * (pe_theta0 - x_calibrated[3])
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
    solve(ec::EquilibriumCalibration; kwargs...)

Calibrate the equilibrium discharge curve with `Jutul.LBFGS.box_bfgs` and
return the calibrated parameter vector.
"""
function solve(
        ec::EquilibriumCalibration;
        grad_tol = 1.0e-6,
        obj_change_tol = 1.0e-8,
        print = 1,
        kwarg...,
    )
    objective(x) = equilibrium_calibration_objective_and_gradient(ec, x)
    jutul_message("Calibration", "Starting equilibrium calibration.", color = :green)
    value, x, history = Jutul.LBFGS.box_bfgs(
        copy(ec.X0), objective, ec.bounds.lower, ec.bounds.upper;
        maximize = false,
        grad_tol = grad_tol,
        obj_change_tol = obj_change_tol,
        print = print,
        kwarg...,
    )
    ec.X_calibrated = copy(x)
    ec.history = history
    jutul_message("Calibration", "Equilibrium calibration finished with RMSE $value V.", color = :green)
    return x
end

function print_calibration_overview(ec::EquilibriumCalibration; use_acronyms = false)
    optimized = if ismissing(ec.X_calibrated)
        fill(missing, length(ec.X0))
    else
        ec.X_calibrated
    end
    header = ["Parameter", "Initial value", "Bounds", "Optimized value"]
    table = Matrix{Any}(undef, length(ec.X0), length(header))
    for i in eachindex(ec.X0)
        parameter = EQUILIBRIUM_CALIBRATION_PARAMETERS[i]
        if use_acronyms
            parameter = [get(EQUILIBRIUM_CALIBRATION_ACRONYMS, part, part) for part in parameter]
        end
        table[i, :] = [
            join(parameter, "."),
            ec.X0[i],
            "$(ec.bounds.lower[i]) - $(ec.bounds.upper[i])",
            optimized[i],
        ]
    end

    try
        return Jutul.PrettyTables.pretty_table(table; header = header, title = "Equilibrium calibration parameters")
    catch
        return Jutul.PrettyTables.pretty_table(table; column_labels = header, title = "Equilibrium calibration parameters")
    end

end
