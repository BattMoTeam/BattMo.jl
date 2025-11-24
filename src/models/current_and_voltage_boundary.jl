export
	CurrentAndVoltageSystem,
	CurrentAndVoltageDomain,
	VoltageVar,
	CurrentVar,
	sineup,
	SimpleCVPolicy,
	CyclingCVPolicy,
	OperationalMode,
	AbstractControl

################################
# Define the operational modes #
################################

@enum OperationalMode cc_discharge1 cc_discharge2 cc_charge1 cv_charge2 rest discharge charging discharging none

function getSymbol(ctrlType::OperationalMode)

	if ctrlType == cc_discharge1
		symb = :cc_discharge1
	elseif ctrlType == cc_discharge2
		symb = :cc_discharge2
	elseif ctrlType == cc_charge1
		symb = :cc_charge1
	elseif ctrlType == cv_charge2
		symb = :cv_charge2
	end

	return symb

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
		tolerances = Dict("discharging" => 1e-4,
			"charging" => 1e-4),
	)
		T = promote_type(T, typeof(lowerCutoffVoltage), typeof(upperCutoffVoltage), typeof(ImaxDischarge), typeof(ImaxCharge))
		new{T}(numberOfCycles, initialControl, ImaxDischarge, ImaxCharge, lowerCutoffVoltage, upperCutoffVoltage, use_ramp_up, current_function, tolerances)
	end
end


""" Simple constant current, constant voltage policy. Stops when lower cut-off value is reached
"""
mutable struct SimpleCVPolicy{R} <: AbstractPolicy
	current_function::Any
	Imax::R
	voltage::R
	function SimpleCVPolicy(; current_function = missing, Imax::T = 0.0, voltage = missing) where T <: Real
		new{Union{Missing, T}}(current_function, Imax, voltage)
	end
end

""" No policy means that the control is kept fixed throughout the simulation
"""
struct NoPolicy <: AbstractPolicy end


"""
Function Policy
"""
struct FunctionPolicy <: AbstractPolicy
	current_function::Function

	function FunctionPolicy(function_name::String; file_path::Union{Nothing, String} = nothing)
		current_function = setup_function_from_function_name(function_name; file_path = file_path)
		new{}(current_function)
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
	initialControl::OperationalMode
	numberOfCycles::I
	tolerances::Any
	use_ramp_up::Bool
	current_function::Any

end

function CyclingCVPolicy(lowerCutoffVoltage,
	upperCutoffVoltage,
	dIdtLimit,
	dEdtLimit,
	initialControl::String,
	numberOfCycles;
	ImaxDischarge = 0 * lowerCutoffVoltage,
	ImaxCharge = 0 * lowerCutoffVoltage,
	use_ramp_up::Bool,
	current_function = missing,
)

	if initialControl == "charging"
		initialControl = charging
	elseif initialControl == "discharging"
		initialControl = discharging
	else
		error("InitialControl $initialControl not recognized")
	end

	tolerances = (cc_discharge1 = 1e-4,
		cc_discharge2 = 0.9,
		cc_charge1 = 1e-4,
		cv_charge2 = 0.9)

	return CyclingCVPolicy(ImaxDischarge,
		ImaxCharge,
		lowerCutoffVoltage,
		upperCutoffVoltage,
		dIdtLimit,
		dEdtLimit,
		initialControl,
		numberOfCycles,
		tolerances,
		use_ramp_up,
		current_function)
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

#########################
# Select the parameters #
#########################

function Jutul.select_parameters!(S,
	system::CurrentAndVoltageSystem{CCPolicy{R}},
	model::SimulationModel) where {R}
	S[:ImaxDischarge] = ImaxDischarge()
	S[:ImaxCharge] = ImaxCharge()
end

function Jutul.select_parameters!(S,
	system::CurrentAndVoltageSystem{SimpleCVPolicy{R}},
	model::SimulationModel) where {R}
	S[:ImaxDischarge] = ImaxDischarge()

end

function Jutul.select_parameters!(S,
	system::CurrentAndVoltageSystem{CyclingCVPolicy{R, I}},
	model::SimulationModel) where {R, I}
	S[:ImaxDischarge] = ImaxDischarge()
	S[:ImaxCharge]    = ImaxCharge()
end


###########################################################################################################
# Definition of the controller and some basic utility functions. The controller will be part of the state #
###########################################################################################################

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

end

function CcCvController()

	maincontroller = SimpleControllerCV()

	return CcCvController(maincontroller, 0, missing, missing)

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
	if f in fieldnames(SimpleControllerCV)
		setfield!(c.maincontroller, f, v)
	else
		setfield!(c, f, v)
	end
end

@inline function Jutul.numerical_type(x::CCController{R, I}) where {R, I}
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


