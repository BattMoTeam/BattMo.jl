using BattMo

experiment = Experiment([
	"Rest for 4000 s",
	"Discharge at 1 mA until 3.0 V",
	"Hold at 3.0 V until 1e-4 A",
	"Charge at 1 A until 4.0 V",
	"Rest for 1 hour",
]);

cyling_protocol = convert_experiment_to_battmo_control_input(experiment)

@info cyling_protocol