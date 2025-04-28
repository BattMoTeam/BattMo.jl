# # Setting Up a Custom Battery Model
# In this tutorial, we’ll configure a custom battery model using BattMo, with a specific focus on SEI (Solid Electrolyte Interphase) growth within a P2D simulation framework.

# ### Load BattMo and Model Settings
using BattMo

# Let’s begin by loading the default model settings for a P2D simulation. This will return a ModelSettings object:

file_path_model = parameter_file_path("model_settings", "P2D.json")
model_settings = load_model_settings(; from_file_path = file_path_model)
nothing #hide 

# We can inspect all current settings with:
model_settings.all

# By default, the "UseSEIModel" parameter is set to false. Since we want to
# observe SEI effects, we’ll enable and set it to Bolay, which is a specific SEI
# model.

model_settings["UseSEIModel"] = "Bolay"
model_settings.all

# ### Initialize the Model
# Let’s now create the battery model using the modified settings:

model = LithiumIonBatteryModel(; model_settings);

# We can see that some warnings are given in the terminal. When setting up the model, the LithiumIonBatteryModel constructor runs a validation on the model_settings. 
# In this case, because we set the "UseSEIModel" parameter to true, the validator provides a warning that we should define which SEI model we would like to use.
# If we ignore the warnings and pass the model to the Simulation constructor then we get an error:

file_path_cell = parameter_file_path("cell_parameters", "SEI_example.json")
file_path_cycling = parameter_file_path("cycling_protocols", "CCCV.json")

cell_parameters_sei = load_cell_parameters(; from_file_path = file_path_cell)
cccv_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)

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


