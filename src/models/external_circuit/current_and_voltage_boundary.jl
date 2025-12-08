export
	CurrentAndVoltageSystem,
	CurrentAndVoltageDomain,
	VoltageVar,
	CurrentVar,
	sineup,
	AbstractControl


#############################################
# Define the variables in the control model #
#############################################

struct VoltageVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

# The following variable will be added as parameters. In this way, they can also be computed when the whole battery
# model is setup

struct ImaxDischarge <: ScalarVariable end
struct ImaxCharge <: ScalarVariable end

abstract type AbstractProtocol end
abstract type Controller end

##################################################
# Define the Current and voltage control systems #
##################################################

## In Jutul, a system is part of a model and contains data

struct CurrentAndVoltageSystem{P <: AbstractProtocol} <: JutulSystem

	# Control policy
	policy::P

end

struct CurrentAndVoltageDomain <: JutulDomain end

CurrentAndVoltageModel{P} = SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{P}}

Jutul.number_of_cells(::CurrentAndVoltageDomain) = 1

####################################
# Types for the different policies #
####################################

## A policy is used to compute the next control from the current control and state

""" Simple constant current. Stops when lower cut-off value is reached
"""
mutable struct CCPolicy{R} <: AbstractProtocol
	numberOfCycles::Int
	initialControl::String
	ImaxDischarge::R
	ImaxCharge::R
	lowerCutoffVoltage::R
	upperCutoffVoltage::R
	use_ramp_up::Bool
	current_function::Union{Missing, Any}
	tolerances::Dict{String, Real}
	function CCPolicy(
		numberOfCycles::Int,
		initialControl::String,
		lowerCutoffVoltage::Real,
		upperCutoffVoltage::Real,
		use_ramp_up::Bool;
		current_function = missing,
		ImaxDischarge::Real = 0.0,
		ImaxCharge::Real = 0.0,
		T = missing,
		tolerances = Dict("discharging" => 1e-4,
			"charging" => 1e-4),
	)
		T = promote_type(T, typeof(lowerCutoffVoltage), typeof(upperCutoffVoltage), typeof(ImaxDischarge), typeof(ImaxCharge))
		new{T}(numberOfCycles, initialControl, ImaxDischarge, ImaxCharge, lowerCutoffVoltage, upperCutoffVoltage, use_ramp_up, current_function, tolerances)
	end
end


""" Simple constant current, constant voltage policy. Stops when lower cut-off value is reached
"""
mutable struct SimpleCVPolicy{R} <: AbstractProtocol
	current_function::Any
	Imax::R
	voltage::R
	function SimpleCVPolicy(; current_function = missing, Imax::T = 0.0, voltage = missing) where T <: Real
		new{Union{Missing, T}}(current_function, Imax, voltage)
	end
end

""" No policy means that the control is kept fixed throughout the simulation
"""
struct NoPolicy <: AbstractProtocol end


"""
Function Policy
"""
struct FunctionPolicy <: AbstractProtocol
	current_function::Function

	function FunctionPolicy(function_name::String; file_path::Union{Nothing, String} = nothing)
		current_function = setup_function_from_function_name(function_name; file_path = file_path)
		new{}(current_function)
	end

end


################################
# Select the primary variables #
################################

function Jutul.select_primary_variables!(S, system::CurrentAndVoltageSystem, model::SimulationModel)

	S[:ElectricPotential] = VoltageVar()
	S[:Current] = CurrentVar()

end

########################
# Select the equations #
########################

function Jutul.select_equations!(eqs, system::CurrentAndVoltageSystem, model::SimulationModel)

	eqs[:charge_conservation] = CurrentEquation()
	eqs[:control] = ControlEquation()

end


"""
We add the controller in the output
"""
function Jutul.select_minimum_output_variables!(outputs,
	system::CurrentAndVoltageSystem{R},
	model::SimulationModel,
) where {R}

	push!(outputs, :Controller)

end


function get_initial_current(model::CurrentAndVoltageModel)

	if model.system.policy isa GenericProtocol

		return get_initial_current(model.system.policy.steps[1])
	else
		return get_initial_current(model.system.policy)
	end

end


"""
When a step has been computed for a given control up to the convergence requirement, it may happen that the state that is obtained do not fulfill the requirement of the control, meaning that a control switch should have been triggered. The function check_constraints checks that and return false in this case and update the control. The step is then not completed and carries on with the new control
"""
function check_constraints(model, storage)

	policy = model[:Control].system.policy

	state  = storage.state[:Control]
	state0 = storage.state0[:Control]

	controller = state[:Controller]

	arefulfilled = true


	control_steps = policy.steps

	control_step = state[:Controller].step
	control_step_previous = state0[:Controller].step

	step_count_previous = state0[:Controller].step_count
	step_count = state[:Controller].step_count
	step_count_next = step_count + 1

	index = step_count + 1

	if index >= length(policy.steps)
		index_next = 1
		control_step_next = control_steps[index_next]
	else
		index_next = index + 1
		control_step_next = control_steps[index_next]
	end

	rsw = get_status_on_termination_region(control_step.termination, state)
	rswN = get_status_on_termination_region(control_step_next.termination, state)

	if (step_count == step_count_previous && rsw.after_termination_region) || (step_count == step_count_next && !rswN.before_termination_region && index != length(control_steps))

		arefulfilled = false

	end

	return arefulfilled

