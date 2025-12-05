###########################################################################################################
# Definition of the controller and some basic utility functions. The controller will be part of the state #
###########################################################################################################

## A controller provides the information to exert the current control

## The controller are implemented as mutable structures and will be attached to the state



mutable struct GenericController <: Controller
	protocol::GenericProtocol
	step::AbstractControlStep
	step_count::Int
	step_index::Int
	cycle_count::Int
	time::Real
	current::Real
	voltage::Real
	target::Real
	dIdt::Real
	dEdt::Real

	function GenericController(protocol::GenericProtocol, step::Union{Nothing, AbstractControlStep}, step_count::Int, step_index::Int, cycle_count::Int, time::Real, current::Real, voltage::Real; target::Real = 0.0, dEdt::Real = 0.0, dIdt::Real = 0.0)
		new(protocol, step, step_count, step_index, cycle_count, time, current, voltage, target, dIdt, dEdt)
	end
end


@inline function Jutul.numerical_type(x::GenericController)
	return typeof(x.step)
end


"""
Function to create (deep) copy of generic controller
"""
function copyController!(cv_copy::GenericController, cv::GenericController)

	cv_copy.protocol = cv.protocol
	cv_copy.step = cv.step
	cv_copy.step_count = cv.step_count
	cv_copy.step_index = cv.step_index
	cv_copy.cycle_count = cv.cycle_count
	cv_copy.time = cv.time
	cv_copy.current = cv.current
	cv_copy.voltage = cv.voltage
	cv_copy.target = cv.target
	cv_copy.dEdt = cv.dEdt
	cv_copy.dIdt = cv.dIdt

end

"""
Overload function to copy GenericController
"""
function Base.copy(cv::GenericController)
	# Construct using the known type parameter S
	cv_copy = GenericController(cv.protocol, cv.step, cv.step_count, cv.step_index, cv.cycle_count, cv.time, cv.current, cv.voltage; target = cv.target, dIdt = cv.dIdt, dEdt = cv.dEdt)

	return cv_copy
end

function Jutul.update_values!(old::GenericController, new::GenericController)

	copyController!(old, new)

end



