export
    CurrentAndVoltageSystem,
    CurrentAndVoltageDomain,
    VoltageVar,
    CurrentVar,
    sineup,
    SimpleCVPolicy,
    CyclingCVPolicy,
    OperationalMode,
    InputCurrentPolicy,
    RestPolicy,
    SequencePolicy

################################
# Define the operational modes #
################################

@enum OperationalMode cc_discharge1 cc_discharge2 cc_charge1 cv_charge2 rest discharge charging discharging none

function getSymbol(ctrlType::OperationalMode)
    if ctrlType == cc_discharge1
        return :cc_discharge1
    elseif ctrlType == cc_discharge2
        return :cc_discharge2
    elseif ctrlType == cc_charge1
        return :cc_charge1
    elseif ctrlType == cv_charge2
        return :cv_charge2
    else
        error("Unsupported CCCV control type: $ctrlType")
    end
end

#############################################
# Define the variables in the control model #
#############################################

struct VoltageVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

# The following variable will be added as parameters. In this way, they can also be computed when the whole battery
# model is setup

struct ImaxDischarge <: ScalarVariable end
struct ImaxCharge <: ScalarVariable end

##################################################
# Define the Current and voltage control systems #
##################################################

## In Jutul, a system is part of a model and contains data

abstract type AbstractPolicy end

struct CurrentAndVoltageSystem{P <: AbstractPolicy} <: JutulSystem

    # Control policy
    policy::P

end

struct CurrentAndVoltageDomain <: JutulDomain end

CurrentAndVoltageModel{P} = SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{P}}

Jutul.number_of_cells(::CurrentAndVoltageDomain) = 1

####################################
# Types for the different policies #
####################################

abstract type AbstractSequenceStep end

struct PolicyStep{P <: AbstractPolicy} <: AbstractSequenceStep
    policy::P
end

mutable struct RestPolicy{R} <: AbstractPolicy
    duration::R
end

mutable struct SequencePolicy{R} <: AbstractPolicy
    steps::Vector{AbstractSequenceStep}
    ImaxDischarge::R
    ImaxCharge::R
    use_ramp_up::Bool
    rampup_time::R
end

function SequencePolicy(
        steps::Vector{AbstractSequenceStep},
        ImaxDischarge::R,
        ImaxCharge::R,
        use_ramp_up::Bool,
        rampup_time::R,
    ) where {R <: Real}
    return SequencePolicy{R}(steps, ImaxDischarge, ImaxCharge, use_ramp_up, rampup_time)
end

function SequencePolicy(
        steps::AbstractVector,
        ImaxDischarge::Real,
        ImaxCharge::Real,
        use_ramp_up::Bool,
        rampup_time::Real,
    )
    normalized_steps = AbstractSequenceStep[]
    for step in steps
        if step isa AbstractSequenceStep
            push!(normalized_steps, step)
        elseif step isa AbstractPolicy
            push!(normalized_steps, PolicyStep(step))
        else
            error("Sequence step $(typeof(step)) must be an AbstractPolicy or AbstractSequenceStep")
        end
    end
    T = promote_type(typeof(ImaxDischarge), typeof(ImaxCharge), typeof(rampup_time))
    return SequencePolicy{T}(normalized_steps, T(ImaxDischarge), T(ImaxCharge), use_ramp_up, T(rampup_time))
end

## A policy is used to compute the next control from the current control and state

""" Simple constant current. Stops when lower cut-off value is reached
"""
mutable struct CCPolicy{R} <: AbstractPolicy
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
            tolerances = Dict(
                "discharging" => 1.0e-4,
                "charging" => 1.0e-4,
            ),
        )
        T = promote_type(T, typeof(lowerCutoffVoltage), typeof(upperCutoffVoltage), typeof(ImaxDischarge), typeof(ImaxCharge))
        return new{T}(numberOfCycles, initialControl, ImaxDischarge, ImaxCharge, lowerCutoffVoltage, upperCutoffVoltage, use_ramp_up, current_function, tolerances)
    end
end


""" Simple constant current, constant voltage policy. Stops when lower cut-off value is reached
"""
mutable struct SimpleCVPolicy{R} <: AbstractPolicy
    current_function::Any
    Imax::R
    voltage::R
    function SimpleCVPolicy(; current_function = missing, Imax::T = 0.0, voltage = missing) where {T <: Real}
        return new{Union{Missing, T}}(current_function, Imax, voltage)
    end
end


"""
Function Policy
"""
struct FunctionPolicy <: AbstractPolicy
    current_function::Function

    function FunctionPolicy(function_name::String; file_path::Union{Nothing, String} = nothing)
        current_function = setup_function_from_function_name(function_name; file_path = file_path)
        return new(current_function)
    end

end

"""
Input current series policy.

Applies a prescribed current time series (times in seconds, currents in amperes).
The `times` vector must be strictly increasing. A Jutul linear interpolator
(`get_1d_interpolator`) is used to evaluate the current at any simulation time.
Voltage limits are enforced: if the voltage response exceeds `upperCutoffVoltage` or
falls below `lowerCutoffVoltage`, the controller switches to constant-voltage control
at the respective limit. The lengths of `times` and `currents` must match.

Voltage limits may be set to `±Inf` if they should not be enforced.
"""
mutable struct InputCurrentPolicy{R} <: AbstractPolicy
    times::Vector{R}
    current_function::Any      # get_1d_interpolator(times, currents) – callable as f(t)
    lowerCutoffVoltage::R
    upperCutoffVoltage::R

    function InputCurrentPolicy(
            times::AbstractVector,
            currents::AbstractVector,
            lowerCutoffVoltage::Real,
            upperCutoffVoltage::Real,
        )
        @assert length(times) == length(currents) "times and currents must have the same length"
        @assert length(times) >= 1 "times and currents must be non-empty"
        @assert issorted(times, lt = <) "times must be strictly increasing"
        T = promote_type(eltype(times), eltype(currents), typeof(lowerCutoffVoltage), typeof(upperCutoffVoltage))
        current_function = get_1d_interpolator(times, currents, cap_endpoints = true)
        return new{T}(convert(Vector{T}, times), current_function, T(lowerCutoffVoltage), T(upperCutoffVoltage))
    end
end

""" Standard CC-CV policy
"""
mutable struct CyclingCVPolicy{R, I} <: AbstractPolicy

    ImaxDischarge::R
    ImaxCharge::R
    lowerCutoffVoltage::R
    upperCutoffVoltage::R
    dIdtLimit::R
    dEdtLimit::R
    cvCurrentCutoff::Union{R, Missing}
    initialControl::OperationalMode
    numberOfCycles::I
    tolerances::Any
    use_ramp_up::Bool
    rampup_time::R
    current_function::Any

end

