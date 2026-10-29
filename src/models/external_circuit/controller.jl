#######################################################################################################################
# Controller
#
# The controller is the state of the external circuit control during a simulation: the current control step, the
# quantities monitored by the terminations and the target of the control equation. It is attached to the state of the
# external circuit model.
#######################################################################################################################


mutable struct ExternalCircuitController{R <: Real, I <: Int}
	protocol::ControlProtocol
	step::AbstractControlStep
	step_count::I              # global index of the current control step, starting at zero
	step_index::I              # index of the current control step within its cycle, starting at zero
	cycle_count::I             # number of the current cycle, starting at zero
	time::R
	step_start_time::R         # time at which the current control step started
	current::R
	voltage::R
	state_of_charge::R
	target::R                  # target value of the control equation
	target_is_voltage::Bool    # whether the target is a voltage or a current
	target_is_c_rate::Bool     # whether a current target is given as a C-rate, see the control equation
	dIdt::R
	dEdt::R
end

function ExternalCircuitController(
	protocol::ControlProtocol,
	step::AbstractControlStep,
	step_count::Int,
	step_index::Int,
	cycle_count::Int,
	time::Real,
	current::Real,
	voltage::Real,
	state_of_charge::Real;
	step_start_time::Real = 0.0,
	target::Real = 0.0,
	target_is_voltage::Bool = false,
	target_is_c_rate::Bool = false,
	dEdt::Real = 0.0,
	dIdt::Real = 0.0,
	T = Float64,
)
	T = promote_type(T, typeof(time), typeof(step_start_time), typeof(current), typeof(voltage), typeof(state_of_charge), typeof(target), typeof(dEdt), typeof(dIdt))
	ExternalCircuitController{T, typeof(step_index)}(protocol, step, step_count, step_index, cycle_count, time, step_start_time, current, voltage, state_of_charge, target, target_is_voltage, target_is_c_rate, dIdt, dEdt)
end


"""
	initial_controller(protocol; T = Float64)

Controller at the start of a simulation, in the first control step of the protocol.
"""
function initial_controller(protocol::ControlProtocol; T = Float64)
	return ExternalCircuitController(protocol, protocol.steps[1], 0, protocol.step_indices[1], protocol.cycle_counts[1], 0.0, 0.0, 0.0, protocol.initial_state_of_charge; T = T)
end


@inline function Jutul.numerical_type(x::ExternalCircuitController{R, I}) where {R, I}
	return R
end


########################################################################
# Copy of the controller

function copy_controller!(cv_copy::ExternalCircuitController, cv::ExternalCircuitController)

	cv_copy.protocol = cv.protocol
	cv_copy.step = cv.step
	cv_copy.step_count = cv.step_count
	cv_copy.step_index = cv.step_index
	cv_copy.cycle_count = cv.cycle_count
	cv_copy.time = cv.time
	cv_copy.step_start_time = cv.step_start_time
	cv_copy.current = cv.current
	cv_copy.voltage = cv.voltage
	cv_copy.state_of_charge = cv.state_of_charge
	cv_copy.target = cv.target
	cv_copy.target_is_voltage = cv.target_is_voltage
	cv_copy.target_is_c_rate = cv.target_is_c_rate
	cv_copy.dEdt = cv.dEdt
	cv_copy.dIdt = cv.dIdt

	return cv_copy
end

function Base.copy(cv::ExternalCircuitController)
	return ExternalCircuitController(cv.protocol, cv.step, cv.step_count, cv.step_index, cv.cycle_count, cv.time, cv.current, cv.voltage, cv.state_of_charge;
		step_start_time = cv.step_start_time, target = cv.target, target_is_voltage = cv.target_is_voltage, target_is_c_rate = cv.target_is_c_rate,
		dIdt = cv.dIdt, dEdt = cv.dEdt)
end

function Jutul.update_values!(old::ExternalCircuitController, new::ExternalCircuitController)
	return copy_controller!(old, new)
end
