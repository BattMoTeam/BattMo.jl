#######################################################################################################################
# Step switching
#
# During a simulation, the controller moves through the control steps of the protocol. At each Newton iteration, the
# quantities monitored by the terminations are updated, the controller decides whether to switch to the next control
# step, and the target of the control equation is set. When a time step has converged, check_constraints checks that
# the switch happened within the termination region, and otherwise makes the Newton iterations continue (eventually
# cutting the time step).
#######################################################################################################################


"""
Update the controller: first the control step, then the target of the control equation.
"""
function update_controller!(state, state0, protocol::ControlProtocol, dt)

	update_control_step!(state, state0, protocol, dt)

	# Only current steps given as C-rates set this flag
	state.Controller.target_is_c_rate = false

	return update_control_target!(state, state0, state.Controller.step)

end


"""
This function is called at each Newton iteration. It updates the quantities monitored by the terminations and decides
if the control switches to the next control step.

The control only switches if the previous converged state has already entered the termination region of the control
step. Within a time step, a switch is not reverted, to avoid oscillations. The in-step constraint check (see
check_constraints) cuts the time step when a converged state has gone past the termination region, so that the switch
happens within the termination region.
"""
function update_control_step!(state, state0, protocol::ControlProtocol, dt)

	controller = state[:Controller]
	controller0 = state0[:Controller]

	voltage = only(value(state[:ElectricPotential]))
	current = only(value(state[:Current]))
	voltage_0 = only(value(state0[:ElectricPotential]))
	current_0 = only(value(state0[:Current]))

	controller.time = controller0.time + dt
	controller.state_of_charge = compute_state_of_charge(controller0.state_of_charge, dt, protocol.rated_capacity, current)
	controller.dIdt = dt > 0 ? (abs(current) - abs(current_0)) / dt : 0.0
	controller.dEdt = dt > 0 ? (voltage - voltage_0) / dt : 0.0
	controller.current = current
	controller.voltage = voltage

	switch = false

	if !experiment_is_finished(protocol, controller0)

		termination = controller0.step.termination

		if is_last_control_step(protocol, controller0)
			# Nothing follows the last control step, so there is no need to end it within its termination region. It
			# ends as soon as the state is past the termination region, and the simulation stops. Once ended within a
			# time step, it is not resumed.
			switch = controller.step_count != controller0.step_count ||
				get_status_on_termination_region(termination, state).after_termination_region

		elseif !get_status_on_termination_region(termination, state0).before_termination_region
			# We entered the termination region in the previous time step. We consider switching control.
			if controller.step_count == controller0.step_count
				# The control has not changed in this time step. We switch if we are past the termination region.
				switch = get_status_on_termination_region(termination, state).after_termination_region
			else
				# The control has already been switched in a previous Newton iteration. We do not switch back to avoid
				# oscillations. We are anyway within the given tolerance for the control.
				switch = true
			end
		end
	end

	set_control_step!(controller, controller0, protocol, switch ? controller0.step_count + 1 : controller0.step_count)

	return nothing
end


function set_control_step!(controller, controller0, protocol::ControlProtocol, step_count)

	number_of_steps = length(protocol.steps)

	if step_count == controller0.step_count
		# The control step is kept
		controller.step = controller0.step
		controller.step_index = controller0.step_index
		controller.cycle_count = controller0.cycle_count
		controller.step_start_time = controller0.step_start_time

	elseif step_count < number_of_steps
		# Switch to the next control step
		index = step_count + 1
		controller.step = protocol.steps[index]
		controller.step_index = protocol.step_indices[index]
		controller.cycle_count = protocol.cycle_counts[index]
		controller.step_start_time = controller0.time

	else
		# The last control step has terminated. We keep its control for this time step and flag the end of the
		# experiment by setting step_count past the last step. The simulation is stopped by the post-ministep hook set
		# up in solver_configuration.
		controller.step = controller0.step
		controller.step_index = controller0.step_index
		controller.cycle_count = protocol.final_cycle_count
		controller.step_start_time = controller0.step_start_time
	end

	controller.step_count = step_count

	return controller
end


"""
Coulomb counting of the state of charge, with the rated capacity in Ah. The current is positive for discharge.
"""
function compute_state_of_charge(
	previous_state_of_charge::Real,
	dt::Real,
	rated_capacity::Real,
	current::Real;
	η_chg::Real = 1.0,
	η_dis::Real = 1.0,
)

	# Choose efficiency based on the sign convention: I>0 discharge, I<0 charge
	η = current >= 0 ? η_dis : η_chg

	# Coulomb counting update; 3600 converts Ah to As
	soc_next = previous_state_of_charge - (η * current * dt) / (3600.0 * rated_capacity)

	# Clamp to physical bounds
	return clamp(soc_next, 0.0, 1.0)
end


"""
When a time step has converged, the converged state may not fulfill the requirements of the control: it can be past
the termination region of the control step, meaning that the control should have switched, or the control has switched
but the state is not before the termination region of the new step. In these cases, check_constraints returns false
and the Newton iterations continue. If the control cannot switch in this time step, the time step is eventually cut.
In this way, the switches happen within the termination regions. This function is used as global convergence check.
"""
function check_constraints(model, storage)

	protocol = model[:Control].system.protocol

	state = storage.state[:Control]
	controller = state[:Controller]
	controller0 = storage.state0[:Control][:Controller]

	if controller.step_count == controller0.step_count
		if is_last_control_step(protocol, controller)
			# The last control step ends as soon as the state is past its termination region, see update_control_step!,
			# so the time step is not cut for it
			return true
		end
		# The control has not switched: the state should not be past the termination region of the step
		return !get_constraint_status(controller.step.termination, state).after_termination_region
	elseif !experiment_is_finished(protocol, controller)
		# The control has switched: the state should be before the termination region of the new step
		return get_constraint_status(controller.step.termination, state).before_termination_region
	else
		return true
	end

end
