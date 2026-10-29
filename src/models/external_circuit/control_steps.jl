#######################################################################################################################
# Control steps
#
# This script defines different control step types:
#	- CurrentStep: current controlled control step
#	- VoltageStep: voltage controlled control step
#	- RestStep: control step where the current is set to zero
#	- PowerStep: power controlled control step
#	- CurrentFunctionStep: the current is given by a function of time and voltage
#	- CurrentSeriesStep: the current is interpolated from a time series, with voltage limits
#
# The control steps are set up from their json description, see setup_control_step in protocol.jl
#######################################################################################################################

export sineup

##################################################
# Define the abstract type

abstract type AbstractControlStep end


##################################################
# Define the different control step types

"""
Constant current, given in A or, if `is_c_rate` is true, as a C-rate. A C-rate is converted to a current with the
capacity parameter of the external circuit model, see the control equation. If `use_ramp_up` is true, the current is
ramped up at the beginning of the simulation.
"""
struct CurrentStep{R} <: AbstractControlStep
    value::R
    is_c_rate::Bool
    direction::String
    termination::AbstractTerminationCriterion
    use_ramp_up::Bool
    ramp_up_time::Float64
end

function CurrentStep(value, direction, termination; is_c_rate = false, use_ramp_up = false, ramp_up_time = 0.0)
    return CurrentStep(value, is_c_rate, direction, termination, use_ramp_up, Float64(ramp_up_time))
end

"""
Constant voltage, given in V.
"""
struct VoltageStep{R} <: AbstractControlStep
    value::R
    termination::AbstractTerminationCriterion
end

"""
Zero current.
"""
struct RestStep <: AbstractControlStep
    termination::AbstractTerminationCriterion
end

"""
Constant power, given in W.
"""
struct PowerStep{R} <: AbstractControlStep
    value::R
    direction::String
    termination::AbstractTerminationCriterion
end

"""
The current is given by a function `current_function(time, voltage)` where time is the time since the start of the
step. The current is positive for discharge.
"""
struct CurrentFunctionStep <: AbstractControlStep
    current_function::Function
    termination::AbstractTerminationCriterion
end

"""
The current is interpolated from a time series, where the times are relative to the start of the step. The current is
positive for discharge. When the voltage reaches the lower limit during discharge or the upper limit during charge,
the step switches to voltage control at the limit.
"""
struct CurrentSeriesStep{R} <: AbstractControlStep
    times::Vector{R}
    current_function::Any # interpolator, callable as current_function(time)
    lower_voltage_limit::R
    upper_voltage_limit::R
    termination::AbstractTerminationCriterion
end

function setup_current_series_step(times::AbstractVector, currents::AbstractVector, lower_voltage_limit, upper_voltage_limit, termination)

    @assert length(times) == length(currents) "Times and Currents must have the same length"
    @assert length(times) >= 1 "Times and Currents must be non-empty"
    @assert issorted(times, lt = <) "Times must be strictly increasing"

    R = promote_type(eltype(times), eltype(currents), typeof(lower_voltage_limit), typeof(upper_voltage_limit))
    times = convert(Vector{R}, times)
    current_function = get_1d_interpolator(times, convert(Vector{R}, currents), cap_endpoints = true)

    return CurrentSeriesStep{R}(times, current_function, R(lower_voltage_limit), R(upper_voltage_limit), termination)
end


###########################################################################
# Value of a CurrentStep at a given time (in A or as C-rate, see CurrentStep), including the ramp up and the sign

function get_current_value(step::CurrentStep, time::Real)

    time, current, ramp_up_time = promote(time, step.value, step.ramp_up_time)

    if step.use_ramp_up && time <= ramp_up_time
        value = sineup(0.0, current, 0.0, ramp_up_time, time)
    else
        value = current
    end

    return adjust_current_sign(value, step.direction)
end

"""
The currents are positive for discharge and negative for charge.
"""
function adjust_current_sign(I, direction)
    if direction == "discharging"
        return I
    elseif direction == "charging"
        return -I
    else
        error("The direction $direction is not recognized.")
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


##################################################
# Initial current values. The capacity (in Ah) is used for C-rates.

