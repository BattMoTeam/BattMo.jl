
struct CycleStep <: AbstractControlStep
	number_of_cycles::Int
	termination::Union{Nothing, Termination}
	cycle_control_steps::Vector{AbstractControlStep}
end


# mutable struct GenericProtocol <: AbstractProtocol
# 	control_policy::String
# 	control_steps::Vector{AbstractControlStep}
# 	initial_control::AbstractControlStep
# 	number_of_control_steps::Int
# 	function GenericProtocol(json::Dict)
# 		steps = []
# 		for step in json["controlsteps"]
# 			parsed_step = parse_control_step(step)

# 			if isa(parsed_step, CycleStep)
# 				# If the parsed step is a compound cycle, expand it
# 				for cycle_step in parsed_step.cycle_control_steps
# 					push!(steps, cycle_step)
# 				end
# 			else
# 				# Otherwise, it's a single step — push directly
# 				push!(steps, parsed_step)
# 			end
# 		end

# 		number_of_steps = length(steps)
# 		return new(json["controlPolicy"], steps, steps[1], number_of_steps)
# 	end
# end


# function parse_control_step(json::Dict)
# 	ctype = json["controltype"]
# 	if ctype == "current"
# 		return CurrentStep(
# 			json["value"],
# 			get(json, "direction", nothing),
# 			Termination(json["termination"]["quantity"], json["termination"]["value"]; comparison = json["termination"]["comparison"]),
# 			get(json, "timeStepSize", nothing),
# 			missing)
# 	elseif ctype == "voltage"
# 		return VoltageStep(
# 			json["value"],
# 			get(json, "direction", nothing),
# 			Termination(json["termination"]["quantity"], json["termination"]["value"]; comparison = json["termination"]["comparison"]),
# 			get(json, "timeStepSize", nothing),
# 		)
# 	elseif ctype == "rest"
# 		return RestStep(
# 			get(json, "value", nothing),
# 			get(json, "direction", nothing),
# 			Termination(json["termination"]["quantity"], json["termination"]["value"]),
# 			get(json, "timeStepSize", nothing),
# 		)
# 	elseif ctype == "cycle"
# 		nested = [parse_control_step(step) for step in json["cycleControlSteps"]]
# 		return CycleStep(json["numberOfCycles"], get(json, "termination", nothing), nested)
# 	else
# 		error("Unsupported controltype: $ctype")
# 	end
# end


function setup_initial_control_policy!(policy::GenericProtocol, input, parameters)

end




