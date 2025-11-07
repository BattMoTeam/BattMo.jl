using BattMo, Test, Jutul
import BattMo: VoltageCalibration, free_calibration_parameter!, freeze_calibration_parameter!, print_calibration_overview

function test_adjoints()
	cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
	cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
	solver_settings = load_solver_settings(; from_default_set = "direct")

	cycling_protocol["InitialStateOfCharge"] = 0.8
	cycling_protocol["LowerVoltageLimit"] = 2.0

	model_setup = LithiumIonBattery()

	cycling_protocol["DRate"] = 0.5
	sim = Simulation(model_setup, cell_parameters, cycling_protocol)

	output0 = solve(sim, info_level = -1)
	t0 = output0.time_series["Time"]
	V0 = output0.time_series["Voltage"]

	vc0 = VoltageCalibration(t0, V0, sim)
	obj0 = BattMo.setup_calibration_objective(vc0)
	dt = report_timesteps(output0.jutul_output.reports)[1:(end-1)]
	multimodel = sim.model.multimodel
	jutul_states = output0.jutul_output.states
	forces = sim.forces
	prm = sim.parameters
	state0 = sim.initial_state
	# Check that the objective is zero when the voltage data matches the model output
	@test Jutul.evaluate_objective(obj0, multimodel, jutul_states, dt, forces) ≈ 0.0
	# Perturb the voltage data to make the objective non-zero
	vc = VoltageCalibration(t0, V0 .+ 1.0, sim)

	free_calibration_parameter!(vc,
		["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
		lower_bound = 0.0, upper_bound = 1.0)
	free_calibration_parameter!(vc,
		["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
		lower_bound = 0.0, upper_bound = 1.0)
	free_calibration_parameter!(vc,
		["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
		lower_bound = 0.0, upper_bound = 1.0)
	free_calibration_parameter!(vc,
		["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
		lower_bound = 0.0, upper_bound = 1.0)
	free_calibration_parameter!(vc,
		["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"];
		lower_bound = 10000.0, upper_bound = 1e5)
	free_calibration_parameter!(vc,
		["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"];
		lower_bound = 10000.0, upper_bound = 1e5)
	free_calibration_parameter!(vc,
		["Electrolyte", "Concentration"];
		lower_bound = 500.0, upper_bound = 2000.0)
	free_calibration_parameter!(vc,
		["NegativeElectrode", "ActiveMaterial", "ReactionRateConstant"];
		lower_bound = 1e-16, upper_bound = 1e-10)
	free_calibration_parameter!(vc,
		["PositiveElectrode", "ActiveMaterial", "ReactionRateConstant"];
		lower_bound = 1e-16, upper_bound = 1e-10)
	obj = BattMo.setup_calibration_objective(vc)
	val = Jutul.evaluate_objective(obj, multimodel, jutul_states, dt, forces)
	@test val ≈ 1.0


	x0, x_setup = BattMo.vectorize_cell_parameters_for_calibration(vc, vc.sim)
	x0_copy = deepcopy(x0)
	setup_battmo_case(X, step_info = missing) = BattMo.setup_battmo_case_for_calibration(X, vc.sim, x_setup, step_info)
	numg = similar(x0)
	f, = BattMo.solve_and_differentiate_for_calibration(x0, setup_battmo_case, vc, obj, solver_settings, gradient = false)
	for i in eachindex(numg)
		x = copy(x0)
		ϵ = max(1e-8 * abs(x[i]), 1e-16)
		x[i] += ϵ
		f1, = BattMo.solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, obj, solver_settings, gradient = false)
		numg[i] = (f1 - f) / ϵ
	end

	f, g = BattMo.solve_and_differentiate_for_calibration(x0, setup_battmo_case, vc, obj, solver_settings)
	mynorm = x -> sum(x -> x^2, x)^(1 / 2)
	@test mynorm(numg - g) / mynorm(numg) ≈ 0.0 atol = 1e-4
	for i in eachindex(numg)
		@testset "$(x_setup.names[i])" begin
			@test numg[i] ≈ g[i] rtol = 5e-3
		end
	end
end

@testset "Parameter adjoints" begin
	test_adjoints()
end
