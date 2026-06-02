using BattMo

# Compute the small-signal impedance of the Chen 2020 P2D cell at several
# states of charge. Frequencies are in Hz and impedance is returned in ohms.
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
frequencies = 10.0 .^ range(-4, 2; length = 60)
socs = range(0.1, 1.0; length = 5)

impedances = Dict(
    soc => compute_impedance(impedance_simulation(cell_parameters; soc), frequencies)
    for soc in socs
)

doplot = true
if doplot
    using GLMakie

    fig = Figure()
    ax = Axis(
        fig[1, 1];
        title = "Impedance",
        xlabel = "real(Z) / ohm",
        ylabel = "-imag(Z) / ohm",
        aspect = DataAspect(),
    )
    for soc in socs
        impedance = impedances[soc]
        lines!(ax, real.(impedance), -imag.(impedance); label = "SOC=$(soc)")
    end
    axislegend(ax)
    display(fig)
end
