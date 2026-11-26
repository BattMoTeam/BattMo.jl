using BattMo
using Test
using DelimitedFiles


@testset "Equilibrium calibration" begin
    data_path = joinpath(dirname(pathof(BattMo)), "..", "examples", "example_data", "Chayambuka_voltage_005C.csv")
    data = readdlm(data_path, ',', Float64)
    capacity = data[:, 1]
    voltage = data[:, 2]
    order = sortperm(capacity)
    # Downsample the measured curve for a coarse-grid machinery test.
    capacity = capacity[order][1:16:end]
    voltage = voltage[order][1:16:end]

    cell_parameters = load_cell_parameters(; from_default_set = "chayambuka_2022")
    current = 0.05 * cell_parameters["Cell"]["NominalCapacity"]
    time = (capacity .- first(capacity)) .* 3.6 ./ current
    calibration = EquilibriumCalibration(time, voltage, current, cell_parameters)
    X0 = copy(calibration.X0)

    @test_throws ArgumentError EquilibriumCalibration(time, voltage, 0.0, cell_parameters)

    initial_voltage = [equilibrium_voltage(calibration, t, calibration.X0) for t in time]
    initial_rmse = BattMo.rmse(time, voltage, time, initial_voltage)
    x_calibrated = solve(calibration; max_it = 2, print = 0)
    calibrated_voltage = [equilibrium_voltage(calibration, t, x_calibrated) for t in time]
    calibrated_rmse = BattMo.rmse(time, voltage, time, calibrated_voltage)

    @test !isempty(calibration.history)
    @test hasproperty(first(calibration.history), :ls_info)
    @test length(calibration.X0) == 4
    @test calibration.X0 == X0
    @test length(calibration.bounds.lower) == 4
    @test length(calibration.bounds.upper) == 4
    @test calibration.Xopt == x_calibrated
    @test all(isfinite, x_calibrated)
    @test calibrated_rmse <= initial_rmse

    exported = export_calibration_parameters(calibration, x_calibrated)
    for (index, path) in enumerate(BattMo.EQUILIBRIUM_CALIBRATION_PARAMETERS)
        @test BattMo.get_nested_json_value(exported, path) ≈ x_calibrated[index] atol = 0.0 rtol = 1.0e-12
    end
    @test_throws ArgumentError export_calibration_parameters(calibration, x_calibrated[1:3])

    charge_calibration = EquilibriumCalibration(time, voltage, -current, cell_parameters)
    discharge_theta = BattMo.equilibrium_stoichiometries(calibration, time[2], calibration.X0)
    charge_theta = BattMo.equilibrium_stoichiometries(charge_calibration, time[2], charge_calibration.X0)

    @test discharge_theta.negative < calibration.X0[1]
    @test discharge_theta.positive > calibration.X0[3]
    @test charge_theta.negative > charge_calibration.X0[1]
    @test charge_theta.positive < charge_calibration.X0[3]

    BattMo.print_calibration_overview(calibration)
end

