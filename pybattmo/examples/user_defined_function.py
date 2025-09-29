from battmo import *

# Import chayambuka input functions
from input.chayambuka_functions import *
from juliacall import Main as jl_main

cell_parameters = load_cell_parameters(from_default_set="Chayambuka2022")
cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")
model_settings = load_model_settings(from_default_set="P2D")
model_settings["ButlerVolmer"] = "Chayambuka"

jl_main.eval(f"typeof(Main.calc_ne_k)")

model_setup = SodiumIonBattery(model_settings=model_settings)
sim = Simulation(model_setup, cell_parameters, cycling_protocol)
output = solve(sim)
