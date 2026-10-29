#######################################################################################################################
# Time stepping
#
# The time step selector below makes the time stepping land exactly on the breakpoints of the control steps (see
# next_breakpoint in control_steps.jl): the end of a step with a time termination and the time points of a current
# series.
#######################################################################################################################


"""
	ControlStepTimestepSelector()

Time step selector that makes the time stepping land exactly on the breakpoints of the control steps. The breakpoints
are relative to the start of a step, which is only known once the step has started, so they are computed during the
simulation from the controller of the last converged state.

Jutul takes the minimum of the time steps proposed by the selectors and then clamps it to the allowed increase and
decrease of the time step. The limit is therefore also applied in `valid_timestep`, which is called after the clamping.
"""
mutable struct ControlStepTimestepSelector <: Jutul.AbstractTimestepSelector
	maximum_timestep::Float64 # limit for the next time step, Inf if there is none
end

ControlStepTimestepSelector() = ControlStepTimestepSelector(Inf)

function Jutul.pick_first_timestep(sel::ControlStepTimestepSelector, sim, config, dT, forces)
	return update_maximum_timestep!(sel, sim)
end

function Jutul.pick_next_timestep(sel::ControlStepTimestepSelector, sim, config, dt_prev, dT, forces, reports, current_reports, step_index, new_step)
	return update_maximum_timestep!(sel, sim)
end

Jutul.valid_timestep(sel::ControlStepTimestepSelector, dt) = min(dt, sel.maximum_timestep)


function update_maximum_timestep!(sel::ControlStepTimestepSelector, sim)

	storage = get_simulator_storage(sim)
	protocol = get_simulator_model(sim)[:Control].system.protocol
	controller = storage.state0[:Control][:Controller]

	sel.maximum_timestep = time_to_next_breakpoint(protocol, controller, storage.state0[:Control])

	return sel.maximum_timestep
end


"""
Time from the last converged state to the next breakpoint of the control steps. If the state is in the termination
region of the current step, the control will probably switch in the next time step, so that the breakpoints of the next
step (starting now) are also taken into account.
"""
function time_to_next_breakpoint(protocol::ControlProtocol, controller, state)

	if experiment_is_finished(protocol, controller)
		return Inf
	end

	step = controller.step
	time_in_step = value(controller.time - controller.step_start_time)

	dt = next_breakpoint(step, time_in_step) - time_in_step

	next_index = controller.step_count + 2
	if next_index <= length(protocol.steps) && !get_status_on_termination_region(step.termination, state).before_termination_region
		dt = min(dt, next_breakpoint(protocol.steps[next_index], 0.0))
	end

	return dt
end