function CyclingCVPolicy(
        lowerCutoffVoltage,
        upperCutoffVoltage,
        dIdtLimit,
        dEdtLimit,
        initialControl::String,
        numberOfCycles;
        ImaxDischarge = 0 * lowerCutoffVoltage,
        ImaxCharge = 0 * lowerCutoffVoltage,
        use_ramp_up::Bool = false,
        rampup_time = zero(lowerCutoffVoltage),
        current_function = missing,
        cv_current_cutoff = missing,
    )

    if initialControl == "charging"
        initialControl = charging
    elseif initialControl == "discharging"
        initialControl = discharging
    else
        error("InitialControl $initialControl not recognized")
    end

    if isnothing(cv_current_cutoff)
        cv_current_cutoff = missing
    end

    tolerances = (
        cc_discharge1 = 1.0e-4,
        cc_discharge2 = 0.9,
        cc_charge1 = 1.0e-4,
        cv_charge2 = 0.9,
    )

    return CyclingCVPolicy(
        ImaxDischarge,
        ImaxCharge,
        lowerCutoffVoltage,
        upperCutoffVoltage,
        dIdtLimit,
        dEdtLimit,
        cv_current_cutoff,
        initialControl,
        numberOfCycles,
        tolerances,
        use_ramp_up,
        rampup_time,
        current_function,
    )
end

################################
# Select the primary variables #
################################

function Jutul.select_primary_variables!(S, system::CurrentAndVoltageSystem, model::SimulationModel)

    S[:ElectricPotential] = VoltageVar()
    return S[:Current] = CurrentVar()

end

########################
# Select the equations #
########################

function Jutul.select_equations!(eqs, system::CurrentAndVoltageSystem, model::SimulationModel)

    eqs[:charge_conservation] = CurrentEquation()
    return eqs[:control] = ControlEquation()

end

#########################
# Select the parameters #
#########################

function Jutul.select_parameters!(
        S,
        system::CurrentAndVoltageSystem{CCPolicy{R}},
        model::SimulationModel,
    ) where {R}
    S[:ImaxDischarge] = ImaxDischarge()
    return S[:ImaxCharge] = ImaxCharge()
end

function Jutul.select_parameters!(
        S,
        system::CurrentAndVoltageSystem{SimpleCVPolicy{R}},
        model::SimulationModel,
    ) where {R}
    return S[:ImaxDischarge] = ImaxDischarge()

end

function Jutul.select_parameters!(
        S,
        system::CurrentAndVoltageSystem{CyclingCVPolicy{R, I}},
        model::SimulationModel,
    ) where {R, I}
    S[:ImaxDischarge] = ImaxDischarge()
    return S[:ImaxCharge] = ImaxCharge()
end

function Jutul.select_parameters!(
        S,
        system::CurrentAndVoltageSystem{SequencePolicy{R}},
        model::SimulationModel,
    ) where {R}
    S[:ImaxDischarge] = ImaxDischarge()
    return S[:ImaxCharge] = ImaxCharge()
end


#######################################
# Types for the different controllers #
#######################################

## A controller provides the information to exert the current control

## The controller are implemented as mutable structures and will be attached to the state

abstract type Controller end

mutable struct FunctionController{R <: Real} <: Controller
    target::R
    time::R
    target_is_voltage::Bool
end

FunctionController() = FunctionController(0.0, 0.0, false)

mutable struct CCController{I <: Integer, R <: Real} <: Controller
    numberOfCycles::I
    target::R
    time::R
    target_is_voltage::Bool
    ctrlType::Union{Missing, String}

end

CCController() = CCController(0, 0.0, 0.0, false, missing)

## SimpleControllerCV

mutable struct SimpleControllerCV{R} <: Controller

    target::R
    time::R
    target_is_voltage::Bool
    ctrlType::OperationalMode

end

SimpleControllerCV() = SimpleControllerCV(0.0, 0.0, true, none)

## CcCvController

mutable struct CcCvController{R, I <: Integer} <: Controller

    maincontroller::SimpleControllerCV{R}
    numberOfCycles::I
    dEdt::Union{R, Missing}
    dIdt::Union{R, Missing}
    ramp_start_time::R
    ramp_duration::R
    ramp_start_target::R # target value at beginning of ramp (actual current or actual voltage)
    ramp_end_target::R # target the controller should reach at the end of the ramp (eg ImaxDischarge, lowerCutoffVoltage etc)
    ramp_target_is_voltage::Bool # current or voltage
    ramp_active::Bool # to keep track if the controller is in the transition

end

function CcCvController()

    maincontroller = SimpleControllerCV()

    return CcCvController(maincontroller, 0, missing, missing, 0.0, 0.0, 0.0, 0.0, false, false)

end


## Helper for CcCvController so that the fields of SimpleControllerCV appears as inherrited.

function Base.getproperty(c::CcCvController, f::Symbol)
    if f in fieldnames(SimpleControllerCV)
        return getfield(c.maincontroller, f)
    else
        return getfield(c, f)
    end
end

function Base.setproperty!(c::CcCvController, f::Symbol, v)
    return if f in fieldnames(SimpleControllerCV)
        setfield!(c.maincontroller, f, v)
    else
        setfield!(c, f, v)
    end
end

@inline function Jutul.numerical_type(x::CCController{I, R}) where {I, R}
    return R
end

@inline function Jutul.numerical_type(x::FunctionController{R}) where {R}
    return R
end

@inline function Jutul.numerical_type(x::SimpleControllerCV{R}) where {R}
    return R
end

@inline function Jutul.numerical_type(x::CcCvController{R, I}) where {R, I}
    return R
end

## InputCurrentController

mutable struct InputCurrentController{R} <: Controller
    target::R
    time::R
    target_is_voltage::Bool
end

InputCurrentController() = InputCurrentController(0.0, 0.0, false)

@inline function Jutul.numerical_type(x::InputCurrentController{R}) where {R}
    return R
end

## RestController

mutable struct RestController{R} <: Controller
    target::R
    time::R
    target_is_voltage::Bool
    ctrlType::OperationalMode
end

RestController() = RestController(0.0, 0.0, false, rest)

@inline function Jutul.numerical_type(x::RestController{R}) where {R}
    return R
end

## SequenceController

mutable struct SequenceController{R} <: Controller
    # Keep data for all the controllers to get a concrete controller for Jutul
    step_index::Int
    step_start_time::R
    target::R
    # Global elapsed controller time. step_start_time tracks the start of the
    # active sequence step, so local step time is time - step_start_time.
    time::R
    target_is_voltage::Bool
    ctrlType::Any
    numberOfCycles::Int
    dEdt::Union{R, Missing}
    dIdt::Union{R, Missing}
    ramp_start_time::R
    ramp_duration::R
    ramp_start_target::R
    ramp_end_target::R
    ramp_target_is_voltage::Bool
    ramp_active::Bool
end

# Construct a sequence controller initialized at the first step with no active ramp.
SequenceController() = SequenceController(1, 0.0, 0.0, 0.0, false, missing, 0, missing, missing, 0.0, 0.0, 0.0, 0.0, false, false)

# Return the numeric scalar type used by the sequence controller.
@inline function Jutul.numerical_type(x::SequenceController{R}) where {R}
    return R
end


##############################################
# Copy helpers for the different controllers #
##############################################

function copyController!(dst::T, src::T) where {T <: Controller}
    for field in fieldnames(T)
        setfield!(dst, field, getfield(src, field))
    end
    return dst
end

function copy_controller_field(dst_value, src_value)
    if dst_value isa Bool && src_value isa Bool
        return src_value
    elseif dst_value isa Number && src_value isa Number
        return zero(dst_value) + src_value
    else
        return src_value
    end
end

