#=
Electro-Chemical component
A component with electric potential, concentration and temperature
The different potentials are independent (diagonal onsager matrix),
and conductivity, diffusivity is constant.
=#

# ENV["JULIA_STACKTRACE_MINIMAL"] = true

using Jutul, BattMo, Plots
using MAT

ENV["JULIA_DEBUG"] = 0;

# name = "model1D_50"
name = "p1d_40"
# name = "model1Dmod_50"
# name = "model1Dmod_500"
# name = "sector_7920"
# name = "model2D_1100" # give error
# name = "model3D_3936"
# name = "sector_1656"
# name = "sector_55200" #To big for direct linear_solver
# name = "spiral_16560"
# name = "spiral_16560_org"
# name = "sector_1656_org"
# name = "model3D_492"

fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")

sim, forces, state0, parameters, exported, model = BattMo.setup_sim(name, use_p2d = true)

states, reports, extra, exported = run_battery(name, use_p2d = true, info_level = 5, max_step = nothing);

stateref  = extra[:states_ref]
timesteps = extra[:timesteps]
steps     = size(states, 1)

E = Matrix{Float64}(undef, steps, 1)

for step in 1 : steps
    phi       = states[step][:BPP][:Phi][1]
    E[step] = phi
    # phi_ref   = stateref[step]["Control"]["E"]
    # E[step,2] = phi_ref
end
timesteps = timesteps[1 : steps]

plt = plot(cumsum(timesteps), E; title = "E", size=(1000, 800))
display(plt)

