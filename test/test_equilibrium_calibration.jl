using BattMo
using Test
using CSV


@testset "Equilibrium calibration" begin
    data_path = joinpath(dirname(pathof(BattMo)), "..", "examples", "example_data", "Chayambuka_voltage_005C.csv")
    data = CSV.File(data_path; header = false)
    capacity = [Float64(row.Column1) for row in data]
    voltage = [Float64(row.Column2) for row in data]
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
    @test length(calibration.X0) == 4
    @test calibration.X0 == X0
    @test length(calibration.bounds.lower) == 4
    @test length(calibration.bounds.upper) == 4
    @test calibration.Xopt == x_calibrated
    @test all(isfinite, x_calibrated)
    @test calibrated_rmse <= initial_rmse

    charge_calibration = EquilibriumCalibration(time, voltage, -current, cell_parameters)
    discharge_theta = BattMo.equilibrium_stoichiometries(calibration, time[2], calibration.X0)
    charge_theta = BattMo.equilibrium_stoichiometries(charge_calibration, time[2], charge_calibration.X0)

    @test discharge_theta.negative < calibration.X0[1]
    @test discharge_theta.positive > calibration.X0[3]
    @test charge_theta.negative > charge_calibration.X0[1]
    @test charge_theta.positive < charge_calibration.X0[3]
end