function copyController!(dst::T, src::S) where {T <: Controller, S <: Controller}
    # Adjoint tracing may copy CCController{..., Float64} into CCController{..., Dual}.
    fieldnames(T) == fieldnames(S) || error("Cannot copy controller $(S) into $(T)")
    for field in fieldnames(T)
        setfield!(dst, field, copy_controller_field(getfield(dst, field), getfield(src, field)))
    end
    return dst
end

function copyController!(dst::CcCvController, src::CcCvController)
    # Need its own copyController since it contains a nested mutable controller
    copyController!(dst.maincontroller, src.maincontroller)
    dst.numberOfCycles = src.numberOfCycles
    dst.dEdt = src.dEdt
    dst.dIdt = src.dIdt
    dst.ramp_start_time = src.ramp_start_time
    dst.ramp_duration = src.ramp_duration
    dst.ramp_start_target = src.ramp_start_target
    dst.ramp_end_target = src.ramp_end_target
    dst.ramp_target_is_voltage = src.ramp_target_is_voltage
    dst.ramp_active = src.ramp_active
    return dst
end

function Base.copy(c::T) where {T <: Controller}
    return T((getfield(c, field) for field in fieldnames(T))...)
end

function Base.copy(c::CcCvController{R, I}) where {R, I}
    return CcCvController(
        copy(c.maincontroller),
        c.numberOfCycles,
        c.dEdt,
        c.dIdt,
        c.ramp_start_time,
        c.ramp_duration,
        c.ramp_start_target,
        c.ramp_end_target,
        c.ramp_target_is_voltage,
        c.ramp_active,
    )
end

#################################################
# Minimum output variables for the control model #
#################################################

"""
We add the controller in the output
"""
function Jutul.select_minimum_output_variables!(
        outputs,
        system::CurrentAndVoltageSystem{R},
        model::SimulationModel,
    ) where {R}

    return push!(outputs, :Controller)

end


###################################################################################################################
# Functions to compute initial current given the policy, it used at initialization of the state in the simulation #
###################################################################################################################
function getInitCurrent(policy::CCPolicy)

    if !ismissing(policy.current_function)
        val = policy.current_function(0.0)

    else
        if policy.initialControl == "charging"

            val = -policy.ImaxCharge

        elseif policy.initialControl == "discharging"
            val = policy.ImaxDischarge
        else
            error("Initial control $(policy.initialControl) not recognized")
        end
    end

    return val
end

function getInitCurrent(policy::FunctionPolicy)
    return 0.0
end

function getInitCurrent(policy::SimpleCVPolicy)
    if !ismissing(policy.current_function)
        val = policy.current_function(0.0)
    else

        val = policy.Imax

    end
    return val
end


function getInitCurrent(policy::CyclingCVPolicy)
    if !ismissing(policy.current_function)
        val = policy.current_function(0.0)

    else
        if policy.initialControl == charging
            val = -policy.ImaxCharge

        elseif policy.initialControl == discharging
            val = policy.ImaxDischarge
        else
            error("Initial control $(policy.initialControl) not recognized")
        end
    end
    return val

end

function getInitCurrent(policy::InputCurrentPolicy)
    # Return the current at the first time point using the interpolator
    return policy.current_function(policy.times[1])
end

function getInitCurrent(policy::RestPolicy)
    return zero(policy.duration)
end

# Return the initial current prescribed by the first step in a sequence.
function getInitCurrent(policy::SequencePolicy)
    return getInitCurrent(sequence_step_policy(policy.steps[1]))
end

function getInitCurrent(model::CurrentAndVoltageModel)

    return getInitCurrent(model.system.policy)

end

# Unwrap a policy step to get the policy that should control the active step.
sequence_step_policy(step::PolicyStep) = step.policy
# Allow already-unwrapped policies to be used as sequence steps.
sequence_step_policy(policy::AbstractPolicy) = policy

#####################################
# Helpers for sequence policy steps #
#####################################

# Return the policy object for the currently active sequence step.
function active_sequence_policy(policy::SequencePolicy, controller::SequenceController)
    return sequence_step_policy(policy.steps[controller.step_index])
end

# Initialize the shared sequence controller fields for a rest step.
function initialize_sequence_step_controller!(controller::SequenceController, step_policy::RestPolicy)
    controller.target = 0.0
    controller.target_is_voltage = false
    controller.ctrlType = rest
    controller.numberOfCycles = 0
    controller.dEdt = missing
    return controller.dIdt = missing
end

# Initialize the shared sequence controller fields for a CC step.
function initialize_sequence_step_controller!(controller::SequenceController, step_policy::CCPolicy)
    if step_policy.initialControl == "discharging"
        controller.ctrlType = "discharging"
        controller.target = step_policy.ImaxDischarge
    elseif step_policy.initialControl == "charging"
        controller.ctrlType = "charging"
        controller.target = -step_policy.ImaxCharge
    else
        error("Initial control $(step_policy.initialControl) is not recognized")
    end
    controller.target_is_voltage = false
    controller.numberOfCycles = 0
    controller.dEdt = missing
    return controller.dIdt = missing
end

# Initialize the shared sequence controller fields for a CCCV step.
function initialize_sequence_step_controller!(controller::SequenceController, step_policy::CyclingCVPolicy)
    if step_policy.initialControl == discharging
        controller.ctrlType = cc_discharge1
    elseif step_policy.initialControl == charging
        controller.ctrlType = cc_charge1
    else
        error("Initial control $(step_policy.initialControl) is not recognized")
    end
    controller.target = 0.0
    controller.target_is_voltage = false
    controller.numberOfCycles = 0
    controller.dEdt = missing
    return controller.dIdt = missing
end

# A rest step is complete once its step-local duration has elapsed.
function sequence_step_complete(policy::RestPolicy, controller, state)
    return controller.time - controller.step_start_time >= policy.duration
end

# A CC step is complete when its voltage limit or cycle count condition is reached.
function sequence_step_complete(policy::CCPolicy, controller, state)
    if policy.numberOfCycles == 0
        if policy.initialControl == "charging"
            return state.ElectricPotential[1] >= policy.upperCutoffVoltage
        elseif policy.initialControl == "discharging"
            return state.ElectricPotential[1] <= policy.lowerCutoffVoltage
        else
            error("Initial control $(policy.initialControl) is not recognized")
        end
    else
        return controller.numberOfCycles >= policy.numberOfCycles
    end
end

# A CCCV step is complete when its requested cycle count has been reached.
function sequence_step_complete(policy::CyclingCVPolicy, controller, state)
    return controller.numberOfCycles >= policy.numberOfCycles
end

# A sequence is complete when the active step index has advanced past the final step.
function sequence_complete(policy::SequencePolicy, controller::SequenceController)
    return controller.step_index > length(policy.steps)
end

# The nominal target for a rest step is zero current.
function sequence_nominal_target(policy::RestPolicy, controller::SequenceController)
    return (target = 0.0, target_is_voltage = false)
end

# The nominal target for a CC step is the current setpoint for the active direction.
function sequence_nominal_target(policy::CCPolicy, controller::SequenceController)
    if controller.ctrlType == "discharging"
        target = policy.ImaxDischarge
    elseif controller.ctrlType == "charging"
        target = -policy.ImaxCharge
    else
        error("ctrlType $(controller.ctrlType) not recognized")
    end
    return (target = target, target_is_voltage = false)
