#############################################################################################################################################################
# Terminations
#
# A termination criterion describes when a control step terminates.
#
# This script defines termination types:
#	- TimeTermination: the control step terminates when the time spent in the step reaches `end_time`
#	- VoltageTermination: the control step terminates when the voltage reaches `end_voltage`
#	- VoltageChangeTermination: the control step terminates when the voltage change rate reaches `end_voltage_change`
#	- CurrentTermination: the control step terminates when the current reaches `end_current`
#	- CurrentChangeTermination: the control step terminates when the current change rate reaches `end_current_change`
#	- StateOfChargeTermination: the control step terminates when the state of charge reaches `end_state_of_charge`
#	- AnyTermination: the control step terminates when one of its conditions has terminated
#	- NoTermination: the control step never terminates, it lasts until the end of the simulation
#
# Except for the time termination, each termination has a comparison, which is one of
#	"above", "below", "absolute value above", "absolute value below"
# and an absolute tolerance defining the width of the termination region around the target.
#
#############################################################################################################################################################


############################################
# Define the termination types

"""
	TimeTermination(end_time, tolerance)

A termination criterion that stops a control step when the time spent in the step reaches `end_time`.
"""
struct TimeTermination{R} <: AbstractTerminationCriterion
    end_time::R
    tolerance::R
end


"""
	NoTermination()

The control step never terminates. It lasts until the end of the simulation.
"""
struct NoTermination <: AbstractTerminationCriterion end


"""
	VoltageTermination(end_voltage, comparison, tolerance)

A termination criterion that stops a control step when the voltage reaches `end_voltage`.
"""
struct VoltageTermination{R} <: AbstractTerminationCriterion
    end_voltage::R
    comparison::String
    tolerance::R
end


"""
	VoltageChangeTermination(end_voltage_change, comparison, tolerance)

A termination criterion that stops a control step when the voltage change rate reaches `end_voltage_change`.
"""
struct VoltageChangeTermination{R} <: AbstractTerminationCriterion
    end_voltage_change::R
    comparison::String
    tolerance::R
end


"""
	CurrentTermination(end_current, comparison, tolerance)

A termination criterion that stops a control step when the current reaches `end_current`.
"""
struct CurrentTermination{R} <: AbstractTerminationCriterion
    end_current::R
    comparison::String
    tolerance::R
end


"""
	CurrentChangeTermination(end_current_change, comparison, tolerance)

A termination criterion that stops a control step when the current change rate reaches `end_current_change`.
"""
struct CurrentChangeTermination{R} <: AbstractTerminationCriterion
    end_current_change::R
    comparison::String
    tolerance::R
end


"""
	StateOfChargeTermination(end_state_of_charge, comparison, tolerance)

A termination criterion that stops a control step when the state of charge reaches `end_state_of_charge`.
"""
struct StateOfChargeTermination{R} <: AbstractTerminationCriterion
    end_state_of_charge::R
    comparison::String
    tolerance::R
end


"""
	AnyTermination(conditions)

A termination criterion that stops a control step when one of the conditions has terminated.
"""
struct AnyTermination <: AbstractTerminationCriterion
    conditions::Vector{AbstractTerminationCriterion}
end


#############################################################
# Setup the termination criteria from the json input

"""
	setup_termination(termination, capacity)

Create a termination criterion from its json description (see the `Termination` definition in the control step schema).
A list of terminations gives an `AnyTermination`. The capacity (in Ah) is used to convert `CRate` terminations to currents.
"""
function setup_termination(termination::AbstractVector, capacity)

    conditions = AbstractTerminationCriterion[setup_termination(t, capacity) for t in termination]

    if length(conditions) == 1
        return conditions[1]
    else
        return AnyTermination(conditions)
    end

end

function setup_termination(termination::AbstractDict, capacity)

    quantity = termination["Quantity"]
    value = float(termination["Value"]) # json integers are converted to floats
    comparison = get(termination, "Comparison", "above")

    # The tolerance is relative to the target value. The width of the termination region matters for the in-step
    # constraint check (see check_constraints): the time step is cut until the switch happens within the region.
    tolerance = get(termination, "Tolerance", default_termination_tolerance(quantity))

    if quantity == "Time"
        return TimeTermination(value, tolerance)
    elseif quantity == "Voltage"
        return VoltageTermination(value, comparison, tolerance * abs(value))
    elseif quantity == "VoltageChange"
        return VoltageChangeTermination(value, comparison, tolerance * abs(value))
    elseif quantity == "Current"
        return CurrentTermination(value, comparison, tolerance * abs(value))
    elseif quantity == "CRate"
        current = value * capacity
        return CurrentTermination(current, comparison, tolerance * abs(current))
    elseif quantity == "CurrentChange"
        return CurrentChangeTermination(value, comparison, tolerance * abs(value))
    elseif quantity == "StateOfCharge"
        return StateOfChargeTermination(value, comparison, tolerance * abs(value))
    else
        error("Unknown termination quantity: $quantity")
    end

