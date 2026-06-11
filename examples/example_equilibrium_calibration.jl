# # Equilibrium calibration against a low-rate discharge curve
#
# This example calibrates electrode stoichiometries and maximum concentrations
# against the Chayambuka 0.05C discharge data. At this low rate, the measured
# cell voltage is treated as an equilibrium voltage.

using BattMo
using CSV
using DataFrames
using GLMakie
import Jutul: si_unit

# ## Load and preprocess the experimental data
#
# The source curve was digitized as capacity and voltage and contains points
# that are not ordered. We sort the data and average it in small capacity bins.
battmo_base = normpath(joinpath(dirname(pathof(BattMo)), ".."))
data_path = joinpath(battmo_base, "examples", "example_data", "Chayambuka_voltage_005C.csv")
data = CSV.read(data_path, DataFrame; header = false)
capacity_raw = Float64.(data[:, 1])
voltage_raw = Float64.(data[:, 2])

order = sortperm(capacity_raw)
capacity_raw = capacity_raw[order]
voltage_raw = voltage_raw[order]

# bin_size = 4
# bins = Iterators.partition(eachindex(capacity_raw), bin_size)
# capacity = [sum(capacity_raw[ix]) / length(ix) for ix in bins]
# voltage = [sum(voltage_raw[ix]) / length(ix) for ix in Iterators.partition(eachindex(voltage_raw), bin_size)]

capacity = capacity_raw
voltage = voltage_raw

# Convert capacity in mAh to time using the 0.05C discharge current.
cell_parameters = load_cell_parameters(; from_default_set = "chayambuka_2022")
current = 0.05 * cell_parameters["Cell"]["NominalCapacity"]
time = (capacity .- first(capacity)) .* si_unit("milli") * si_unit("hour") ./ current

# ## Set up and solve the equilibrium calibration
calibration = EquilibriumCalibration(
    time,
    voltage,
    current,
    cell_parameters;
    np_ratio = 1.1,
    lower_cutoff_voltage = minimum(voltage),
)
print_calibration_overview(calibration; use_acronyms = true)
calibrated_parameters = solve(calibration; max_it = 100)
print_calibration_overview(calibration; use_acronyms = true)

# ## Compare the fitted equilibrium voltage with the measurements
x0, = BattMo.equilibrium_calibration_vector(calibration)
x_calibrated = equilibrium_calibration_vector(calibration, calibrated_parameters)
initial_voltage = [equilibrium_voltage(calibration, t, x0) for t in time]
calibrated_voltage = [equilibrium_voltage(calibration, t, x_calibrated) for t in time]
initial_rmse = BattMo.rmse(time, voltage, initial_voltage)
calibrated_rmse = BattMo.rmse(time, voltage, calibrated_voltage)
println("Initial RMSE: $(initial_rmse / si_unit("milli")) mV")
println("Calibrated RMSE: $(calibrated_rmse / si_unit("milli")) mV")

fig = Figure()
ax = Axis(
    fig[1, 1],
    xlabel = "Capacity / mAh",
    ylabel = "Voltage / V",
    title = "Calibrated RMSE: $(round(calibrated_rmse / si_unit("milli"), digits = 4)) mV",
)
lines!(ax, capacity, voltage, label = "Chayambuka 0.05C", color = :black, linestyle = :dash)
lines!(ax, capacity, initial_voltage, label = "Initial equilibrium curve")
lines!(ax, capacity, calibrated_voltage, label = "Calibrated equilibrium curve", color = :firebrick)
axislegend(ax)
display(GLMakie.Screen(), fig)


fig = Figure()
ax = Axis(
    fig[1, 1],
    xlabel = "Time  /  hour",
    ylabel = "Voltage / V",
    title = "Calibrated RMSE: $(round(calibrated_rmse / si_unit("milli"), digits = 4)) mV",
)
lines!(ax, time / si_unit("hour"), voltage, label = "Chayambuka 0.05C", color = :black, linestyle = :dash)
lines!(ax, time / si_unit("hour"), initial_voltage, label = "Initial equilibrium curve")
lines!(ax, time / si_unit("hour"), calibrated_voltage, label = "Calibrated equilibrium curve", color = :firebrick)
axislegend(ax)
display(GLMakie.Screen(), fig)