end

# The nominal target for a CCCV step is the current or voltage setpoint for its active mode.
function sequence_nominal_target(policy::CyclingCVPolicy, controller::SequenceController)
    if controller.ctrlType == cc_discharge1
        target = policy.ImaxDischarge
        target_is_voltage = false
    elseif controller.ctrlType == cc_discharge2
        target = 0.0
        target_is_voltage = false
    elseif controller.ctrlType == cc_charge1
        target = -policy.ImaxCharge
        target_is_voltage = false
    elseif controller.ctrlType == cv_charge2
        target = policy.upperCutoffVoltage
        target_is_voltage = true
    else
        error("ctrlType $(controller.ctrlType) not recognized")
    end
    return (target = target, target_is_voltage = target_is_voltage)
end

# Advance to the next sequence step and start a transition ramp when requested.
function advance_sequence_step!(controller::SequenceController, policy::SequencePolicy)
    previous_target = controller.target
    previous_target_is_voltage = controller.target_is_voltage

    controller.step_index += 1
    controller.step_start_time = controller.time
    if !sequence_complete(policy, controller)
        initialize_sequence_step_controller!(controller, active_sequence_policy(policy, controller))
        nominal = sequence_nominal_target(active_sequence_policy(policy, controller), controller)
        if policy.use_ramp_up && policy.rampup_time > 0 && previous_target_is_voltage == nominal.target_is_voltage && previous_target != nominal.target
            controller.ramp_start_time = controller.time
            controller.ramp_duration = policy.rampup_time
            controller.ramp_start_target = previous_target
            controller.ramp_end_target = nominal.target
            controller.ramp_target_is_voltage = nominal.target_is_voltage
            controller.ramp_active = true
            controller.target = previous_target
            controller.target_is_voltage = previous_target_is_voltage
        else
            controller.ramp_active = false
        end
    else
        controller.ramp_active = false
    end
    return controller
end

# Apply an active sequence transition ramp to the controller target.
function apply_sequence_transition_ramp!(controller::SequenceController)
    if controller.ramp_active
        elapsed = controller.time - controller.ramp_start_time
        if elapsed < controller.ramp_duration
            delta = controller.ramp_end_target - controller.ramp_start_target
            controller.target = controller.ramp_start_target + currentFun(elapsed, delta, controller.ramp_duration)
            controller.target_is_voltage = controller.ramp_target_is_voltage
        else
            controller.target = controller.ramp_end_target
            controller.target_is_voltage = controller.ramp_target_is_voltage
            controller.ramp_active = false
        end
    end
    return controller
end


######################################################
# Setup the initial policy from the input parameters #
######################################################

setup_initial_control_policy!(policy::AbstractPolicy, input, parameters) = nothing

function setup_initial_control_policy!(policy::CCPolicy, input, parameters)

    cycling_protocol = input.cycling_protocol

    if policy.initialControl == "charging"

        Imax = only(parameters[:Control][:ImaxCharge])


    elseif policy.initialControl == "discharging"
        Imax = only(parameters[:Control][:ImaxDischarge])

    else
        error("Initial control $(policy.initialControl) is not recognized")
    end

    if policy.use_ramp_up

        tup = Float64(input.simulation_settings["RampUpTime"])

        cFun(time) = currentFun(time, Imax, tup)

        policy.current_function = cFun
    end

    if haskey(cycling_protocol, "UpperVoltageLimit")
        policy.upperCutoffVoltage = cycling_protocol["UpperVoltageLimit"]
    end
    if haskey(cycling_protocol, "LowerVoltageLimit")
        policy.lowerCutoffVoltage = cycling_protocol["LowerVoltageLimit"]
    end
    policy.ImaxCharge = only(parameters[:Control][:ImaxCharge])
    return policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])

end


function setup_initial_control_policy!(policy::SimpleCVPolicy, input, parameters)

    cycling_protocol = input.cycling_protocol

    Imax = only(parameters[:Control][:ImaxDischarge])

    tup = Float64(input.simulation_settings["RampUpTime"])

    cFun(time) = currentFun(time, Imax, tup)

    policy.current_function = cFun
    policy.Imax = Imax
    return policy.voltage = cycling_protocol["LowerVoltageLimit"]

end


function setup_initial_control_policy!(policy::CyclingCVPolicy, input, parameters)

    cycling_protocol = input.cycling_protocol

    if policy.initialControl == charging
        Imax = only(parameters[:Control][:ImaxCharge])


    elseif policy.initialControl == discharging
        Imax = only(parameters[:Control][:ImaxDischarge])

    else
        error("Initial control $(policy.initialControl) is not recognized")
    end

    if policy.use_ramp_up

        tup = Float64(input.simulation_settings["RampUpTime"])

        cFun(time) = currentFun(time, Imax, tup)

        policy.current_function = cFun
        policy.rampup_time = tup
    end


    policy.ImaxCharge = only(parameters[:Control][:ImaxCharge])
    policy.upperCutoffVoltage = cycling_protocol["UpperVoltageLimit"]
    policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])
    return policy.lowerCutoffVoltage = cycling_protocol["LowerVoltageLimit"]

end

function setup_initial_control_policy!(policy::InputCurrentPolicy, input, parameters)
    # The policy already contains the full time series and voltage limits.
    # Nothing additional needs to be set up from parameters.
end

function setup_initial_control_policy!(policy::RestPolicy, input, parameters)
    return nothing
end

# Sequence steps are fully configured before setup, so no additional initial policy data is needed.
function setup_initial_control_policy!(policy::SequencePolicy, input, parameters)
    return nothing
end

###################################
# Special primary variable update #
###################################

"""
We need a more fine-tuned update of the variables when we use a cycling policies, to avoid convergence problem.
"""
function Jutul.update_primary_variable!(state, p::CurrentVar, state_symbol, model::P, dx, w) where {R, I, Q <: Union{CyclingCVPolicy{R, I}, CCPolicy{R}}, P <: CurrentAndVoltageModel{Q}}

    entity = associated_entity(p)
    active = active_entities(model.domain, entity, for_variables = true)
    v = state[state_symbol]

    nu = length(active)
    ImaxDischarge = model.system.policy.ImaxDischarge
    ImaxCharge = model.system.policy.ImaxCharge

    Imax = max(ImaxCharge, ImaxDischarge)

    abs_max = 0.2 * Imax
    rel_max = relative_increment_limit(p)
    maxval = maximum_value(p)
    minval = minimum_value(p)
    scale = variable_scale(p)
    return @inbounds for i in 1:nu
        a_i = active[i]
        v[a_i] = update_value(v[a_i], w * dx[i], abs_max, rel_max, minval, maxval, scale)
    end

end

# Bound sequence current updates by the largest current used by any step in the sequence.
function Jutul.update_primary_variable!(state, p::CurrentVar, state_symbol, model::P, dx, w) where {P <: CurrentAndVoltageModel{<:SequencePolicy}}

    entity = associated_entity(p)
    active = active_entities(model.domain, entity, for_variables = true)
    v = state[state_symbol]

    ImaxDischarge = model.system.policy.ImaxDischarge
    ImaxCharge = model.system.policy.ImaxCharge
    Imax = max(ImaxCharge, ImaxDischarge)

    abs_max = 0.2 * Imax
    rel_max = relative_increment_limit(p)
    maxval = maximum_value(p)
    minval = minimum_value(p)
    scale = variable_scale(p)
    return @inbounds for i in eachindex(active)
        a_i = active[i]
        v[a_i] = update_value(v[a_i], w * dx[i], abs_max, rel_max, minval, maxval, scale)
    end