function initial_current(step::CurrentStep, capacity)
    value = get_current_value(step, 0.0)
    return step.is_c_rate ? value * capacity : value
end

# For power, voltage and function control, the current is not known before solving. Zero is used as initial guess.

initial_current(step::AbstractControlStep, capacity) = 0.0

function initial_current(step::CurrentSeriesStep, capacity)
    return step.current_function(0.0)
end


##################################################
# Breakpoints: times (relative to the start of the step) that the time stepping should land on exactly, see
# time_stepping.jl. Returns the first breakpoint after `time_in_step`, or Inf if there is none.

function next_breakpoint(step::AbstractControlStep, time_in_step)
    return next_breakpoint(step.termination, time_in_step)
end

function next_breakpoint(step::CurrentSeriesStep, time_in_step)
    index = findfirst(t -> t > time_in_step + BREAKPOINT_TOLERANCE, step.times)
    series_breakpoint = isnothing(index) ? Inf : step.times[index]
    return min(series_breakpoint, next_breakpoint(step.termination, time_in_step))
end


##################################################
# Maximum current of a step, used to limit the Newton updates of the current. Zero means unknown.

maximum_current(step::AbstractControlStep, capacity) = 0.0
maximum_current(step::CurrentStep, capacity) = step.is_c_rate ? abs(step.value * capacity) : abs(step.value)


##################################################
# Control target
#
# Given the control step, the target value of the control equation is set in the controller, together with whether
# the target is a voltage or a current.

function update_control_target!(state, state0, step::PowerStep)

    power = step.value
    voltage = state.Controller.voltage

    current = power / voltage

    state.Controller.target = adjust_current_sign(current, step.direction)
    return state.Controller.target_is_voltage = false

end

function update_control_target!(state, state0, step::CurrentStep)

    # The ramp up is applied with respect to the simulation time, so that only a current step at the beginning of
    # the simulation is ramped up
    state.Controller.target = get_current_value(step, state.Controller.time)
    state.Controller.target_is_voltage = false
    return state.Controller.target_is_c_rate = step.is_c_rate

end

function update_control_target!(state, state0, step::VoltageStep)
    state.Controller.target = step.value
    return state.Controller.target_is_voltage = true
end

function update_control_target!(state, state0, step::RestStep)
    state.Controller.target = 0.0
    return state.Controller.target_is_voltage = false
end

function update_control_target!(state, state0, step::CurrentFunctionStep)

    controller = state.Controller
    time = controller.time - controller.step_start_time

    controller.target = step.current_function(time, controller.voltage)
    return controller.target_is_voltage = false

end

function update_control_target!(state, state0, step::CurrentSeriesStep)

    # Relative tolerance for voltage hysteresis: if the voltage is within this fraction of the limit, we remain in
    # voltage control to avoid oscillating between current and voltage control during the Newton iterations.
    hysteresis_tolerance = 1.0e-4

    controller = state.Controller
    time = controller.time - controller.step_start_time
    E = controller.voltage

    current = step.current_function(time)

    # Determine which voltage limit is relevant based on the sign of the prescribed current, then check whether the
    # voltage has crossed that limit.
    if current > 0
        target_is_voltage = E <= step.lower_voltage_limit
    elseif current < 0
        target_is_voltage = E >= step.upper_voltage_limit
    else
        target_is_voltage = false
    end

    # Hysteresis: if the step was already in voltage control in the previous converged state, stay in voltage control
    # as long as the limit is still binding.
    controller0 = state0.Controller
    if controller0.step_count == controller.step_count && controller0.target_is_voltage && !target_is_voltage
        if current > 0 && E <= step.lower_voltage_limit * (1 + hysteresis_tolerance)
            target_is_voltage = true
        elseif current < 0 && E >= step.upper_voltage_limit * (1 - hysteresis_tolerance)
            target_is_voltage = true
        end
    end

    if target_is_voltage
        controller.target = current >= 0 ? step.lower_voltage_limit : step.upper_voltage_limit
    else
        controller.target = current
    end
    return controller.target_is_voltage = target_is_voltage

end
