# # How to run a simulation
#
# BattMo simulations repicate the voltage-current response of a cell. To run a Battmo simulation, the basic workflow is:    
# * Set up cell parameters 
# * Set up a cycling protocol  
# * Select a model
# * Prepare a simulation
# * Run the simulation
# * Inspect and visualize the outputs of the simulation  

# To start, we load BattMo (battery models and simulations) and Plotly (plotting). 

using BattMo, GLMakie

# BattMo stores cell parameters, cycling protocols and settings in a user-friendly JSON format to facilitate reuse. For our example, we read 
# the cell parameter set from a NMC811 vs Graphite-SiOx cell whose parameters were determined in the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050). 
# We also read an example cycling protocol for a simple Constant Current Discharge.


cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
nothing # hide

# Next, we select the Lithium-Ion Battery Model with default model settings. A model can be thought as a mathematical implementation of the electrochemical and 
# transport phenomena occuring in a real battery cell. The implementation consist of a system of partial differential equations and their corresponding parameters, constants and boundary conditions. 
# The default Lithium-Ion Battery Model selected below corresponds to a basic P2D model, where neither current collectors nor thermal effects are considered.

model_setup = LithiumIonBattery()

# Then we setup a Simulation by passing the model, cell parameters and a cycling protocol. A Simulation can be thought as a procedure to predict how the cell responds to the cycling protocol, 
# by solving the equations in the model using the cell parameters passed.  
# We first prepare the simulation: 

sim = Simulation(model_setup, cell_parameters, cycling_protocol);

# When the simulation is prepared, there are some validation checks happening in the background, which verify whether i) the cell parameters, cycling protocol and settings are sensible and complete 
# to run a simulation. It is good practice to ensure that the Simulation has been properly configured by checking if has passed the validation procedure:   
sim.is_valid

# Now we can run the simulation
output = solve(sim;)
nothing # hide


# The ouput is a NamedTuple storing the results of the simulation within multiple dictionaries. Let's plot the cell current and cell voltage over time and make a plot with the GLMakie package.

states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
nothing # hide


f = Figure(size = (1000, 400))

ax = Axis(f[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

ax = Axis(f[1, 2], title = "Current", xlabel = "Time / s", ylabel = "Current / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

