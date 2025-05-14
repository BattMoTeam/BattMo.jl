
using BattMo

cell_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
cycling_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(cell_path)
cc_discharge_protocol = read_cycling_protocol(cycling_path)

cc_discharge_protocol["DRate"] = 2.0
cell_parameters["NegativeElectrode"]["ElectrodeCoating"]["Thickness"] = 0.00011

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cc_discharge_protocol)

output = solve(sim)
nothing # hide