@testset "Equilibrium calibration of a time series" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chayambuka_2022")
    current = 0.05 * cell_parameters["Cell"]["NominalCapacity"]
    time = collect(range(0.0, 10.0 * 3600.0; length = 101))

    # Without hysteresis, a constant-current series gives the voltage of the single-curve form.
    single = EquilibriumCalibration(time, zeros(length(time)), current, cell_parameters)
    series = EquilibriumCalibration(time, zeros(length(time)), fill(current, length(time)), cell_parameters)
    @test series.X0 == single.X0
    @test isnan(series.current)
    @test equilibrium_states(series, single.X0).voltage ≈ [equilibrium_voltage(single, t, single.X0) for t in time] atol = 0.0 rtol = 1.0e-12
    @test_throws ArgumentError equilibrium_voltage(series, time[2], series.X0)
    # A series that starts with a charge starts at the SOC 0 stoichiometries.
    reversed = EquilibriumCalibration(time, zeros(length(time)), fill(-current, length(time)), cell_parameters)
    @test reversed.X0[1] ≈ cell_parameters["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC0"]
    @test reversed.X0[3] ≈ cell_parameters["PositiveElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC0"]

    # OCP branches 10 mV either side of each OCP, as tables of the stoichiometry.
    hysteresis_parameters = deepcopy(cell_parameters)
    grid = collect(range(0.0, 1.0; length = 201))
    for electrode in ("NegativeElectrode", "PositiveElectrode")
        ocp = BattMo.setup_equilibrium_ocp(cell_parameters, electrode)
        am = hysteresis_parameters[electrode]["ActiveMaterial"]
        u = [BattMo.evaluate_equilibrium_ocp(ocp, theta, am["MaximumConcentration"], 298.15) for theta in grid]
        am["OpenCircuitPotentialLithiation"] = Dict("x" => grid, "y" => u .- 0.01)
        am["OpenCircuitPotentialDelithiation"] = Dict("x" => grid, "y" => u .+ 0.01)
        am["HysteresisDecayRateLithiation"] = 50.0
        am["HysteresisDecayRateDelithiation"] = 50.0
    end

    # A discharge of 40 % of the smaller electrode capacity, a rest of 1 h, and a charge back.
    capacities = [
        series.active_volumes[key] * hysteresis_parameters[electrode]["ActiveMaterial"]["MaximumConcentration"] *
            hysteresis_parameters[electrode]["ActiveMaterial"]["NumberOfElectronsTransfered"] * BattMo.FARADAY_CONSTANT
            for (key, electrode) in ((:negative, "NegativeElectrode"), (:positive, "PositiveElectrode"))
    ]
    discharge_time = 0.4 * minimum(capacities) / current
    t = collect(0.0:60.0:(2 * discharge_time + 3600.0))
    currents = [s < discharge_time ? current : s < discharge_time + 3600.0 ? 0.0 : -current for s in t]
    data = EquilibriumCalibration(
        t, zeros(length(t)), currents, hysteresis_parameters;
        initial_hysteresis = (negative = -1.0, positive = 1.0), fit_resistance = true,
    )
    @test !isnothing(data.hysteresis.negative) && !isnothing(data.hysteresis.positive)
    x_true = [0.85, 1.05 * data.X0[2], 0.35, 0.95 * data.X0[4], 0.005 / current]
    truth = equilibrium_states(data, x_true)
    data.v .= truth.voltage
    # At an exact fit, the objective and its gradient vanish.
    objective, gradient = BattMo.equilibrium_calibration_objective_and_gradient(data, x_true)
    @test objective == 0.0
    @test all(iszero, gradient)
    # A constant-current curve does not take the OCP hysteresis of the cell parameters.
    @test_logs (:warn, r"hysteresis") EquilibriumCalibration(time, zeros(length(time)), current, hysteresis_parameters)

    # The hysteresis state moves towards the branch of the current direction and stays in [-1, 1].
    end_of_discharge = findlast(>(0), currents)
    @test all(h -> -1 <= h <= 1, [truth.negative.h; truth.positive.h])
    @test truth.negative.h[end_of_discharge] > 0.99
    @test truth.positive.h[end_of_discharge] < -0.99
    @test truth.negative.h[end] < -0.99
    @test truth.positive.h[end] > 0.99
    rest = findall(iszero, currents)
    @test all(==(truth.negative.h[first(rest)]), truth.negative.h[rest])

    # From a perturbed start, the fit recovers the parameters of the synthetic data.
    data.X0 .= [0.8, 0.98 * x_true[2], 0.4, 1.02 * x_true[4], 0.0]
    x = solve(data; max_it = 200, grad_tol = 1.0e-12, obj_change_tol = 1.0e-16, print = 0)
    @test x[1:4] ≈ x_true[1:4] rtol = 1.0e-5
    @test x[5] ≈ x_true[5] rtol = 1.0e-3

    exported = export_calibration_parameters(data, x_true)
    full = BattMo.equilibrium_stoichiometries_at_charge(data, minimum(data.charge), x_true)
    empty = BattMo.equilibrium_stoichiometries_at_charge(data, maximum(data.charge), x_true)
    @test exported["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"] ≈ full.negative
    @test exported["PositiveElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC0"] ≈ empty.positive
    @test exported["PositiveElectrode"]["ActiveMaterial"]["MaximumConcentration"] == x_true[4]
    from_first = export_calibration_parameters(data, x_true; soc100_sample = 1, soc0_sample = end_of_discharge)
    @test from_first["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"] == x_true[1]
    @test from_first["PositiveElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC0"] ≈ truth.positive.theta[end_of_discharge]
    @test_throws ArgumentError export_calibration_parameters(data, x_true[1:4])
    BattMo.print_calibration_overview(data)
end
