export AbstractOutput, SimulationOutput

abstract type AbstractOutput end

struct SimulationOutput <: AbstractOutput
	time_series::Dict{String, Any}
	states::Dict{String, Any}
	metrics::Dict{String, Any}
	input::FullSimulationInput
	jutul_output::NamedTuple
	model::ModelConfigured
	simulation::Simulation
end