"""
Function to create (deep) copy of simple controller
"""
function copyController!(cv_copy::CCController, cv::CCController)

	cv_copy.numberOfCycles = cv.numberOfCycles
	cv_copy.target = cv.target
	cv_copy.time = cv.time
	cv_copy.target_is_voltage = cv.target_is_voltage
	cv_copy.ctrlType = cv.ctrlType

end


"""
Function to create (deep) copy of function controller
"""
function copyController!(cv_copy::FunctionController, cv::FunctionController)

	cv_copy.target = cv.target
	cv_copy.time = cv.time
	cv_copy.target_is_voltage = cv.target_is_voltage

end

"""
Function to create (deep) copy of simple controller
"""
function copyController!(cv_copy::SimpleControllerCV, cv::SimpleControllerCV)

	cv_copy.target            = cv.target
	cv_copy.time              = cv.time
	cv_copy.target_is_voltage = cv.target_is_voltage
	cv_copy.ctrlType          = cv.ctrlType

end

"""
Function to create (deep) copy of CC-CV controller
"""
function copyController!(cv_copy::CcCvController, cv::CcCvController)

	copyController!(cv_copy.maincontroller, cv.maincontroller)
	cv_copy.numberOfCycles = cv.numberOfCycles

end

"""
Overload function to copy simple controller
"""
function Base.copy(cv::FunctionController)

	cv_copy = FunctionController()
	copyController!(cv_copy, cv)

	return cv_copy

end


"""
Overload function to copy simple controller
"""
function Base.copy(cv::CCController)

	cv_copy = CCController()
	copyController!(cv_copy, cv)

	return cv_copy

end

"""
Overload function to copy simple controller
"""
function Base.copy(cv::SimpleControllerCV)

	cv_copy = SimpleControllerCV()
	copyController!(cv_copy, cv)

	return cv_copy

end

"""
Overload function to copy CC-CV controller
"""
function Base.copy(cv::CcCvController)

	cv_copy = CcCvController()
	copyController!(cv_copy, cv)

	return cv_copy

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

function getInitCurrent(model::CurrentAndVoltageModel)

	return getInitCurrent(model.system.policy)

end



######################################################
# Setup the initial policy from the input parameters #
######################################################

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
	elseif haskey(cycling_protocol, "LowerVoltageLimit")
		policy.lowerCutoffVoltage = cycling_protocol["LowerVoltageLimit"]
	end
	policy.ImaxCharge = only(parameters[:Control][:ImaxCharge])
	policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])

end


function setup_initial_control_policy!(policy::FunctionPolicy, input, parameters)

end

function setup_initial_control_policy!(policy::SimpleCVPolicy, input, parameters)

	cycling_protocol = input.cycling_protocol

	Imax = only(parameters[:Control][:ImaxDischarge])

	tup = Float64(input.simulation_settings["RampUpTime"])

	cFun(time) = currentFun(time, Imax, tup)

	policy.current_function = cFun
	policy.Imax             = Imax
	policy.voltage          = cycling_protocol["LowerVoltageLimit"]

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
	end


	policy.ImaxCharge = only(parameters[:Control][:ImaxCharge])
	policy.upperCutoffVoltage = cycling_protocol["UpperVoltageLimit"]
	policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])
	policy.lowerCutoffVoltage = cycling_protocol["LowerVoltageLimit"]



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

	nu            = length(active)
	ImaxDischarge = model.system.policy.ImaxDischarge
	ImaxCharge    = model.system.policy.ImaxCharge

	Imax = max(ImaxCharge, ImaxDischarge)

	abs_max = 0.2 * Imax
	rel_max = relative_increment_limit(p)
	maxval = maximum_value(p)
	minval = minimum_value(p)
	scale = variable_scale(p)
	@inbounds for i in 1:nu
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
	I = only(state.Current)



	if ctrlType == cc_discharge1 || ctrlType == "discharging"

		before = E > Emin * (1 + tol)
		after  = E < Emin * (1 - tol)

	elseif ctrlType == cc_discharge2

		dEdt = state.Controller.dEdt
		if !ismissing(dEdt)
			before = abs(dEdt) > dEdtMin * (1 + tol)
			after  = abs(dEdt) < dEdtMin * (1 - tol)
		else
			before = false
			after  = false
		end

	elseif ctrlType == cc_charge1 || ctrlType == "charging"

		before = E < Emax * (1 - tol)
		after  = E > Emax * (1 + tol)

	elseif ctrlType == cv_charge2

		dIdt = state.Controller.dIdt
		if !ismissing(dIdt)
			before = abs(dIdt) > dIdtMin * (1 + tol)
			after  = abs(dIdt) < dIdtMin * (1 - tol)
		else
			before = false
			after  = false
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

	state  = storage.state[:Control]
	state0 = storage.state0[:Control]

	controller = state[:Controller]

	arefulfilled = true

	if policy isa CyclingCVPolicy
		ctrlType = state[:Controller].ctrlType
		ctrlType0 = state0[:Controller].ctrlType
		nextCtrlType = getNextCtrlTypecccv(ctrlType0)
		rsw = setupRegionSwitchFlags(policy, state, ctrlType)
		rswN = setupRegionSwitchFlags(policy, state, nextCtrlType)

		if (ctrlType == ctrlType0 && rsw.afterSwitchRegion) || (ctrlType == nextCtrlType && !rswN.beforeSwitchRegion)

			arefulfilled = false

		end

	elseif policy isa CCPolicy
		ctrlType = state[:Controller].ctrlType
		ctrlType0 = state0[:Controller].ctrlType

		if ctrlType == "discharging"
			nextCtrlType = "charging"
		else
			nextCtrlType = "discharging"
		end

		rsw = setupRegionSwitchFlags(policy, state, ctrlType)
		rswN = setupRegionSwitchFlags(policy, state, nextCtrlType)

		if (ctrlType == ctrlType0 && rsw.afterSwitchRegion) || (ctrlType == nextCtrlType && !rswN.beforeSwitchRegion)

			arefulfilled = false

		end

	elseif policy isa GenericPolicy

		control_steps = policy.control_steps

		control_step = state[:Controller].current_step
		control_step_previous = state0[:Controller].current_step

		step_number_previous = state0[:Controller].current_step_number
		step_index_previous = step_number_previous + 1
		step_number = state[:Controller].current_step_number
		step_index = step_number + 1

		if step_index >= policy.number_of_control_steps
			step_index_next = 1
			control_step_next = control_steps[step_index_next]
		else
			step_index_next = step_index + 1
			control_step_next = control_steps[step_index_next]
		end

		rsw  = setupRegionSwitchFlags(control_step, state, controller)
		rswN = setupRegionSwitchFlags(control_step_next, state, controller)

		if (step_index == step_index_previous && rsw.afterSwitchRegion) || (step_index == step_index_next && !rswN.beforeSwitchRegion)

			arefulfilled = false

		end

	else
		error("Policy $(typeof(policy)) not recognized")
	end






	return arefulfilled

