using BattMo
import Random: seed!

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

# Set currents to about 1C for the ~5 Ah Chen 2020 cell
I_discharge = 5.0 
I_charge    = -5.0

n_discharge = 60   # number of discharge steps
n_rest      = 10   # number of rest steps
n_charge    = 20   # number of charge steps

# Base step sizes (s) for each phase
dt_d = 1*HOUR / n_discharge
dt_r = 0.5*HOUR  / n_rest
dt_c = 1*HOUR / n_charge

# Add jitter to each step to create non-uniform spacing
jitter(n, dt) = dt .* (1.0 .+ 0.9 .* (2.0 .* rand(n) .- 1.0))

# Use a fixed seed for reproducibility
seed!(12345)

dt_discharge = jitter(n_discharge, dt_d)
dt_rest      = jitter(n_rest,      dt_r)
dt_charge    = jitter(n_charge,    dt_c)

# Build cumulative time vector starting from 0
t_discharge = [0; cumsum(dt_discharge)]
t_rest      = t_discharge[end] .+ cumsum(dt_rest)
t_charge    = t_rest[end]      .+ cumsum(dt_charge)

times    = [t_discharge; t_rest; t_charge]
@assert all(diff(times) .> 0.0) "Time points must be strictly increasing."
currents = [I_discharge .* ones(n_discharge+1);
            zeros(n_rest);
            I_charge .* ones(n_charge)]

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

println("Total simulation time:  $(round(t_sim[end]/3600; digits=2)) h")
println("Number of time steps:   $(length(t_sim))")
println("Min voltage:            $(round(minimum(V_sim); digits=3)) V")
println("Max voltage:            $(round(maximum(V_sim); digits=3)) V")
println("Min current:            $(round(minimum(I_sim); digits=3)) A")
println("Max current:            $(round(maximum(I_sim); digits=3)) A")

doplot = false
if doplot
    using GLMakie
    plot_dashboard(output; plot_type = "simple")
end
