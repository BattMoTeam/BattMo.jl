

"""
	EndCycleIndexTerminationCriterion(end_time)

A termination criterion that stops time-stepping when the global cycle_index reaches `end_cycle_index`.
"""
struct EndCycleIndexTerminationCriterion <: AbstractTerminationCriterion
	end_cycle_index::Float64
end

function Jutul.timestepping_is_done(C::EndCycleIndexTerminationCriterion, simulator, states, substates, reports, solve_recorder)

	s = get_simulator_storage(simulator)

	return s.state.Control.Controller.numberOfCycles >= C.end_cycle_index
end



"""
	EndControlStepTerminationCriterion(end_time)

A termination criterion that stops time-stepping when the global control_step_index reaches `end_control_step_index`.
"""
struct EndControlStepTerminationCriterion <: AbstractTerminationCriterion
	end_control_step_index::Float64
end

function Jutul.timestepping_is_done(C::EndControlStepTerminationCriterion, simulator, states, substates, reports, solve_recorder)

	s = get_simulator_storage(simulator)
	return s.state.Control.Controller.current_step_number + 1 > C.end_control_step_index
end



"""
	EndVoltageTerminationCriterion(end_time)

A termination criterion that stops time-stepping when the global electric potential reaches `end_voltage`.
"""
struct EndVoltageTerminationCriterion <: AbstractTerminationCriterion
	end_voltage::Float64
end

function Jutul.timestepping_is_done(C::EndVoltageTerminationCriterion, simulator, states, substates, reports, solve_recorder)

	s = get_simulator_storage(simulator)
	m = get_simulator_model(simulator)


	if m[:Control].system.policy.initialControl == "charging"

		terminate = s.state.Control.ElectricPotential[1] >= C.end_voltage
	elseif m[:Control].system.policy.initialControl == "discharging"

		terminate = s.state.Control.ElectricPotential[1] <= C.end_voltage

	end
	return terminate
end
