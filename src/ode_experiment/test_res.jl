using Test
import Jutul
import BattMo
import LinearAlgebra

init = BattMo.JSONFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/jsonfiles/p2d_40_jl.json")
states, reports, extra = BattMo.run_battery(init,info_level = -1, general_ad = true,use_p2d=true);
state0 = extra[:state0]
sim = extra[:simulator]
forces = extra[:forces]
dt = extra[:timesteps]
model = sim.model

## Trick simulator into doing a single linearization
Jutul.simulate!(sim, dt, forces = forces, state0 = state0,
max_timestep_cuts = 0, max_nonlinear_iterations = 0, info_level = -1)
lsys_r = sim.storage.LinearizedSystem.r
# Helper version
hsim = Jutul.HelperSimulator(model, state0 = state0, parameters = extra[:parameters])
x = Jutul.vectorize_variables(model, state0)
r = Jutul.model_residual(hsim, x, x, dt[1], forces = forces, time = 0.0)
@test lsys_r ≈ r

# Get accumulation terms (needs to be fixed for SolidMassCons equation but
# should work for all ConservationLaw instances)
accum=Jutul.model_accumulation(hsim, x)

for i=1:100
    diff=accum-Jutul.model_accumulation(hsim, x)
    println("diff: ", LinearAlgebra.norm(diff))
    println("pos: ", findmax(abs.(accum)))
end