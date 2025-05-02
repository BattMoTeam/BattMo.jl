# # Handling Cell Parameters

# To change cell parameters, cycling protocols and settings, we can modify the JSON files directly, or we can read 
# them into objects in the script and modify them as Dictionaries. 

# ###  Load parameter files and initialize Model

# We begin by loading pre-defined parameters from JSON files:

using BattMo

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020_calibrated")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
nothing # hide

# ### Access parameters
# Cell parameters, cycling protocols, model settings and simulation settings are all Dictionary-like objects, which come with additional handy functions.
# First, lets list the outermost keys of the cell parameters object.
keys(cell_parameters)

# Now we access the Separator key.
cell_parameters["Separator"]

# We have a flat list of parameters and values for the separator. In other cases, a key might nest other dictionaries, 
# which can be accessed using the normal dictionary notation. Lets see for instance the  active material parameters of 
# the negative electrode.
cell_parameters["NegativeElectrode"]["ActiveMaterial"]

# In addition to manipulating parameters as dictionaries, we provide additional handy attributes and functions. 
# For instance, we can display all cell parameters:
cell_parameters.all

# However, there are many parameters, nested into dictionaries. Often, we are more interested in a specific subset of parameters. 
# We can find a parameter with the search_parameter function. For example, we'd like to now how electrode related objects and parameters are named:
search_parameter(cell_parameters, "Electrode")

# Another example where we'd like to now which concentration parameters are part of the parameter set:
search_parameter(cell_parameters, "Concentration")

# The search function also accepts partial matches and it is case-insentive.
search_parameter(cell_parameters, "char")

# ### Editing scalar parameters

# Parameter that take single numerical values (e.g. real, integers, booleans) can be directly modified. Examples:
cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 1e-13
nothing # hide

cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] = 8.2e-5
nothing # hide


# ### Editing non-scalar parameters

# Some parameters are described as functions or arrays, since the parameter value depends on other variables. For instance
# the Open Circuit Potentials of the Active Materials depend on the lithium stoichiometry and temperature. 

# > MISSING 

# ### Compare simulations 

# After the updates, we instantiate the model and the simulations, verify the simulation to be valid, 
# and run it as in the first tutorial.

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol)

output = solve(sim);

states = output[:states]
t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
using GLMakie # hide
fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t, E)
ax = Axis(fig[1, 2], ylabel = "Current / I", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t, I)
fig

# Let’s reload the original parameters and simulate again to compare:

cell_parameters_2 = load_cell_parameters(; from_default_set = "Chen2020_calibrated")
sim2 = Simulation(model, cell_parameters_2, cycling_protocol);
output2 = solve(sim2)
nothing # hide

# Now, we plot the original and modified results:

t2 = [state[:Control][:Controller].time for state in output2[:states]]
E2 = [state[:Control][:Phi][1] for state in output2[:states]]
I2 = [state[:Control][:Current][1] for state in output2[:states]]

fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t, E)
lines!(ax, t2, E2)
ax = Axis(fig[1, 2], ylabel = "Current / A", xlabel = "Time / s")
lines!(ax, t, I, label = "intial value")
lines!(ax, t2, I2, label = "updated value")
fig[1, 3] = Legend(fig, ax, "Reaction rate", framevisible = false)
fig # hide

# Note that not only the voltage profiles are different but also the currents, even if the cycling protocols have the same DRate.
# The change in current originates form our change in electrode thickness. By changing this thickness, we have also changed the
# cell capacity used to translate from DRate to cell current. As a conclusion, we should be mindful that some parameters might
# influence the simulation in ways we might not anticipate.