end

#######################################
# Helper functions for control switch #
#######################################

"""
The setupRegionSwitchFlags function detects from the current state and control, if we are in the switch region. The functions return two flags :
- beforeSwitchRegion : the state is before the switch region for the current control
- afterSwitchRegion : the state is after the switch region for the current control
"""
function setupRegionSwitchFlags(policy::Union{CyclingCVPolicy, CCPolicy}, state, ctrlType)

    Emin = policy.lowerCutoffVoltage
    Emax = policy.upperCutoffVoltage
    if policy isa CyclingCVPolicy
        dIdtMin = policy.dIdtLimit
        dEdtMin = policy.dEdtLimit
        tols = policy.tolerances
        tol = tols[getSymbol(ctrlType)]
    else
        tols = policy.tolerances
        tol = tols[ctrlType]

    end

    E = only(state.ElectricPotential)

    if ctrlType == cc_discharge1 || ctrlType == "discharging"

        before = E > Emin * (1 + tol)
        after = E < Emin * (1 - tol)

    elseif ctrlType == cc_discharge2

        dEdt = state.Controller.dEdt
        if !ismissing(dEdt)
            before = abs(dEdt) > dEdtMin * (1 + tol)
            after = abs(dEdt) < dEdtMin * (1 - tol)
        else
            before = false
            after = false
        end

    elseif ctrlType == cc_charge1 || ctrlType == "charging"

        before = E < Emax * (1 - tol)
        after = E > Emax * (1 + tol)

    elseif ctrlType == cv_charge2

        if !ismissing(policy.cvCurrentCutoff)
            I = abs(only(state.Current))
            before = I > policy.cvCurrentCutoff
            after = I < policy.cvCurrentCutoff
        else
            dIdt = state.Controller.dIdt
            if !ismissing(dIdt)
                before = abs(dIdt) > dIdtMin * (1 + tol)
                after = abs(dIdt) < dIdtMin * (1 - tol)
            else
                before = false
                after = false
            end
        end

    else

        error("Control type $ctrlType not recognized")

    end

    return (beforeSwitchRegion = before, afterSwitchRegion = after)

end

"""
When a step has been computed for a given control up to the convergence requirement, it may happen that the state that is obtained do not fulfill the requirement of the control, meaning that a control switch should have been triggered. The function check_constraints checks that and return false in this case and update the control. The step is then not completed and carries on with the new control
"""
function check_constraints(model, storage)

    policy = model[:Control].system.policy

    state = storage.state[:Control]
    state0 = storage.state0[:Control]

    controller = state[:Controller]
    ctrlType = state[:Controller].ctrlType
    ctrlType0 = state0[:Controller].ctrlType

    if policy isa SequencePolicy
        if sequence_complete(policy, controller)
            return true
        end
        policy = active_sequence_policy(policy, controller)
    end

    if policy isa RestPolicy
        return true
    elseif policy isa CyclingCVPolicy
        if controller.ramp_active
            return true
        end
        nextCtrlType = getNextCtrlTypecccv(ctrlType0)
    elseif policy isa CCPolicy
        if ctrlType == "discharging"
            nextCtrlType = "charging"
        else
            nextCtrlType = "discharging"
        end
    else
        error("Policy $(typeof(policy)) not recognized")
    end

    arefulfilled = true

    rsw = setupRegionSwitchFlags(policy, state, ctrlType)
    rswN = setupRegionSwitchFlags(policy, state, nextCtrlType)

    if (ctrlType == ctrlType0 && rsw.afterSwitchRegion) || (ctrlType == nextCtrlType && !rswN.beforeSwitchRegion)

        arefulfilled = false

    end

    return arefulfilled

end

################################################
# Functions to update values in the controller #
################################################


function Jutul.update_values!(old::FunctionController, new::FunctionController)

    return copyController!(old, new)

end

function Jutul.update_values!(old::CCController, new::CCController)

    return copyController!(old, new)

end

function Jutul.update_values!(old::SimpleControllerCV, new::SimpleControllerCV)

    return copyController!(old, new)

end

function Jutul.update_values!(old::CcCvController, new::CcCvController)

    return copyController!(old, new)

end

function Jutul.update_values!(old::InputCurrentController, new::InputCurrentController)

    return copyController!(old, new)

end

function Jutul.update_values!(old::RestController, new::RestController)

    return copyController!(old, new)

end

# Copy the sequence controller when Jutul updates controller values.
function Jutul.update_values!(old::SequenceController, new::SequenceController)

    return copyController!(old, new)

end

"""
In addition to update the values in all primary variables, we need also to update the values in the controller. We do that by specializing the method perform_step_solve_impl!
"""
function Jutul.update_extra_state_fields!(storage, model::SimulationModel{CurrentAndVoltageDomain, <:CurrentAndVoltageSystem}, dt, time)
    state = storage.state
    state0 = storage.state0
    policy = model.system.policy
    update_controller!(state, state0, policy, dt)
    return storage
end

"""
We need to add the specific treatment of the controller variables
"""
function Jutul.reset_state_to_previous_state!(
        storage,
        model::SimulationModel{CurrentAndVoltageDomain, <:CurrentAndVoltageSystem, T3, T4},
    ) where {T3, T4}

    invoke(
        reset_state_to_previous_state!,
        Tuple{
            typeof(storage),
            SimulationModel,
        },
        storage,
        model,
    )
    return copyController!(storage.state[:Controller], storage.state0[:Controller])
end


function update_controller!(state, state0, policy::AbstractPolicy, dt)

    update_control_type_in_controller!(state, state0, policy, dt)
    return update_values_in_controller!(state, policy)

end


##################################
# Implementation of the policies #
##################################

# Given a policy, a current control and state, we compute the next control
"""
Implementation of the function policy
"""
function update_control_type_in_controller!(state, state0, policy::FunctionPolicy, dt)
    controller = state.Controller
    controller.target_is_voltage = false
    return controller.time = state0.Controller.time + dt

end

"""
Implementation of the simple CV policy
"""
function update_control_type_in_controller!(state, state0, policy::SimpleCVPolicy, dt)

    phi_p = policy.voltage

    controller = state.Controller

    phi = only(state.ElectricPotential)

    target_is_voltage = (phi <= phi_p)

    controller.target_is_voltage = target_is_voltage
    controller.ctrlType = discharge # for the moment only discharge in a simple controller
    return controller.time = state0.Controller.time + dt

end

#####################################
# Helpers for CCCV transition ramps #
#####################################

function cccv_nominal_target(policy::CyclingCVPolicy, ctrlType)
    if ctrlType == cc_discharge1
        target = policy.ImaxDischarge
        target_is_voltage = false
    elseif ctrlType == cc_discharge2
        target = 0.0
        target_is_voltage = false
    elseif ctrlType == cc_charge1
        target = -policy.ImaxCharge
        target_is_voltage = false
    elseif ctrlType == cv_charge2
        target = policy.upperCutoffVoltage
        target_is_voltage = true
    else
        error("ctrlType $ctrlType not recognized")
    end
    return (target = target, target_is_voltage = target_is_voltage)
