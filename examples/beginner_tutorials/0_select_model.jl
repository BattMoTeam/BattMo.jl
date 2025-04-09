# # Selecting a model

# As mentioned in the first tutorial, a model can be thought as a mathematical implementation of the electrochemical and transport phenomena occuring in a real battery cell. 
# The implementation consist of a system of partial differential equations and their corresponding parameters, constants, boundary conditions and assumptions. 

# The default Lithium-Ion Battery Model corresponds to a basic P2D model, where neither current collectors, degradation nor thermal effects are considered. 
# BattMo has implemented several variants of the Lithium-Ion Battery Model, which can be accessed by *configuring the model object*. In this tutorial, we’ll configure a
# P2D model with degradation driven by SEI (Solid Electrolyte Interphase) growth.

# ### Load BattMo and Model Settings
using BattMo

# Let’s begin by loading the default model settings for a P2D simulation. This will return a ModelSettings object:

file_path_model = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/model_settings/", "model_settings_P2D.json")
model_settings = read_model_settings(file_path_model)
nothing #hide 

# We can inspect all current settings with:
model_settings.all

# By default, the "UseSEIModel" parameter is set to false. Since we want to observe SEI-driven degradation effects, we’ll enable it:

model_settings["UseSEIModel"] = true
model_settings.all

# ### Initialize the Model
# Let’s now create the battery model using the modified settings:

model = LithiumIonBatteryModel(; model_settings);

# We can see that some warnings are given in the terminal. When setting up the model, the LithiumIonBatteryModel constructor runs a validation on the model_settings. 
# In this case, because we set the "UseSEIModel" parameter to true, the validator provides a warning that we should define which SEI model we would like to use.
# If we ignore the warnings and pass the model to the Simulation constructor then we get an error:

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_SEI_example.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCCV.json")

cell_parameters_sei = read_cell_parameters(file_path_cell)
cccv_protocol = read_cycling_protocol(file_path_cycling)

try  # hide
	sim = Simulation(model, cell_parameters_sei, cccv_protocol)
catch err # hide
	showerror(stderr, err) # hide
end  # hide

# As expected, this results in an error because we haven't yet specified the SEI model type.

# ### Specify SEI Model and Rebuild
# To resolve this, we’ll explicitly set the SEI model to "Bolay":

model_settings["SEIModel"] = "Bolay"
nothing # hide

# Now rebuild the model:

model = LithiumIonBatteryModel(; model_settings);

# Run the Simulation
# Now we can setup the simulation and run it.

sim = Simulation(model, cell_parameters_sei, cccv_protocol)
output = solve(sim);
nothing # hide


# ## Plot of voltage and current

states = output[:states]

t = [state[:Control][:ControllerCV].time for state in states]
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


