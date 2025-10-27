using BattMo, GLMakie

cycling_protocol = CyclingProtocol(Dict(
	"Protocol" => "Experiment",
	"TotalTime" => 18000000,
	"InitialStateOfCharge" => 0.99,
	"Experiment" => [
		"Rest for 4000 s",
        "Discharge at 1 A until 3.0 V",
        "Hold at 3.0 V until 1e-4 A",
        "Charge at 1 A until 4.0 V",
        "Rest for 1 hour"]
	

))

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol)

output = solve(sim; info_level = 0)

plot_dashboard(output)
