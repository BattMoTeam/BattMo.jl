
abstract type AbstractStepTermination end

mutable struct Termination <: AbstractStepTermination
	quantity::String
	comparison::Union{String, Nothing}
	value::Float64
	function Termination(quantity, value; comparison = nothing)
		return new{}(quantity, comparison, value)
	end
end