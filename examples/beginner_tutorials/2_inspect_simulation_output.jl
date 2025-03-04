# # How to inspect simulation output

# We have seen how to simple it is to run a simulation using BattMo. 
# Now we'll have a look into how to inspect the results of a simulation.

# We'll run a simulation like we saw in the previous tutorial

using BattMo

file_name = "p2d_40_jl_chen2020.json"
file_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", file_name)

inputparams = readBattMoJsonInputFile(file_path)

output = run_battery(inputparams);

# Now we'll have a look into what the output entail. The ouput is of type NamedTuple and contains multiple dicts. Lets print the
# keys of each dict. 

println("Keys: ", keys(output))

# So we can see the the output contains state data, cell specifications, reports on the simulation, the input parameters of the simulation, and some extra data.
# The most important dicts, that we'll dive a bit deeper into, are the states and cell specifications. First let's see how the states output is structured.

# ### States
states = output[:states];
println("Type: ", typeof(states))
println("Keys: ", keys(states))

# As we can see, the states output is a Vector that contains dicts. In this case it consists of 77 dicts. Each dict represents 
# a time step in the simulation and each time step stores quantities divided into battery component related group. This structure agrees with the overal model structure of BattMo.

initial_state = states[1]
println("Keys: ", keys(initial_state))

# So each time step contains quantities related to the electrolyte, the negative electrode active material, the cycling control, and the positive electrode active material.
# Lets print the stored quantities for each group.


println("Electrolyte keys: ", keys(initial_state[:Elyte]))
println("Negative electrode active material keys: ", keys(initial_state[:NeAm]))
println("Positive electrode active material keys: ", keys(initial_state[:PeAm]))
println("Control keys: ", keys(initial_state[:Control]))

# ### Cell specifications
# Now lets see what quantities are stored within the cellSpecifications dict in the simulation output.

cell_specifications = output[:cellSpecifications];
println("Keys: ", keys(cell_specifications))

