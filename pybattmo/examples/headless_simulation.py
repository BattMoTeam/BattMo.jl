from battmo import *

simulation_input = load_full_simulation_input(from_default_set="Chen2020")

output = run_simulation(simulation_input)

plot_dashboard(output, plot_type="contour")
