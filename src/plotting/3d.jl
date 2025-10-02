export plot_interactive_3d

"""
plot_interactive_3d

Launch an interactive plot for visualizing simulation results of 3D geometries.
"""
function plot_interactive_3d(output::NamedTuple; shift = nothing, colormap = :curl)

	if isnothing(shift)
		shift_copy = Dict()
	else
		shift_copy = Dict()

		if haskey(shift, "NegativeActiveMaterial")

			shift_copy[:NAM] = shift["NegativeActiveMaterial"]
		end
		if haskey(shift, "PositiveActiveMaterial")
			shift_copy[:PAM] = shift["PositiveActiveMaterial"]
		end
		if haskey(shift, "CurrentCollector")
			shift_copy[:CC] = shift["CurrentCollector"]
		end
		if haskey(shift, "Electrolyte")
			shift_copy[:Electrolyte] = shift["Electrolyte"]
		end
		shift_copy[:PP] = shift["NegativeActiveMaterial"]

	end

	jutul_states = output.jutul_output.states
	solved_model = output.jutul_output.multimodel


	plot_multimodel_interactive(solved_model, jutul_states; shift = shift_copy, colormap = colormap)
end
