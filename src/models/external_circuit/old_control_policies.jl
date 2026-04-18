export
	SimpleCVPolicy,
	CyclingCVPolicy,
	OperationalMode,
	InputCurrentProtocol

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

# The following variable will be added as parameters. In this way, they can also be computed when the whole battery
# model is setup

struct ImaxDischarge <: ScalarVariable end
struct ImaxCharge <: ScalarVariable end


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
mutable struct SimpleCVPolicy{R} <: AbstractProtocol
	current_function::Any
	Imax::R
	voltage::R
	function SimpleCVPolicy(; current_function = missing, Imax::T = 0.0, voltage = missing) where {T <: Real}
		return new{Union{Missing, T}}(current_function, Imax, voltage)
	end
end

""" No policy means that the control is kept fixed throughout the simulation
"""
struct NoPolicy <: AbstractProtocol end


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

function CyclingCVPolicy(
	lowerCutoffVoltage,
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
		initialControl,
		numberOfCycles,
		tolerances,
		use_ramp_up,
		current_function,
	)
end


#########################
# Select the parameters #
#########################

function Jutul.select_parameters!(
	S,
	system::ExternalCircuitSystem{CCPolicy{R}},
	model::SimulationModel,
) where {R}
	S[:ImaxDischarge] = ImaxDischarge()
	return S[:ImaxCharge] = ImaxCharge()
end

function Jutul.select_parameters!(
	S,
	system::ExternalCircuitSystem{SimpleCVPolicy{R}},
	model::SimulationModel,
) where {R}
	return S[:ImaxDischarge] = ImaxDischarge()

end

function Jutul.select_parameters!(
	S,
	system::ExternalCircuitSystem{CyclingCVPolicy{R, I}},
	model::SimulationModel,
) where {R, I}
	S[:ImaxDischarge] = ImaxDischarge()
	return S[:ImaxCharge] = ImaxCharge()
end


###########################################################################################################
# Definition of the controller and some basic utility functions. The controller will be part of the state #
###########################################################################################################


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
	return if f in fieldnames(SimpleControllerCV)
		setfield!(c.maincontroller, f, v)
	else
		setfield!(c, f, v)
	end
end

@inline function Jutul.numerical_type(x::CCController{R, I}) where {R, I}
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
	return cv_copy.ctrlType = cv.ctrlType

end



"""
Function to create (deep) copy of simple controller
"""
function copyController!(cv_copy::SimpleControllerCV, cv::SimpleControllerCV)

	cv_copy.target = cv.target
	cv_copy.time = cv.time
	cv_copy.target_is_voltage = cv.target_is_voltage
	return cv_copy.ctrlType = cv.ctrlType

end

"""
Function to create (deep) copy of CC-CV controller
"""
function copyController!(cv_copy::CcCvController, cv::CcCvController)

	copyController!(cv_copy.maincontroller, cv.maincontroller)
	return cv_copy.numberOfCycles = cv.numberOfCycles

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



###################################################################################################################
# Functions to compute initial current given the policy, it used at initialization of the state in the simulation #
###################################################################################################################
function get_initial_current(policy::CCPolicy)

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


function get_initial_current(policy::SimpleCVPolicy)
	if !ismissing(policy.current_function)
		val = policy.current_function(0.0)
	else

		val = policy.Imax

	end
	return val
end


function get_initial_current(policy::CyclingCVPolicy)
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
	end


	policy.ImaxCharge = only(parameters[:Control][:ImaxCharge])
	policy.upperCutoffVoltage = cycling_protocol["UpperVoltageLimit"]
	policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])
	return policy.lowerCutoffVoltage = cycling_protocol["LowerVoltageLimit"]

end


###################################
# Special primary variable update #
###################################

"""
We need a more fine-tuned update of the variables when we use a cycling policies, to avoid convergence problem.
"""
function Jutul.update_primary_variable!(state, p::Current, state_symbol, model::P, dx, w) where {R, I, Q <: Union{CyclingCVPolicy{R, I}, CCPolicy{R}}, P <: ExternalCircuitModel{Q}}

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

		dIdt = state.Controller.dIdt
		if !ismissing(dIdt)
			before = abs(dIdt) > dIdtMin * (1 + tol)
			after = abs(dIdt) < dIdtMin * (1 - tol)
		else
			before = false
			after = false
		end

	else

		error("Control type $ctrlType not recognized")

	end

	return (beforeSwitchRegion = before, afterSwitchRegion = after)

end



################################################
# Functions to update values in the controller #
################################################


function Jutul.update_values!(old::CCController, new::CCController)

	return copyController!(old, new)

end

function Jutul.update_values!(old::SimpleControllerCV, new::SimpleControllerCV)

	return copyController!(old, new)

end

function Jutul.update_values!(old::CcCvController, new::CcCvController)

	return copyController!(old, new)

end



"""
We need to add the specific treatment of the controller variables
"""
function Jutul.reset_state_to_previous_state!(storage, model::SimulationModel{ExternalCircuitDomain, ExternalCircuitSystem{CyclingCVPolicy{T1, T2}}, T3, T4}) where {T1, T2, T3, T4}

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

function Jutul.reset_state_to_previous_state!(storage, model::SimulationModel{ExternalCircuitDomain, ExternalCircuitSystem{CCPolicy{T1}}, T3, T4}) where {T1, T3, T4}

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



##################################
# Implementation of the policies #
##################################

# Given a policy, a current control and state, we compute the next control


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

"""
Implementation of the cycling CC-CV policy
"""
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

	return controller.target = target


end

function update_values_in_controller!(state, policy::FunctionProtocol)

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
	return controller.target = target

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