end

################################################
# Functions to update values in the controller #
################################################


function Jutul.update_values!(old::FunctionController, new::FunctionController)

	copyController!(old, new)

end

function Jutul.update_values!(old::CCController, new::CCController)

	copyController!(old, new)

end

function Jutul.update_values!(old::SimpleControllerCV, new::SimpleControllerCV)

	copyController!(old, new)

end

function Jutul.update_values!(old::CcCvController, new::CcCvController)

	copyController!(old, new)

end

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

"""
We need to add the specific treatment of the controller variables
"""
function Jutul.reset_state_to_previous_state!(storage, model::SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{CyclingCVPolicy{T1, T2}}, T3, T4}) where {T1, T2, T3, T4}

	invoke(reset_state_to_previous_state!,
		Tuple{typeof(storage),
			SimulationModel},
		storage,
		model)
	copyController!(storage.state[:Controller], storage.state0[:Controller])
end

function Jutul.reset_state_to_previous_state!(storage, model::SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{CCPolicy{T1}}, T3, T4}) where {T1, T3, T4}

	invoke(reset_state_to_previous_state!,
		Tuple{typeof(storage),
			SimulationModel},
		storage,
		model)
	copyController!(storage.state[:Controller], storage.state0[:Controller])
end


function update_controller!(state, state0, policy::AbstractPolicy, dt)

	update_control_type_in_controller!(state, state0, policy, dt)
	update_values_in_controller!(state, policy)

end


##################################
# Implementation of the policies #
##################################

# Given a policy, a current control and state, we compute the next control
"""
Implementation of the function policy
"""
function update_control_type_in_controller!(state, state0, policy::FunctionPolicy, dt)
	controller                   = state.Controller
	controller.target_is_voltage = false
	controller.time              = state0.Controller.time + dt

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
	controller.ctrlType          = discharge # for the moment only discharge in a simple controller
	controller.time              = state0.Controller.time + dt

end

"""
Implementation of the cycling CC-CV policy
"""
function update_control_type_in_controller!(state, state0, policy::CyclingCVPolicy, dt)

	E  = only(value(state[:ElectricPotential]))
	I  = only(value(state[:Current]))
	E0 = only(value(state0[:ElectricPotential]))
	I0 = only(value(state0[:Current]))

	controller = state.Controller

	controller.time = state0.Controller.time + dt
	controller.dIdt = (I - I0) / dt
	controller.dEdt = (E - E0) / dt

	ctrlType0 = state0.Controller.ctrlType

	nextCtrlType = getNextCtrlTypecccv(ctrlType0)

	rsw00 = setupRegionSwitchFlags(policy, state0, ctrlType0)


	if rsw00.beforeSwitchRegion

		# We have not entered the switching region in the time step. We are not going to change control
		# in this step.
		ctrlType = ctrlType0

	else

		# We entered the switch region in the previous time step. We consider switching control

		currentCtrlType = state.Controller.ctrlType # current control in the the Newton iteration
		nextCtrlType0   = getNextCtrlTypecccv(ctrlType0) # next control that can occur after the previous time step control (if it changes)

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


