
export format_battmo_input

abstract type BattMoParameters end

struct BattMoInput <: BattMoParameters
	Dict::Dict{String, Any}

end

function format_battmo_input(model::LithiumIon, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol)


	model_settings_dict = model.model_settings.dict
	cell_parameters_dict = cell_parameters.dict
	cycling_protocol_dict = cycling_protocol.dict

	model_geometry = model_settings_dict["ModelGeometry"]
	use_current_collector = model_settings_dict["UseCurrentCollectors"]
	use_thermal = model_settings_dict["UseThermalModel"]

	input = Dict()



end

function format_battmo_input_3d_pouch_current_collectors(model_settings_dict, cell_parameters_dict)

	cell_width = minimum([
		cell_parameters_dict["NegativeElectrode"]["ElectrodeCoating"]["Width"],
		cell_parameters_dict["PositiveElectrode"]["ElectrodeCoating"]["Width"],
	])

	cell_length = minimum([
		cell_parameters_dict["NegativeElectrode"]["ElectrodeCoating"]["Length"],
		cell_parameters_dict["PositiveElectrode"]["ElectrodeCoating"]["Length"],
	])
	model_settings = Dict(
		:include_current_collectors => true,
		:Geometry => Dict(
			:case => "3D-demo",
			:width => cell_width,
			:height => cell_length,
			:Nw => ,
			:Nh => ,
		),
		:NegativeElectrode => Dict(
			:Coating => Dict(
				:thickness => cell_parameters_dict["thickness"],
				:N => cell_parameters_dict["N"],
			),
			:CurrentCollector => Dict(
				:thickness => 10e-6,
				:N => 2,
				:tab => Dict(
					:width => 4e-3,
					:height => 1e-3,
					:Nw => 3,
					:Nh => 3,
				),
			),
		),
		:PositiveElectrode => Dict(
			:Coating => Dict(
				:thickness => 80e-6,
				:N => 3,
			),
			:CurrentCollector => Dict(
				:thickness => 10e-6,
				:N => 2,
				:tab => Dict(
					:width => 4e-3,
					:height => 1e-3,
					:Nw => 3,
					:Nh => 3,
				),
			),
		),
		:Separator => Dict(
			:thickness => 50e-6,
			:N => 3,
		),
	)

end

