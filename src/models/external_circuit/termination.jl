

mutable struct Termination <: AbstractTerminationCriterion
	quantity::String
	comparison::Union{String, Nothing}
	value::Real
	function Termination(quantity, value; comparison = nothing)
		return new{}(quantity, comparison, value)
	end
end


"""
	TimeTermination(end_time)

A termination criterion that stops a control step or time-stepping when the time reaches `end_time`.
"""
mutable struct TimeTermination <: AbstractTerminationCriterion
	end_time::Real
	tolerance::Real
end


"""
	VoltageTermination(end_voltage,comparison)

A termination criterion that stops a control step or time-stepping when the voltage reaches `end_voltage`.
"""
mutable struct VoltageTermination <: AbstractTerminationCriterion
	end_voltage::Real
	direction::String
	tolerance::Real

end


"""
	VoltageChangeTermination(end_voltage_change,comparison)

A termination criterion that stops a control step or time-stepping when the voltage changes reaches `end_voltage_change`.
"""
mutable struct VoltageChangeTermination <: AbstractTerminationCriterion
	end_voltage_change::Real
	tolerance::Real
end


"""
	CurrentTermination(end_current,comparison)

A termination criterion that stops a control step or time-stepping when the current reaches `end_current`.
"""
mutable struct CurrentTermination <: AbstractTerminationCriterion
	end_current::Real
	direction::String
	tolerance::Real

end

"""
	CurrentChangeTermination(end_current_change)

A termination criterion that stops a control step or time-stepping when the current change reaches `end_current_change`.
"""
mutable struct CurrentChangeTermination <: AbstractTerminationCriterion
	end_current_change::Real
	tolerance::Real

end


"""
	CycleIndexTermination(end_cycle_index)

A termination criterion that stops time-stepping when the global cycle_index reaches `end_cycle_index`.
"""
struct CycleIndexTermination <: AbstractTerminationCriterion
	end_cycle_index::Float64
end


"""
	ControlStepIndexTermination(end_control_step_index)

A termination criterion that stops time-stepping when the global control_step_index reaches `end_control_step_index`.
"""
struct ControlStepIndexTermination <: AbstractTerminationCriterion
	end_control_step_index::Float64
end



###########################################################
# Termination criterion for the end of a control step
###########################################################

function get_termination_instance(quantity, target; direction = "discharge")

	if quantity == "Voltage"
		return VoltageTermination(target, direction, 1e-4)
	elseif quantity == "VoltageChange"
		return VoltageChangeTermination(target, 1e-3)
	elseif quantity == "Current"
		return CurrentTermination(target, direction, 1e-4)
	elseif quantity == "CurrentChange"
		return CurrentChangeTermination(target, 1e-4)
	elseif quantity == "Time"
		return TimeTermination(target, 1e-2)
	else
		error("Unknown quantity: $quantity")
	end

end


"""
The get_status_on_termination_region function detects from the current state and control, if we are in the termination region. The functions return two flags :
- before_termination_region : the state is before the termination region for the current control
- after_termination_region : the state is after the termination region for the current control
"""
function get_status_on_termination_region(T::VoltageTermination, state)
	target = T.end_voltage
	tol = T.tolerance #1e-4

	E = only(state.Controller.voltage)

	before = false
	after = false

	if isnothing(T.direction) || T.direction == "discharging"
		before = E > target * (1 + tol)
		after  = E < target * (1 - tol)
	elseif T.direction == "charging"
		before = E < target * (1 - tol)
		after  = E > target * (1 + tol)
	end


	return (before_termination_region = before, after_termination_region = after)
end

function get_status_on_termination_region(T::VoltageChangeTermination, state)
	target = T.end_voltage_change
	tol = T.tolerance #1e-4

	dEdt = state.Controller.dEdt

	before = false
	after = false

	before = abs(dEdt) > target * (1 + tol)
	after  = abs(dEdt) < target * (1 - tol)

	return (before_termination_region = before, after_termination_region = after)
end


function get_status_on_termination_region(T::CurrentTermination, state)
	target = T.end_current
	tol = T.tolerance #1e-4

	I = only(state.Controller.current)

	before = false
	after = false

	if isnothing(T.direction) || T.direction == "discharging"
		before = abs(I) > target * (1 + tol)
		after  = abs(I) < target * (1 - tol)
	elseif T.direction == "charging"
		before = abs(I) < target * (1 - tol)
		after  = abs(I) > target * (1 + tol)
	end

	return (before_termination_region = before, after_termination_region = after)
end

function get_status_on_termination_region(T::CurrentChangeTermination, state)
	target = T.end_current_change
	tol = T.tolerance #1e-4

	dIdt = state.Controller.dIdt

	before = false
	after = false

	before = abs(dIdt) > target * (1 + tol)
	after = abs(dIdt) < target * (1 - tol)

	return (before_termination_region = before, after_termination_region = after)
end

function get_status_on_termination_region(T::TimeTermination, state)
	t = state.Controller.time

	target = T.end_time
	tol = T.tolerance #1e-1

	before = false
	after = false

	before = t < target - tol
	after  = t > target + tol

	return (before_termination_region = before, after_termination_region = after)
end



###########################################################
# Termination criterion for the end of the simulation
###########################################################

function Jutul.timestepping_is_done(C::CycleIndexTermination, simulator, states, substates, reports, solve_recorder)

	s = get_simulator_storage(simulator)

	return s.state.Control.Controller.numberOfCycles >= C.end_cycle_index
end


function Jutul.timestepping_is_done(C::ControlStepIndexTermination, simulator, states, substates, reports, solve_recorder)

	s = get_simulator_storage(simulator)
	return s.state.Control.Controller.current_step_number + 1 > C.end_control_step_index
end


function Jutul.timestepping_is_done(C::VoltageTermination, simulator, states, substates, reports, solve_recorder)

	s = get_simulator_storage(simulator)
	m = get_simulator_model(simulator)


	if m[:Control].system.policy.initialControl == "charging"

		terminate = s.state.Control.ElectricPotential[1] >= C.end_voltage
	elseif m[:Control].system.policy.initialControl == "discharging"

		terminate = s.state.Control.ElectricPotential[1] <= C.end_voltage

	end
	return terminate
end