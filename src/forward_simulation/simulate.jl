
abstract type SolvingProcess end

struct Simulate{M} where {M <: SolvingProcess}
	model::M
	cell_parameters::CellParameters
	cycling_protocol::CyclingProtocol
	simulation_settings::SimulationSettings

	function Simulate(model, cell_parameters, cycling_protocol; simulation_settings = Dict(:ModelGeometry => "1D", :UseCurrentCollector => false))
		cell_parameters_struct = CellParameters(cell_parameters)
		cycling_protocol = CellParameters(CyclingProtocol)
		simulation_settings = CellParameters(SimulationSettings)
		return new{typeof(model), typeof(cell_parameters), typeof(cycling_protocol), typeof(simulation_settings)}(model, cell_parameters, cycling_protocol, simulation_settingss)
	end
end