end

setup_termination(::Nothing, capacity) = NoTermination()


"""
Default relative tolerance of a termination. The time tolerance is absolute, in seconds. The change rates are noisy,
so a wide termination region is used for them.
"""
function default_termination_tolerance(quantity)
    if quantity == "Time"
        return 1.0e-3
    elseif quantity in ["VoltageChange", "CurrentChange"]
        return 0.9
    elseif quantity in ["Current", "CRate"]
        return 1.0e-4
    else
        return 1.0e-3
    end
end


#############################################################
# Status of a state with respect to a termination

"""
The get_status_on_termination_region function detects from the current state and control, if we are in the termination region. The functions return two flags :
- before_termination_region : the state is before the termination region for the current control
- after_termination_region : the state is after the termination region for the current control
"""
function get_status_on_termination_region(value, target, comparison::AbstractString, tolerance)

    if comparison == "absolute value above" || comparison == "absolute value below"
        value = abs(value)
    end

    if comparison == "above" || comparison == "absolute value above"
        before = value < target - tolerance
        after = value > target + tolerance
    elseif comparison == "below" || comparison == "absolute value below"
        before = value > target + tolerance
        after = value < target - tolerance
    else
        error("Termination comparison $comparison not recognized.")
    end

    return (before_termination_region = before, after_termination_region = after)
end

function get_status_on_termination_region(T::VoltageTermination, state)
    E = only(state.Controller.voltage)
    return get_status_on_termination_region(E, T.end_voltage, T.comparison, T.tolerance)
end

function get_status_on_termination_region(T::VoltageChangeTermination, state)
    dEdt = state.Controller.dEdt
    return get_status_on_termination_region(dEdt, T.end_voltage_change, T.comparison, T.tolerance)
end

function get_status_on_termination_region(T::CurrentTermination, state)
    current = only(state.Controller.current)
    return get_status_on_termination_region(current, T.end_current, T.comparison, T.tolerance)
end

function get_status_on_termination_region(T::CurrentChangeTermination, state)
    dIdt = state.Controller.dIdt
    return get_status_on_termination_region(dIdt, T.end_current_change, T.comparison, T.tolerance)
end

function get_status_on_termination_region(T::StateOfChargeTermination, state)
    state_of_charge = only(state.Controller.state_of_charge)
    return get_status_on_termination_region(state_of_charge, T.end_state_of_charge, T.comparison, T.tolerance)
end

function get_status_on_termination_region(T::TimeTermination, state)
    controller = state.Controller
    time_in_step = controller.time - controller.step_start_time
    return get_status_on_termination_region(time_in_step, T.end_time, "above", T.tolerance)
end

function get_status_on_termination_region(T::NoTermination, state)
    return (before_termination_region = true, after_termination_region = false)
end

function get_status_on_termination_region(T::AnyTermination, state)
    return combine_termination_statuses([get_status_on_termination_region(condition, state) for condition in T.conditions])
end

function combine_termination_statuses(statuses)
    # We are before the termination region only if all conditions are, and after it as soon as one condition is
    before = all(status.before_termination_region for status in statuses)
    after = any(status.after_termination_region for status in statuses)

    return (before_termination_region = before, after_termination_region = after)
end


"""
Status used in the in-step constraint check (see check_constraints). Time conditions are treated as never reached
there, because cutting the time step to end a step within the small time tolerance would require many time step
cuts. The time stepping lands on the end of a time termination instead, see time_stepping.jl.
"""
get_constraint_status(T::AbstractTerminationCriterion, state) = get_status_on_termination_region(T, state)

get_constraint_status(T::TimeTermination, state) = get_status_on_termination_region(NoTermination(), state)

function get_constraint_status(T::AnyTermination, state)
    return combine_termination_statuses([get_constraint_status(condition, state) for condition in T.conditions])
end


#############################################################
# Breakpoints of the terminations, see next_breakpoint in control_steps.jl

# Breakpoints closer than this (in seconds) to the current time are considered reached
const BREAKPOINT_TOLERANCE = 1.0e-6

next_breakpoint(T::AbstractTerminationCriterion, time_in_step) = Inf

function next_breakpoint(T::TimeTermination, time_in_step)
    return T.end_time > time_in_step + BREAKPOINT_TOLERANCE ? T.end_time : Inf
end

function next_breakpoint(T::AnyTermination, time_in_step)
    return minimum(next_breakpoint(condition, time_in_step) for condition in T.conditions)
end
