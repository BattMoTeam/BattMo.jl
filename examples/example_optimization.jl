using BattMo, GLMakie

# # Initial simulation

# Run a simulation witht the initial parameter values
name = "Chen2020_calibrated"
cell_parameters = load_cell_parameters(; from_default_set = name)
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol)

output_0 = solve(sim)

states = output_0[:states]
nothing # hide

# # Specify an objective

# Objective: Penalize any voltage less than target value of 4.2 (higher than initial voltage for battery)
v_target = 4.2
function objective(model, state, dt, step_no, forces)
	return dt * max(v_target - state[:Control][:Phi][1], 0)^2
end

# # Setup the optimization problem

opt = Optimization(output_0, objective)
nothing # hide
# # Solve the optimization problem

output_tuned = solve(opt)
nothing # hide

# # Plot results
states_tuned = output_tuned[:states]
report_tuned = output_tuned[:report]
final_x = output_tuned[:final_x]

optimization_setup = opt.setup
x0 = optimization_setup.x0
F0 = optimization_setup.F!(x0)
F_final = optimization_setup.F!(final_x)
lower = optimization_setup.limits.min
upper = optimization_setup.limits.max

parameters = opt.parameters
opt_model = opt.model
data = opt.setup.data



fig = Figure()
ys = log10
ax1 = Axis(fig[1, 1], yscale = ys, title = "Objective evaluations", xlabel = "Iterations", ylabel = "Objective")
GLMakie.plot!(ax1, opt.setup[:data][:obj_hist][2:end] .+ 1e-12)
fig

fig = Figure()
ax1 = Axis(fig[1, 1], title = "Scaled parameters", ylabel = "Value")
GLMakie.scatter!(ax1, final_x, label = "Final X")
GLMakie.scatter!(ax1, x0, label = "Initial X")
lines!(ax1, lower, label = "Lower bound")
lines!(ax1, upper, label = "Upper bound")
axislegend()
fig

# Plot difference in the main objective input

F = s -> map(x -> only(x[:Control][:Phi]), s)
fig = Figure()
ax1 = Axis(fig[1, 1], title = name, ylabel = "Voltage")
lines!(ax1, F(states), label = "Base case (G = $F0)")
lines!(ax1, F(states_tuned), label = "Tuned (G = $F_final)")
lines!(ax1, repeat([v_target], length(states)), label = "Target voltage")
axislegend(position = (:center, :bottom))
fig


