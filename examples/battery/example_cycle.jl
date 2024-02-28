using BattMo

#name="model1D_50"
name = "p2d_40"

# Run base case and plot the results against BattMo-MRST reference
states, reports, extra = run_battery(name, info_level = 1, max_step = nothing);

prm       = extra[:parameters]
model     = extra[:model]
timesteps = extra[:timesteps]
steps     = size(states, 1)
stateref  = extra[:init].object["states"]
E         = Matrix{Float64}(undef,steps,2)

for step in 1:steps
    phi = states[step][:BPP][:Phi][1]
    E[step,1] = phi
    phi_ref = stateref[step]["Control"]["E"]
    E[step,2] = phi_ref
end

timesteps = timesteps[1:steps]

using Plots

T = cumsum(timesteps)
plot1 = Plots.plot(T,E[:, 1]; title = "E", size=(1000, 800), label = "BattMo.jl", ylabel = "Voltage")
Plots.plot!(T, E[:, 2], label = "BattMo")
closeall()
display(plot1)

using Jutul

dt     = extra[:timesteps]
forces = deepcopy(extra[:forces])
state0 = deepcopy(extra[:state0])

state0[:BPP][:ControllerCV]
cfg = extra[:config]

V_lim = 2.7
V_lim = 3.4
V_up  = 4.0

state0[:BPP][:Phi][1] = (V_lim + V_up)/2.0

I_t = 3e-3

cycler = CyclingCVPolicy(current_discharge = I_t,
                         current_charge    = -I_t,
                         voltage_discharge = V_lim,
                         voltage_charge    = V_up,
                         hold_time         = 360.0)

simple = SimpleCVPolicy(I_t, V_lim)

policy = simple



bpp_force = setup_forces(model[:BPP], policy = policy)
forces    = setup_forces(model, BPP = bpp_force)

cfg[:error_on_incomplete] = false
dt = repeat(dt, 100)

states_c = nothing
states_c, rep = simulate(state0, model, dt, parameters = prm, config = cfg, forces = forces, info_level = 0);

##

Ti = cumsum(dt[1:length(states_c)])
V  = map(s -> s[:BPP][:Phi][1], states_c)
I  = map(s -> s[:BPP][:Current][1], states_c)

plot2 = Plots.plot(Ti, V; title = "E", size=(1000, 800), legend=:topleft, label = "Voltage")
Plots.plot!(twinx(), Ti, I; title = "E", size=(1000, 800), label = "Current", color = :red)

closeall()
display(plot2)

##
x = Ti/[3600]
l = @layout [a; b]
p1 = plot(x, V, ylabel = "Voltage", xlabel = "Time [min]")
p2 = plot(x, I, ylabel = "Current", xlabel = "Time [min]")
ylims!(p2, -1.01*I_t, 1.01*I_t)
plot(p1, p2, layout = l, legend = false)

##
t = cumsum(map(x -> x[:total_time], rep));
x = Ti/[3600]
n = 100
N = length(Ti)
plotrange = range(1, length(Ti), length = n)
plotrange = [collect(plotrange)..., repeat([length(Ti)], 50)...]

@gif for i in plotrange
    l = @layout [a; b; c]
    stop = Int64(ceil(i))
    subs = 1:stop

    ti = t[subs]
    p1 = plot(x[subs], V[subs], ylabel = "Voltage", xlabel = "Time [min]")
    p2 = plot(x[subs], I[subs], ylabel = "Current", xlabel = "Time [min]")
    p3 = plot(1:length(ti), ti, ylabel = "Runtime [s]", xlabel = "Time-step index")
    ylims!(p2, -1.01*I_t, 1.01*I_t)
    ylims!(p3, 0, maximum(t))

    plot(p1, p2, p3, layout = l, legend = false)
end

