#######################################################################################################################
# External Circuit Model
#
# This script defines the model for the external circuit and the variables and equations that come with it. The
# external circuit model describes the voltage and current boundary of an external circuit and the loading and 
# control of the cell.
#######################################################################################################################



##################################################
# Define the external circuit model 

struct ExternalCircuitSystem{P <: AbstractProtocol} <: JutulSystem
	# Control protocol
	protocol::P
end

struct ExternalCircuitDomain <: JutulDomain end

ExternalCircuitModel{P} = SimulationModel{ExternalCircuitDomain, ExternalCircuitSystem{P}}

Jutul.number_of_cells(::ExternalCircuitDomain) = 1




#########################################################
# Define the variables in the external circuit model 

struct Voltage <: ScalarVariable end
struct Current <: ScalarVariable end

function Jutul.select_primary_variables!(S, system::ExternalCircuitSystem, model::SimulationModel)

	S[:ElectricPotential] = Voltage()
	S[:Current] = Current()

end

"""
We need a more fine-tuned update of the variables when we use a cycling policies, to avoid convergence problem.
"""
function Jutul.update_primary_variable!(state, p::Current, state_symbol, model::P, dx, w) where {Q <: GenericProtocol, P <: ExternalCircuitModel{Q}}

	entity = associated_entity(p)
	active = active_entities(model.domain, entity, for_variables = true)
	v = state[state_symbol]

	nu = length(active)

	time = state.Controller.time
	maximum_current = model.system.protocol.maximum_current

	abs_max = 0.2 * maximum_current
	abs_max = nothing
	rel_max = relative_increment_limit(p)
	maxval = maximum_value(p)
	minval = minimum_value(p)
	scale = variable_scale(p)
	@inbounds for i in 1:nu
		a_i = active[i]
		v[a_i] = update_value(v[a_i], w * dx[i], abs_max, rel_max, minval, maxval, scale)
	end

end



#########################################################
# Define the equations in the external circuit model 


"""
	CurrentBalanceEquation <: JutulEquation

Enforces the electrical charge balance by ensuring the net current
leaving/entering the external terminal is consistent with the internal
electrochemical current (discrete divergence and reaction source terms).
Typically couples to the internal battery domains.
"""
struct CurrentBalanceEquation <: JutulEquation end


"""
	ControlEquation <: JutulEquation

Imposes the external circuit control/constraint:
- VoltageStep:  φ_terminal = target
- CurrentStep:  I_terminal = target
- RestStep:     I_terminal = target (often zero)
- PowerStep:    I_terminal * φ_terminal = target

Used to close the external circuit according to the cycling protocol.
"""
struct ControlEquation <: JutulEquation end


Jutul.local_discretization(::CurrentBalanceEquation, i) = nothing
Jutul.local_discretization(::ControlEquation, i) = nothing


function Jutul.update_equation_in_entity!(v, i, state, state0, eq::CurrentBalanceEquation, model, dt, ldisc = local_discretization(eq, i))

	# Sign is strange here due to cross term?
	I   = only(state.Current)
	phi = only(state.ElectricPotential)

	v[] = I + phi * 1e-10


end

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

function Jutul.select_equations!(eqs, system::ExternalCircuitSystem, model::SimulationModel)

	eqs[:charge_conservation] = CurrentBalanceEquation()
	eqs[:control] = ControlEquation()

end



############################################################
# Define the output variables in the external circuit model 

"""
We add the controller in the output
"""
function Jutul.select_minimum_output_variables!(outputs,
	system::ExternalCircuitSystem{R},
	model::SimulationModel,
) where {R}

	push!(outputs, :Controller)

end


#######################################################
# Setup initial values in the external circuit model 

function get_initial_current(model::ExternalCircuitModel)

	if model.system.protocol isa GenericProtocol

		return get_initial_current(model.system.protocol.steps[1])
	else
		return get_initial_current(model.system.protocol)
	end

end


########################################################################################################
# Intiantiate and update the controller that stores the state of the external circuit and load control

"""
Function called when setting up state initially. Initialize the controller.
"""
function Jutul.initialize_extra_state_fields!(state, ::Any, model::ExternalCircuitModel; T = Float64)

	protocol = model.system.protocol

	if protocol isa FunctionProtocol

		time = 0.0
		target = 0.0

		target_is_voltage = false

		state[:Controller] = FunctionController(target, time, target_is_voltage)

	elseif protocol isa GenericProtocol
		number_of_steps = length(protocol.steps)
		step_count = 0
		step_index = 0
		cycle_count = 0
		step = protocol.steps[1]
		time_in_step = 0.0
		current = 0.0
		voltage = 0.0
		state[:Controller] = GenericController(protocol, step, step_count, step_index, cycle_count, time_in_step, current, voltage)

	end

end


"""
We need to add the specific treatment of the controller variables for GenericProtocol
"""
function Jutul.reset_state_to_previous_state!(
	storage,
	model::SimulationModel{ExternalCircuitDomain, ExternalCircuitSystem{GenericProtocol}, T3, T4},
) where {T3, T4}

	invoke(reset_state_to_previous_state!,
		Tuple{typeof(storage), SimulationModel},
		storage,
		model)

	copyController!(storage.state[:Controller], storage.state0[:Controller])
end


""" Update after convergence. Here, we copy the controller to state0
"""
function Jutul.update_after_step!(storage, domain::ExternalCircuitDomain, model::ExternalCircuitModel, dt, forces; time = NaN)

	ctrl = storage.state[:Controller]

	copyController!(storage.state0[:Controller], ctrl)

end


"""
In addition to update the values in all primary variables, we need also to update the values in the controller. We do that by specializing the method perform_step_solve_impl!
"""
function Jutul.update_extra_state_fields!(storage, model::SimulationModel{ExternalCircuitDomain, <:ExternalCircuitSystem}, dt, time)
	state  = storage.state
	state0 = storage.state0
	policy = model.system.protocol
	update_controller!(state, state0, policy, dt)
	return storage
end

function update_controller!(state, state0, protocol::AbstractProtocol, dt)

	if protocol isa GenericProtocol

		update_control_step_in_controller!(state, state0, protocol, dt)

		step = state.Controller.step
		update_values_in_controller!(state, step)
	else
		update_control_type_in_controller!(state, state0, protocol, dt)

		update_values_in_controller!(state, protocol)
	end

end


########################################################################################################
# Setup contraints when switching between control steps

"""
When a step has been computed for a given control up to the convergence requirement, 
it may happen that the state that is obtained do not fulfill the requirement of the control, 
meaning that a control switch should have been triggered. The function check_constraints checks 
that and return false in this case and updates the control. The step is then not completed and carries on with the new control.
"""
function check_constraints(model, storage)

	policy = model[:Control].system.protocol

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

