using BattMo, Jutul

# Very rough battery optimization example
name = "p2d_40"
fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
# init = JSONFile(fn)
init = load_battmo_formatted_input(fn)

states, cell_, reports, _, extra = run_battery(init, use_p2d = true, config_kwargs = (info_level = 1,), max_step = nothing, general_ad = true);

prm       = extra[:parameters]
model     = extra[:model]
state0    = extra[:state0]
forces    = extra[:forces]
sim_cfg   = extra[:cfg]
timesteps = extra[:timesteps]

## Compute sensitivities

# Objective: Penalize any voltage less than target value of 4.2 (higher than
# initial voltage for battery)
v_target = 4.2
function voltage_objective(model, state, dt, step_no, forces)
	return dt * max(v_target - state[:Control][:Phi][1], 0)^2
end

G = voltage_objective
dG = solve_adjoint_sensitivities(model, states, reports, G,
	forces = forces, state0 = state0, parameters = prm)

sim_cfg[:info_level] = -1
sim_cfg[:end_report] = false

cfg = optimization_config(model, prm, rel_min = 0.5, rel_max = 5, use_scaling = true)

opt_setup = setup_parameter_optimization(model, state0, prm, timesteps, forces, G, cfg, config = sim_cfg);

## Print starting values

x0 = opt_setup.x0
F0 = opt_setup.F!(x0)
dF0 = opt_setup.dF!(similar(x0), x0)

@info "Initial objective: $F0, gradient norm $(sum(abs, dF0))"

## Perform optimization loop using LBFGSB package

import LBFGSB as lb

lower = opt_setup.limits.min
upper = opt_setup.limits.max
x0 = opt_setup.x0
prt = 1
f! = opt_setup.F!
g! = opt_setup.dF!
results, final_x = lb.lbfgsb(f!, g!, x0, lb = lower, ub = upper, iprint = prt, maxfun = 200, maxiter = 100)

## Verify the results

F_final = opt_setup.F!(final_x)
prm_tuned = deepcopy(prm)
data = opt_setup.data
devectorize_variables!(prm_tuned, model, final_x, data[:mapper], config = data[:config])
states_t, rep_t = simulate(state0, model, timesteps, parameters = prm_tuned, forces = forces, config = sim_cfg);

## Plot results

using GLMakie

fig = Figure()
ys = log10
ax1 = Axis(fig[1, 1], yscale = ys, title = "Objective evaluations", xlabel = "Iterations", ylabel = "Objective")
GLMakie.plot!(ax1, opt_setup[:data][:obj_hist][2:end] .+ 1e-12)
fig

fig = Figure()
ax1 = Axis(fig[1, 1], title = "Scaled parameters", ylabel = "Value")
GLMakie.scatter!(ax1, final_x, label = "Final X")
GLMakie.scatter!(ax1, x0, label = "Initial X")
lines!(ax1, lower, label = "Lower bound")
lines!(ax1, upper, label = "Upper bound")
axislegend()
fig

## Create a "state" that contains the relative change in all parameters

rel_change = final_x ./ x0
changed_param = deepcopy(prm)
devectorize_variables!(changed_param, model, final_x, data[:mapper], config = data[:config])
for (mk, mv) in changed_param
	for (k, v) in mv
		@. v = v / prm[mk][k]
	end
end

## Plot difference in the main objective input

F = s -> map(x -> only(x[:Control][:Phi]), s)
fig = Figure()
ax1 = Axis(fig[1, 1], title = name, ylabel = "Voltage")
lines!(ax1, F(states), label = "Base case (G = $F0)")
lines!(ax1, F(states_t), label = "Tuned (G = $F_final)")
lines!(ax1, repeat([v_target], length(states)), label = "Target voltage")
axislegend(position = (:center, :bottom))
fig
