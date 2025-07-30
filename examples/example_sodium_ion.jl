using BattMo, GLMakie

# BattMo stores cell parameters, cycling protocols and settings in a user-friendly JSON format to facilitate reuse. For our example, we read 
# the cell parameter set from a NMC811 vs Graphite-SiOx cell whose parameters were determined in the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050). 
# We also read an example cycling protocol for a simple Constant Current Discharge.

# ## Load the experimental data and set up a base case
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
exdata = joinpath(battmo_base, "examples", "example_data")
df_01 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_1_crate.csv"), DataFrame)
df_06 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_6_crate.csv"), DataFrame)
df_14 = CSV.read(joinpath(exdata, "Chayambuka_voltage_1_4_crate.csv"), DataFrame)

A = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]
t_exp_06 = df_06[:, 1] * 3600 / 1000 / A / 5
v_exp_06 = df_06[:, 2]

t_exp_01 = df_01[:, 1] * 3600 / 1000 / A
v_exp_01 = df_01[:, 2]

t_exp_14 = df_14[:, 1] * 3600 / 1000 / A / 12
v_exp_14 = df_14[:, 2]

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")
model_settings = load_model_settings(; from_default_set = "P2D")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

# cell_parameters["NegativeElectrode"]["ElectrodeCoating"]["Thickness"] = 1.667145305054536 * cell_parameters["NegativeElectrode"]["ElectrodeCoating"]["Thickness"]
# cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] = 1.667145305054536 * cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"]
simulation_settings["NegativeElectrodeCoating"] = 50

model_settings["ReactionRateConstant"] = "UserDefined"

cycling_protocol["DRate"] = 0.6
cycling_protocol["CRate"] = 0.6
cycling_protocol["LowerVoltageLimit"] = 2.0
cycling_protocol["UpperVoltageLimit"] = 4.0
cycling_protocol["InitialControl"] = "charging"
cycling_protocol["TotalNumberOfCycles"] = 1
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 2.0306459345750275e-15
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 4.542183772045386e-11
# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 1.2952951004386266e-16

# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 1.6787424917471138e-11

nothing # hide

# Next, we select the Lithium-Ion Battery Model with default model settings. A model can be thought as a mathematical implementation of the electrochemical and 
# transport phenomena occuring in a real battery cell. The implementation consist of a system of partial differential equations and their corresponding parameters, constants and boundary conditions. 
# The default Lithium-Ion Battery Model selected below corresponds to a basic P2D model, where neither current collectors nor thermal effects are considered.

model = LithiumIonBattery(; model_settings)

# Then we setup a Simulation by passing the model, cell parameters and a cycling protocol. A Simulation can be thought as a procedure to predict how the cell responds to the cycling protocol, 
# by solving the equations in the model using the cell parameters passed.  
# We first prepare the simulation: 

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

# When the simulation is prepared, there are some validation checks happening in the background, which verify whether the cell parameters, cycling protocol and settings are sensible and complete 
# to run a simulation. It is good practice to ensure that the Simulation has been properly configured by checking if has passed the validation procedure:   
sim.is_valid

# Now we can run the simulation
output = solve(sim; accept_invalid = true, info_level = 1)
nothing # hide


# Now we can easily plot some results

states = get_output_states(output)
time_series = get_output_time_series(output)

ne_am_diff = states[:NeAmDiffusionCoefficient][:, :10]
pe_am_diff = states[:PeAmDiffusionCoefficient][:, 14:23]

@info maximum(ne_am_diff)
@info maximum(pe_am_diff)

ne_am_diff = states[:NeAmReactionRateConst][:, :10]
pe_am_diff = states[:PeAmReactionRateConst][:, 14:23]

@info maximum(ne_am_diff)
@info maximum(pe_am_diff)

plot_dashboard(output; plot_type = "contour")

max_t_exp = maximum(t_exp_06)
max_t = maximum(time_series[:Time])

@info "ratio", max_t_exp / max_t

# fig = Figure()
# ax = Axis(fig[1, 1], title = "CRate = 0.6", xlabel = "Time / s", ylabel = "Voltage / V")
# lines!(ax, time_series[:Time], time_series[:Voltage], label = "Base case")
# lines!(ax, t_exp_06, v_exp_06, label = "Experimental data")
# axislegend(position = :lb)
# fig

# plot_output(output, ["NeAmOpenCircuitPotential vs ", "PeAmOpenCircuitPotential vs Time and Position", "NeAmSurfaceConcentration vs Time and Position"]; layout = (3, 1))
# plot_output(output, ["NeAmReactionRateConst vs Time and Position", "PeAmReactionRateConst vs Time and Position"]; layout = (2, 1))
