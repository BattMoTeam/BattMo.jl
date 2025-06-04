# # Example of jelly roll
# This example demonstrates how to set up, run and visualize a 3D cylindrical battery model

# ## Load the packages
using BattMo, GLMakie, Jutul

# ## Load the cell parameters
cell_parameters     = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol    = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings      = load_model_settings(; from_default_set = "P4D_cylindrical")
simulation_settings = load_simulation_settings(; from_default_set = "P4D_cylindrical")
nothing #hide

# ## Set up the model

model_setup = LithiumIonBattery(; model_settings)
nothing #hide

# ## Review and modify the cell parameters
# We go through some of the geometrical and discretization parameters. We modify some of them to obtain a cell where the different components are easier to visualize

# The cell geometry is determined by the inner and outer radius and the height. We reduce the outer radius
cell_parameters["Cell"]["OuterRadius"] = 0.010 
nothing #hide

# We modify the current collector thicknesses, for visualization purpose
cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"]    = 50e-6
cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"]    = 50e-6
nothing #hide

# The tabs are part of the current collectors that connect the electrodes to the external circuit. The location of the
# tabs is given as a fraction length, where the length is measured along the current collector in the horizontal
# direction, meaning that we follow the rolling spiral. Indeed, this is the relevant length to use if we want to
# dispatch the current collector in a equilibrated way, where each of them will a priori collect the same amount of
# current. In the following, we include three tabs with one in the middle and the other at a distance such that each tab
# will collect one third of the current

cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabFractions"] = [0.5/3, 0.5, 0.5 + 0.5/3] 
nothing #hide

# We set the tab width to 2 mm

cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"] = 0.002
nothing #hide

# The angular discretization of the cell is determined by the number of angular grid points.

simulation_settings["GridResolution"]["Angular"]                         = 30
nothing #hide

# ## Create the simulation object

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);
nothing #hide

# ## We preprocess the simulation object to retrieve the grids and coupling structure, which we want to visualize prior running the simulation

output = setup_simulation(sim)
grids     = output[:grids]
couplings = output[:couplings]
nothing #hide

# ## Visualize the grids and couplings

# Define a list of the component to iterate over in the ploting routin below

components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector" ]
colors = [:gray, :green, :blue, :black]
nothing #hide

# We plot the components

for (i, component) in enumerate(components)
    if i == 1
        global fig, ax = plot_mesh(grids[component],
                            color = colors[i])
    else
        plot_mesh!(ax,
                   grids[component],
                   color = colors[i])
    end
end
fig #hide

# ## Plot the current collectors tabs

# We plot the tabs, which couple the current collectors with the external circuits. The tabs will typically protude from
# the cell in the vertical directions but we can neglect this 3d feature in the simulation model. The tabs are then
# represented by horizontal faces at the top or bottom of the current collectors. In the figure below, they are plotted
# in red.

components = [
    "NegativeCurrentCollector",
    "PositiveCurrentCollector"
]

for component in components
    plot_mesh!(ax, grids[component];
               boundaryfaces = couplings[component]["External"]["boundaryfaces"],
               color = :red)
end

fig #hide

ax.azimuth[] = 4.0
ax.elevation[] = 1.56

fig #hide
