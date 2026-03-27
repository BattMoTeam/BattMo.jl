export AbstractOutput, SimulationOutput, BattMoPosition, BattMoStateArray

abstract type AbstractOutput end

struct BattMoPosition{M}
	mesh::M
	component::String
end

struct SimulationOutput <: AbstractOutput
	time_series::Dict{String, Any}
	states::Dict{String, Any}
	metrics::Dict{String, Any}
	input::FullSimulationInput
	jutul_output::NamedTuple
	model::ModelConfigured
	simulation::Simulation
end

Jutul.physical_representation(position::BattMoPosition) = physical_representation(position.mesh)

