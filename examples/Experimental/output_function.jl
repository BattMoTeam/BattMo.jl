using BattMo

model_settings = load_model_settings(; from_default_set = "P2D")
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")

model_setup = LithiumIonBattery(; model_settings)

sim = Simulation(model_setup, cell_parameters, cycling_protocol);

output = solve(sim;)

time_series = get_output_time_series(output, ["Voltage", "Current"])
states = get_output_states(output, ["PeAmPotential", "NeAmPotential", "ElectrolytePotential", "PeAmSurfaceConcentration", "NeAmSurfaceConcentration", "ElectrolyteConcentration"])
metrics = get_output_metrics(output, ["DischargeEnergy", "DischargeCapacity"])

t = time_series[:Time]
I = time_series[:Current]
E = time_series[:Voltage]


NeAmC_t10 = states[:NeAmSurfaceConcentration][10, :, 1]
PeAmCSurf_t10 = states[:PeAmSurfaceConcentration][10, :]
ElyteC_t10 = states[:ElectrolyteConcentration][10, :]

f = Figure()
ax = Axis(f[1, 1], title = "Concentrations", xlabel = "Distance [m]", ylabel = "Concentration")
lines!(ax, states.x, NeAmC_t10, color = :red, linewidth = 2, label = "NeAm Surface Conc")
lines!(ax, states.x, PeAmCSurf_t10, color = :blue, linewidth = 2, label = "PeAm Surface Conc")
lines!(ax, states.x, ElyteC_t10, color = :green, linewidth = 2, label = "Elyte Conc")
axislegend(ax, position = :rt, valign = :center)

display(f)


plot_dashboard(output; plot_type = "line")