end

function start_cccv_transition_ramp!(controller, policy::CyclingCVPolicy, ctrlType, E, I)
    nominal = cccv_nominal_target(policy, ctrlType)
    controller.ramp_start_time = controller.time
    controller.ramp_duration = policy.rampup_time
    controller.ramp_start_target = nominal.target_is_voltage ? E : I
    controller.ramp_end_target = nominal.target
    controller.ramp_target_is_voltage = nominal.target_is_voltage
    controller.ramp_active = policy.use_ramp_up && policy.rampup_time > 0 && controller.ramp_start_target != controller.ramp_end_target
    return controller
end

function apply_cccv_transition_ramp!(controller)
    if controller.ramp_active
        elapsed = controller.time - controller.ramp_start_time
        if elapsed < controller.ramp_duration
            delta = controller.ramp_end_target - controller.ramp_start_target
            controller.target = controller.ramp_start_target + currentFun(elapsed, delta, controller.ramp_duration)
            controller.target_is_voltage = controller.ramp_target_is_voltage
        else
            controller.target = controller.ramp_end_target
            controller.target_is_voltage = controller.ramp_target_is_voltage
            controller.ramp_active = false
        end
    end
    return controller
end

"""
Implementation of the cycling CC-CV policy
"""

##################################################
# Control-type updates for the different policies #
##################################################

function update_control_type_in_controller!(state, state0, policy::CyclingCVPolicy, dt)

    E = only(value(state[:ElectricPotential]))
    I = only(value(state[:Current]))
    E0 = only(value(state0[:ElectricPotential]))
    I0 = only(value(state0[:Current]))

    controller = state.Controller

    controller.time = state0.Controller.time + dt
    controller.dIdt = (I - I0) / dt
    controller.dEdt = (E - E0) / dt

    ctrlType0 = state0.Controller.ctrlType

    if state0.Controller.ramp_active
        return controller.ctrlType = ctrlType0
    end

    nextCtrlType = getNextCtrlTypecccv(ctrlType0)

    rsw00 = setupRegionSwitchFlags(policy, state0, ctrlType0)


    if rsw00.beforeSwitchRegion

        # We have not entered the switching region in the time step. We are not going to change control
        # in this step.
        ctrlType = ctrlType0

    else

        # We entered the switch region in the previous time step. We consider switching control

        currentCtrlType = state.Controller.ctrlType # current control in the the Newton iteration
        nextCtrlType0 = getNextCtrlTypecccv(ctrlType0) # next control that can occur after the previous time step control (if it changes)

        rsw0 = setupRegionSwitchFlags(policy, state, ctrlType0)

        if currentCtrlType == ctrlType0

            # The control has not changed from previous time step and we want to determine if we should change it.

            if rsw0.afterSwitchRegion

                # We switch to a new control because we are no longer in the acceptable region for the current
                # control
                ctrlType = nextCtrlType0

            else

                ctrlType = ctrlType0

            end

        elseif currentCtrlType == nextCtrlType0

            # We do not switch back to avoid oscillation. We are anyway within the given tolerance for the
            # control so that we keep the control as it is.

            ctrlType = nextCtrlType0

        else

            error("Control type $currentCtrlType not recognized")

        end

    end

    if ctrlType != ctrlType0 && !controller.ramp_active
        start_cccv_transition_ramp!(controller, policy, ctrlType, E, I)
    end

    return controller.ctrlType = ctrlType

end


function update_control_type_in_controller!(state, state0, policy::CCPolicy, dt)

    return if policy.numberOfCycles == 0
        controller = state.Controller
        controller.time = state0.Controller.time + dt
    else

        controller = state.Controller

        controller.time = state0.Controller.time + dt

        ctrlType0 = state0.Controller.ctrlType

        if ctrlType0 == "discharging"
            nextCtrlType = "charging"
        else
            nextCtrlType = "discharging"
        end

        rsw00 = setupRegionSwitchFlags(policy, state0, ctrlType0)

        if rsw00.beforeSwitchRegion

            # We have not entered the switching region in the time step. We are not going to change control
            # in this step.
            ctrlType = ctrlType0

        else

            # We entered the switch region in the previous time step. We consider switching control

            currentCtrlType = state.Controller.ctrlType # current control in the the Newton iteration
            if ctrlType0 == "discharging"
                nextCtrlType0 = "charging"
            else
                nextCtrlType0 = "discharging"
            end # next control that can occur after the previous time step control (if it changes)

            rsw0 = setupRegionSwitchFlags(policy, state, ctrlType0)

            if currentCtrlType == ctrlType0

                # The control has not changed from previous time step and we want to determine if we should change it.

                if rsw0.afterSwitchRegion

                    # We switch to a new control because we are no longer in the acceptable region for the current
                    # control
                    ctrlType = nextCtrlType0

                else

                    ctrlType = ctrlType0

                end

            elseif currentCtrlType == nextCtrlType0

                # We do not switch back to avoid oscillation. We are anyway within the given tolerance for the
                # control so that we keep the control as it is.

                ctrlType = nextCtrlType0

            else

                error("Control type $currentCtrlType not recognized")

            end

        end

        controller.ctrlType = ctrlType

    end

end

function update_control_type_in_controller!(state, state0, policy::RestPolicy, dt)
    controller = state.Controller
    controller.time = state0.Controller.time + dt
    controller.target_is_voltage = false
    return controller.ctrlType = rest
end

# Delegate sequence control-type updates to the currently active step policy.
function update_control_type_in_controller!(state, state0, policy::SequencePolicy, dt)
    controller = state.Controller
    if sequence_complete(policy, controller)
        return nothing
    end
    step_policy = active_sequence_policy(policy, controller)
    return update_control_type_in_controller!(state, state0, step_policy, dt)
end


##################################################
# Control-type update for input-current policies #
##################################################

"""
Implementation of the InputCurrentPolicy.

The prescribed current is evaluated by calling the Jutul linear interpolator
(`policy.current_function`) at the current simulation time.
If the resulting voltage response would violate the voltage limits, constant-voltage
control is applied at the respective limit instead, preventing voltage spikes.
"""
function update_control_type_in_controller!(state, state0, policy::InputCurrentPolicy, dt)

    # Relative tolerance for voltage hysteresis: if the voltage is within this fraction
    # of the limit, we remain in CV mode to avoid oscillating between CC and CV control
    # during Newton iterations at the transition boundary.
    const_voltage_hysteresis_tol = 1.0e-4

    controller = state.Controller

    controller.time = state0.Controller.time + dt

    E = only(value(state[:ElectricPotential]))
    t = controller.time

    I_target = policy.current_function(t)

    # Determine which voltage limit is relevant based on the sign of the prescribed current,
    # then check whether the voltage has crossed that limit.
    if I_target > 0
        # Discharging: enforce lower voltage limit
        target_is_voltage = (E <= policy.lowerCutoffVoltage)
    elseif I_target < 0
        # Charging: enforce upper voltage limit
        target_is_voltage = (E >= policy.upperCutoffVoltage)
    else
        # Zero current (rest): no voltage limit applies
        target_is_voltage = false
    end

    # Hysteresis: if we were already in voltage-control mode in the converged previous
    # state, stay in voltage-control mode as long as the limit is still binding.
    # This prevents oscillations at the CC/CV boundary within Newton iterations.
    if state0.Controller.target_is_voltage && !target_is_voltage
        # We were in CV mode; only switch back to CC if the prescribed current
        # would not immediately violate the limit again.
        if I_target > 0 && E <= policy.lowerCutoffVoltage * (1 + const_voltage_hysteresis_tol)
            target_is_voltage = true
        elseif I_target < 0 && E >= policy.upperCutoffVoltage * (1 - const_voltage_hysteresis_tol)
            target_is_voltage = true
        end
    end

    return controller.target_is_voltage = target_is_voltage

