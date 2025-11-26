###########################################################################################################
# Definition of the controller and some basic utility functions. The controller will be part of the state #
###########################################################################################################

## A controller provides the information to exert the current control

## The controller are implemented as mutable structures and will be attached to the state



mutable struct GenericController <: Controller
	protocol::GenericProtocol
	current_step::AbstractControlStep
	current_step_number::Int
	time::Real
	current::Real
	voltage::Real
	target::Real
	dIdt::Real
	dEdt::Real

	function GenericController(protocol::GenericProtocol, current_step::Union{Nothing, AbstractControlStep}, current_step_number::Int, time::Real, current::Real, voltage::Real; target::Real = 0.0, dEdt::Real = 0.0, dIdt::Real = 0.0)
		new(protocol, current_step, current_step_number, time, current, voltage, target, dIdt, dEdt)
	end
end


@inline function Jutul.numerical_type(x::GenericController)
	return typeof(x.current_step)
end


"""
Function to create (deep) copy of generic controller
"""
function copyController!(cv_copy::GenericController, cv::GenericController)

	cv_copy.protocol = cv.protocol
	cv_copy.current_step = cv.current_step
	cv_copy.current_step_number = cv.current_step_number
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
	cv_copy = GenericController(cv.protocol, cv.current_step, cv.current_step_number, cv.time, cv.current, cv.voltage; target = cv.target, dIdt = cv.dIdt, dEdt = cv.dEdt)

	return cv_copy
end

function Jutul.update_values!(old::GenericController, new::GenericController)

	copyController!(old, new)

end


"""
The setupRegionSwitchFlags function detects from the current state and control, if we are in the switch region. The functions return two flags :
- beforeSwitchRegion : the state is before the switch region for the current control
- afterSwitchRegion : the state is after the switch region for the current control
"""
function setupRegionSwitchFlags(policy::P, state, controller::GenericController) where P <: AbstractControlStep

	step = policy
	termination = step.termination

	# if haskey(state, :ElectricPotential)
	# 	E = only(state.ElectricPotential)
	# 	I = only(state.Current)
	# else
	# 	E = ForwardDiff.value(only(state.Control.ElectricPotential))
	# 	I = ForwardDiff.value(only(state.Control.Current))
	# end

	before = false
	after = false

	progress = get_status_on_termination_region(termination, state)

	before = progress.beforeSwitchRegion
	after = progress.afterSwitchRegion

	# if termination.quantity == "voltage"

	# 	target = termination.value
	# 	tol = 1e-4

	# 	if isnothing(termination.comparison) || termination.comparison == "below"
	# 		before = E > target * (1 + tol)
	# 		after  = E < target * (1 - tol)
	# 	elseif termination.comparison == "above"
	# 		before = E < target * (1 - tol)
	# 		after  = E > target * (1 + tol)
	# 	end

	# elseif termination.quantity == "current"
	# 	target = termination.value
	# 	tol = 1e-4

	# 	if isnothing(termination.comparison) || termination.comparison == "absolute value below"
	# 		before = abs(I) > target * (1 + tol)
	# 		after  = abs(I) < target * (1 - tol)
	# 	elseif termination.comparison == "absolute value above"
	# 		before = abs(I) < target * (1 - tol)
	# 		after  = abs(I) > target * (1 + tol)
	# 	end

	# elseif termination.quantity == "time"
	# 	t = controller.time

	# 	target = termination.value
	# 	tol = 0.1

	# 	before = t < target - tol
	# 	after  = t > target + tol


	# else
	# 	error("Unsupported termination quantity: $(termination.quantity)")
	# end

	return (beforeSwitchRegion = before, afterSwitchRegion = before)

end