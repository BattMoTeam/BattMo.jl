using BattMo
using Jutul: si_unit

###
# Example: Sequence control with CC, Rest, and CCCV steps
#
# This example demonstrates the Sequence cycling protocol. The sequence below
# starts with a short constant-current discharge, rests, and then charges using
# a CCCV step. Ramp-up is configured globally in the simulation settings and is
# applied to the current-controlled parts of the CC and CCCV steps.
###

model_settings = load_model_settings(; from_default_set = "p2d")
#delete!(model_settings, "Rampup")
model = LithiumIonBattery(; model_settings = model_settings)
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")

simulation_settings["TimeStepDuration"] = 500.0
# simulation_settings["RampUpTime"] = 10.0
# simulation_settings["RampUpSteps"] = 5
# delete!(simulation_settings, "RampUpTime")
# delete!(simulation_settings, "RampUpSteps")

cc = Dict(
    "Protocol" => "CC",
    "InitialControl" => "discharging",
    "DRate" => 1.0,
    "TotalNumberOfCycles" => 0,
    "LowerVoltageLimit" => 3.0,
    "UpperVoltageLimit" => 4.2,
)
rest = Dict(
    "Protocol" => "Rest",
    "Duration" => 1.0*si_unit("hour")
)
cccv = Dict(
    "Protocol" => "CCCV",
    "InitialControl" => "charging",
    "CRate" => 1.5,
    "DRate" => 1.0,
    "TotalNumberOfCycles" => 1,
    "LowerVoltageLimit" => 3.0,
    "UpperVoltageLimit" => 3.8,
    "CurrentChangeLimit" => 1.0e-4,
    "VoltageChangeLimit" => 1.0e-4,
)

cycling_protocol = CyclingProtocol(
    Dict(
        "Protocol" => "Sequence",
        "InitialStateOfCharge" => 1.0,
        "Steps" => [cc, rest, cccv]
    )
)

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
output = solve(sim; info_level = -1)

time = output.time_series["Time"]
current = output.time_series["Current"]
voltage = output.time_series["Voltage"]

println("Completed sequence-control example with $(length(cycling_protocol["Steps"])) steps.")
println("Ramp-up time:           $(simulation_settings["RampUpTime"]) s")
println("Ramp-up steps:          $(simulation_settings["RampUpSteps"])")
println("Final time:             $(round(time[end]; digits = 2)) s")
println("Current range:          $(round(minimum(current); digits = 4)) A to $(round(maximum(current); digits = 4)) A")
println("Voltage range:          $(round(minimum(voltage); digits = 4)) V to $(round(maximum(voltage); digits = 4)) V")

doplot = true
if doplot
    using GLMakie
    plot_dashboard(output; plot_type = "simple")
end
