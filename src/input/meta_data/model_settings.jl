export get_model_settings_meta_data


function get_model_settings_meta_data()
	meta_data = Dict(
		"ModelFramework" => Dict(
			"type" => String,
			"options" => ["P2D", "P4D Pouch", "P4D Cylindrical"],
			"context_type" => "ModelFramework",
			"context_type_iri" => "https://w3id.org/emmo/domain/battery#battery_b1921f7b_afac_465a_a275_26f929f7f936",
			"category" => "ModelSettings",
			"documentation" => "https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model",
			"description" => """Framework defining the dimensionality of the electrochemical model. Examples: "P2D", "P4D Pouch". """,
		),
		"SEIModel" => Dict(
			"type" => String,
			"options" => ["Bolay"],
			"category" => "ModelSettings",
			"context_type_iri" => nothing,
			"description" => """Which SEI model is used. For instance: "Bolay" """,
			"documentation" => "https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/sei_model",
		),
		"PotentialFlowDiscretization" => Dict(
			"type" => String,
			"options" => ["GeneralAD", "TwoPointDiscretization"],
			"category" => "ModelSettings",
			"context_type_iri" => nothing,
			"description" => """Specifies the numerical backend used for solving the potential flow equations. 
								The GenericAD option uses a general automatic differentiation approach that is robust and widely applicable, 
								while the TwoPointDiscretization option applies a specialized two-point flux discretization of the conservation laws, 
									which can be faster but is less general. We recommend using GenericAD unless performance considerations dictate otherwise."""),
		"ButlerVolmer" => Dict(
			"type" => String,
			"options" => ["Standard", "Chayambuka"],
			"context_type" => "ButlerVolmerEquation",
			"context_type_iri" => "https://w3id.org/emmo/domain/battery#battery_b1921f7b_afac_465a_a275_26f929f7f936",
			"category" => "ModelSettings",
			"documentation" => "https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model",
			"description" => """When set to Chayambuka, the slightly adapted butler volmer equation from reference [Chayambuka2020](https://www.sciencedirect.com/science/article/pii/S0013468621020478?via%3Dihub) will be selected within the model.""",
		),
		"TemperatureDependence" => Dict(
			"type" => String,
			"options" => ["Arrhenius"],
			"category" => "ModelSettings",
			"documentation" => "https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/arrhenius",
			"description" => """Temperature dependence model for electrode diffusion coefficients and reaction rates. Example: "Arrhenius".""",
		),
		"ThermalModel" => Dict(
			"type" => String,
			"options" => ["Sequential"],
			"category" => "ModelSettings",
			"description" => """Sequential thermal model""",
		),
		"TransportInSolid" => Dict(
			"type" => String,
			"options" => ["FullDiffusion"],
			"category" => "ModelSettings",
			"context_type_iri" => nothing,
			"description" => """Which model is used to describe the intercalant diffusion in the solid particles. Example "FullDiffusion". """,
		),
		"CurrentCollectors" => Dict(
			"type" => String,
			"options" => ["Standard"],
			"context_type" => "CurrentCollectors",
			"context_type_iri" => nothing,
			"category" => "ModelSettings",
			"description" => "Which model describes the current collectors.",
		),
		"RampUp" => Dict(
			"type" => String,
			"options" => ["Sinusoidal"],
			"category" => "SimulationSettings",
			"context_type" => "RampUp",
			"context_type_iri" => "https://w3id.org/emmo/domain/electrochemistry#electrochemistry_rampup",
			"documentation" => "https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/ramp_up",
			"category" => "ModelSettings",
			"description" => """Type of signal of electric current used to initialize the cell simulation. Example: "Sinusoidal".""",
		),
	)

	return meta_data
end
