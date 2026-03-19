using BattMo

const HOUR = 3600.0

###
# Example: InputCurrentSeries protocol with discharge, rest, and charge
#
# This example demonstrates the InputCurrentSeries cycling protocol, which
# accepts a prescribed time series of (time [s], current [A]) pairs.
# Voltage limits are enforced: the controller switches from current to
# voltage control if a limit is hit, and back when the limit is no longer
# binding. Note that there may be spikes when switching.
###

model_setup = LithiumIonBattery()
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
model_settings = load_model_settings(; from_default_set = "p2d")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")

# Set discharge current to about 1.2C and charge to about 1C for the ~5 Ah Chen 2020 cell
I_discharge = 6.0
I_charge    = -5.0

# Set time duration
T_discharge = 1*HOUR
T_rest      = 0.5*HOUR
T_charge    = 1*HOUR

# Set number of time steps
n_discharge = 50
n_rest      = 10
n_charge    = 50

# Construct time array
t_discharge = range(0.0, T_discharge, n_discharge)
t_rest      = range(0.0, T_rest, n_rest) .+ t_discharge[end]
t_charge    = range(0.0, T_charge, n_charge) .+ t_rest[end]
times       = [t_discharge; t_rest[2:end]; t_charge[2:end]]
@assert all(diff(times) .> 0.0) "Time points must be strictly increasing."

# Construct current array
currents = [I_discharge .* ones(n_discharge);
            zeros(n_rest-1);
            I_charge .* ones(n_charge-1)]

# Pass the time and current series, along with voltage limits, to the cycling protocol.
cycling_protocol = CyclingProtocol(Dict(
	"Protocol"             => "InputCurrentSeries",
	"Times"                => times,
	"Currents"             => currents,
	"LowerVoltageLimit"    => 2.6,
	"UpperVoltageLimit"    => 4.1,
	"InitialStateOfCharge" => 1.0,
))

# Create a simulation case
sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

# The user can also override the time steps after creating the Simulation.
# For example, to use the exact diff(times) from data:

# dt = sim.time_steps
# empty!(dt)
# append!(dt, diff(times))

# This is useful when loading time series from an external file.

output = solve(sim; accept_invalid = true)

# Inspect results
ts = output.time_series
t_sim = ts["Time"]
I_sim = ts["Current"]
V_sim = ts["Voltage"]

println("Total simulation time:  $(round(t_sim[end]/HOUR; digits=2)) h")
println("Number of time steps:   $(length(t_sim))")
println("Min voltage:            $(round(minimum(V_sim); digits=3)) V")
println("Max voltage:            $(round(maximum(V_sim); digits=3)) V")
println("Min current:            $(round(minimum(I_sim); digits=3)) A")
println("Max current:            $(round(maximum(I_sim); digits=3)) A")

doplot = true
if doplot
    using GLMakie
    plot_dashboard(output; plot_type = "simple")
end
