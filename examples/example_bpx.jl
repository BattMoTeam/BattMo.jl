# # Simulating a BPX parameter set and comparing with its validation data
#
# [BPX](https://bpxstandard.com) (Battery Parameter eXchange) is an open standard for
# physics-based battery parameter sets. Besides the parameters and the operating
# conditions of the cell, a BPX file can contain validation data: measured or simulated
# curves that the parameter set is expected to reproduce.
#
# In this example we
# 1. load the BPX parameterisation of an NMC111|graphite 12.5 Ah pouch cell,
# 2. simulate a discharge within the BPX operating conditions,
# 3. simulate the experiments of the `Validation` section and compare them with the data, and
# 4. write the parameter set back to a BPX file.
#
# See [BPX parameter sets](@ref) for a description of the conversion.

using BattMo, GLMakie

# ## Load the cell parameters
#
# `load_cell_parameters` converts the BPX parameters to BattMo cell parameters. The
# conversion is summarised in one warning, with everything that differs from the BPX
# input or needs attention, and one info message with the details. For this file, the
# warning reports that the OCPs give 4.2018 V at the stoichiometry limits, slightly above
# the upper cut-off voltage of 4.2 V, and that BattMo does not use the lumped thermal model
# of BPX, which does not matter for the isothermal simulations below.

bpx_file_path = joinpath(dirname(pathof(BattMo)), "..", "test", "data", "jsonfiles", "nmc_pouch_cell_BPX.json")

cell_parameters = load_cell_parameters(; from_bpx_file_path = bpx_file_path)

# The converted parameters can be inspected and modified in the usual way. The BPX cell
# consists of 34 electrode pairs of 168 cm², which BattMo represents as 34 single coated
# electrode layers.

cell = cell_parameters["Cell"]
println("Electrode area of one layer: ", cell["ElectrodeGeometricSurfaceArea"], " m²")
println("Number of layers:            ", cell["NumberOfLayersInParallel"])
println("Total electrode area:        ", compute_total_electrode_area(cell_parameters), " m²")

# ## Simulate a discharge within the BPX operating conditions
#
# The operating conditions of the BPX file (voltage cut-offs, initial state of charge
# and temperatures) belong to the cycling protocol in BattMo. `load_cycling_protocol`
# reads them from the BPX file. BPX does not define a cycling experiment, so a constant
# current discharge with `DRate = 1` is set up, which the warning points out.

cycling_protocol = load_cycling_protocol(; from_bpx_file_path = bpx_file_path)

# The `DRate` is relative to the theoretical capacity that BattMo computes from the
# electrode parameters, not to the nominal capacity of the BPX file. For a discharge at
# the nominal 1C current of 12.5 A, we set the rate relative to the theoretical capacity.

capacity = compute_cell_theoretical_capacity(cell_parameters)
println("Nominal capacity:     ", cell["NominalCapacity"], " Ah")
println("Theoretical capacity: ", round(capacity, digits = 2), " Ah")

cycling_protocol["DRate"] = cell["NominalCapacity"] / capacity

model = LithiumIonBattery()
output = solve(Simulation(model, cell_parameters, cycling_protocol); info_level = -1)

plot_dashboard(output; plot_type = "simple")

# ## Simulate the validation experiments
#
# The `Validation` section of this file contains a C/20 and a 1C discharge. With the
# `experiment` option, `load_full_simulation_input` sets up a complete simulation input
# in which the current of the chosen experiment is prescribed with the `InputCurrentSeries`
# protocol. The current is converted from the BPX sign convention (positive for
# charging) to the BattMo one (positive for discharging); the import checks that the
# sign of the current matches the voltage curve and the name of the experiment.
#
# For each experiment we run the simulation and compute the root mean square error of
# the voltage. The simulation uses the times of the data as time steps, so the simulated
# and measured voltages are compared at the same times. The first output is at the end
# of the first time step, so the voltage at time zero is not compared.

experiments = ["C/20 discharge", "1C discharge"]
validation = BattMo.JSON.parsefile(bpx_file_path)["Validation"]

results = map(experiments) do experiment
    simulation_input = load_full_simulation_input(;
        from_bpx_file_path = bpx_file_path,
        bpx_options = (experiment = experiment,),
    )
    output = run_simulation(simulation_input; info_level = -1)

    time = output.time_series["Time"]
    voltage = output.time_series["Voltage"]

    data = validation[experiment]
    time_data = Float64.(data["Time [s]"])
    voltage_data = Float64.(data["Voltage [V]"])

    ## Compare at the times of the data within the simulated time span
    compared = [findfirst(t -> isapprox(t, t_data), time) for t_data in time_data]
    measured = .!isnothing.(compared)
    error = voltage[compared[measured]] .- voltage_data[measured]
    rmse = sqrt(sum(error .^ 2) / length(error))
    println(rpad(experiment, 16), "RMSE ", round(1000 * rmse, digits = 1), " mV")

    (; experiment, time, voltage, time_data, voltage_data, rmse)
end

# ## Plot the comparison

fig = Figure(size = (1000, 400))
for (i, result) in enumerate(results)
    ax = Axis(
        fig[1, i],
        title = "$(result.experiment) (RMSE $(round(1000 * result.rmse, digits = 1)) mV)",
        xlabel = "Time / h",
        ylabel = "Voltage / V",
    )
    lines!(ax, result.time ./ 3600, result.voltage, label = "BattMo", linewidth = 2)
    scatter!(ax, result.time_data ./ 3600, result.voltage_data, label = "BPX validation data", color = :black, markersize = 8)
    axislegend(ax, position = :lb)
end
fig

# The simulations reproduce both validation curves with an RMSE below 20 mV.

# ## Export to BPX
#
# A BattMo parameter set can be written to a BPX file with `write_bpx`. The voltage
# cut-offs and the initial state are taken from the cycling protocol. The export is
# validated against the BPX schema and reports parameters that BPX cannot represent.

exported_file_path = joinpath(mktempdir(), "nmc_pouch_cell_BPX.json")
write_bpx(exported_file_path, cell_parameters; cycling_protocol)

# The exported file can be loaded again and gives the same parameters.

reloaded = load_cell_parameters(; from_bpx_file_path = exported_file_path)
println("Electrode area after the round trip: ", reloaded["Cell"]["ElectrodeGeometricSurfaceArea"], " m²")
