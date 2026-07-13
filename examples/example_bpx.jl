# # Loading cell parameters from a BPX file
#
# This example demonstrates how to use the `from_bpx_file_path` argument of
# `load_cell_parameters` to load battery parameters from a BPX
# (Battery Parameter eXchange, https://bpxstandard.com) formatted JSON file.

using BattMo, GLMakie

# We load the BPX parameterisation of an NMC111|graphite 12.5 Ah pouch cell.

bpx_file_path = joinpath(dirname(pathof(BattMo)), "..", "test", "data", "jsonfiles", "nmc_pouch_cell_BPX.json")

cell_parameters = load_cell_parameters(; from_bpx_file_path = bpx_file_path)

# The BPX parameters are converted to the BattMo cell parameter format, so they can be
# inspected and modified in the usual way.

println("Cell nominal capacity: ", cell_parameters["Cell"]["NominalCapacity"], " Ah")
println("Negative electrode stoichiometry at SOC 0: ", cell_parameters["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC0"])
println("Negative electrode stoichiometry at SOC 100: ", cell_parameters["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"])

# BPX operating conditions such as the voltage cut-offs belong to the cycling protocol in
# BattMo. Here we set up a 1C constant current discharge using the voltage window from the
# BPX file (2.7 V - 4.2 V).

cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
cycling_protocol["DRate"] = 1.0
cycling_protocol["LowerVoltageLimit"] = 2.7
cycling_protocol["UpperVoltageLimit"] = 4.2

# We select the default Lithium-Ion Battery Model (P2D) and run the simulation.

model = LithiumIonBattery()

sim = Simulation(model, cell_parameters, cycling_protocol)
output = solve(sim)

# Finally we plot the results.

plot_dashboard(output; plot_type = "simple")