end

# Once the controller has been assigned the given control, we adjust the target value which is used in the equation
# assembly

###################################################
# Target-value updates for the different policies #
###################################################

function update_values_in_controller!(state, policy::CCPolicy)

    controller = state.Controller
    ctrlType = controller.ctrlType

    cf = policy.current_function

    if controller.numberOfCycles == 0 && controller.ctrlType == policy.initialControl && !ismissing(cf)

        if cf isa Real
            I_t = cf
        else
            # Function of time at the end of interval
            I_t = cf(controller.time)
        end

        if ctrlType == "discharging"

            I_t = I_t


        elseif ctrlType == "charging"

            # minus sign below follows from convention
            I_t = -I_t


        else

            error("ctrlType $ctrlType not recognized")

        end
    else


        if ctrlType == "discharging"

            I_t = policy.ImaxDischarge


        elseif ctrlType == "charging"


            I_t = -policy.ImaxCharge


        else

            error("ctrlType $ctrlType not recognized")

        end
    end

    target = I_t

    return controller.target = target


end

function update_values_in_controller!(state, policy::FunctionPolicy)

    controller = state.Controller

    cf = policy.current_function

    I_p = cf(controller.time, value(only(state.ElectricPotential)))

    return controller.target = I_p


end

function update_values_in_controller!(state, policy::SimpleCVPolicy)

    controller = state.Controller

    return if controller.target_is_voltage

        phi_p = policy.voltage

        controller.target = phi_p

    else

        cf = policy.current_function

        if cf isa Real
            I_p = cf
        else
            # Function of time at the end of interval
            I_p = cf(controller.time)
        end

        controller.target = I_p

    end

end

function update_values_in_controller!(state, policy::CyclingCVPolicy)

    controller = state[:Controller]

    ctrlType = controller.ctrlType

    cf = policy.current_function


    if ctrlType == cc_discharge1

        if controller.numberOfCycles == 0 && controller.ctrlType == policy.initialControl && !ismissing(cf)

            if cf isa Real
                I_t = cf
            else
                # Function of time at the end of interval
                I_t = cf(controller.time)
            end
        else

            I_t = policy.ImaxDischarge
        end
        target_is_voltage = false

    elseif ctrlType == cc_discharge2

        I_t = 0.0
        target_is_voltage = false

    elseif ctrlType == cc_charge1

        # minus sign below follows from convention
        if controller.numberOfCycles == 0 && controller.ctrlType == policy.initialControl && !ismissing(cf)

            if cf isa Real
                I_t = cf
            else
                # Function of time at the end of interval
                I_t = cf(controller.time)
            end
            I_t = -I_t
        else
            I_t = -policy.ImaxCharge
        end
        target_is_voltage = false

    elseif ctrlType == cv_charge2

        V_t = policy.upperCutoffVoltage
        target_is_voltage = true

    else

        error("ctrlType $ctrlType not recognized")

    end

    if target_is_voltage
        target = V_t
    else
        target = I_t
    end


    controller.target_is_voltage = target_is_voltage
    controller.target = target
    return apply_cccv_transition_ramp!(controller)

end

function update_values_in_controller!(state, policy::InputCurrentPolicy)

    controller = state.Controller
    t = controller.time

    I_target = policy.current_function(t)

    return if controller.target_is_voltage
        # In voltage-control mode: use the appropriate voltage limit
        if I_target >= 0
            # Discharging hit the lower limit
            controller.target = policy.lowerCutoffVoltage
        else
            # Charging hit the upper limit
            controller.target = policy.upperCutoffVoltage
        end
    else
        # In current-control mode: use the interpolated time-series current
        controller.target = I_target
    end

end

#############################################
# Target-value updates for sequence steps   #
#############################################

# Update a sequence rest step target using the standalone rest target logic.
function update_sequence_values_in_controller!(state, policy::RestPolicy)
    return update_values_in_controller!(state, policy)
end

# Update a sequence CC step target using step-local time for any ramp function.
function update_sequence_values_in_controller!(state, policy::CCPolicy)
    controller = state.Controller
    ctrlType = controller.ctrlType
    cf = policy.current_function

    if controller.numberOfCycles == 0 && controller.ctrlType == policy.initialControl && !ismissing(cf)
        local_time = controller.time - controller.step_start_time
        I_t = cf isa Real ? cf : cf(local_time)

        if ctrlType == "discharging"
            target = I_t
        elseif ctrlType == "charging"
            target = -I_t
        else
            error("ctrlType $ctrlType not recognized")
        end
    else
        if ctrlType == "discharging"
            target = policy.ImaxDischarge
        elseif ctrlType == "charging"
            target = -policy.ImaxCharge
        else
            error("ctrlType $ctrlType not recognized")
        end
    end

    controller.target_is_voltage = false
    return controller.target = target
end

# Update a sequence CCCV step target using step-local time for any ramp function.
function update_sequence_values_in_controller!(state, policy::CyclingCVPolicy)
    controller = state[:Controller]
    ctrlType = controller.ctrlType
    cf = policy.current_function

    if ctrlType == cc_discharge1
        if controller.numberOfCycles == 0 && controller.ctrlType == policy.initialControl && !ismissing(cf)
            local_time = controller.time - controller.step_start_time
            target = cf isa Real ? cf : cf(local_time)
        else
            target = policy.ImaxDischarge
        end
        target_is_voltage = false

    elseif ctrlType == cc_discharge2
        target = 0.0
        target_is_voltage = false

    elseif ctrlType == cc_charge1
        if controller.numberOfCycles == 0 && controller.ctrlType == policy.initialControl && !ismissing(cf)
            local_time = controller.time - controller.step_start_time
            target = -(cf isa Real ? cf : cf(local_time))
        else
            target = -policy.ImaxCharge
        end
        target_is_voltage = false

    elseif ctrlType == cv_charge2
        target = policy.upperCutoffVoltage
        target_is_voltage = true

    else
        error("ctrlType $ctrlType not recognized")
    end

    controller.target_is_voltage = target_is_voltage
    return controller.target = target
end

function update_values_in_controller!(state, policy::RestPolicy)
    controller = state.Controller
    controller.target_is_voltage = false
    return controller.target = 0.0
end

