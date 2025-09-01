using BattMo, GLMakie

### Create wltp function to calculate Current (WLTP data from https://github.com/JRCSTU/wltp)

using CSV
using DataFrames
using Jutul

"""

path = joinpath(@__DIR__, "../assets/wltp.csv")
df = CSV.read(path, DataFrame)

t = df[:, 1]
P = df[:, 2]

power_func = get_1d_interpolator(t, P, cap_endpoints = false)

"""

function current_function(time, voltage)

	factor = 4000 # Tot account for the fact that we're simulating a single cell instead of a battery pack

	return 1
end

@eval Main current_function = $current_function


### Run a simulation with the current function

model_setup = LithiumIonBattery()
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")
simulation_settings["TimeStepDuration"] = 1


cycling_protocol = load_cycling_protocol(; from_default_set = "user_defined_current_function")

cycling_protocol["TotalTime"] = 1800

sim_current = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);

output = solve(sim_current);


plot_dashboard(output; plot_type = "simple")
