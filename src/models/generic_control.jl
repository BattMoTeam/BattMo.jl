abstract type AbstractControlStep end

struct Termination
	quantity::String
	comparison::String
	value::Float64
end

struct CurrentStep <: AbstractControlStep
	value::Float64
	direction::String
	termination::Termination
	timeStepSize::Union{Nothing, Float64}
end

struct VoltageStep <: AbstractControlStep
	value::Float64
	direction::String
	termination::Termination
	timeStepSize::Union{Nothing, Float64}
end

struct RestStep <: AbstractControlStep
	value::Union{Nothing, Float64}
	direction::Union{Nothing, String}
	termination::Termination
	timeStepSize::Union{Nothing, Float64}
end

struct CycleStep <: AbstractControlStep
	numberOfCycles::Int
	termination::Union{Nothing, Termination}
	cycleControlSteps::Vector{AbstractControlStep}
end

struct GenericPolicy
	controlPolicy::String
	controlsteps::Vector{AbstractControlStep}
end


function parse_control_step(json::Dict)
	ctype = json["controltype"]
	if ctype == "current"
		return CurrentStep(
			json["value"],
			json["direction"],
			Termination(json["termination"]["quantity"], json["termination"]["comparison"], json["termination"]["value"]),
			get(json, "timeStepSize", nothing),
		)
	elseif ctype == "voltage"
		return VoltageStep(
			json["value"],
			json["direction"],
			Termination(json["termination"]["quantity"], json["termination"]["comparison"], json["termination"]["value"]),
			get(json, "timeStepSize", nothing),
		)
	elseif ctype == "rest"
		return RestStep(
			get(json, "value", nothing),
			get(json, "direction", nothing),
			Termination(json["termination"]["quantity"], json["termination"]["comparison"], json["termination"]["value"]),
			get(json, "timeStepSize", nothing),
		)
	elseif ctype == "cycle"
		nested = [parse_control_step(step) for step in json["cycleControlSteps"]]
		return CycleStep(json["numberOfCycles"], get(json, "termination", nothing), nested)
	else
		error("Unsupported controltype: $ctype")
	end
end

function parse_generic_policy(json::Dict)
	steps = [parse_control_step(step) for step in json["controlsteps"]]
	return GenericPolicy(json["controlPolicy"], steps)
end

mutable struct GenericController
	policy::GenericPolicy
	current_step::Int
	time_in_step::Float64
	numberOfCycles::Int
end


"""
Function to create (deep) copy of GenericController
"""
function copyController!(cv_copy::GenericController, cv::GenericController)

	cv_copy.policy = cv.policy
	cv_copy.current_step = cv.current_step
	cv_copy.time_in_step = cv.time_in_step
	cv_copy.cycles_remaining = cv.cycles_remaining

end

"""
Overload function to copy GenericController
"""
function Base.copy(cv::GenericController)

	cv_copy = GenericController()
	copyController!(cv_copy, cv)

	return cv_copy

end

function Jutul.update_values!(old::GenericController, new::GenericController)

	copyController!(old, new)

end


#######################################
# Helper functions for control switch #
#######################################

"""
The setupRegionSwitchFlags function detects from the current state and control, if we are in the switch region. The functions return two flags :
- beforeSwitchRegion : the state is before the switch region for the current control
- afterSwitchRegion : the state is after the switch region for the current control
"""
function setupRegionSwitchFlags(policy::CyclingCVPolicy, state, ctrlType)

	Emin    = policy.lowerCutoffVoltage
	Emax    = policy.upperCutoffVoltage
	dIdtMin = policy.dIdtLimit
	dEdtMin = policy.dEdtLimit
	tols    = policy.tolerances

	E = only(state.Phi)
	I = only(state.Current)

	tol = tols[getSymbol(ctrlType)]

	if ctrlType == cc_discharge1

		before = E > Emin * (1 + tol)
		after  = E < Emin * (1 - tol)

	elseif ctrlType == cc_discharge2

		dEdt = state.ControllerCV.dEdt
		if !ismissing(dEdt)
			before = abs(dEdt) > dEdtMin * (1 + tol)
			after  = abs(dEdt) < dEdtMin * (1 - tol)
		else
			before = false
			after  = false
		end

	elseif ctrlType == cc_charge1

		before = E < Emax * (1 - tol)
		after  = E > Emax * (1 + tol)

	elseif ctrlType == cv_charge2

		dIdt = state.ControllerCV.dIdt
		if !ismissing(dIdt)
			before = abs(dIdt) > dIdtMin * (1 + tol)
			after  = abs(dIdt) < dIdtMin * (1 - tol)
		else
			before = false
			after  = false
		end

	else

		error("control type not recognized")

	end

	return (beforeSwitchRegion = before, afterSwitchRegion = after)

end