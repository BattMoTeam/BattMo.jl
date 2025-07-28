using BattMo, GLMakie

# BattMo stores cell parameters, cycling protocols and settings in a user-friendly JSON format to facilitate reuse. For our example, we read 
# the cell parameter set from a NMC811 vs Graphite-SiOx cell whose parameters were determined in the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050). 
# We also read an example cycling protocol for a simple Constant Current Discharge.


cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

cycling_protocol["DRate"] = 0.5
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 3.3e-14
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 6.716e-12
# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 4.0e-15
# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 3.545e-11

nothing # hide

# Next, we select the Lithium-Ion Battery Model with default model settings. A model can be thought as a mathematical implementation of the electrochemical and 
# transport phenomena occuring in a real battery cell. The implementation consist of a system of partial differential equations and their corresponding parameters, constants and boundary conditions. 
# The default Lithium-Ion Battery Model selected below corresponds to a basic P2D model, where neither current collectors nor thermal effects are considered.

model = LithiumIonBattery()

# Then we setup a Simulation by passing the model, cell parameters and a cycling protocol. A Simulation can be thought as a procedure to predict how the cell responds to the cycling protocol, 
# by solving the equations in the model using the cell parameters passed.  
# We first prepare the simulation: 

sim = Simulation(model, cell_parameters, cycling_protocol);

# When the simulation is prepared, there are some validation checks happening in the background, which verify whether the cell parameters, cycling protocol and settings are sensible and complete 
# to run a simulation. It is good practice to ensure that the Simulation has been properly configured by checking if has passed the validation procedure:   
sim.is_valid

# Now we can run the simulation
output = solve(sim; accept_invalid = true)
nothing # hide


# Now we can easily plot some results

plot_dashboard(output; plot_type = "contour")

