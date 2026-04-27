export Separator

const SeparatorParameters = JutulStorage

struct Separator{D} <: BattMoSystem where {D <: AbstractDict}
	params::SeparatorParameters
	#  
	# - bruggeman          
	# - effective_thermal_conductivity
	# - effective_volumetric_heat_capacity
	# - density
	scalings::D
end

function Separator(params, scalings = Dict())

	return Separator{typeof(scalings)}(params, scalings)

end

const SeparatorModel = SimulationModel{<:Any, <:Separator, <:Any, <:Any}
