abstract type AbstractControlStep end

mutable struct CurrentStep <: AbstractControlStep
	value::Float64
	direction::Union{String, Nothing}
	termination::Termination
	current_function::Union{Missing, Any}
end

struct VoltageStep <: AbstractControlStep
	value::Float64
	termination::Termination
end

mutable struct RestStep <: AbstractControlStep
	value::Union{Nothing, Float64}
	termination::Termination
end

mutable struct PowerStep <: AbstractControlStep
	value::Union{Nothing, Float64}
	direction::Union{Nothing, String}
	termination::Termination
end