function update_control_type_in_controller!(state, state0, policy::CCPolicy, dt)

	if policy.numberOfCycles == 0
		controller = state.Controller
		controller.time = state0.Controller.time + dt
	else

		controller = state.Controller

		controller.time = state0.Controller.time + dt

		ctrlType0 = state0.Controller.ctrlType

		nextCtrlType0 = getNextCtrlType(ctrlType0)

		rsw00 = setupRegionSwitchFlags(policy, state0, ctrlType0)

		if rsw00.beforeSwitchRegion

			# We have not entered the switching region in the time step. We are not going to change control
			# in this step.
			ctrlType = ctrlType0

		else

			# We entered the switch region in the previous time step. We consider switching control

			currentCtrlType = state.Controller.ctrlType # current control in the the Newton iteration

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


#############################################################
# Functions to update the values in the controller in state #
#############################################################

# Once the controller has been assigned the given control, we adjust the target value which is used in the equation
# assembly

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

	controller.target = target


end

function update_values_in_controller!(state, policy::FunctionPolicy)

	controller = state.Controller

	cf = policy.current_function

	I_p = cf(controller.time, value(only(state.ElectricPotential)))

	controller.target = I_p


end

function update_values_in_controller!(state, policy::SimpleCVPolicy)

	controller = state.Controller

	if controller.target_is_voltage

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
	controller.target            = target

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

		if ctrl.current_step isa VoltageStep
			v[] = phi - ctrl.target
		elseif ctrl.current_step isa CurrentStep
			v[] = I - ctrl.target
		elseif ctrl.current_step isa RestStep
			v[] = I - ctrl.target
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

""" Update after convergence. Here, we copy the controller to state0 and count the total number of cycles in case of CyclingCVPolicy
"""
function Jutul.update_after_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces; time = NaN)

	ctrl = storage.state[:Controller]

	policy = model.system.policy

	if policy isa CyclingCVPolicy

		initctrl = policy.initialControl

		ctrlType = ctrl.ctrlType

		ctrlType0 = storage.state0[:Controller].ctrlType
		ncycles   = storage.state0[:Controller].numberOfCycles

		copyController!(storage.state0[:Controller], ctrl)

		if initctrl == charging

			if (ctrlType0 == cc_discharge1 || ctrlType0 == cc_discharge2) && (ctrlType == cc_charge1 || ctrlType == cv_charge2)
				ncycles = ncycles + 1
			end

		elseif initctrl == discharging

			if (ctrlType0 == cc_charge1 || ctrlType0 == cv_charge2) && (ctrlType == cc_discharge1 || ctrlType == cc_discharge2)
				ncycles = ncycles + 1
			end

		end

		ctrl.numberOfCycles = ncycles

	elseif policy isa SimpleCVPolicy

		copyController!(storage.state0[:Controller], ctrl)

	elseif policy isa FunctionPolicy

		copyController!(storage.state0[:Controller], ctrl)

	elseif policy isa CCPolicy

		if policy.numberOfCycles == 0
			copyController!(storage.state0[:Controller], ctrl)

		else

			initctrl = policy.initialControl

			ctrlType = ctrl.ctrlType

			ctrlType0 = storage.state0[:Controller].ctrlType
			ncycles   = storage.state0[:Controller].numberOfCycles

			copyController!(storage.state0[:Controller], ctrl)

			if initctrl == "charging"

				if ctrlType0 == "discharging" && ctrlType == "charging"
					ncycles = ncycles + 1
				end

			elseif initctrl == "discharging"

				if ctrlType0 == "charging" && ctrlType == "discharging"
					ncycles = ncycles + 1
				end

			end

			ctrl.numberOfCycles = ncycles
		end

	elseif policy isa GenericPolicy

		copyController!(storage.state0[:Controller], ctrl)



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

	if policy isa SimpleCVPolicy

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

	elseif policy isa GenericPolicy
		number_of_steps = policy.number_of_control_steps
		current_step_number = 0
		current_step = policy.initial_control
		time_in_step = 0.0
		state[:Controller] = GenericController(policy, false, current_step, current_step_number, time_in_step, number_of_steps)

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

function getNextCtrlType(ctrlType::String)

	if ctrlType == "discharging"
		nextCtrlType = "charging"
	else
		nextCtrlType = "discharging"
	end
	return nextCtrlType
end

############################################
# Helper function to compute control value #
############################################

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
