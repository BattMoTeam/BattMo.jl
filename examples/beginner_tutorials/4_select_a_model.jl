# # Selecting a model

# As mentioned in the first tutorial, a model can be thought as a mathematical implementation of the electrochemical and transport phenomena occuring in a real battery cell. 
# The implementation consist of a system of partial differential equations and their corresponding parameters, constants, boundary conditions and assumptions. 

# The default Lithium-Ion Battery Model corresponds to a basic P2D model, where neither current collectors, degradation nor thermal effects are considered. 
# BattMo has implemented several variants of the Lithium-Ion Battery Model, which can be accessed by *configuring the model object*. In this tutorial, we’ll configure a
# P2D model with degradation driven by SEI (Solid Electrolyte Interphase) growth.

# ### Load BattMo and Model Settings
using BattMo, GLMakie

# Let’s begin by loading the default model settings for a P2D simulation. This will return a ModelSettings object:

model_settings = load_model_settings(; from_default_set = "P2D")
nothing #hide 

# We can inspect all current settings with:
model_settings.all

# By default, the "UseSEIModel" parameter is set to false. Since we want to observe SEI-driven degradation effects, we’ll specify which SEI model we'd like to use, and with that enable the use of 
# the SEI model during the simulation. Let's have a look at which models are available to include in the settings:

print_submodels_info()

# For the SEI model, we can see there's one model to enable which is the "Bolay" model. We enable it in the model settings:

model_settings["UseSEIModel"] = "Bolay"
model_settings.all

# ### Initialize the Model
# Let’s now create the battery model using the modified settings:

model_setup = LithiumIonBattery(; model_settings);

# When setting up the model, the LithiumIonBattery constructor runs a validation on the model_settings. 
# In this case, because we set the "UseSEIModel" parameter to true, the validator provides a warning that we should define which SEI model we would like to use.
# If we ignore any warnings and pass the model to the Simulation constructor then we get an error. Let's create such a situation:

model_settings["UseSEIModel"] = "Bola"


model_setup = LithiumIonBattery(; model_settings);


# We get a warning that a validation issue has been encountered. For now we ignore it:

cell_parameters_sei = load_cell_parameters(; from_default_set = "SEI_example")
cccv_protocol = load_cycling_protocol(; from_default_set = "CCCV")

try  # hide
	sim = Simulation(model_setup, cell_parameters_sei, cccv_protocol)
catch err # hide
	showerror(stderr, err) # hide
end  # hide

# As expected, this results in an error because we didn't specify the SEI model correctly.

# ### Specify SEI Model and Rebuild
# Let's resolve the issue again and run the simulation:

model_settings["UseSEIModel"] = "Bolay"
nothing # hide

# Now rebuild the model:

model_setup = LithiumIonBattery(; model_settings);

# Now we can setup the simulation and run it.

sim = Simulation(model_setup, cell_parameters_sei, cccv_protocol)
output = solve(sim)
nothing # hide


# ## Plot of voltage and current

states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	I;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)

display(GLMakie.Screen(), f) # hide
f # hide

# ## Plot of SEI length

# We recover the SEI length from the `state` output
seilength = [state[:NeAm][:SEIlength][end] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Length",
	xlabel = "Time / s",
	ylabel = "Length / m",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	seilength;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black)

ax = Axis(f[2, 1],
	title = "Length",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black)

display(GLMakie.Screen(), f) # hide
f # hide


