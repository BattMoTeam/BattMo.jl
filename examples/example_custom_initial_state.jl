# # Splitting a simulation into sequential segments using a custom initial state
#
# This example shows how to split a multi-phase battery simulation into
# separate sequential simulations whose combined results match a single
# reference run. The scenario consists of three steps:
#
# 1. **Reference** -- a complete discharge - charge cycle run in a single
#    simulation.
# 2. **Discharge** -- only the discharge phase, saving the final state.
# 3. **Charge** -- a charge phase that *continues from the saved state*.
#
# The combined voltage curves of steps 2 and 3 should reproduce the voltage
# curve of step 1.
#
# This pattern is useful whenever you want to restart or resume a simulation,
# change the cycling protocol mid-way, or store and reload intermediate states.
#
# We use the Chen 2020 parameter set

using BattMo
using GLMakie

getTime(output) = [s[:Control][:Controller].time for s in output.jutul_output.states]
getE(output) = [s[:Control][:ElectricPotential][1] for s in output.jutul_output.states]
getI(output) = [s[:Control][:Current] for s in output.jutul_output.states]

# ## Common setup

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
model_settings = load_model_settings(; from_default_set = "p2d")
delete!(model_settings, "RampUp")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")
simulation_settings["TimeStepDuration"] = 100
delete!(simulation_settings, "RampUpTime")
delete!(simulation_settings, "RampUpSteps")
model = LithiumIonBattery(; model_settings)

# ## Step 1. One complete discharge - charge cycle for reference
println("Running Step 1: Reference discharge - charge cycle")
cycling_ref = load_cycling_protocol(; from_default_set = "cc_cycling")
cycling_ref["TotalNumberOfCycles"] = 1
cycling_ref["InitialControl"] = "discharging"
cycling_ref["DRate"] = 1.0
cycling_ref["CRate"] = 1.0
cycling_ref["InitialStateOfCharge"] = 1.0
cycling_ref["LowerVoltageLimit"] = 3.0
cycling_ref["UpperVoltageLimit"] = 4.0

sim_ref = Simulation(model, cell_parameters, cycling_ref; simulation_settings)
output_ref = solve(sim_ref)

V_ref = output_ref.time_series["Voltage"]
t_ref = output_ref.time_series["Time"]

# Same
# V_refj = getE(output_ref)
# t_refj = getTime(output_ref)

println("cc_cycling:")
println("initial state: ", sim_ref.initial_state[:Control][:Controller].time, " s, ", sim_ref.initial_state[:Control][:ElectricPotential][1], " V")
println("time series: ", t_ref[1], " s, ", V_ref[1], " V")

# ## Step 2. Discharge only, saving the end state
println("Running Step 2: Discharge only, saving end state")
cycling_disc = load_cycling_protocol(; from_default_set = "cc_discharge")
cycling_disc["DRate"] = cycling_ref["DRate"]
cycling_disc["InitialStateOfCharge"] = cycling_ref["InitialStateOfCharge"]
cycling_disc["LowerVoltageLimit"] = cycling_ref["LowerVoltageLimit"]

sim_disc = Simulation(model, cell_parameters, cycling_disc; simulation_settings, time_steps = sim_ref.time_steps)
output_disc = solve(sim_disc)

V_disc = output_disc.time_series["Voltage"]
t_disc = output_disc.time_series["Time"]

println("cc_discharge:")
println("initial state: ", sim_disc.initial_state[:Control][:Controller].time, " s, ", sim_disc.initial_state[:Control][:ElectricPotential][1], " V")
println("time series: ", t_disc[1], " s, ", V_disc[1], " V")


# Extract the end state to be used as initial state for the charge
state0 = output_disc.jutul_output.states[end]

# ## Step 3, Charge starting from the saved discharge end state
println("Running Step 3: Charge starting from saved discharge end state")
cycling_charge = load_cycling_protocol(; from_default_set = "cc_charge")
cycling_charge["CRate"] = cycling_ref["CRate"]
cycling_charge["UpperVoltageLimit"] = cycling_ref["UpperVoltageLimit"]

sim_charge = Simulation(model, cell_parameters, cycling_charge; simulation_settings, state0, time_steps = sim_ref.time_steps)
output_charge = solve(sim_charge)

V_charge = output_charge.time_series["Voltage"]
t_charge = output_charge.time_series["Time"]

# ## Comparison
fig = Figure()
ax = Axis(fig[1, 1], xlabel = "Time  /  s", ylabel = "Voltage  /  V")
lines!(ax, t_ref, V_ref, label = "Reference using cc_cycling")
lines!(ax, t_disc, V_disc, linestyle = :dash, label = "Discharge using cc_discharge")
lines!(ax, (t_charge .+ t_disc[end]), V_charge, linestyle = :dash, label = "Charge using cc_charge (offset)")
# lines!(ax, (t_charge .- t_charge[1] .+ t_disc[end]), V_charge, linestyle = :dash, label = "Charge using cc_charge (offset)")
axislegend(ax, position = :lb)
display(GLMakie.Screen(), fig)