end

################################################
# Functions to update values in the controller #
################################################



"""
In addition to update the values in all primary variables, we need also to update the values in the controller. We do that by specializing the method perform_step_solve_impl!
"""
function Jutul.update_extra_state_fields!(storage, model::SimulationModel{CurrentAndVoltageDomain, <:CurrentAndVoltageSystem}, dt, time)
	state  = storage.state
	state0 = storage.state0
	policy = model.system.policy
	update_controller!(state, state0, policy, dt)
	return storage
end


function update_controller!(state, state0, policy::AbstractProtocol, dt)


	if policy isa GenericProtocol

		update_control_step_in_controller!(state, state0, policy, dt)

		step = state.Controller.step
		update_values_in_controller!(state, step)
	else
		update_control_type_in_controller!(state, state0, policy, dt)

		update_values_in_controller!(state, policy)
	end

end


#############################
# Assembly of the equations #
#############################

struct CurrentEquation <: JutulEquation end
Jutul.local_discretization(::CurrentEquation, i) = nothing

struct ControlEquation <: JutulEquation end
Jutul.local_discretization(::ControlEquation, i) = nothing

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::ControlEquation, model, dt, ldisc = local_discretization(eq, i))

	I = only(state.Current)

	phi = only(state.ElectricPotential)

	ctrl = state[:Controller]

	if ctrl isa GenericController

		if ctrl.step isa VoltageStep
			v[] = phi - ctrl.target
		elseif ctrl.step isa CurrentStep
			v[] = I - ctrl.target
		elseif ctrl.step isa RestStep
			v[] = I - ctrl.target
		elseif ctrl.step isa PowerStep
			v[] = I - ctrl.target
		else
			error("Step $(ctrl.step) does not have an update equation.")
		end

	else

		if ctrl.target_is_voltage
			v[] = phi - ctrl.target
		else
			v[] = I - ctrl.target
		end
	end

end



function Jutul.update_equation_in_entity!(v, i, state, state0, eq::CurrentEquation, model, dt, ldisc = local_discretization(eq, i))

	# Sign is strange here due to cross term?
	I   = only(state.Current)
	phi = only(state.ElectricPotential)

	v[] = I + phi * 1e-10


end

#####################################################################
# Function to update the controller part in state after convergence #
#####################################################################

""" Update after convergence. Here, we copy the controller to state0
"""
function Jutul.update_after_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces; time = NaN)

	ctrl = storage.state[:Controller]

	copyController!(storage.state0[:Controller], ctrl)

end

########################################################################
# Controller initialization function. Adds the controller to the state #
########################################################################

"""
Function called when setting up state initially. We need to add the fields corresponding to the controller
"""
function Jutul.initialize_extra_state_fields!(state, ::Any, model::CurrentAndVoltageModel; T = Float64)

	policy = model.system.policy


	if policy isa FunctionPolicy

		time = 0.0
		target = 0.0

		target_is_voltage = false

		state[:Controller] = FunctionController(target, time, target_is_voltage)

	elseif policy isa GenericProtocol
		number_of_steps = length(policy.steps)
		step_count = 0
		step_index = 0
		cycle_count = 0
		step = policy.steps[1]
		time_in_step = 0.0
		current = 0.0
		voltage = 0.0
		state[:Controller] = GenericController(policy, step, step_count, step_index, cycle_count, time_in_step, current, voltage)

	end

end


"""
sineup rampup function
"""
function sineup(y1, y2, x1, x2, x)
	#SINEUP Creates a sine ramp function
	#
	#   res = sineup(y1, y2, x1, x2, x) creates a sine ramp
	#   starting at value y1 at point x1 and ramping to value y2 at
	#   point x2 over the vector x.
	y1, y2, x1, x2, x = promote(y1, y2, x1, x2, x)
	T = typeof(x)

	dy = y1 - y2
	dx = abs(x1 - x2)

	res = zero(T)

	if (x >= x1) && (x <= x2)
		res = dy / 2.0 .* cos(pi .* (x - x1) ./ dx) + y1 - (dy / 2)
	end

	if (x > x2)
		res .+= y2
	end

	if (x < x1)
		res .+= y1
	end

	return res

end
