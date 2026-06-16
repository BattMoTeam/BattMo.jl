using BattMo
using Jutul: expand_to_ministeps, si_unit

###
# Example: Sequence control with CC, Rest, and CCCV steps
#
# This example demonstrates the Sequence cycling protocol. The sequence below
# starts with a short constant-current discharge, rests, and then charges using
# a CCCV step. Ramp-up is configured globally in the simulation settings and is
# applied to the current-controlled parts of the CC and CCCV steps.
###

model_settings = load_model_settings(; from_default_set = "p2d")

# Optionally disable ramp-up to see the effect of the initial ramp-up steps on the current and voltage profiles.
# delete!(model_settings, "RampUp")

model = LithiumIonBattery(; model_settings = model_settings)
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")
simulation_settings["TimeStepDuration"] = 360.0

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
    "Duration" => 1.0 * si_unit("hour")
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
output = solve(sim; info_level = -1, output_substates = true)

stored_states = output.jutul_output.states
raw_states, dt, = expand_to_ministeps(stored_states, output.jutul_output.reports[eachindex(stored_states)])
time = cumsum(dt)
current = [only(state[:Control][:Current]) for state in raw_states]
voltage = [only(state[:Control][:ElectricPotential]) for state in raw_states]

doplot = true
if doplot
    using GLMakie

    sequence_step_index = [state[:Control][:Controller].step_index for state in raw_states]
    sequence_time = [state[:Control][:Controller].time for state in raw_states]
    step_boundary_times = Float64[]

    for i in 2:length(sequence_step_index)
        if sequence_step_index[i] != sequence_step_index[i - 1] && sequence_step_index[i] <= length(cycling_protocol["Steps"])
            push!(step_boundary_times, sequence_time[i])
        end
    end

    hour = si_unit("hour")
    time_hours = time ./ hour
    dt_minutes = dt ./ si_unit("minute")
    timestep_time_hours = Float64[]
    timestep_values = Float64[]
    for i in eachindex(dt)
        push!(timestep_time_hours, (time[i] - dt[i]) / hour)
        push!(timestep_time_hours, time_hours[i])
        push!(timestep_values, dt_minutes[i])
        push!(timestep_values, dt_minutes[i])
    end
    boundary_hours = step_boundary_times ./ hour

    fig = Figure(size = (900, 760))
    ax_voltage = Axis(fig[1, 1], xlabel = "Time / h", ylabel = "Voltage / V")
    ax_current = Axis(fig[2, 1], xlabel = "Time / h", ylabel = "Current / A")
    ax_timestep = Axis(fig[3, 1], xlabel = "Time / h", ylabel = "Timestep / min")
    linkxaxes!(ax_voltage, ax_current, ax_timestep)

    scatterlines!(ax_voltage, time_hours, voltage, label = "Voltage", linewidth = 4.0, markersize = 10, markercolor = :black)
    scatterlines!(ax_current, time_hours, current, label = "Current", linewidth = 4.0, markersize = 10, markercolor = :black)
    lines!(ax_timestep, timestep_time_hours, timestep_values, label = "Timestep", linewidth = 3.0)

    if !isempty(boundary_hours)
        vlines!(ax_voltage, boundary_hours, color = :black, linestyle = :dash, linewidth = 2)
        vlines!(ax_current, boundary_hours, color = :black, linestyle = :dash, linewidth = 2)
        vlines!(ax_timestep, boundary_hours, color = :black, linestyle = :dash, linewidth = 2)
    end

    screen = GLMakie.Screen()
    GLMakie.display(screen, fig)
end
