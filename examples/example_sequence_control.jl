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

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
base_simulation_settings = load_simulation_settings(; from_default_set = "p2d")
base_simulation_settings["TimeStepDuration"] = 360.0

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

function run_sequence_case(use_rampup::Bool)
    model_settings = load_model_settings(; from_default_set = "p2d")
    simulation_settings = deepcopy(base_simulation_settings)

    if use_rampup
        label = "W rampup"
    else
        delete!(model_settings, "RampUp")
        label = "WO rampup"
    end

    model = LithiumIonBattery(; model_settings = model_settings)
    sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
    output = solve(sim; info_level = -1, output_ministeps = false)
    ministep_output = solve(sim; info_level = -1, output_ministeps = true)

    return (
        label = label,
        output = output,
        ministep_output = ministep_output,
    )
end

results = [run_sequence_case(use_rampup) for use_rampup in (true, false)]

doplot = true
if doplot

    using GLMakie

    fig = Figure(size = (900, 760))
    hour = si_unit("hour")
    min = si_unit("minute")

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

    report_colors = [:dodgerblue3, :darkorange2]
    ministep_colors = [:seagreen4, :purple3]

    ax_voltage = Axis(
        fig[1, 1],
        title = "Voltage: report output and ministep output",
        xlabel = "Time / h",
        ylabel = "Voltage / V",
    )
    ax_current = Axis(
        fig[2, 1],
        title = "Current: report output and ministep output",
        xlabel = "Time / h",
        ylabel = "Current / A",
    )
    ax_timestep = Axis(
        fig[3, 1],
        title = "Accepted solver timestep",
        xlabel = "Time / h",
        ylabel = "Accepted solver timestep / min",
    )
    linkxaxes!(ax_voltage, ax_current, ax_timestep)

    for (case_index, result) in enumerate(results)
        label = result.label
        output = result.output
        ministep_output = result.ministep_output
        report_color = report_colors[case_index]
        ministep_color = ministep_colors[case_index]

        scatter!(
            ax_voltage,
            output.time_series["Time"] ./ hour,
            output.time_series["Voltage"],
            label = "$label: output",
            color = report_color,
            markersize = 8,
        )
        scatter!(
            ax_current,
            output.time_series["Time"] ./ hour,
            output.time_series["Current"],
            label = "$label: output",
            color = report_color,
            markersize = 8,
        )
        output_timestep_time, output_timestep_vals = t_pw_const(output.time_series["Time"])
        lines!(
            ax_timestep,
            output_timestep_time ./ hour,
            output_timestep_vals ./ min,
            label = "$label: output",
            color = report_color,
            linewidth = 3.0,
        )

        # output_ministeps=true shows accepted solver ministeps, including adaptive
        # timestep cuts from convergence and control transitions, not only ramp-up steps.
        time = ministep_output.time_series["Time"]
        scatterlines!(
            ax_voltage,
            time ./ hour,
            ministep_output.time_series["Voltage"],
            label = "$label: ministeps",
            color = ministep_color,
            linewidth = 3.0,
            markersize = 8,
            marker = :circle,
        )
        scatterlines!(
            ax_current,
            time ./ hour,
            ministep_output.time_series["Current"],
            label = "$label: ministeps",
            color = ministep_color,
            linewidth = 3.0,
            markersize = 8,
            marker = :circle,
        )
        ministep_timestep_time, ministep_timestep_vals = t_pw_const(time)
        lines!(
            ax_timestep,
            ministep_timestep_time ./ hour,
            ministep_timestep_vals ./ min,
            label = "$label: ministeps",
            color = ministep_color,
            linewidth = 3.0,
        )
    end

    axislegend(ax_voltage, position = :rb)
    axislegend(ax_current, position = :rb)
    axislegend(ax_timestep, position = :rt)

    fig_cases = Figure(size = (1100, 760))

    function plot_voltage_current!(position, output, title)
        time = output.time_series["Time"] ./ hour
        voltage = output.time_series["Voltage"]
        current = output.time_series["Current"]

        ax_voltage = Axis(
            position,
            title = title,
            xlabel = "Time / h",
            ylabel = "Voltage / V",
        )
        ax_current = Axis(
            position,
            yaxisposition = :right,
            ylabel = "Current / A",
        )
        hidespines!(ax_current, :l, :t, :b)
        hidexdecorations!(ax_current, grid = false)
        linkxaxes!(ax_voltage, ax_current)

        voltage_line = lines!(
            ax_voltage,
            time,
            voltage,
            color = :dodgerblue3,
            linewidth = 3.0,
        )
        current_line = lines!(
            ax_current,
            time,
            current,
            color = :firebrick3,
            linewidth = 3.0,
        )
        return Legend(
            position,
            [voltage_line, current_line],
            ["Voltage", "Current"],
            halign = :right,
            valign = :top,
            tellwidth = false,
            tellheight = false,
        )
    end

    plot_voltage_current!(fig_cases[1, 1], results[1].output, "W rampup: output")
    plot_voltage_current!(fig_cases[1, 2], results[1].ministep_output, "W rampup: ministeps")
    plot_voltage_current!(fig_cases[2, 1], results[2].output, "WO rampup: output")
    plot_voltage_current!(fig_cases[2, 2], results[2].ministep_output, "WO rampup: ministeps")

    screen1 = GLMakie.Screen()
    screen2 = GLMakie.Screen()
    GLMakie.display(screen1, fig)
    GLMakie.display(screen2, fig_cases)

end
