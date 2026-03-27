# Geometries

BattMo supports several battery-cell geometries through the `ModelFramework` setting. These geometries determine how the electrochemical model is distributed in space, which grids are constructed, and which component-wise outputs are available.

The currently supported geometry families are:

- `P2D`
- `P4D Pouch`
- `P4D Cylindrical`

## Overview

| Model framework | Cell type | Spatial representation | Typical use |
| --- | --- | --- | --- |
| `P2D` | Through-thickness cell model | 1D across the stack, with radial particle diffusion | Fast cell-level studies, parameter sweeps, cycling analysis |
| `P4D Pouch` | Pouch cell | 3D current-collector / electrode geometry combined with particle diffusion | Tab placement effects, current distribution, pouch thermal/electrical nonuniformity |
| `P4D Cylindrical` | Cylindrical / jelly-roll cell | Cylindrical wound-cell geometry combined with particle diffusion | Radial and axial heterogeneity in cylindrical cells |

In all three cases, BattMo uses a pseudo-dimensional formulation:

- the electrolyte and solid-phase transport are resolved on the cell geometry
- diffusion inside active-material particles is resolved on a particle-radius coordinate
- component coupling is handled automatically in the assembled multiphysics model

## P2D

`P2D` is the classical Doyle-Fuller-Newman style through-thickness model. The cell is represented as a one-dimensional stack:

- negative electrode
- separator
- positive electrode

If current collectors are enabled, the stack also includes:

- negative current collector
- positive current collector

This is the most efficient option and is usually the right starting point when:

- studying voltage response, concentration profiles, or degradation behavior
- calibrating parameters
- running large parameter sweeps
- current-collector in-plane effects are not important

For `P2D`, BattMo provides:

- a global through-cell position, `output.states["Cell"]["Position"]`
- component-wise positions, such as `output.states["NegativeElectrode"]["ActiveMaterial"]["Position"]`

````@example p2d_geometry
using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p2d")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")

sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol; simulation_settings)
positions = BattMo.get_component_positions_1d(sim.grids)

fig = Figure(size = (950, 240))
ax = Axis(fig[1, 1];
	title = "P2D Through-Thickness Geometry",
	xlabel = "Position / m",
	ylabel = "",
	yticks = (1:5, ["Neg. CC", "Neg. electrode", "Separator", "Pos. electrode", "Pos. CC"]),
)

component_specs = [
	("NegativeElectrodeCurrentCollectorPosition", 1, :steelblue),
	("NegativeElectrodeActiveMaterialPosition", 2, :slategray),
	("SeparatorPosition", 3, :goldenrod),
	("PositiveElectrodeActiveMaterialPosition", 4, :seagreen),
	("PositiveElectrodeCurrentCollectorPosition", 5, :black),
]

for (name, y, color) in component_specs
	if haskey(positions, name)
		x = positions[name]
		scatter!(ax, x, fill(y, length(x)); color = color, markersize = 14)
		lines!(ax, [minimum(x), maximum(x)], [y, y]; color = color, linewidth = 6)
	end
end

hidedecorations!(ax; grid = false, minorgrid = false, ticks = false, minorticks = false, label = false)
ax.yticksvisible = false
ax.ylabelvisible = false
fig
````

## P4D Pouch

`P4D Pouch` resolves the cell in a pouch-cell geometry. The model keeps the pseudo-dimensional electrochemistry, but the cell components are placed on a multi-dimensional spatial grid so that in-plane current and potential variations can be captured.

This geometry is useful when:

- tab placement matters
- current collectors contribute significantly to the cell response
- you want to visualize spatially varying potentials, concentrations, or currents
- nonuniform utilization across the pouch is important

The main components represented are:

- negative current collector
- negative electrode active material / coating
- separator
- electrolyte
- positive electrode active material / coating
- positive current collector

BattMo provides component-wise mesh positions for these domains in the output, for example:

- `output.states["NegativeElectrode"]["CurrentCollector"]["Position"]`
- `output.states["PositiveElectrode"]["ActiveMaterial"]["Position"]`
- `output.states["Electrolyte"]["Position"]`

````@example p4d_pouch_geometry
using BattMo, GLMakie, Jutul

cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")

sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol; simulation_settings)

components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:slategray, :seagreen, :steelblue, :black]

for (i, component) in enumerate(components)
	if i == 1
		global fig, ax, _ = plot_mesh(sim.grids[component]; color = colors[i])
	else
		plot_mesh!(ax, sim.grids[component]; color = colors[i])
	end
end

ax.title = "P4D Pouch Geometry"
ax.azimuth[] = 5.1
ax.elevation[] = 0.45
ax.aspect = :data
fig
````

See also:

- [3D Pouch example](/examples/example_3D_pouch)

## P4D Cylindrical

`P4D Cylindrical` targets cylindrical cells with a jelly-roll type internal structure. It extends the pseudo-dimensional electrochemistry to a cylindrical geometry so that spatial variations around the wound cell can be represented.

This geometry is useful when:

- modelling cylindrical commercial cells
- studying radial and axial nonuniformities
- investigating tab-driven current distribution
- comparing simplified `P2D` behavior with a more spatially resolved cylindrical model

As for the pouch case, outputs are provided component-wise for the resolved domains.

````@example p4d_cylindrical_geometry
using BattMo, GLMakie, Jutul

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_cylindrical")
simulation_settings = load_simulation_settings(; from_default_set = "p4d_cylindrical")

cell_parameters["Cell"]["OuterRadius"] = 0.010
cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"] = 50e-6
cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"] = 50e-6
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabFractions"] = [0.5 / 3, 0.5, 0.5 + 0.5 / 3]
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabFractions"] = [0.5 / 3, 0.5, 0.5 + 0.5 / 3]
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"] = 0.002
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabWidth"] = 0.002
simulation_settings["AngularGridPoints"] = 24

sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol; simulation_settings)

components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:slategray, :seagreen, :steelblue, :black]

for (i, component) in enumerate(components)
	if i == 1
		global fig, ax, _ = plot_mesh(sim.grids[component]; color = colors[i])
	else
		plot_mesh!(ax, sim.grids[component]; color = colors[i])
	end
end

for component in ["NegativeCurrentCollector", "PositiveCurrentCollector"]
	plot_mesh!(ax, sim.grids[component];
		boundaryfaces = sim.couplings[component]["External"]["boundaryfaces"],
		color = :red)
end

ax.title = "P4D Cylindrical Geometry"
ax.azimuth[] = 4.0
ax.elevation[] = 1.56
ax.aspect = :data
fig
````

See also:

- [3D cylindrical example](/examples/example_3D_cylindrical)

## Choosing A Geometry

As a rule of thumb:

- use `P2D` when speed and robust cell-scale trends are most important
- use `P4D Pouch` for pouch cells with spatially resolved collector/electrode effects
- use `P4D Cylindrical` for cylindrical cells where wound-cell geometry matters

You select the geometry through the model settings:

```julia
model_settings = load_model_settings(; from_default_set = "p4d_pouch")
model = LithiumIonBattery(; model_settings)
```

or by setting:

```julia
model_settings["ModelFramework"] = "P2D"
```

## Related Pages

- [Lithium ion model](/manuals/user_guide/pxd_model)
- [Grid parameters](/manuals/user_guide/grid_params)
- [Simulation output](/manuals/user_guide/simulation_output)
