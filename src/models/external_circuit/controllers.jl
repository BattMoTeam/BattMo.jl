###########################################################################################################
# Definition of the controller and some basic utility functions. The controller will be part of the state #
###########################################################################################################

## A controller provides the information to exert the current control

## The controller are implemented as mutable structures and will be attached to the state

abstract type Controller end

mutable struct GenericController <: Controller
	protocol::GenericProtocol
	current_step::AbstractControlStep
	current_step_number::Int
	time::Real
	target::Real
	dIdt::Real
	dEdt::Real

	function GenericController(protocol::GenericProtocol, current_step::Union{Nothing, AbstractControlStep}, current_step_number::Int, time::Real; target::Real = 0.0, dEdt::Real = 0.0, dIdt::Real = 0.0)
		new(protocol, current_step, current_step_number, time, target, dIdt, dEdt)
	end
end

GenericController() = GenericController(nothing, nothing, 0, 0.0)