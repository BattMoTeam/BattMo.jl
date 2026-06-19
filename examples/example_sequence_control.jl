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
delete!(model_settings, "RampUp")

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
states = output.states

stored_states = output.jutul_output.states
raw_states, _, _ = expand_to_ministeps(stored_states, output.jutul_output.reports[eachindex(stored_states)])

doplot = true
if doplot

    using GLMakie

    fig = Figure(size = (900, 760))
    ax_voltage = Axis(fig[1, 1], xlabel = "Time / h", ylabel = "Voltage / V")
    ax_current = Axis(fig[2, 1], xlabel = "Time / h", ylabel = "Current / A")
    ax_timestep = Axis(fig[3, 1], xlabel = "Time / h", ylabel = "Timestep / min")
    linkxaxes!(ax_voltage, ax_current, ax_timestep)

    hour = si_unit("hour")
    min = si_unit("minute")

    function t_mid(times)
        return times[2:end] .- diff(times) ./ 2
    end

    function t_pw_const(times)
        timestep_time = Float64[]
        timestep_vals = Float64[]
        dt = diff(times)
        for i in 2:length(times)
            push!(timestep_time, times[i - 1])
            push!(timestep_time, times[i])
            push!(timestep_vals, dt[i - 1])
            push!(timestep_vals, dt[i - 1])
        end
        return timestep_time, timestep_vals
    end

    # Plot standard output
    scatterlines!(ax_voltage, output.time_series["Time"] ./ si_unit("hour"), output.time_series["Voltage"], label = "output.time_series", linewidth = 3.0, markersize = 8)
    scatterlines!(ax_current, output.time_series["Time"] ./ si_unit("hour"), output.time_series["Current"], label = "output.time_series", linewidth = 3.0, markersize = 8)
    # lines!(ax_timestep, t_mid(output.time_series["Time"]) ./ si_unit("hour"), diff(output.time_series["Time"]) ./ min, label = "output.time_series", linewidth = 3.0)
    output_timestep_time, output_timestep_vals = t_pw_const(output.time_series["Time"])
    lines!(ax_timestep, output_timestep_time ./ hour, output_timestep_vals ./ min, label = "output.time_series", linewidth = 3.0)

    # Plot expanded output (raw_states)
    time = [only(state[:Control][:Controller].time) for state in raw_states]
    current = [only(state[:Control][:Current]) for state in raw_states]
    voltage = [only(state[:Control][:ElectricPotential]) for state in raw_states]
    scatterlines!(ax_voltage, time ./ hour, voltage, label = "expanded", linewidth = 3.0, markersize = 8, marker = :circle)
    scatterlines!(ax_current, time ./ hour, current, label = "expanded", linewidth = 3.0, markersize = 8, marker = :circle)
    # lines!(ax_timestep, t_mid(time) ./ hour, diff(time) ./ min, label = "expanded", linewidth = 3.0, linestyle = :dash)
    expanded_timestep_time, expanded_timestep_vals = t_pw_const(time)
    lines!(ax_timestep, expanded_timestep_time ./ hour, expanded_timestep_vals ./ min, label = "expanded", linewidth = 3.0, linestyle = :dash)

    # Plot horizontal lines at step boundaries
    sequence_step_index = [state[:Control][:Controller].step_index for state in raw_states]
    sequence_time = [state[:Control][:Controller].time for state in raw_states]
    step_boundary_times = Float64[]
    for i in 2:length(sequence_step_index)
        if sequence_step_index[i] != sequence_step_index[i - 1] && sequence_step_index[i] <= length(cycling_protocol["Steps"])
            push!(step_boundary_times, sequence_time[i])
        end
    end
    vlines!(ax_voltage, step_boundary_times ./ hour, color = :black, linestyle = :dash, linewidth = 2)
    vlines!(ax_current, step_boundary_times ./ hour, color = :black, linestyle = :dash, linewidth = 2)
    vlines!(ax_timestep, step_boundary_times ./ hour, color = :black, linestyle = :dash, linewidth = 2)

    screen = GLMakie.Screen()
    GLMakie.display(screen, fig)

end
