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
		elseif ctrl.step isa StateOfChargeStep
			v[] = phi - ctrl.target
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
		state[:Controller] = GenericController(protocol, step, step_count, step_index, cycle_count, time_in_step, current, voltage, protocol.initial_state_of_charge, T = T)

	end

end


function compute_state_of_charge(previous_state_of_charge::Real,
	dt::Real,
	rated_capacity::Real,
	current::Real;
	η_chg::Real = 1.0,
	η_dis::Real = 1.0)

	# Choose efficiency based on the sign convention: I>0 discharge, I<0 charge
	η = current >= 0 ? η_dis : η_chg

	# Coulomb counting update; 3600 converts Ah to As
	soc_next = previous_state_of_charge - (η * current * dt) / (3600.0 * rated_capacity)

	# Clamp to physical bounds
	return clamp(soc_next, 0.0, 1.0)
end


"""
Implementation of the generic control protocol
"""
function update_control_step_in_controller!(state, state0, protocol::GenericProtocol, dt)
	control_steps = protocol.steps
	cycle_counts = protocol.cycle_counts
	step_indices = protocol.step_indices

	number_of_control_steps = length(protocol.steps)

	# --- Helpers: mapping between controller.step_count (zero-based) and control_steps (1-based) ---

	# Map controller.step_count (which in your logs is 0 for the first step)
	# to 1-based index used for control_steps array
	stepcount_to_index(step_count::Integer) = clamp(step_count + 1, 1, number_of_control_steps)   # stepnum 0 -> index 1
	index_to_stepcount(index::Integer) = clamp(index - 1, 0, number_of_control_steps - 1)      # index 1 -> stepnum 0

	# --- Extract scalars safely ---
	voltage_values = value(state[:ElectricPotential])
	current_values = value(state[:Current])
	voltage_0_values = value(state0[:ElectricPotential])
	current_0_values = value(state0[:Current])

	@assert length(voltage_values) == 1 "Expected scalar ElectricPotential"
	@assert length(current_values) == 1 "Expected scalar Current"
	@assert length(voltage_0_values) == 1 "Expected scalar ElectricPotential (state0)"
	@assert length(current_0_values) == 1 "Expected scalar Current (state0)"

	voltage = first(voltage_values)
	current = first(current_values)
	voltage_0 = first(voltage_0_values)
	current_0 = first(current_0_values)

	# --- Time and derivatives ---
	controller = state[:Controller]

	controller.time = state0.Controller.time + dt
	controller.state_of_charge = compute_state_of_charge(state0.Controller.state_of_charge, dt, protocol.rated_capacity, current)
	controller.dIdt = dt > 0 ? (abs(current) - abs(current_0)) / dt : 0.0
	controller.dEdt = dt > 0 ? (voltage - voltage_0) / dt : 0.0
	controller.current = current
	controller.voltage = voltage

	# --- Determine previous/ current indices and types (clearly mapped) ---
	previous_step_count = state0.Controller.step_count                # e.g. 0 for first step
	previous_step_index = state0.Controller.step_index                # e.g. 0 for first step
	previous_cycle_count = state0.Controller.cycle_count                # e.g. 0 for first cycle
	previous_index = stepcount_to_index(previous_step_count)                     # 1-based index into control_steps
	previous_control_step = state0.Controller.step

	# Compute region switch flags for previous states
	# status_previous = setupRegionSwitchFlags(previous_control_step, state0, controller)
	status_previous = get_status_on_termination_region(previous_control_step.termination, state0)


	if status_previous.before_termination_region
		# We have not entered the switching region in the time step. We are not going to change control.

		step_count = previous_step_count
		step_index = previous_step_index
		cycle_count = previous_cycle_count
		control_step = previous_control_step

	else
		# We entered the switch region in the previous time step. We consider switching control

		# If controller hasn't already changed this Newton iteration, decide
		if controller.step_count == state0.Controller.step_count
			# The control has not changed from previous time step and we want to determine if we should change it.
			# status_current = setupRegionSwitchFlags(previous_control_step, state, controller)
			status = get_status_on_termination_region(previous_control_step.termination, state)

			if status.after_termination_region
				# Attempt to move forward one stepnum
				step_count = previous_step_count + 1   # still zero-based
				index = previous_index + 1


				if index <= number_of_control_steps && step_count <= (number_of_control_steps - 1)
					# 	# Copy the policy step so we can mutate termination without altering original policy
					cycle_count = cycle_counts[index]
					step_index = step_indices[index]
					control_step = control_steps[index]

					# Adjust time-based termination (if needed)
					adjust_time_based_termination_target!(control_step.termination, state0.Controller.time)

				else
					step_count = step_count
					# @info "step_count", step_count
					# @info "index", index
					cycle_count = cycle_counts[step_count]
					step_index = step_indices[step_count]

					control_step = control_steps[1]
				end

			else
				step_count = previous_step_count
				step_index = previous_step_index
				cycle_count = previous_cycle_count
				control_step = previous_control_step

			end

		else
			# controller already advanced this iteration: We do not switch back to avoid oscillation. We are anyway within the given tolerance for the
			# control so that we keep the control as it is.

			step_count = previous_step_count + 1   # still zero-based
			index = previous_index + 1

			if index <= number_of_control_steps && step_count <= (number_of_control_steps - 1)
				# 	# Copy the policy step so we can mutate termination without altering original policy
				cycle_count = cycle_counts[index]
				step_index = step_indices[index]
				control_step = control_steps[index]

				# Adjust time-based termination (if needed)
				adjust_time_based_termination_target!(control_step.termination, state0.Controller.time)

			else
				step_count = step_count
				step_index = step_indices[step_count]
				cycle_count = cycle_counts[step_count]

				control_step = control_steps[1]
			end
		end

	end

	# --- Finalize: clamp stepnum and set controller fields ---
	# Ensure we stay within valid [0, nsteps-1] for stepnum convention
	# step_number = clamp(step_number, 0, max(0, nsteps - 1))

	controller.step_count = step_count
	controller.step_index = step_index
	controller.cycle_count = cycle_count
	controller.step = control_step

	return nothing
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

"""
Implementation of the function policy
"""
function update_control_type_in_controller!(state, state0, policy::FunctionProtocol, dt)
	controller                   = state.Controller
	controller.target_is_voltage = false
	controller.time              = state0.Controller.time + dt

end

function update_values_in_controller!(state, policy::FunctionProtocol)

	controller = state.Controller

	cf = policy.current_function

	I_p = cf(controller.time, value(only(state.ElectricPotential)))

	controller.target = I_p


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