# Update the active sequence step target and apply any sequence transition ramp.
function update_values_in_controller!(state, policy::SequencePolicy)
    controller = state[:Controller]
    if sequence_complete(policy, controller)
        return nothing
    end
    update_sequence_values_in_controller!(state, active_sequence_policy(policy, controller))
    return apply_sequence_transition_ramp!(controller)
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

    return if ctrl.target_is_voltage
        v[] = phi - ctrl.target
    else

        v[] = I - ctrl.target
    end

end

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::CurrentEquation, model, dt, ldisc = local_discretization(eq, i))

    I = only(state.Current)
    phi = only(state.ElectricPotential)

    return v[] = I + phi * 1.0e-10


end

#####################################################################
# Function to update the controller part in state after convergence #
#####################################################################

function update_cycle_count!(ctrl, ctrl0, initialControl::OperationalMode)
    ctrlType = ctrl.ctrlType
    ctrlType0 = ctrl0.ctrlType
    ncycles = ctrl0.numberOfCycles

    if initialControl == charging
        if (ctrlType0 == cc_discharge1 || ctrlType0 == cc_discharge2) && (ctrlType == cc_charge1 || ctrlType == cv_charge2)
            ncycles += 1
        end
    elseif initialControl == discharging
        if (ctrlType0 == cc_charge1 || ctrlType0 == cv_charge2) && (ctrlType == cc_discharge1 || ctrlType == cc_discharge2)
            ncycles += 1
        end
    else
        error("Initial control $initialControl is not recognized")
    end

    ctrl.numberOfCycles = ncycles
    return ctrl
end

function update_cycle_count!(ctrl, ctrl0, initialControl::String)
    ctrlType = ctrl.ctrlType
    ctrlType0 = ctrl0.ctrlType
    ncycles = ctrl0.numberOfCycles

    if initialControl == "charging"
        if ctrlType0 == "discharging" && ctrlType == "charging"
            ncycles += 1
        end
    elseif initialControl == "discharging"
        if ctrlType0 == "charging" && ctrlType == "discharging"
            ncycles += 1
        end
    else
        error("Initial control $initialControl is not recognized")
    end

    ctrl.numberOfCycles = ncycles
    return ctrl
end

""" Update after convergence. Copy the controller to state0 and update cycle counts. """
function Jutul.update_after_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces; time = NaN)

    ctrl = storage.state[:Controller]
    ctrl0 = storage.state0[:Controller]
    policy = model.system.policy

    if policy isa CyclingCVPolicy
        update_cycle_count!(ctrl, ctrl0, policy.initialControl)
        return copyController!(ctrl0, ctrl)

    elseif policy isa SimpleCVPolicy || policy isa FunctionPolicy || policy isa InputCurrentPolicy || policy isa RestPolicy
        return copyController!(ctrl0, ctrl)

    elseif policy isa CCPolicy
        if policy.numberOfCycles > 0
            update_cycle_count!(ctrl, ctrl0, policy.initialControl)
        end
        return copyController!(ctrl0, ctrl)

    elseif policy isa SequencePolicy
        if sequence_complete(policy, ctrl)
            return copyController!(ctrl0, ctrl)
        end

        step_policy = active_sequence_policy(policy, ctrl)

        if step_policy isa CyclingCVPolicy
            update_cycle_count!(ctrl, ctrl0, step_policy.initialControl)
        elseif step_policy isa CCPolicy && step_policy.numberOfCycles > 0
            update_cycle_count!(ctrl, ctrl0, step_policy.initialControl)
        end

        if sequence_step_complete(step_policy, ctrl, storage.state)
            advance_sequence_step!(ctrl, policy)
        end

        return copyController!(ctrl0, ctrl)

    else
        error("Policy $(typeof(policy)) not recognized")
    end
end

########################################################################
# Controller initialization function. Adds the controller to the state #
########################################################################

"""
Function called when setting up state initially. We need to add the fields corresponding to the controller
"""
function Jutul.initialize_extra_state_fields!(state, ::Any, model::CurrentAndVoltageModel; T = Float64)

    policy = model.system.policy

    return if policy isa SimpleCVPolicy

        time = 0.0
        Imax = policy.Imax
        if !ismissing(policy.current_function)
            target = policy.current_function(time)
        else
            target = Imax
        end
        target_is_voltage = false
        ctrlType = discharging
        state[:Controller] = SimpleControllerCV(target, time, target_is_voltage, ctrlType)

    elseif policy isa FunctionPolicy

        time = 0.0
        target = 0.0

        target_is_voltage = false

        state[:Controller] = FunctionController(target, time, target_is_voltage)

    elseif policy isa CCPolicy

        time = 0.0

        if policy.initialControl == "discharging"
            ctrlType = "discharging"
            Imax = policy.ImaxDischarge
        elseif policy.initialControl == "charging"
            ctrlType = "charging"
            Imax = -policy.ImaxCharge

        end

        if !ismissing(policy.current_function)
            I = policy.current_function(time)
            if policy.initialControl == "discharging"
                target = I
            elseif policy.initialControl == "charging"
                target = -I

            end

        else
            target = Imax
        end
        target_is_voltage = false

        number_of_cycles = 0
        target, time = promote(target, time)
        state[:Controller] = CCController(number_of_cycles, target, time, target_is_voltage, ctrlType)

    elseif policy isa CyclingCVPolicy

        state[:Controller] = CcCvController()

        if policy.initialControl == discharging

            state[:Controller].ctrlType = cc_discharge1

        elseif policy.initialControl == charging

            state[:Controller].ctrlType = cc_charge1

        else
            error("Initial control $(typeof(policy.initialControl)) not recognized")
        end

        update_values_in_controller!(state, policy)

    elseif policy isa InputCurrentPolicy

        time = 0.0
        target = policy.current_function(time)
        target_is_voltage = false

        target, time = promote(target, time)
        state[:Controller] = InputCurrentController(target, time, target_is_voltage)

    elseif policy isa RestPolicy

        time = 0.0
        target = 0.0
        target_is_voltage = false

        target, time = promote(target, time)
        state[:Controller] = RestController(target, time, target_is_voltage, rest)

    elseif policy isa SequencePolicy

        time = 0.0
        target = 0.0
        target_is_voltage = false

        target, time = promote(target, time)
        state[:Controller] = SequenceController(1, time, target, time, target_is_voltage, missing, 0, missing, missing, time, 0.0, target, target, target_is_voltage, false)
        initialize_sequence_step_controller!(state[:Controller], active_sequence_policy(policy, state[:Controller]))

    end

end

#######################################
# Utility functions for CC-CV control #
#######################################

function getNextCtrlTypecccv(ctrlType::OperationalMode)

    if ctrlType == cc_discharge1

        nextCtrlType = cc_discharge2

    elseif ctrlType == cc_discharge2

        nextCtrlType = cc_charge1

    elseif ctrlType == cc_charge1

        nextCtrlType = cv_charge2

    elseif ctrlType == cv_charge2

        nextCtrlType = cc_discharge1

    else

        error("ctrlType $ctrlType not recognized.")

    end

    return nextCtrlType

end

############################################
# Helper function to compute control value #
############################################

function currentFun(t::Real, inputI::Real, tup::Real = 0.1)

    t, inputI, tup, val = promote(t, inputI, tup, 0.0)

    if t <= tup
        val = sineup(0.0, inputI, 0.0, tup, t)
    else
        val = inputI
    end

    return val

end

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
